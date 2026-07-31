-- | Judging whether a module is one LLVM would accept.
--
-- "Olivine.Core.Verify" is the same idea one layer down, and the two divide
-- the work by what they can see.  This one judges what is written: which
-- symbols and locals and blocks there are, what refers to them, where a phi
-- stands and what it takes a value from, and everything retained beside the
-- code — a global's initializer, a declaration's clauses, what an @ifunc@
-- resolves through.  Every comment in this layer saying that something is a
-- verifier's business means here.
--
-- __What it does not judge is what an instruction means.__  Whether an
-- addition's operands agree, whether a conversion reads what it can convert,
-- which flags an opcode may carry: those are questions about types, and the
-- answer to them is the same on either side of the lowering, so the core
-- verifier asks them once, on the form the passes actually work on.  What is
-- left here is what only this layer has — the names, the block structure, the
-- phis — which is to say exactly what the lowering discards.
--
-- __It is run at both ends.__  A module that arrives broken would otherwise
-- go unnoticed: the lowering is total, and a definition it cannot take is
-- retained as written rather than refused, so a use of a local nothing defines
-- leaves the core verifier nothing to look at.  A module Olivine wrote is
-- judged by the same rules, and there the checks that have no counterpart in
-- the core are the point — putting a function back into single assignment form
-- is where a phi can end up in the wrong place, or naming a block that no
-- longer reaches it, or reading a value that does not reach the use.
--
-- __What it cannot read, it does not judge.__  An opaque entry may define a
-- symbol, a comdat or a metadata node as readily as not, so a module with one
-- is not asked what it has; an opaque instruction may assign any local, so a
-- function with one is not asked which locals are defined; a block ending in
-- an unmodelled terminator has successors nobody can name, so a function with
-- one is not asked what reaches what.  The alternative is answering from
-- whatever happens to have been understood, which would report the rest of the
-- module as wrong for being unread — and would do it to every module carrying
-- debug information, the specialized nodes being unmodelled and referred to by
-- number all through.
--
-- __Nothing is thrown.__  'verify' returns what it found, so a caller can
-- report every problem rather than the first.  An empty list is a module that
-- passes.
module Olivine.Syntax.Verify
  ( Problem (..)
  , Site (..)
  , Where (..)
  , Complaint (..)
  , verify
  , renderProblem
  , symbolsDefinedBy
  ) where

import Data.Foldable (toList)
import Data.List (nub, (\\))
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Numeric.Natural (Natural)

import Olivine.Syntax.Ast
import Olivine.Syntax.Attribute (ParamAttribute (..))
import Olivine.Syntax.Function
import Olivine.Syntax.Global
import Olivine.Syntax.Instruction
import Olivine.Syntax.Linkage
import Olivine.Syntax.Metadata (MetadataOperand (..))
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Printer (renderLinkage, renderName, renderParamAttribute)
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value
  ( TypedValue (..)
  , Value (..)
  , globalsIn
  , holdsAsm
  , isConstant
  )

-- | Something wrong, and where it is.
data Problem = Problem
  { problemSite :: Site
  , problemComplaint :: Complaint
  }
  deriving (Eq, Show)

-- | Where in a module a problem is.
--
-- A top-level entry is named by the symbol it defines, which is the only name
-- it has; an instruction is named by its position, since two identical ones in
-- a block are two instructions.
data Site
  = -- | The module as a whole, for what is wrong with no entry of it in
    -- particular.
    InModule
  | -- | A global, an alias, an ifunc, a declaration, or a definition's header.
    At Name
  | AtBlock Name Where
  | -- | The nth instruction of a block, counting from zero.
    AtInstruction Name Where Int
  deriving (Eq, Show)

-- | Which block, as a reader would find it.
data Where
  = Labelled Name
  | -- | The block written without a label, which is only ever the entry block.
    TheEntry
  deriving (Eq, Show)

