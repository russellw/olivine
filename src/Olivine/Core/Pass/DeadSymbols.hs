-- | Removing functions, globals and aliases no live path reaches.
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
-- The kinds are one graph, not three.  A function's body names globals, a
-- global's initializer names functions, an alias names whichever of them it
-- stands for, and so a chain of dead symbols can cross between the kinds for
-- as long as it likes: a table of function pointers that only a dead function
-- indexes is dead, the functions in the table are dead with it, and whatever
-- /their/ bodies named may be dead in turn.  A pass per kind would have to run
-- again every time any other found something, so all three are grown from the
-- same roots in one walk, which reaches the end of such a chain the first
-- time.
module Olivine.Core.Pass.DeadSymbols
  ( eliminateDeadSymbols
  , removableWhenUnreached
  , mentionedIn
  ) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (isNothing)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function (Signature (..))
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Global (Alias (..), Global (..), GlobalAttribute (..))
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Linkage (Linkage (..))
import Olivine.Syntax.Metadata (MetadataOperand (..))
import Olivine.Syntax.Name (Name (..), isIdentifierChar)
import Olivine.Syntax.Operands (globalsUsedBy)
import Olivine.Syntax.Value (globalsIn, typedValue)

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
  program {programEntries = filter reached (programEntries program)}
  where
    live = reachableIn program

    reached entry = case entry of
      EFunction f
        | removableWhenUnreached (signatureLinkage (functionSignature f)) ->
            isLive (signatureName (functionSignature f))
      ERetained (Syntax.EDeclare signature) -> isLive (signatureName signature)
      ERetained (Syntax.EGlobal g)
        | removableGlobal g -> isLive (globalName g)
      ERetained (Syntax.EAlias a)
        | removableWhenUnreached (aliasLinkage a) -> isLive (aliasName a)
      _ -> True
    isLive name = nameText name `Set.member` live

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
-- Linkage settles it for a function.  A global is judged on two further things
-- that its linkage does not record, one either way.
--
-- A global with no initializer is a declaration, and one nothing names
-- contributes nothing, the same as a @declare@.  So it goes whatever linkage
-- it was written with: they are nearly all @external@, which would otherwise
-- keep every one of them.
--
-- A global in a comdat stays whatever its linkage says.  The group is what the
-- linker keeps or discards, and it does so as a unit, because its members are
-- put there together precisely when each is unusable without the others.
-- Removing one because this module happens not to name it would leave the
-- survivors in a group that no longer supplies what they refer to.  Comdats
-- are modelled as far as the clause naming one and no further, so from here
-- the rest of the group cannot be found to be judged along with it.  The price
-- is that a group with nothing live in it is kept entire rather than dropped
-- entire, which is a missed removal and not a wrong one; it is worth paying
-- until group membership is something a pass can read.
--
-- @externally_initialized@ is deliberately /not/ among these.  It says that
-- the value a global holds when the program starts is not the one written as
-- its initializer, which is a fact about the value and not about who can reach
-- the symbol — and a global no live path reaches has no value anyone observes.
-- A module that means such a global to survive says so the way anything else
-- unreferenced says so, by naming it in @\@llvm.used@.
removableGlobal :: Global -> Bool
removableGlobal g
  | inComdat = False
  | otherwise = isDeclaration || removableWhenUnreached (globalLinkage g)
  where
    isDeclaration = isNothing (globalInitializer g)
    inComdat = any comdat (globalAttributes g)
    comdat (GAComdat _) = True
    comdat _ = False

-- | The names a live path arrives at.
--
-- Names as text, rather than as 'Name': @\@f@ and @\@"f"@ are one symbol, and
-- the quoting a name was written with is a fact about the writing.  Nothing
-- distinguishes symbols by it, so nothing here may either.  Functions and
-- globals share the one set as they share the one namespace, which is LLVM's
-- doing and not a simplification made here: there is a single @\@@ sigil and a
-- single symbol table, and no way for a call and a load to mean different
-- @\@g@s.
reachableIn :: Program -> Set Text
reachableIn program = grow Set.empty (concatMap roots (programEntries program))
  where
    -- What each symbol that could be removed would carry with it if it turned
    -- out to be live.  The rest are roots and are walked as such.
    bodies :: Map Text [Text]
    bodies =
      Map.fromListWith (<>) $
        [ (nameText (signatureName (functionSignature f)), referencesIn f)
        | EFunction f <- programEntries program
        , removableWhenUnreached (signatureLinkage (functionSignature f))
        ]
          <> [ (nameText (globalName g), initializerReferences g)
             | ERetained (Syntax.EGlobal g) <- programEntries program
             , removableGlobal g
             ]
          <> [ (nameText (aliasName a), aliaseeReferences a)
             | ERetained (Syntax.EAlias a) <- programEntries program
             , removableWhenUnreached (aliasLinkage a)
             ]

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
            nameText (signatureName (functionSignature f)) : referencesIn f
      ERetained (Syntax.EGlobal g)
        | removableGlobal g -> []
        | otherwise -> nameText (globalName g) : initializerReferences g
      -- An alias is judged on its linkage and nothing else.  It has no comdat
      -- clause to be pinned by, LLVM rejecting one here, and no declaration
      -- form to be the leftover of, an alias being a definition or nothing.
      ERetained (Syntax.EAlias a)
        | removableWhenUnreached (aliasLinkage a) -> []
        | otherwise -> nameText (aliasName a) : aliaseeReferences a
      ERetained e -> referencesInEntry e

