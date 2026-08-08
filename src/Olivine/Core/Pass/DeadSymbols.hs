-- | Removing functions, globals, aliases, ifuncs and comdat groups no live
-- path reaches.
--
-- The first pass whose question cannot be asked inside a function.  Whether an
-- instruction is dead is settled by looking at the function holding it;
-- whether a /symbol/ is dead is settled by looking at everything else, since
-- the one place its name cannot appear is the place a single-function pass
-- would look.
--
-- Three things make this more than removing functions nothing calls.
--
-- It is reachability, not a reference count.  Two internal functions that call
-- only each other refer to one another as much as any live pair does, and both
-- are dead.  So the live set is grown from roots — the symbols the program can
-- be entered at, and the symbols named by everything that is kept regardless —
-- and a symbol is dead when that growth never arrives at it.
--
-- A call is not the only way to name a function.  A function pointer in a
-- global's initializer, a @ptrtoint@ of one in a constant expression, a
-- metadata operand, and a line of source Olivine has not learned to read are
-- all mentions, and a pass that counted calls would delete a function the
-- program then jumps to.  Every one of them is followed here.
--
-- The kinds are one graph, not five.  A function's body names globals, a
-- global's initializer names functions, an alias names whichever of them it
-- stands for, an ifunc names the function that resolves it, a comdat group
-- and its members name each other, and so a chain of dead symbols can cross
-- between the kinds for as long as it likes: a table of function pointers that
-- only a dead function indexes is dead, the functions in the table are dead
-- with it, and whatever /their/ bodies named may be dead in turn.  A pass per
-- kind would have to run again every time any other found something, so all of
-- them are grown from the same roots in one walk, which reaches the end of
-- such a chain the first time.
module Olivine.Core.Pass.DeadSymbols
  ( eliminateDeadSymbols
  , removableWhenUnreached
  , Reference (..)
  , mentionedIn
  ) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Foldable (toList)
import Data.Maybe (fromMaybe, isNothing)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function (FunctionClause (..), Signature (..))
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Global (Global (..), IndirectSymbol (..))
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Linkage (GlobalAttribute (..), Linkage (..))
import Olivine.Syntax.Metadata (MetadataOperand (..))
import Olivine.Syntax.Name (Name (..), isIdentifierChar)
import Olivine.Syntax.Value (blockAddressesIn, globalsIn, typedValue)

-- | Something a live path can arrive at.
--
-- Two namespaces, not one.  A symbol is written @\@g@ and a comdat group
-- @$g@, and the two are written side by side constantly, since a symbol whose
-- @comdat@ clause names no group is in the group its own name spells.  So the
-- sigil is part of the key, and a live @\@g@ says nothing about @$g@.
--
-- Names as text, rather than as 'Name': @\@f@ and @\@"f"@ are one symbol, and
-- the quoting a name was written with is a fact about the writing.  Nothing
-- distinguishes symbols by it, so nothing here may either.  Functions and
-- globals do share the one namespace, which is LLVM's doing and not a
-- simplification made here: there is a single @\@@ sigil and a single symbol
-- table, and no way for a call and a load to mean different @\@g@s.
data Reference
  = RSymbol Text
  | RComdat Text
  deriving (Eq, Ord, Show)