-- | What is wrong.
--
-- Structured rather than a message, so that a test can say which problem it
-- expects without matching on English, and so that the wording lives in one
-- place.
data Complaint
  = -- | Two entries defining one symbol.  A declaration and a definition of
    -- the same function are two of them: LLVM reads the second as a
    -- redefinition rather than as the body of the first.
    RedefinedSymbol Name
  | RedefinedType Name
  | -- | Two comdat groups of one name.  A comdat is not a symbol and has a
    -- namespace of its own, so this is a separate complaint from
    -- 'RedefinedSymbol' rather than the same one.
    RedefinedComdat Name
  | RedefinedMetadata Natural
  | -- | A reference to a symbol the module does not have.
    UndefinedSymbol Name
  | -- | A @comdat@ clause naming a group the module does not have.  A clause
    -- written bare names the group the symbol's own name spells, so this is
    -- the name it was resolved to rather than the name that was written.
    UndefinedComdat Name
  | UndefinedMetadata Natural
  | -- | A linkage on something with no definition present that promises one.
    -- LLVM allows a declaration @external@ and @extern_weak@ and no other.
    LinkageNotForDeclaration Linkage
  | -- | @extern_weak@ on something with a definition present, which is the
    -- one linkage that says there is none.
    LinkageNotForDefinition Linkage
  | -- | A linkage an alias or an ifunc may not take.  Both are definitions of
    -- a symbol, so the four that say a definition is elsewhere or absent are
    -- rejected for both.
    LinkageNotForIndirect Linkage
  | -- | A global initialized to something that is not a compile-time
    -- constant, which is what the type deliberately no longer refuses.
    InitializerNotConstant
  | -- | An alias or ifunc whose target is not a constant.
    TargetNotConstant
  | -- | An ifunc resolving through a constant expression rather than through
    -- a symbol.  An alias may compute an address; an ifunc needs a function
    -- it can call.
    ResolverNotSymbol
  | -- | A @comdat@ clause on a @declare@, which defines nothing to put in a
    -- group.
    ComdatOnDeclaration
  | -- | A @personality@ on a @declare@.  LLVM takes @gc@ and @prefix@ there
    -- and refuses this one, which says what an unwinder should do about a
    -- body that is not present.
    --
    -- An attachment was once judged here too, and wrongly: a declaration does
    -- carry one, and every declaration clang writes under @-g@ does.  What
    -- misled the rule was asking about @declare void \@f() !dbg !3@, which
    -- LLVM refuses as a parse error rather than as a complaint — the
    -- attachment on a declaration goes before the return type, not after the
    -- parameters.  See 'Olivine.Syntax.Function.AttachmentPosition'.
    ClauseOnDeclaration
  | -- | A @prefix@, @prologue@ or @personality@ given something that is not a
    -- compile-time constant.  There is nothing else it could be: the header
    -- stands where no local exists yet.
    ClauseNotConstant
  | -- | A @landingpad@ that neither catches anything nor asks for cleanup,
    -- which tells the personality routine nothing.
    LandingPadEmpty
  | -- | A @landingpad@ standing after an instruction that is not a phi.  It
    -- says what the block is for, so it comes before the block does anything.
    LandingPadNotFirst
  | -- | A block beginning with a @landingpad@ that something other than the
    -- unwind edge of an @invoke@ leads to.  Control arrives there holding an
    -- exception, and no ordinary branch has one to hand over.
    LandingPadNotUnwound
  | -- | An @invoke@ whose unwind destination does not begin with a
    -- @landingpad@.
    UnwindNotToLandingPad
  | -- | A @landingpad@ or a @resume@ in a function with no @personality@.
    -- Neither means anything without the routine that decides what an
    -- unwinder does here.
    PersonalityMissing
  | -- | An attribute in the return position that belongs to a parameter.
    AttributeNotOnReturn ParamAttribute
  | -- | A definition with nothing in it, which is a declaration written wrong.
    NoBlocks
  | -- | Two blocks with one label.  A label is the whole of a block's
    -- identity, so two blocks sharing one are not two blocks.
    DuplicateBlock Name
  | -- | A local assigned twice.  This layer is LLVM's, where a local is
    -- defined once; it is the core that lets one be reassigned.
    DuplicateLocal Name
  | -- | A block that does not end in a terminator.
    NoTerminator
  | -- | A terminator with instructions after it.  LLVM's parser takes those
    -- for a block of their own and its verifier then rejects the pair, and
    -- Olivine reads them as the one block they are written as, so the two do
    -- not even agree on what the function is.
    TerminatorNotLast
  | -- | A branch to a block the function does not have.
    MissingBlock Name
  | -- | A branch to the entry block, which LLVM rejects: a function starts
    -- there, so nothing may arrive there.
    BranchToEntry
  | -- | An operand naming a local nothing in the function defines.
    UndefinedLocal Name
  | -- | A local read where its definition does not reach.  LLVM asks that a
    -- definition dominate every use of it, which is what makes a value read
    -- exactly where it is known to have been computed; a block that nothing
    -- reaches is exempt, having no path along which anything could be wrong.
    NotDominated Name
  | -- | A result named for an operation that produces no value.  A value
    -- assigned to nothing is not the mirror of this and is not a complaint:
    -- LLVM numbers such a result itself.
    ResultOfVoid
  | -- | A phi standing after something that is not one.  Phis are what a
    -- block is entered with, so they are all of them at the top or the block
    -- means nothing definite.
    PhiNotFirst
  | -- | An edge into this block that the phi has no value for.
    PhiEntryMissing Name
  | -- | A value the phi takes from somewhere that does not branch here.
    PhiEntryUnexpected Name
  | -- | A @switch@ case that is not a compile-time constant.
    CaseNotConstant
  | -- | Inline assembly written somewhere other than the callee of a call.
    -- It is what a call calls, not a value that can be passed about: LLVM's
    -- parser reads one nowhere else, so this catches a pass rather than a
    -- module.
    AsmNotCallee
  | -- | A @callbr@ calling something that is not inline assembly.  LLVM's
    -- parser reads one — a @callbr@ of a function parses — and its verifier
    -- then refuses it: @Callbr is currently only used for asm-goto@.  The
    -- construct exists for assembly that branches, and nothing else has a way
    -- to reach the destinations it names.
    CallBrNotAsm
  deriving (Eq, Show)

