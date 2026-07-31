-- | Syntax to core.
--
-- Total, by the same device the syntax layer used: a definition the lowering
-- cannot take is retained as syntax rather than rejected, so a program always
-- lowers and what is not yet handled still comes back out intact.
module Olivine.Core.Lower
  ( lower
  ) where

import Control.Monad (guard)
import Data.List (partition)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Numeric.Natural (Natural)

import Olivine.Core.Instruction
import Olivine.Core.Phi (Joined (..), PhiNode (..), eliminate)
import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction (isTerminator)
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Type qualified as Syntax
import Olivine.Syntax.Value (TypedValue (..), Value (..))

lower :: Syntax.Module -> Program
lower m = Program (map (lowerEntry (typesIn m)) (Syntax.moduleEntries m))

lowerEntry :: Map Name Type -> Syntax.Entry -> Entry
lowerEntry types entry = case entry of
  Syntax.EDefine definition ->
    maybe (ERetained entry) EFunction (lowerDefinition types definition)
  _ -> ERetained entry

-- | What each named type stands for.
--
-- Needed because a @getelementptr@ walking into a named struct says what the
-- next index means only by way of the definition: @%struct.point@ is the
-- field's owner, and which field the index picks is a fact about the body.
-- Lowering sees the whole module, so it can look.
typesIn :: Syntax.Module -> Map Name Type
typesIn m =
  Map.fromList [(name, t) | Syntax.ETypeDefinition name t <- Syntax.moduleEntries m]

-- | Lower a definition, or refuse it whole.
--
-- Refusing covers a branch to a block that is not there as well as an
-- instruction that is not modelled: every label becomes a 'Label' by looking
-- it up, so a destination nothing defines has nothing to become, and the
-- definition is retained as written rather than lowered into a graph with an
-- edge to nowhere.
lowerDefinition :: Map Name Type -> Syntax.Definition -> Maybe Function
lowerDefinition types definition = do
  -- Taking a @getelementptr@ apart makes instructions the source did not
  -- name, so a counter runs through the blocks issuing locals for them.  It
  -- starts past everything the source named and ends where phi elimination
  -- picks up.
  (issued, blocks) <-
    mapAccumM
      (readBlock types labels locals)
      (Map.size locals)
      (zip (map Label [0 ..]) written)
  pure
    Function
      { functionSignature = signature {Syntax.signatureParameters = nameless}
      , functionParameters = take (length parameters) (map Local [0 ..])
      , functionBlocks = eliminate (length written) issued blocks
      }
  where
    signature = Syntax.definitionSignature definition
    parameters = Syntax.signatureParameters signature
    written = Syntax.definitionBlocks definition

    -- Blocks are labelled by where they were written, which is the one thing
    -- about a block that cannot be ambiguous.
    labels =
      Map.fromList
        [ (nameOf block, Label i)
        | (i, block) <- zip [0 ..] written
        ]
    nameOf block =
      maybe (Syntax.entryBlockName signature) Syntax.blockLabelName (Syntax.blockLabel block)

    -- Every local the function defines, in the order written: the parameters
    -- first, then each result.  A local is defined once in LLVM, so this
    -- names every local there is, and an operand naming anything else is a
    -- use of something undefined — which fails the definition rather than
    -- lowering into a reference to nothing.
    locals =
      Map.fromList
        (zip ([name | p <- parameters, Just name <- [Syntax.parameterName p]] <> results) (map Local [0 ..]))
    results =
      [ name
      | b <- written
      , Syntax.IOperation (Just name) _ _ <- Syntax.blockBody b
      ]
    -- The names in the signature are not what the body calls the parameters
    -- any more, so they are not kept: 'functionParameters' says what is, and
    -- the raising writes the names LLVM will see.
    nameless = [p {Syntax.parameterName = Nothing} | p <- parameters]

readBlock ::
  Map Name Type ->
  Map Name Label ->
  Map Name Local ->
  Int ->
  (Label, Syntax.BasicBlock) ->
  Maybe (Int, Joined)