-- | Drop every symbol the live set does not contain.
--
-- Declarations go the same way, on both sides.  A declaration is a definition
-- that is somewhere else, and one nothing names emits nothing and says
-- nothing; the reachability that finds the definitions to remove has already
-- worked out which declarations are left over, and leaving them behind would
-- mean this pass could delete the only caller of @\@printf@ and still write
-- out its @declare@.
eliminateDeadSymbols :: Program -> Program
eliminateDeadSymbols program =
  program {programEntries = map released (filter reached (programEntries program))}
  where
    live = reachableIn program
    still = addressedIn program

    reached entry = case entry of
      EFunction f
        | removableWhenUnreached (signatureLinkage (functionSignature f)) ->
            isLive (symbol (signatureName (functionSignature f)))
      ERetained (Syntax.EDeclare signature) -> isLive (symbol (signatureName signature))
      ERetained (Syntax.EGlobal g)
        | removableGlobal g -> isLive (symbol (globalName g))
      ERetained (Syntax.EIndirect i)
        | removableWhenUnreached (indirectLinkage i) -> isLive (symbol (indirectName i))
      -- A comdat group has no linkage to be judged on and needs none.  It
      -- defines nothing and takes up no room in the program: it is a name for
      -- the linker to group by, and one that nothing in the module is in
      -- groups nothing.  LLVM agrees to the letter — an unreferenced comdat
      -- does not survive being read and written back out.
      ERetained (Syntax.EComdat name _) -> isLive (comdat name)
      _ -> True
    isLive reference = reference `Set.member` live

    released (EFunction f) = EFunction (letting f)
    released retained = retained
    letting f
      | null unread =
          f
            { functionAddressed =
                Map.filterWithKey
                  (\block _ -> (signatureName (functionSignature f), block) `Set.member` still)
                  (functionAddressed f)
            }
      | otherwise = f

    -- A line this cannot read may name a block as well as a symbol, and there
    -- is no scanning a name out of it: what @blockaddress(\@f, %b)@ says is
    -- two names of two kinds, and a block's is not a symbol's to be looked up
    -- afterwards.  So while any unread line holds the word, nothing is
    -- released at all.  The corpus has no such line; this is what keeps the
    -- rule true rather than nearly true.
    unread =
      [ ()
      | ERetained (Syntax.EOpaque text) <- programEntries program
      , T.isInfixOf "blockaddress" text
      ]

-- | Which blocks of which functions the program still takes the address of.
--
-- The counterpart of the reading the lowering does, asked again because the
-- answer changes: a @select@ between two block addresses that folded into a
-- branch is two addresses nothing names any more, and the blocks they named
-- can then be merged and forwarded through like any others.  A block stays
-- pinned for exactly as long as something can still hold its address, which
-- is what this measures and what 'Olivine.Core.Program.pinnedIn' reads.
--
-- This is the same kind of fact as the rest of the pass: what nothing names
-- can go, and the only place the question can be asked is the whole program.
addressedIn :: Program -> Set (Name, Name)
addressedIn program =
  Set.fromList (concatMap fromEntry (programEntries program))
  where
    fromEntry (EFunction f) =
      [ address
      | b <- functionBlocks f
      , operand <-
          concatMap (toList . instructionOperation) (blockInstructions b)
            <> toList (terminatorTransfer (blockTerminator b))
      , address <- blockAddressesIn (typedValue operand)
      ]
    fromEntry (ERetained entry) = case entry of
      Syntax.EGlobal g -> foldMap blockAddressesIn (globalInitializer g)
      Syntax.EIndirect s -> blockAddressesIn (indirectTarget s)
      Syntax.EDefine d ->
        [ address
        | b <- Syntax.definitionBlocks d
        , Syntax.IOperation _ operation _ <- Syntax.blockBody b
        , operand <- toList operation
        , address <- blockAddressesIn (typedValue operand)
        ]
      _ -> []

-- | Whether a symbol can go when nothing live reaches it, as far as its
-- linkage is concerned.
--
-- Functions and globals share this because linkage is one vocabulary, and what
-- it is being asked is one question: whether the symbol can be reached from
-- outside this module without passing through anything inside it.
--
-- @private@ and @internal@ cannot be named from outside at all.
-- @available_externally@ is a copy of a definition another module owns and is
-- never emitted, and @linkonce@ says in so many words that an unreferenced
-- definition may be discarded.  Everything else stays, @weak@ included:
-- @weak@ differs from @linkonce@ in precisely this, that an unreferenced weak
-- definition may /not/ be discarded, because it may be the one the linker
-- picks for a symbol some other module refers to.
--
-- @appending@ stays too, and is worth naming because it is what
-- @\@llvm.global_ctors@ and @\@llvm.used@ are written with.  Those exist to
-- say that something otherwise unreferenced is live — a constructor nothing
-- calls, a symbol kept for a linker script — so their being roots is not a
-- concession this pass makes to an awkward case.  It is the mechanism working:
-- the global is kept because of its linkage, and what it names is reached
-- through it like anything else.
--
-- A symbol with no linkage written is external, and this pass can do nothing
-- with it — which, while a program is one module, is most of them.  When a
-- whole program really is several modules linked together, external linkage
-- stops being the end of the question and only the entry point and what the
-- program is linked against are roots.  That is a fact about how much of the
-- program has been read, not about this function, so it will change here and
-- nowhere else.
removableWhenUnreached :: Maybe Linkage -> Bool
removableWhenUnreached linkage = case linkage of
  Just LinkPrivate -> True
  Just LinkInternal -> True
  Just LinkAvailableExternally -> True
  Just LinkLinkOnce -> True
  Just LinkLinkOnceODR -> True
  _ -> False