-- | Every problem in a module, in the order the module is written.
verify :: Module -> [Problem]
verify (Module entries) =
  map (Problem InModule) (redefinitions entries) <> concatMap (inEntry known) entries
  where
    known =
      Known
        { knownWhole = not (any opaque entries)
        , knownSymbols = Set.fromList (concatMap symbolsDefinedBy entries)
        , knownComdats = Set.fromList [name | EComdat name _ <- entries]
        , knownNodes = Set.fromList [node | EMetadata node _ _ <- entries]
        }

    opaque (EOpaque _) = True
    opaque _ = False

-- | The symbols a top-level entry defines.
--
-- Shared with the core verifier, which asks the same question of the entries
-- it retained: what defines a symbol is a fact about this grammar, and a
-- second copy of it would be a second place to forget a construct.
symbolsDefinedBy :: Entry -> [Name]
symbolsDefinedBy entry = case entry of
  EGlobal g -> [globalName g]
  EIndirect s -> [indirectName s]
  EDeclare signature -> [signatureName signature]
  EDefine d -> [signatureName (definitionSignature d)]
  _ -> []

-- | What the module has, for everything that refers to something by name.
--
-- Three namespaces, because @\@g@ and @$g@ and @!0@ are three unrelated names
-- and a definition of one is no definition of another.
data Known = Known
  { -- | Whether every entry was read.  An unread line can define into any of
    -- the three and there is no telling which, so nothing is asked of any of
    -- them while one is outstanding.
    knownWhole :: Bool
  , knownSymbols :: Set Name
  , knownComdats :: Set Name
  , knownNodes :: Set Natural
  }

-- | Whether the module has what is named here, when it can be said what the
-- module has at all.
has :: Ord a => (Known -> Set a) -> Known -> a -> Bool
has which known x = not (knownWhole known) || Set.member x (which known)

-- | Each namespace that admits one definition of a name, asked once.
redefinitions :: [Entry] -> [Complaint]
redefinitions entries =
  map RedefinedSymbol (repeated (concatMap symbolsDefinedBy entries))
    <> map RedefinedType (repeated [name | ETypeDefinition name _ <- entries])
    <> map RedefinedComdat (repeated [name | EComdat name _ <- entries])
    <> map RedefinedMetadata (repeated [node | EMetadata node _ _ <- entries])

inEntry :: Known -> Entry -> [Problem]
inEntry known entry = case entry of
  EGlobal g -> at (globalName g) (global known g)
  EIndirect s -> at (indirectName s) (indirect known s)
  EDeclare signature -> at (signatureName signature) (declaration known signature)
  EDefine d -> definition known d
  -- A node stands on its own line and is referred to by number, so the number
  -- in the complaint is the whole of where it is.
  EMetadata _ _ operands -> atModule (concatMap (metadataOperand known) operands)
  ENamedMetadata _ nodes -> atModule (concatMap (nodeReference known) nodes)
  _ -> []
  where
    at name = map (Problem (At name))
    atModule = map (Problem InModule)

