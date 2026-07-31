-- | Taking a slot that holds a struct apart into a slot per field.
--
-- LLVM calls this scalar replacement of aggregates, and what it is for here is
-- "Olivine.Core.Pass.Promote".  A slot holding a whole struct is not a local
-- waiting to be found: a local holds one value, and no one value is what a
-- program means when it writes one field and reads another.  Worse, every
-- field the program does name is a step off the slot's address, which
-- promotion has to count as an escape.  So a struct a front end put on the
-- stack is not merely storage left unpromoted, it is storage that stops the
-- pass looking further.  Split the one allocation into one per field and each
-- field is a slot in its own right, at the type its accesses are already
-- written at, which is the shape promotion was built for.
--
-- __It splits by name, not by offset.__  What makes a field a candidate is
-- that the program stepped to it with an 'OField', which says which field it
-- meant; nothing here asks where a field begins or how many bytes it covers,
-- so the pass wants no data layout and answers the same on every target.  That
-- is also the whole of its limit.  A slot loaded or stored whole, strided into
-- as though it were an array, or stepped into as some other struct keeps its
-- storage, because what such an access covers is a number of bytes and this
-- pass is not in the business of bytes.  LLVM's own gives up on the same
-- programs for the same reason, having watched the bytes and found an access
-- it could not place.
--
-- __Nothing reached through a field may leave it.__  Separating the fields is
-- only truthful if no access the program makes crosses from one into the next,
-- and — since a pointer carries the provenance of the whole allocation — only
-- if no pointer into the slot ever reaches code that could do the crossing.
-- Both are the same condition, and 'contains' is it: everything reached
-- through a field's address is a load or a store at that field's own type, or
-- a step into it whose own reach keeps to what it stepped into.  A pointer
-- passed to a call, returned, compared, or written into memory is none of
-- those, so the escape is refused by the same rule that refuses the wide load.
--
-- __A field nothing names gets no storage.__  The struct said how much room to
-- leave for every field; a slot per field says nothing about a field there is
-- no slot for, and a field nothing steps to is one nothing can read.
-- Allocating for it anyway would leave the dead code pass to take it away
-- again.
--
-- __The new slots keep the old one's alignment.__  A field stands wherever the
-- struct put it, so how well aligned it is is the struct's alignment and the
-- offset together — never more than the struct's.  Giving each new slot the
-- whole allocation's alignment is therefore never less than what any access to
-- a field could honestly claim, and never wrong to claim more.  Working out
-- how much less would want the offsets, which is the layout's business and not
-- this pass's; an allocation that states no alignment at all is declined for
-- the same reason, since what it would then be aligned to is what the target
-- says about the type.
--
-- __It splits again what splitting exposed.__  A struct inside a struct
-- becomes a slot holding a struct, and the steps that read the inner one's
-- fields now step off that slot, so the sweep runs until it finds nothing.  It
-- terminates because a sweep that changes anything removes at least one field
-- step and writes none, and a slot with no field step on it is not a
-- candidate.
module Olivine.Core.Pass.Split
  ( splitAggregates
  , Aggregate (..)
  , splittableIn
  ) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust)
import Numeric.Natural (Natural)

import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Alloca (..), Load (..), Store (..))
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type (..), resolveNamed)
import Olivine.Syntax.Value (TypedValue (..), Value (..))

splitAggregates :: Program -> Program
splitAggregates program =
  program {programEntries = map entry (programEntries program)}
  where
    -- What a field selection means is a fact about the module: the struct it
    -- names may be a named type, and the allocation may name the same one
    -- differently.
    types = namedTypes program

    entry (EFunction f) = EFunction (settle types f)
    entry retained = retained

-- | Split, and then split what splitting brought into view.
settle :: Map Name Type -> Function -> Function
settle types f
  | split == f = f
  | otherwise = settle types split
  where
    split = splitIn types f