-- | Whether a global can go when nothing live reaches it.
--
-- Linkage settles it for a function.  A global is judged on one further thing
-- that its linkage does not record: a global with no initializer is a
-- declaration, and one nothing names contributes nothing, the same as a
-- @declare@.  So it goes whatever linkage it was written with — they are
-- nearly all @external@, which would otherwise keep every one of them.
--
-- Being in a comdat is /not/ among these, and used to be.  The group is what
-- the linker keeps or discards, and it does so as a unit; but that is a fact
-- about the group and every symbol in it, not a reason to pin one member.
-- Now that membership is read rather than passed through as text, it is an
-- edge of the graph like any other, so a live member keeps the whole group
-- and a group nothing reaches goes entire, members and definition together.
--
-- @externally_initialized@ is deliberately not among these either.  It says
-- that the value a global holds when the program starts is not the one written
-- as its initializer, which is a fact about the value and not about who can
-- reach the symbol — and a global no live path reaches has no value anyone
-- observes.  A module that means such a global to survive says so the way
-- anything else unreferenced says so, by naming it in @\@llvm.used@.
removableGlobal :: Global -> Bool
removableGlobal g = isDeclaration || removableWhenUnreached (globalLinkage g)
  where
    isDeclaration = isNothing (globalInitializer g)

symbol :: Name -> Reference
symbol = RSymbol . nameText

comdat :: Name -> Reference
comdat = RComdat . nameText

-- | The names a live path arrives at.
reachableIn :: Program -> Set Reference
reachableIn program = grow Set.empty (concatMap roots (programEntries program))
  where
    -- What each name that could be removed would carry with it if it turned
    -- out to be live.  The rest are roots and are walked as such.
    bodies :: Map Reference [Reference]
    bodies =
      Map.fromListWith (<>) $
        [ (symbol (signatureName (functionSignature f)), functionReferences f)
        | EFunction f <- programEntries program
        , removableWhenUnreached (signatureLinkage (functionSignature f))
        ]
          <> [ (symbol (signatureName s), signatureReferences s)
             | ERetained (Syntax.EDeclare s) <- programEntries program
             ]
          <> [ (symbol (globalName g), globalReferences g)
             | ERetained (Syntax.EGlobal g) <- programEntries program
             , removableGlobal g
             ]
          <> [ (symbol (indirectName i), targetReferences i)
             | ERetained (Syntax.EIndirect i) <- programEntries program
             , removableWhenUnreached (indirectLinkage i)
             ]
          <> comdatMembers program

    grow seen [] = seen
    grow seen (name : rest)
      | name `Set.member` seen = grow seen rest
      | otherwise =
          grow (Set.insert name seen) (Map.findWithDefault [] name bodies <> rest)

    -- A symbol that cannot be removed is a way into the program, so it is live
    -- and so is everything it names.  Everything else kept regardless —
    -- metadata, definitions the lowering could not take, text not yet read —
    -- contributes what it names and not itself.
    roots entry = case entry of
      EFunction f
        | removableWhenUnreached (signatureLinkage (functionSignature f)) -> []
        | otherwise ->
            symbol (signatureName (functionSignature f)) : functionReferences f
      ERetained (Syntax.EGlobal g)
        | removableGlobal g -> []
        | otherwise -> symbol (globalName g) : globalReferences g
      -- An alias or ifunc is judged on its linkage and nothing else.  It has
      -- no comdat clause to be grouped by, LLVM rejecting one here, and no
      -- declaration form to be the leftover of, being a definition or nothing.
      ERetained (Syntax.EIndirect i)
        | removableWhenUnreached (indirectLinkage i) -> []
        | otherwise -> symbol (indirectName i) : targetReferences i
      -- A comdat group is never a root.  Being named is the whole of what
      -- keeps one, and its own definition names nothing: the members are on
      -- the far side of the edge, written where they are and not here.
      ERetained (Syntax.EComdat _ _) -> []
      ERetained e -> referencesInEntry e