-- * What is retained beside the code

global :: Known -> Global -> [Complaint]
global known g =
  [InitializerNotConstant | Just value <- [initializer], not (isConstant value)]
    -- An initializer is what makes a global a definition: @\@g = external
    -- global i32@ says the storage is somewhere else.
    <> linkageOf (globalLinkage g) (if isJust initializer then Defined else Declared)
    <> concatMap (clause known (globalName g)) (globalAttributes g)
    <> concatMap (nodeReference known . attachmentNode) (globalMetadata g)
    <> symbols known (foldMap globalsIn initializer)
  where
    initializer = globalInitializer g

indirect :: Known -> IndirectSymbol -> [Complaint]
indirect known s =
  [ LinkageNotForIndirect l
  | Just l <- [indirectLinkage s]
  , l `elem` [LinkAvailableExternally, LinkCommon, LinkAppending, LinkExternWeak]
  ]
    <> [TargetNotConstant | not (isConstant target)]
    <> [ResolverNotSymbol | indirectKind s == IndirectIFunc, not (symbol target)]
    <> symbols known (globalsIn target)
  where
    target = indirectTarget s
    symbol (VGlobal _) = True
    symbol _ = False

declaration :: Known -> Signature -> [Complaint]
declaration known signature =
  [ComdatOnDeclaration | GAComdat _ <- signatureClauses signature]
    <> [ClauseOnDeclaration | FCPersonality _ <- signatureFunctionClauses signature]
    <> linkageOf (signatureLinkage signature) Declared
    <> header known signature

-- | What a signature says whether it is a declaration's or a definition's.
header :: Known -> Signature -> [Complaint]
header known signature =
  returnAttributes (signatureReturnAttributes signature)
    <> concatMap (clause known (signatureName signature)) (signatureClauses signature)
    <> concatMap functionClause (signatureFunctionClauses signature)
    <> concatMap (nodeReference known . attachmentNode) (signatureMetadata signature)
  where
    -- The three clauses holding a value are asked the same two questions the
    -- initializer of a global is asked, and for the same reason: it is a
    -- constant standing outside any body, naming symbols the module must have.
    functionClause c = case c of
      FCGarbageCollector _ -> []
      FCPrefix value -> constant value
      FCPrologue value -> constant value
      FCPersonality value -> constant value
    constant (TypedValue _ value) =
      [ClauseNotConstant | not (isConstant value)]
        <> symbols known (globalsIn value)

-- | Whether a definition of the symbol is present here, which is what its
-- linkage is judged against: the same word means one thing on a function with
-- a body and something else on one without.
data Presence
  = Defined
  | Declared

linkageOf :: Maybe Linkage -> Presence -> [Complaint]
linkageOf Nothing _ = []
linkageOf (Just l) Defined = [LinkageNotForDefinition l | l == LinkExternWeak]
linkageOf (Just l) Declared =
  [LinkageNotForDeclaration l | l `notElem` [LinkExternal, LinkExternWeak]]

-- | A trailing clause, of which only @comdat@ refers to anything.
clause :: Known -> Name -> GlobalAttribute -> [Complaint]
clause known owner (GAComdat which) =
  [UndefinedComdat name | not (has knownComdats known name)]
  where
    -- Written bare, it means the group the symbol's own name spells.
    name = fromMaybe owner which
clause _ _ _ = []

returnAttributes :: [ParamAttribute] -> [Complaint]
returnAttributes attributes =
  [AttributeNotOnReturn a | a <- attributes, not (onReturn a)]

-- | Whether an attribute may qualify a return value rather than a parameter.
--
-- The list is the one LLVM accepts, which is shorter than it looks: an
-- attribute describing where an argument is passed or what the callee does
-- with it — @byval@, @sret@, @nest@, @writeonly@ — has nothing to say about a
-- value coming back.  What is left describes the value itself.
onReturn :: ParamAttribute -> Bool
onReturn attribute = case attribute of
  PAZeroExt -> True
  PASignExt -> True
  PANoExt -> True
  PAInReg -> True
  PANoAlias -> True
  PANoCapture -> True
  PANonNull -> True
  PANoUndef -> True
  PAAlign _ -> True
  PAAlignStack _ -> True
  PADereferenceable _ -> True
  PADereferenceableOrNull _ -> True
  PARange _ -> True
  PANoFPClass _ -> True
  _ -> False