-- | One sweep: every slot 'splittableIn' admits becomes the slots its fields
-- want, and every step to a field becomes the slot the field got.
splitIn :: Map Name Type -> Function -> Function
splitIn types f
  | Map.null aggregates = f
  | otherwise = f {functionBlocks = map block (functionBlocks f)}
  where
    aggregates = splittableIn types f

    Local next = nextLocal f

    -- A local for each field of each slot, numbered in the order the maps are
    -- in rather than the order the blocks are walked in, so what comes out is
    -- settled before the rewrite starts.
    issued :: Map (Local, Natural) (Local, Type)
    issued =
      Map.fromList
        [ ((slot, index), (Local n, t))
        | ((slot, index, t), n) <- zip wanted [next ..]
        ]

    wanted =
      [ (slot, index, t)
      | (slot, aggregate) <- Map.toAscList aggregates
      , (index, (t, _)) <- Map.toAscList (aggregateFields aggregate)
      ]

    -- What each address of a field is now that the field has a slot: whatever
    -- named it names the slot instead.  A substitution rather than an
    -- assignment because promotion follows an address through a step of zero
    -- and not through a copy — a copy here would put back the very thing the
    -- split was for.
    renaming :: Map Local Local
    renaming =
      Map.fromList
        [ (named, new)
        | (slot, aggregate) <- Map.toList aggregates
        , (index, (_, names)) <- Map.toList (aggregateFields aggregate)
        , (new, _) <- maybe [] pure (Map.lookup (slot, index) issued)
        , named <- names
        ]

    renamed local = Map.findWithDefault local local renaming

    block b =
      b
        { blockInstructions = concatMap instruction (blockInstructions b)
        , blockTerminator = terminator (blockTerminator b)
        }

    -- The allocation being split comes first, because a slot whose first field
    -- is reached by its own address is renamed to that field's slot and would
    -- otherwise be read here as an instruction to drop.
    instruction i
      -- A marker on an object that is about to be several.  Substituting would
      -- leave it naming one field where it meant the whole, and there is no
      -- honest rewriting of it: what it said is where a stack slot may be
      -- reused, and this pass has just replaced the slot it said it about.
      -- Dropping it costs a back end the chance to overlap that storage with
      -- something else and costs nothing here, markers being what a pass may
      -- believe rather than something it must keep.
      | Just marked <- lifetimeMarked (instructionOperation i)
      , Map.member marked aggregates || Map.member marked renaming =
          []
      | otherwise = case instructionResult i of
          Just slot
            | Just aggregate <- Map.lookup slot aggregates ->
                allocations i slot aggregate
          Just result | Map.member result renaming -> []
          _ -> [substituted i]

    substituted i =
      i {instructionOperation = fmap (fmap renamed) (instructionOperation i)}

    -- A terminator names no address of a field, every one of them having
    -- stayed in an address position to get this far, and is rewritten anyway
    -- rather than left out on the strength of that.
    terminator t =
      t {terminatorTransfer = fmap (fmap renamed) (terminatorTransfer t)}

    -- The one allocation becomes the ones its fields want, where it stood: an
    -- @alloca@ in a loop is fresh storage each time round, and so are these.
    -- The metadata goes on each of them, there being no one field of the
    -- struct it was ever about.
    allocations i slot aggregate =
      [ i {instructionResult = Just new, instructionOperation = OAlloca (holding t)}
      | index <- Map.keys (aggregateFields aggregate)
      , (new, t) <- maybe [] pure (Map.lookup (slot, index) issued)
      ]
      where
        holding t =
          (aggregateAlloca aggregate)
            { allocaType = t
            , -- One object, whether or not the original asked for one element
              -- in so many words.  The alignment and the address space are the
              -- allocation's own and stay as they were.
              allocaElementCount = Nothing
            }