-- | The members of each comdat group, as edges from the group to them.
--
-- This is the direction the group supplies: arriving at a group arrives at
-- every symbol in it, because the linker keeps or discards the whole of one
-- and a member left behind by a discarded group would refer to what is no
-- longer there.  The other direction is each member's own affair and is among
-- its references, a symbol in a group being unemittable without it.
--
-- Members the syntax layer has not learned to read are not here, and need not
-- be: an unread line is kept whatever happens, and the group it names is a
-- mention like any other — written with a @$@, or taken from the names on the
-- line when the clause is bare, which is 'impliedGroups' — so the group and
-- the rest of its members are kept along with it.
comdatMembers :: Program -> [(Reference, [Reference])]
comdatMembers program =
  [ (group, [symbol name])
  | (name, clauses) <- objects
  , group <- groupsOf name clauses
  ]
  where
    objects = concatMap object (programEntries program)
    object entry = case entry of
      EFunction f -> [clausesOf (functionSignature f)]
      ERetained (Syntax.EDefine d) -> [clausesOf (Syntax.definitionSignature d)]
      ERetained (Syntax.EDeclare s) -> [clausesOf s]
      ERetained (Syntax.EGlobal g) -> [(globalName g, globalAttributes g)]
      _ -> []
    clausesOf s = (signatureName s, signatureClauses s)

-- | The comdat group a symbol's trailing clauses put it in.
--
-- A bare @comdat@ means the group whose name is the symbol's own, which is
-- why the symbol's name is wanted here and not only its clauses.
groupsOf :: Name -> [GlobalAttribute] -> [Reference]
groupsOf name clauses =
  [comdat (fromMaybe name group) | GAComdat group <- clauses]

-- | The names a function reaches: what its body mentions, and the group it is
-- in.
functionReferences :: Function -> [Reference]
functionReferences f =
  referencesIn f <> signatureReferences (functionSignature f)

-- | The names a signature reaches on its own: its comdat group, and the
-- symbols its header clauses name.
--
-- A @personality@ names the routine an unwinder calls, and @prefix@ and
-- @prologue@ hold constants that may name anything a constant may.  None of
-- them is in any body, so nothing else here would find them, and a personality
-- routine that no call names is exactly the shape this pass would otherwise
-- take for dead.
signatureReferences :: Signature -> [Reference]
signatureReferences s =
  groupsOf (signatureName s) (signatureClauses s)
    <> [ RSymbol (nameText n)
       | clause <- signatureFunctionClauses s
       , value <- case clause of
          FCGarbageCollector _ -> []
          FCPrefix v -> [v]
          FCPrologue v -> [v]
          FCPersonality v -> [v]
       , n <- globalsIn (typedValue value)
       ]

-- | The globals a function's body names.
referencesIn :: Function -> [Reference]
referencesIn f =
  map (RSymbol . nameText) $
    concat
      [ globalsUsedBy (instructionOperation i)
      | b <- functionBlocks f
      , i <- blockInstructions b
      ]
      <> [ n
         | b <- functionBlocks f
         , n <- globalsUsedBy (terminatorTransfer (blockTerminator b))
         ]

-- | The names a global reaches: what its initializer mentions, and the group
-- it is in.
globalReferences :: Global -> [Reference]
globalReferences g =
  map (RSymbol . nameText) (foldMap globalsIn (globalInitializer g))
    <> groupsOf (globalName g) (globalAttributes g)

-- | The global an alias or ifunc stands for: the aliasee of the one, the
-- resolver of the other.
--
-- One symbol, but reached through 'globalsIn' like any other operand, since
-- LLVM allows a constant expression here and the symbol is then inside it.
targetReferences :: IndirectSymbol -> [Reference]
targetReferences = map (RSymbol . nameText) . globalsIn . indirectTarget

-- | The names a retained entry reaches.
--
-- A global is not one of the entries asked, although it is retained: whether
-- it is a node of the graph or a root of it is decided where that distinction
-- is drawn, and only entries that are roots in every case arrive here.
--
-- A definition the lowering could not take is one of them, and its comdat
-- group is among what it names for that reason: it is kept whatever happens,
-- so the group it declares itself a member of has to be kept under it.
--
-- Metadata attachments are not read here either.  An attachment refers to a
-- node, every node is an entry of its own and kept, and what the node names
-- has already been counted at the node.
referencesInEntry :: Syntax.Entry -> [Reference]
referencesInEntry entry = case entry of
  Syntax.EDefine definition ->
    signatureReferences (Syntax.definitionSignature definition)
      <> concatMap
        instruction
        (concatMap Syntax.blockBody (Syntax.definitionBlocks definition))
  Syntax.EMetadata _ _ operands -> concatMap metadata operands
  Syntax.EOpaque text -> mentionedIn text
  _ -> []
  where
    names = map (RSymbol . nameText)
    instruction (Syntax.IOperation _ operation _) = names (globalsUsedBy operation)
    instruction (Syntax.IOpaque text) = mentionedIn text
    metadata (MDValue value) = names (globalsIn (typedValue value))
    metadata (MDTuple operands) = concatMap metadata operands
    metadata _ = []