-- | The globals a function names.
referencesIn :: Function -> [Text]
referencesIn f =
  map nameText $
    concat
      [ operation (instructionOperation i)
      | b <- functionBlocks f
      , i <- blockInstructions b
      ]
      <> [ n
         | b <- functionBlocks f
         , n <- globalsUsedBy (terminatorOperation (blockTerminator b))
         ]
  where
    operation (Perform op) = globalsUsedBy op
    operation (Assign value) = globalsIn (typedValue value)

-- | The globals a global's initializer names.
initializerReferences :: Global -> [Text]
initializerReferences = map nameText . foldMap globalsIn . globalInitializer

-- | The global an alias resolves to.
--
-- One symbol, but reached through 'globalsIn' like any other operand, since
-- LLVM allows a constant expression here and the symbol is then inside it.
aliaseeReferences :: Alias -> [Text]
aliaseeReferences = map nameText . globalsIn . aliasAliasee

-- | The globals a retained entry names.
--
-- A global is not one of the entries asked, although it is retained: whether
-- it is a node of the graph or a root of it is decided where that distinction
-- is drawn, and only entries that are roots in every case arrive here.
--
-- Metadata attachments are not read here either.  An attachment refers to a
-- node, every node is an entry of its own and kept, and what the node names
-- has already been counted at the node.
referencesInEntry :: Syntax.Entry -> [Text]
referencesInEntry entry = case entry of
  Syntax.EDefine definition ->
    concatMap
      instruction
      (concatMap Syntax.blockBody (Syntax.definitionBlocks definition))
  Syntax.EMetadata _ _ operands -> concatMap metadata operands
  Syntax.EOpaque text -> mentionedIn text
  _ -> []
  where
    names = map nameText
    instruction (Syntax.IOperation _ operation _) = names (globalsUsedBy operation)
    instruction (Syntax.IOpaque text) = mentionedIn text
    metadata (MDValue value) = names (globalsIn (typedValue value))
    metadata (MDTuple operands) = concatMap metadata operands
    metadata _ = []

-- | Every global a line Olivine has not read mentions.
--
-- An @ifunc@, a comdat, a definition whose header held something unmodelled:
-- each comes through as the text it was written as, and any of them can name
-- a symbol.  A name in text the optimizer cannot read is a name it has to
-- assume is used, so this looks for the sigil and takes what follows.
--
-- An alias used to be read this way and now is not, which is what let it be
-- removed: a construct is safe here in proportion to how little is known
-- about it, and worth reading in the same proportion.
--
-- Two places a sigil is not one.  A comment runs to the end of its line and
-- means nothing — a comment on a line of its own is dropped at the parse, but
-- one trailing an unread line arrives here still attached to it; a string
-- literal is data, and @c"\@f"@ is two
-- bytes.  Both are skipped, and skipping them is why this scans rather than
-- searching: which of @;@ and @"@ comes first is the whole difference between
-- a comment holding a string and a string holding a semicolon.
mentionedIn :: Text -> [Text]
mentionedIn = go
  where
    go text = case T.uncons (T.dropWhile ordinary text) of
      Nothing -> []
      Just (';', rest) -> go (T.drop 1 (T.dropWhile (/= '\n') rest))
      Just ('"', rest) -> go (afterQuote rest)
      Just (_, rest) -> case T.uncons rest of
        -- @"a b", a name that had to be quoted to be written.
        Just ('"', quoted) ->
          let (name, after) = T.break (== '"') quoted
           in name : go (T.drop 1 after)
        _ ->
          let (name, after) = T.span isIdentifierChar rest
           in [name | not (T.null name)] <> go after
    ordinary c = c /= '@' && c /= ';' && c /= '"'
    afterQuote = T.drop 1 . T.dropWhile (/= '"')