-- | A slot that can be taken apart, and what into.
data Aggregate = Aggregate
  { -- | The allocation as written, which the new ones are made from: they
    -- differ in what they hold and in nothing else, so which memory the
    -- storage is in and how well aligned it is come from here.
    aggregateAlloca :: Alloca (TypedValue Local)
  , -- | For each field the function reaches: what that field holds, and the
    -- locals that are its address and have to become the new slot.
    --
    -- Usually one local per step and several steps to a field, a front end
    -- writing the step afresh at every mention of it.  The slot's own local is
    -- among them when the first field is reached by the slot's own address,
    -- which is where a front end wrote the access without a step at all.
    aggregateFields :: Map Natural (Type, [Local])
  }
  deriving (Eq, Show)

-- | The slots a function's storage can be taken apart into a slot per field.
--
-- An @alloca@ qualifies when all of the following hold.
--
-- * It allocates one object of a struct type, and says how it is aligned.
--   @alloca %s, i32 %n@ is an array of them, @inalloca@ storage is how an
--   argument is passed rather than something the function owns, and an
--   alignment left to the target is one this cannot pass on.
--
-- * Nothing else assigns to the local it names, so that the local is the
--   storage everywhere and not sometimes something else.
--
-- * Every use of that local is a step to a field of the struct it was
--   allocated as, or an access at the first field's own type, which is the
--   same address said without a step.  A load or store of the whole thing, a
--   stride, a step into some other struct: any of them and this pass has
--   nothing to say, because what such an access covers is a number of bytes
--   and nothing here measures bytes.
--
-- * Everything reached through each of those addresses keeps to the field it
--   is an address of, which is 'contains'.
splittableIn :: Map Name Type -> Function -> Map Local Aggregate
splittableIn types f =
  Map.fromList
    [ (slot, Aggregate a (Map.fromListWith together taken))
    | Instruction (Just slot) (OAlloca a) _ <- instructions
    , single a
    , isJust (allocaAlignment a)
    , Map.findWithDefault 0 slot definitions == 1
    , slot `notElem` functionParameters f
    , let held = resolveNamed types (allocaType a)
    , TStruct _ fields <- [held]
    , let taken = concatMap (reaching held fields slot) (usesOf slot)
    , -- A slot nothing reaches has nothing to be split into, and a slot with a
      -- use this could not read has a field it cannot account for.  Each of
      -- the uses below names the slot exactly once, so the two numbers agree
      -- when every use of it is one of them and not otherwise.
      not (null taken)
    , length taken + length (bracketing slot) == Map.findWithDefault 0 slot uses
    ]
  where
    instructions = [i | b <- functionBlocks f, i <- blockInstructions b]

    together (t, new) (_, old) = (t, old <> new)

    -- What one use of a slot says about a field of it: nothing, or the field
    -- and the local that is its address.
    reaching held fields slot i
      | not (only slot i) = []
      | otherwise = case instructionOperation i of
          OField x
            | names slot (fieldPointer x)
            , Just result <- instructionResult i
            , Map.findWithDefault 0 result definitions == 1
            , resolveNamed types (fieldStructType x) == held
            , Just t <- fields !? fieldIndex x
            , contains (length instructions) t result ->
                [(fieldIndex x, (t, [result]))]
          -- The address of the first field is the address of the struct,
          -- packed or not, and a front end that wrote the access without a
          -- step wrote this.  It is at that field's own type, so it keeps to
          -- the field for the reason every access 'contains' admits does.
          OLoad l | names slot (loadPointer l) -> first (loadType l)
          OStore s | names slot (storePointer s) -> first (typedValueType (storeValue s))
          _ -> []
      where
        first accessed = case fields !? 0 of
          Just t | resolveNamed types t == resolveNamed types accessed -> [(0, (t, [slot]))]
          _ -> []

    -- Whether everything reached through this address keeps to the value of
    -- this type that it is the address of.
    --
    -- A load or a store at that very type covers it exactly.  A step into it
    -- covers part of it, and what that part is asked again of the part.
    -- Everything else is refused, which is what makes this the escape check as
    -- well: a pointer handed to a call or written into memory is not among the
    -- shapes here, so the slot it came from is not split.
    --
    -- The fuel is what a chain of steps that closes on itself runs out of.
    -- Nothing well formed writes one, and this pass runs before the thing that
    -- would say so.
    contains :: Int -> Type -> Local -> Bool
    contains fuel t pointer =
      fuel > 0
        && length here == Map.findWithDefault 0 pointer uses
        && all keeping here
      where
        here = Map.findWithDefault [] pointer usedBy

        keeping i =
          only pointer i
            && case instructionOperation i of
              OLoad l -> names pointer (loadPointer l) && at (loadType l)
              OStore s -> names pointer (storePointer s) && at (typedValueType (storeValue s))
              OField x
                | names pointer (fieldPointer x)
                , Just result <- instructionResult i
                , Map.findWithDefault 0 result definitions == 1
                , resolveNamed types (fieldStructType x) == resolveNamed types t
                , TStruct _ fields <- resolveNamed types t
                , Just inner <- fields !? fieldIndex x ->
                    contains (fuel - 1) inner result
              -- A field's own address bracketed, which a front end writes
              -- where a member outlives less of the function than the struct
              -- around it.  The same answer as for the whole slot above.
              operation -> lifetimeMarked operation == Just pointer

        at accessed = resolveNamed types accessed == resolveNamed types t

    names local (TypedValue _ (VLocal n)) = n == local
    names _ _ = False

    -- The lifetime markers naming a local, which are uses of it that say
    -- nothing about any field and are not escapes either.  Counted rather than
    -- accounted for, since the whole of what they mark is the whole of what is
    -- about to stop being one object: the rewrite drops them, as it must —
    -- after the split there is no local for one to name.
    --
    -- Whether a slot bracketed this way is worth splitting is not in question.
    -- It is what a front end writes for every local aggregate at any level
    -- above @-O0@, so refusing them left every struct in the newer half of the
    -- corpus in memory.
    bracketing local =
      [ i
      | i <- usesOf local
      , lifetimeMarked (instructionOperation i) == Just local
      ]

    -- Whether an instruction names a local in one place only, so that a
    -- pointer standing in an address position and somewhere else besides is
    -- refused for the somewhere else: @store ptr %p, ptr %p@ writes an address
    -- into the storage it is the address of.
    only local i =
      length (filter (== local) (localsUsedBy (instructionOperation i))) == 1

    (!?) :: [Type] -> Natural -> Maybe Type
    fields !? index = case drop (fromIntegral index) fields of
      field : _ -> Just field
      [] -> Nothing

    single a =
      not (allocaInalloca a) && case allocaElementCount a of
        Nothing -> True
        Just (TypedValue _ (VInteger 1)) -> True
        Just _ -> False

    definitions :: Map Local Int
    definitions =
      Map.fromListWith (+) [(result, 1) | Just result <- map instructionResult instructions]

    -- How many operand positions name each local, terminators included, and
    -- which instructions those are for the ones an instruction names.  The
    -- count is what the two checks above are written in terms of: a use
    -- accounted for does not say the others were, and a local the count
    -- reaches but 'usedBy' does not is one a terminator names.
    uses :: Map Local Int
    uses =
      Map.fromListWith
        (+)
        ( [ (local, 1)
          | i <- instructions
          , local <- localsUsedBy (instructionOperation i)
          ]
            <> [ (local, 1)
               | b <- functionBlocks f
               , local <- localsUsedBy (terminatorTransfer (blockTerminator b))
               ]
        )

    usedBy :: Map Local [Instruction]
    usedBy =
      Map.fromListWith
        (<>)
        [ (local, [i])
        | i <- instructions
        , local <- localsUsedBy (instructionOperation i)
        ]

    usesOf slot = Map.findWithDefault [] slot usedBy