-- | Every symbol and comdat group a line Olivine has not read mentions.
--
-- A @module asm@ block, a definition whose header held something unmodelled:
-- each comes through as the text it was written as, and any of them can name a
-- symbol or a group.  A name in text the optimizer cannot read is a name it
-- has to assume is used, so this looks for the sigils and takes what follows.
--
-- Aliases, ifuncs and comdats used to be read this way and now are not, which
-- is what let them be removed: while a construct is only text, everything it
-- names is a root and the construct itself can never go.  That is the safe
-- reading, and the reason to keep replacing it.
--
-- Three places a sigil is not one.  A comment runs to the end of its line and
-- means nothing — a comment on a line of its own is dropped at the parse, but
-- one trailing an unread line arrives here still attached to it; a string
-- literal is data, and @c"\@f"@ is two bytes.  Both are skipped, and skipping
-- them is why this scans rather than searching: which of @;@ and @"@ comes
-- first is the whole difference between a comment holding a string and a
-- string holding a semicolon.  The third is @$@, which is an identifier
-- character as well as a sigil, so one that follows another such character is
-- part of the name it is in rather than the start of a new one.
--
-- And one place a name is written with no sigil at all, which is
-- 'impliedGroups'.
mentionedIn :: Text -> [Reference]
mentionedIn text = named <> impliedGroups text named
  where
    named = go text

    go source = case T.uncons rest of
      Nothing -> []
      Just (';', more) -> go (T.drop 1 (T.dropWhile (/= '\n') more))
      Just ('"', more) -> go (afterQuote more)
      Just ('$', more) | attached -> go more
      Just (sigil, more) -> case T.uncons more of
        -- @"a b", a name that had to be quoted to be written.
        Just ('"', quoted) ->
          let (name, after) = T.break (== '"') quoted
           in reference sigil name : go (T.drop 1 after)
        _ ->
          let (name, after) = T.span isIdentifierChar more
           in [reference sigil name | not (T.null name)] <> go after
      where
        (skipped, rest) = T.span ordinary source
        attached = maybe False (isIdentifierChar . snd) (T.unsnoc skipped)
    ordinary c = c /= '@' && c /= '$' && c /= ';' && c /= '"'
    reference '$' = RComdat
    reference _ = RSymbol
    afterQuote = T.drop 1 . T.dropWhile (/= '"')

-- | The groups a line is in without saying so.
--
-- A @comdat@ clause written bare means the group the symbol's own name spells,
-- and that is a group named with no @$@ anywhere in the line — the one
-- reference into a namespace this pass can empty that the scan for sigils
-- cannot find.  Which symbol on the line the clause belongs to is a question
-- about the grammar, and the grammar is the thing this text is here for want
-- of, so every symbol the line mentions is taken to name a group as well.
--
-- Being wrong that way costs a group nothing is in, which LLVM drops when it
-- next reads the module.  Being wrong the other way costs a member kept while
-- the group it names is gone, which is a module that no longer parses — and
-- did, for every C++ translation unit, since a @linkonce_odr@ definition with
-- a clause of its own is what a template instantiation is written as and one
-- unmodelled keyword in the header is enough to leave it as text.
--
-- A string or a comment holding the word is not distinguished from a clause,
-- and need not be: that mistake is the one the paragraph above says is cheap.
impliedGroups :: Text -> [Reference] -> [Reference]
impliedGroups text named =
  [RComdat name | any bare (T.breakOnAll keyword text), RSymbol name <- named]
  where
    keyword = "comdat"
    bare (before, match) =
      not (endsInName before) && alone (T.drop (T.length keyword) match)
    endsInName = maybe False (isIdentifierChar . snd) . T.unsnoc
    -- @comdat($c)@ says which group and the scan finds it, and a name that
    -- happens to end in these six letters is not the keyword at all.
    alone rest = case T.uncons rest of
      Just ('(', _) -> False
      Just (c, _) -> not (isIdentifierChar c)
      Nothing -> True