readBlock types labels locals issued (label, block) = do
  (body, terminator) <- split labels locals (Syntax.blockBody block)
  let (phis, rest) = partition isPhi body
  -- A phi becomes assignments on the edges that reach it, and an edge into a
  -- landing pad is one nothing may be put on: LLVM asks that an invoke unwind
  -- to a block that begins with a pad, so a block holding the copies cannot
  -- stand between them.  The way round it is to give each such edge a pad of
  -- its own, copied from this one, and until that is here the definition is
  -- retained as written.  Nothing clang emits at -O0 has one, phis being what
  -- promotion produces rather than what a front end writes.
  guard (null phis || not (any isLandingPad rest))
  written <- traverse phi phis
  (issued', instructions) <- mapAccumM instruction issued rest
  pure (issued', Joined label written (concat instructions) terminator)
  where
    isPhi (Syntax.IOperation _ (Syntax.OPhi _) _) = True
    isPhi _ = False
    isLandingPad (Syntax.IOperation _ (Syntax.OLandingPad _) _) = True
    isLandingPad _ = False
    phi (Syntax.IOperation (Just name) (Syntax.OPhi p) _) =
      PhiNode
        <$> Map.lookup name locals
        <*> pure (Syntax.phiType p)
        <*> traverse
          (bitraverse (traverse (`Map.lookup` locals) . typedValue) (`Map.lookup` labels))
          (Syntax.phiIncoming p)
    phi _ = Nothing

    -- One written instruction is one core instruction, except a
    -- @getelementptr@, which is as many as it has steps.
    instruction n (Syntax.IOperation result operation metadata) = do
      assigns <- traverse (`Map.lookup` locals) result
      case operation of
        Syntax.OGetElementPtr g -> do
          steps <- traverse (traverse (`Map.lookup` locals)) g
          lowerGep types n assigns metadata steps
        _ -> do
          core <- lowerOperation locals operation
          pure (n, [Instruction assigns core metadata])
    instruction _ _ = Nothing

    bitraverse f g (x, y) = (,) <$> f x <*> g y

-- | Traverse with a counter, failing whole.
--
-- 'traverse' would do this with a state applicative, which would mean a
-- dependency and a newtype for one use.
mapAccumM :: (s -> a -> Maybe (s, b)) -> s -> [a] -> Maybe (s, [b])
mapAccumM _ s [] = Just (s, [])
mapAccumM f s (x : xs) = do
  (s', y) <- f s x
  (s'', ys) <- mapAccumM f s' xs
  pure (s'', y : ys)

-- | One operation, on the other side of the boundary.
--
-- Renaming the locals comes first and is the derived traversal, so every
-- operand is reached whatever it is written inside; what is left is the arm
-- for each operation, which is where the two grammars actually differ.  A
-- terminator is not an operation here and fails, as does a phi, which by this
-- point 'readBlock' has taken out.
--
-- Failing fails the whole definition, which is what makes a use of a local
-- nothing defines something the core cannot be made to hold.
lowerOperation ::
  Map Name Local ->
  Syntax.Operation (TypedValue Name) ->
  Maybe (Operation (TypedValue Local))
lowerOperation locals written = do
  operation <- traverse (traverse (`Map.lookup` locals)) written
  case operation of
    Syntax.OBinary b -> Just (OBinary b)
    Syntax.OUnary u -> Just (OUnary u)
    Syntax.OICmp c -> Just (OICmp c)
    Syntax.OFCmp c -> Just (OFCmp c)
    Syntax.OConvert c -> Just (OConvert c)
    Syntax.OSelect s -> Just (OSelect s)
    Syntax.OExtractElement e -> Just (OExtractElement e)
    Syntax.OInsertElement i -> Just (OInsertElement i)
    Syntax.OShuffleVector s -> Just (OShuffleVector s)
    Syntax.OExtractValue e -> Just (OExtractValue e)
    Syntax.OInsertValue i -> Just (OInsertValue i)
    Syntax.OCall c -> Just (OCall c)
    Syntax.OAlloca a -> Just (OAlloca a)
    Syntax.OLoad l -> Just (OLoad l)
    Syntax.OStore s -> Just (OStore s)
    Syntax.OAtomicLoad l -> Just (OAtomicLoad l)
    Syntax.OAtomicStore s -> Just (OAtomicStore s)
    Syntax.OAtomicRmw r -> Just (OAtomicRmw r)
    Syntax.OCmpXchg c -> Just (OCmpXchg c)
    Syntax.OFence f -> Just (OFence f)
    -- Both of these are dealt with before this is reached: a phi by
    -- 'readBlock', which takes them off the head of the block, and a
    -- getelementptr by 'lowerGep', which is several instructions rather than
    -- one and so cannot come back through here.
    Syntax.OPhi _ -> Nothing
    Syntax.OGetElementPtr _ -> Nothing
    Syntax.ORet _ -> Nothing
    Syntax.OBr _ -> Nothing
    Syntax.OCondBr _ _ _ -> Nothing
    Syntax.OSwitch _ _ _ -> Nothing
    Syntax.OIndirectBr _ _ -> Nothing
    Syntax.OUnreachable -> Nothing
    Syntax.OLandingPad p -> Just (OLandingPad p)
    -- All three are terminators, which 'split' takes off the end before this
    -- is reached, the way it does for every other transfer.
    Syntax.OInvoke _ -> Nothing
    Syntax.OCallBr _ -> Nothing
    Syntax.OResume _ -> Nothing

-- * Taking a getelementptr apart

-- | One @getelementptr@ as the chain of single steps the core writes it as.
--
-- The result of each step is the pointer the next one starts from, so all but
-- the last assign to a local nobody wrote down.  The last assigns to whatever
-- the @getelementptr@ did.
--
-- A @getelementptr@ with no indices at all is the pointer it started from,
-- which is an assignment — an operation the core has and LLVM does not, so
-- there is somewhere for the answer to go rather than a step that has to be
-- invented to hold it.
lowerGep ::
  Map Name Type ->
  Int ->
  Maybe Local ->
  [Syntax.MetadataAttachment] ->
  Syntax.GetElementPtr (TypedValue Local) ->
  Maybe (Int, [Instruction])
lowerGep types issued assigns metadata g = do
  steps <- gepSteps types (Syntax.gepSourceType g) (Syntax.gepIndices g)
  pure (build issued (Syntax.gepPointer g) (fuse steps))
  where
    flags = Syntax.gepFlags g

    -- Each step but the last leaves its answer in a local of its own, and
    -- reads the one before it.
    build n pointer [] = (n, [Instruction assigns (OAssign pointer) metadata])
    build n pointer [step] = (n, [Instruction assigns (operation pointer step) metadata])
    build n pointer (step : rest) =
      let intermediate = Local n
          -- Every step but the first starts from a pointer, and the type of a
          -- pointer says nothing about what it points at.
          carried = TypedValue (Syntax.TPointer Nothing) (VLocal intermediate)
          (n', following) = build (n + 1) carried rest
       in (n', Instruction (Just intermediate) (operation pointer step) [] : following)

    operation pointer (StrideBy t index) =
      OOffset
        Offset
          { offsetFlags = flags
          , offsetElementType = t
          , offsetPointer = pointer
          , offsetIndex = index
          }
    operation pointer (SelectField t index) =
      OField
        Field
          { fieldFlags = flags
          , fieldStructType = t
          , fieldPointer = pointer
          , fieldIndex = index
          }

-- | One step of a @getelementptr@.
data GepStep operand
  = StrideBy Type operand
  | SelectField Type Natural

-- | A zero stride whose only purpose is to arrive at a struct is not a step.
--
-- @getelementptr %S, ptr %p, i32 0, i32 1@ is one field selection, written
-- the only way LLVM can write one: there is no syntax for naming a field
-- without an index in front of it saying which @%S@.  So the two indices are
-- one step here, and 'Olivine.Core.Raise' writes both back.  Without this the
-- trip through the core would lengthen the chain every time, because what the
-- raising wrote would lower to two steps rather than the one it came from.
fuse :: [GepStep (TypedValue Local)] -> [GepStep (TypedValue Local)]
fuse (StrideBy t index : rest@(SelectField t' _ : _))
  | t == t'
  , TypedValue _ (VInteger 0) <- index =
      fuse rest
fuse (step : rest) = step : fuse rest
fuse [] = []

-- | What a @getelementptr@\'s indices mean, one at a time.
--
-- The first strides over the pointee type; each one after it indexes into
-- whatever the last arrived at, which is a stride through an array or a
-- vector and a field selection in a struct.  Nothing else can be indexed
-- into, and a chain reaching something else fails the definition rather than
-- guessing what LLVM meant.
gepSteps ::
  Map Name Type -> Type -> [TypedValue Local] -> Maybe [GepStep (TypedValue Local)]
gepSteps types = first
  where
    first _ [] = Just []
    first pointee (index : rest) = (StrideBy pointee index :) <$> inside pointee rest

    inside _ [] = Just []
    inside current (index : rest) = case resolve current of
      Syntax.TArray _ element -> stride element index rest
      Syntax.TVector _ _ element -> stride element index rest
      Syntax.TStruct _ fields -> do
        k <- constantIndex index
        field <- fields !? k
        -- The struct is named as it was written, so a named type stays named
        -- on the way back out; only the walk needs the body.
        (SelectField current k :) <$> inside field rest
      _ -> Nothing

    stride element index rest = (StrideBy element index :) <$> inside element rest

    -- A named type stands for its body.
    resolve = Syntax.resolveNamed types

    constantIndex (TypedValue _ (VInteger n))
      | n >= 0 = Just (fromInteger n)
    constantIndex _ = Nothing

    fields !? k = case drop (fromIntegral k) fields of
      field : _ -> Just field
      [] -> Nothing

-- | One terminator, on the other side of the boundary.
--
-- Every destination becomes a 'Label' by looking it up, so a branch to a
-- block nothing defines has nothing to become and the definition is retained
-- as written rather than lowered into a graph with an edge to nowhere.
lowerTransfer ::
  Map Name Label ->
  Map Name Local ->
  Maybe Local ->
  Syntax.Operation (TypedValue Name) ->
  Maybe (Transfer (TypedValue Local))
lowerTransfer labels locals result written = do
  operation <- traverse (traverse (`Map.lookup` locals)) written
  let target = (`Map.lookup` labels)
  case operation of
    Syntax.ORet value -> Just (Ret value)
    Syntax.OBr d -> Br <$> target d
    Syntax.OCondBr c a b -> CondBr c <$> target a <*> target b
    Syntax.OSwitch value d cases ->
      Switch value
        <$> target d
        <*> traverse (\(x, l) -> (x,) <$> target l) cases
    Syntax.OIndirectBr address ds -> IndirectBr address <$> traverse target ds
    Syntax.OUnreachable -> Just Unreachable
    Syntax.OInvoke i ->
      Invoke result (Syntax.invokeCall i)
        <$> target (Syntax.invokeNormal i)
        <*> target (Syntax.invokeUnwind i)
    Syntax.OCallBr c ->
      CallBr result (Syntax.callBrCall c)
        <$> target (Syntax.callBrFallthrough c)
        <*> traverse target (Syntax.callBrIndirect c)
    Syntax.OResume value -> Just (Resume value)
    _ -> Nothing

-- | Take the terminator off the end and the rest as the body.
--
-- Anything unmodelled fails the whole definition rather than part of it: a
-- half-lowered function would have to be printed from a mixture of parsed
-- structure and remembered text, and retaining the definition whole is
-- already correct.
split ::
  Map Name Label ->
  Map Name Local ->
  [Syntax.Instruction] ->
  Maybe ([Syntax.Instruction], Terminator)
split labels locals body = case reverse body of
  -- A terminator names a result only where it is one of the two calls, and
  -- there it must: what the call left is read in the blocks it goes on to.
  -- Whether the name belongs on this terminator at all is the verifier's, not
  -- this rule's.
  Syntax.IOperation result operation metadata : rest
    | isTerminator operation
    , all modelled rest -> do
        assigns <- traverse (`Map.lookup` locals) result
        t <- lowerTransfer labels locals assigns operation
        pure (reverse rest, Terminator t metadata)
  _ -> Nothing
  where
    modelled (Syntax.IOperation _ operation _) = not (isTerminator operation)
    modelled _ = False