metadataOperand :: Known -> MetadataOperand -> [Complaint]
metadataOperand known operand = case operand of
  MDRef node -> nodeReference known node
  MDTuple operands -> concatMap (metadataOperand known) operands
  MDValue value -> symbols known (globalsIn (typedValue value))
  MDString _ -> []
  MDNull -> []

nodeReference :: Known -> Natural -> [Complaint]
nodeReference known node =
  [UndefinedMetadata node | not (has knownNodes known node)]

-- | Whether the module has every symbol named here.
symbols :: Known -> [Name] -> [Complaint]
symbols known names =
  [UndefinedSymbol name | name <- nub names, not (has knownSymbols known name)]

-- * What a function is made of

definition :: Known -> Definition -> [Problem]
definition known d =
  map (Problem (At name)) whole
    <> concat (zipWith inBlock [0 ..] blocks)
  where
    signature = definitionSignature d
    name = signatureName signature
    blocks = definitionBlocks d

    whole =
      header known signature
        <> linkageOf (signatureLinkage signature) Defined
        <> [NoBlocks | null blocks]
        <> map DuplicateBlock (repeated labels)
        <> map DuplicateLocal (repeated assigned)

    -- What each block is called, and where each name leads.  A block written
    -- without a label is the entry block under the number LLVM gives it, so
    -- that a phi naming it is understood.
    labels = map labelOf blocks
    labelOf b = maybe (entryBlockName signature) blockLabelName (blockLabel b)
    -- First wins, so that a duplicated label — already complained about —
    -- leaves the earlier block reachable rather than neither.
    index = Map.fromList (reverse (zip labels [0 :: Int ..]))
    at label = Map.lookup label index

    site b = maybe TheEntry (Labelled . blockLabelName) (blockLabel b)

    -- * The control flow graph
    --
    -- Successors are taken from the terminator alone, and only when it is one
    -- this layer models, so a function ending a block in something unread has
    -- edges nobody can see and the questions that need all of them go unasked.
    successorsOf b = case lastOf (blockBody b) of
      Just (IOperation _ operation _) -> destinationsOf operation
      _ -> []

    -- Once for each edge rather than once for each block, which is how LLVM
    -- counts a phi's entries.
    predecessorsOf i =
      [ q
      | (q, b) <- zip [0 ..] blocks
      , target <- successorsOf b
      , at target == Just i
      ]

    charted = all readable blocks
    readable b = case lastOf (blockBody b) of
      Just (IOperation _ operation _) -> isTerminator operation
      _ -> False

    -- Which blocks stand between the entry and each block, in the sense that
    -- control cannot arrive at the one without having passed the other.
    --
    -- Every block starts out dominated by everything and loses whatever a
    -- predecessor does not have, so a block nothing reaches keeps the lot and
    -- every definition reaches every use in it.  That is LLVM's answer too:
    -- an unreachable block has no path along which a value could be missing.
    dominators :: [Set Int]
    dominators = settle (Set.singleton 0 : replicate (length blocks - 1) everything)
      where
        everything = Set.fromList (take (length blocks) [0 ..])
        settle current =
          let next = step current
           in if next == current then current else settle next
        step current =
          [ if i == 0 then Set.singleton 0 else Set.insert i (meet current i)
          | i <- take (length blocks) [0 ..]
          ]
        meet current i = case [current !! q | q <- predecessorsOf i] of
          [] -> everything
          sets -> foldr1 Set.intersection sets

    dominates above below = Set.member above (dominators !! below)

    -- * What the function defines
    --
    -- The parameters, and then each result in the order written.  A local is
    -- defined once in LLVM, so a name appearing twice here is a redefinition
    -- rather than a reassignment.
    assigned =
      [name' | p <- signatureParameters signature, Just name' <- [parameterName p]]
        <> [ result
           | b <- blocks
           , IOperation (Just result) _ _ <- blockBody b
           ]

    definitions :: Map Name Place
    definitions =
      Map.fromListWith
        (\_ first -> first)
        ( [ (name', AParameter)
          | p <- signatureParameters signature
          , Just name' <- [parameterName p]
          ]
            <> [ (result, Assigned bi ii)
               | (bi, b) <- zip [0 ..] blocks
               , (ii, IOperation (Just result) _ _) <- zip [0 ..] (blockBody b)
               ]
        )

    -- Whether every local the function has is one the source named.
    --
    -- An unread line may assign anything.  So may a result left unwritten:
    -- LLVM numbers one of those itself, from a counter running through
    -- everything a function leaves unnamed, and a later @%1@ refers to
    -- whatever it landed on.  Either way the names here are not all the names
    -- there are, and a verifier that went by them would report a definition it
    -- could not see as a use of nothing.  Neither is a gap in what Olivine
    -- accepts: the lowering reads the same names and retains a definition
    -- whose locals it cannot account for.
    named = all spelled (concatMap blockBody blocks)
    spelled (IOperation result operation _) =
      not (producesValue operation) || isJust result
    spelled (IOpaque _) = False

    -- Whether a local is defined, and defined somewhere control has been.
    reaching point local
      | not named = []
      | otherwise = case Map.lookup local definitions of
          Nothing -> [UndefinedLocal local]
          Just place -> [NotDominated local | not (place `reaches` point)]

    reaches AParameter _ = True
    reaches (Assigned bi ii) point = case point of
      Before bj ij
        | bi == bj -> ii < ij
        | otherwise -> dominates bi bj
      -- A value arriving along an edge is read where that edge leaves, which
      -- everything in the block it leaves has already been computed by.
      Leaving bj
        | bi == bj -> True
        | otherwise -> dominates bi bj

    -- * Block by block

    -- * Landing pads
    --
    -- Whether a block begins with one, where 'Nothing' means the head of the
    -- block holds a line nobody has read and so nothing is known either way.
    -- Phis come first if there are any, which LLVM allows and this skips.
    isPad i = at' i >>= \b -> case dropWhile isPhiInstruction (blockBody b) of
      IOpaque _ : _ -> Nothing
      IOperation _ (OLandingPad _) _ : _ -> Just True
      _ -> Just False
    at' i = if i < length blocks then Just (blocks !! i) else Nothing

    -- The edges arriving at a block that carry an exception, counted the way
    -- 'predecessorsOf' counts edges.
    unwindEdgesTo i =
      [ q
      | (q, b) <- zip [0 :: Int ..] blocks
      , Just (IOperation _ (OInvoke v) _) <- [lastOf (blockBody b)]
      , at (invokeUnwind v) == Just i
      ]

    hasPersonality = or [True | FCPersonality _ <- signatureFunctionClauses signature]

    inBlock bi b =
      map (Problem (AtBlock name (site b))) blockwide
        <> concat (zipWith (instruction bi b) [0 ..] (blockBody b))
      where
        blockwide =
          ( case lastOf (blockBody b) of
              -- A block ending in a line nobody has read may well end in a
              -- terminator; only a block ending in something known not to be
              -- one is known to be missing it.
              Just (IOperation _ operation _) -> [NoTerminator | not (isTerminator operation)]
              Just (IOpaque _) -> []
              Nothing -> [NoTerminator]
          )
            -- A pad is where an unwinder resumes the function, so every way in
            -- has to be one that carries an exception.  Asked only where the
            -- whole graph is visible, since an unread terminator may hold the
            -- very edge that would make this right.
            <> [ LandingPadNotUnwound
               | charted
               , isPad bi == Just True
               , predecessorsOf bi /= unwindEdgesTo bi
               ]

    instruction bi b ii i =
      map (Problem (AtInstruction name (site b) ii)) $ case i of
        IOpaque _ -> []
        IOperation result operation attachments ->
          [TerminatorNotLast | isTerminator operation, ii + 1 /= length (blockBody b)]
            <> [ResultOfVoid | Just _ <- [result], not (producesValue operation)]
            <> [ PhiNotFirst
               | isPhi operation
               , not (all isPhiInstruction (take ii (blockBody b)))
               ]
            <> concatMap destination (destinationsOf operation)
            <> [ CaseNotConstant
               | OSwitch _ _ cases <- [operation]
               , (value, _) <- cases
               , not (isConstant (typedValue value))
               ]
            <> incoming bi operation
            <> [ a
               | Just c <- [callOf operation]
               , a <- returnAttributes (callReturnAttributes c)
               ]
            <> [ AsmNotCallee
               | operand <- besideTheCallee operation
               , holdsAsm (typedValue operand)
               ]
            <> [ CallBrNotAsm
               | OCallBr c <- [operation]
               , not (holdsAsm (typedValue (callCallee (callBrCall c))))
               ]
            <> exceptional bi b ii operation
            <> reading bi ii operation
            <> symbols
              known
              [g | operand <- toList operation, g <- globalsIn (typedValue operand)]
            <> concatMap (nodeReference known . attachmentNode) attachments

    -- What the three exception handling instructions ask of the function
    -- around them.
    exceptional _ b ii operation = case operation of
      OLandingPad p ->
        [LandingPadEmpty | not (landingPadCleanup p), null (landingPadClauses p)]
          <> [ LandingPadNotFirst
             | not (all isPhiInstruction (take ii (blockBody b)))
             ]
          <> [PersonalityMissing | not hasPersonality]
          <> [ ClauseNotConstant
             | clause <- landingPadClauses p
             , value <- toList clause
             , not (isConstant (typedValue value))
             ]
      OResume _ -> [PersonalityMissing | not hasPersonality]
      OInvoke v ->
        [ UnwindNotToLandingPad
        | Just target <- [at (invokeUnwind v)]
        , isPad target == Just False
        ]
      _ -> []

    destination label = case at label of
      Nothing -> [MissingBlock label]
      Just 0 -> [BranchToEntry]
      Just _ -> []

    -- What a phi says it is entered from has to be what enters: one value for
    -- each edge, and none from anywhere else.  Both halves are LLVM's rule,
    -- and both are things reconstruction can get wrong.
    incoming bi (OPhi p) =
      [PhiEntryMissing q | charted, q <- expected \\ given]
        <> [PhiEntryUnexpected q | charted, q <- given \\ expected]
      where
        given = map snd (phiIncoming p)
        expected = [labels !! q | q <- predecessorsOf bi]
    incoming _ _ = []

    -- Where each operand is read, which for a phi is the end of the block the
    -- value comes from rather than the phi's own position.
    reading _ _ (OPhi p) =
      [ complaint
      | (value, q) <- phiIncoming p
      , Just qi <- [at q]
      , local <- toList value
      , complaint <- reaching (Leaving qi) local
      ]
    reading bi ii operation =
      [ complaint
      | operand <- toList operation
      , local <- toList operand
      , complaint <- reaching (Before bi ii) local
      ]

-- | Where a local is defined.
data Place
  = AParameter
  | -- | The nth instruction of the nth block.
    Assigned Int Int

-- | Where a local is read.
data Point
  = Before Int Int
  | -- | Along an edge out of a block, which is where a phi reads its operands.
    Leaving Int

isPhi :: Operation operand -> Bool
isPhi (OPhi _) = True
isPhi _ = False

-- | Every operand of an operation except the one that may be inline assembly.
--
-- A call is the whole of the exception: its callee is where an @asm@ belongs,
-- and its arguments — and whatever its bundles carry — are operands like any
-- other.  Written by naming what is kept rather than by dropping what is not,
-- so a call gaining an operand cannot silently become a place assembly may be
-- written; the bundles are here because it did gain one.
besideTheCallee :: Operation operand -> [operand]
besideTheCallee operation = case callOf operation of
  Just c -> map argumentValue (callArguments c) <> concatMap toList (callBundles c)
  Nothing -> toList operation

isPhiInstruction :: Instruction -> Bool
isPhiInstruction (IOperation _ operation _) = isPhi operation
isPhiInstruction (IOpaque _) = False

-- | Whether an operation leaves a value to be named.
--
-- The question a result name asks, and the only type question this layer has
-- to answer: LLVM refuses a name to an operation that produces nothing.  What
-- a call produces is the return type of the function type written on it, or
-- of the return type written alone, which is what that field holds.
producesValue :: Operation operand -> Bool
producesValue operation = case operation of
  -- The three calls, whatever they do about control afterwards.
  _ | Just c <- callOf operation -> returns (callType c) /= TVoid
  ORet _ -> False
  OBr _ -> False
  OCondBr{} -> False
  OSwitch{} -> False
  OIndirectBr{} -> False
  OUnreachable -> False
  OStore _ -> False
  -- The two atomic operations that leave nothing behind.  A store is a store
  -- however it is ordered, and a fence does not touch memory at all.
  OAtomicStore _ -> False
  OFence _ -> False
  OResume _ -> False
  _ -> True
  where
    returns (TFunction t _ _) = t
    returns t = t

-- | The last of a list, for the several questions that are about how a block
-- ends and have no answer for one with nothing in it.
lastOf :: [a] -> Maybe a
lastOf [] = Nothing
lastOf xs = Just (last xs)

repeated :: Eq a => [a] -> [a]
repeated xs = nub (xs \\ nub xs)

-- * Saying what was found

-- | One problem, as a line for whoever is reading.
renderProblem :: Problem -> Text
renderProblem p = place (problemSite p) <> renderComplaint (problemComplaint p)
  where
    place InModule = T.empty
    place (At name) = "@" <> renderName name <> ": "
    place (AtBlock name w) = "@" <> renderName name <> ", " <> renderWhere w <> ": "
    place (AtInstruction name w index) =
      "@"
        <> renderName name
        <> ", "
        <> renderWhere w
        <> ", instruction "
        <> number index
        <> ": "

renderWhere :: Where -> Text
renderWhere (Labelled label) = "%" <> renderName label
renderWhere TheEntry = "the entry block"

renderComplaint :: Complaint -> Text
renderComplaint complaint = case complaint of
  RedefinedSymbol name -> "@" <> renderName name <> " is defined twice"
  RedefinedType name -> "%" <> renderName name <> " is defined twice"
  RedefinedComdat name -> "$" <> renderName name <> " is defined twice"
  RedefinedMetadata node -> "!" <> natural node <> " is defined twice"
  UndefinedSymbol name -> "@" <> renderName name <> " is defined nowhere in the module"
  UndefinedComdat name -> "$" <> renderName name <> " is defined nowhere in the module"
  UndefinedMetadata node -> "!" <> natural node <> " is defined nowhere in the module"
  LinkageNotForDeclaration l ->
    renderLinkage l <> ", which promises a definition that is not here"
  LinkageNotForDefinition l ->
    renderLinkage l <> ", which says there is no definition, on one that has it"
  LinkageNotForIndirect l ->
    renderLinkage l <> ", which an alias or an ifunc may not take"
  InitializerNotConstant -> "an initializer that is not a constant"
  TargetNotConstant -> "a target that is not a constant"
  ResolverNotSymbol -> "an ifunc resolving through something that is not a symbol"
  ComdatOnDeclaration -> "a comdat on a declaration, which defines nothing to put in one"
  ClauseOnDeclaration ->
    "a personality on a declaration, which has no body for it to describe"
  ClauseNotConstant -> "a clause given something that is not a constant"
  LandingPadEmpty -> "a landing pad with neither a clause nor a cleanup"
  LandingPadNotFirst -> "a landing pad standing after an instruction that is not a phi"
  LandingPadNotUnwound ->
    "a landing pad reached by something that is not the unwind edge of an invoke"
  UnwindNotToLandingPad -> "an invoke unwinding to a block that has no landing pad"
  PersonalityMissing ->
    "a landing pad or a resume in a function with no personality"
  AttributeNotOnReturn a ->
    renderParamAttribute a <> ", which does not apply to a return value"
  NoBlocks -> "a definition with no blocks in it"
  DuplicateBlock label -> "two blocks are both %" <> renderName label
  DuplicateLocal local -> "%" <> renderName local <> " is assigned twice"
  NoTerminator -> "a block that does not end in a terminator"
  TerminatorNotLast -> "a terminator with instructions after it"
  MissingBlock label -> "a branch to %" <> renderName label <> ", which is not there"
  BranchToEntry -> "a branch to the entry block, which may not be a destination"
  UndefinedLocal local -> "%" <> renderName local <> " is defined nowhere"
  NotDominated local ->
    "%" <> renderName local <> " is read where its definition does not reach"
  ResultOfVoid -> "a result named for an operation that produces no value"
  PhiNotFirst -> "a phi standing after an instruction that is not one"
  PhiEntryMissing label ->
    "nothing for the edge from %" <> renderName label <> ", which branches here"
  PhiEntryUnexpected label ->
    "a value from %" <> renderName label <> ", which does not branch here"
  CaseNotConstant -> "a switch case that is not a constant"
  AsmNotCallee -> "inline assembly somewhere other than as a callee"
  CallBrNotAsm -> "a callbr calling something that is not inline assembly"

number :: Int -> Text
number = T.pack . show

natural :: Natural -> Text
natural = T.pack . show
