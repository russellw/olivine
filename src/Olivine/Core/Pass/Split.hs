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
-- is also the whole of its limit.  A slot strided into as though it were an
-- array, stepped into as some other struct, or handed to a @memset@ or a
-- @memcpy@ keeps its storage, because what such an access covers is a number of
-- bytes and this pass is not in the business of bytes.  LLVM's own gives up on
-- the same programs for the same reason, having watched the bytes and found an
-- access it could not place.
--
-- The one that used to be on that list and no longer is is the slot read or
-- written /whole/, at the very type it was allocated as.  That access names no
-- field, but it names every field, and the struct type says which they are —
-- so 'unpackedIn' writes it out one field at a time before the split looks, and
-- the whole thing stays a question about names.  See there for what it costs
-- and why it is only done where the slot then goes.
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

import Data.List (mapAccumL)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust)
import Data.Set qualified as Set
import Data.Text qualified as T
import Numeric.Natural (Natural)

import Olivine.Core.Instruction
import Olivine.Core.Layout (Layout, allocSize, layoutOf)
import Olivine.Core.Program
import Olivine.Syntax.Instruction
  ( Alloca (..)
  , Argument (..)
  , Call (..)
  , ExtractValue (..)
  , InsertValue (..)
  , Load (..)
  , Store (..)
  )
import Olivine.Syntax.Name (Name, nameText)
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

    -- Asked one question and no other: whether a byte count covers exactly the
    -- type a slot was allocated as.  See 'unpackedIn'.
    layout = layoutOf program

    entry (EFunction f) = EFunction (settle layout types f)
    entry retained = retained

-- | Split, and then split what splitting brought into view.
settle :: Maybe Layout -> Map Name Type -> Function -> Function
settle layout types f
  | split == f = f
  | otherwise = settle layout types split
  where
    split = splitIn layout types f

-- | One sweep: every slot 'splittableIn' admits becomes the slots its fields
-- want, and every step to a field becomes the slot the field got — after any
-- slot said whole has been said a field at a time, which is what makes some of
-- them admissible in the first place.
splitIn :: Maybe Layout -> Map Name Type -> Function -> Function
splitIn layout types original
  | Map.null aggregates = original
  | otherwise = f {functionBlocks = map block (functionBlocks f)}
  where
    f = unpackedIn layout types original
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

-- | Whether an allocation is of one object rather than an array of them.
--
-- @alloca %s, i32 %n@ is an array of them, and @inalloca@ storage is how an
-- argument is passed rather than something the function owns.
single :: Alloca (TypedValue Local) -> Bool
single a =
  not (allocaInalloca a) && case allocaElementCount a of
    Nothing -> True
    Just (TypedValue _ (VInteger 1)) -> True
    Just _ -> False

-- | A slot loaded or stored whole, said one field at a time instead.
--
-- A struct small enough to travel in registers is returned as a value, and a
-- front end builds it by writing the fields into a slot and then loading the
-- whole thing: @load { double, double }, ptr %p@.  That access covers a number
-- of bytes rather than a field, so it is exactly what 'splittableIn' refuses,
-- and it refuses the slot entire — the very slot whose every other use is a
-- field step.  Written out field by field the access says the same thing in the
-- terms this pass reads, and the slot goes.
--
-- __What it becomes.__  A load is a step to each field, a load of each field,
-- and an @insertvalue@ chain assembling them; a store is the chain read
-- backwards, an @extractvalue@ per field and a store of each.  None of it
-- survives: the steps are what the split renames away, the accesses become
-- accesses to the new slots and then locals under promotion, and a chain
-- assembling what another chain took apart is what
-- "Olivine.Core.Pass.Fold" reads as the aggregate it came from.  What is left
-- is the chain a caller of the function actually needs.
--
-- __Only where it pays, decided by trying it.__  Unpacking a slot that is not
-- then split would be a pessimization — one access for several — so the rewrite
-- is made, 'splittableIn' asked of the result, and only the slots it admits are
-- unpacked for real.  Two walks rather than a predicate that would have to
-- say in advance what that function already says.
--
-- __No bytes, still.__  The struct type names the fields and @insertvalue@
-- names them the same way, so nothing here asks where a field begins.  The new
-- accesses claim the /allocation's/ alignment, which is honest for the reason
-- the new slots may claim it: after the split each field stands at the start of
-- a slot allocated that well.  The metadata on the access is dropped rather
-- than copied onto each field, an aliasing fact about a struct not being one
-- about a field of it, and dropping one is always allowed.
--
-- __And the two that are a byte count.__  A @memset@ of a slot to zero and a
-- @memcpy@ between two of them say the whole of a slot as plainly as a wide
-- load does, but they say it in bytes: what has to be shown is that the count
-- covers exactly the type the slot was allocated as, and that is @sizeof@.  So
-- this is the one question "Olivine.Core.Layout" is asked here, and asked of
-- nothing else — a module with no layout string declines these two and splits
-- everything else exactly as before.  A fill of anything but zero is refused:
-- @zeroinitializer@ is the one spelling of a zero that needs no knowledge of
-- how a type is represented, where a fill of @0xAB@ would want the byte
-- repeated to each field\'s width and a float literal invented to hold it.
--
-- What is left refused after those: a slot strided into as an array, and a
-- @memcpy@ one end of which is not a slot of this function — its fields would
-- have to be stepped to at an alignment nothing here knows.
unpackedIn :: Maybe Layout -> Map Name Type -> Function -> Function
unpackedIn layout types f
  | Set.null worthwhile = f
  | otherwise = unpacking layout types worthwhile f
  where
    candidates = Set.fromList (concatMap snd (wholeAccessesIn layout types f))

    -- Shrunk until it stops shrinking.  An access naming two slots is only
    -- written out if both of them go, so dropping one slot can take another
    -- access with it and leave a third slot no longer worth unpacking; taking
    -- the answer from one round would leave a rewrite standing that nothing
    -- then splits.  It terminates because the set only ever loses members.
    worthwhile = shrinking candidates
    shrinking chosen
      | Set.size fewer == Set.size chosen = chosen
      | otherwise = shrinking fewer
      where
        splittable = splittableIn types (unpacking layout types chosen f)
        fewer = Set.filter (`Map.member` splittable) chosen

-- | The slots this function assigns one @alloca@ of a struct to, with what
-- that struct holds.
--
-- Assigned once, because a local that is the storage only sometimes is not the
-- storage; and one object of the struct rather than an array of them, which is
-- 'single' and the same question 'splittableIn' asks.
slotsIn :: Map Name Type -> Function -> Map Local (Alloca (TypedValue Local), Type, [Type])
slotsIn types f =
  Map.fromList
    [ (slot, (a, held, fields))
    | Instruction (Just slot) (OAlloca a) _ <- instructions
    , single a
    , isJust (allocaAlignment a)
    , length [() | Just other <- map instructionResult instructions, other == slot] == 1
    , slot `notElem` functionParameters f
    , let held = resolveNamed types (allocaType a)
    , TStruct _ fields <- [held]
    , not (null fields)
    ]
  where
    instructions = [i | b <- functionBlocks f, i <- blockInstructions b]

-- | Every access that reads or writes one of those slots whole, with the slots
-- it names.
--
-- At the type it was allocated as and no other: an access at some other type
-- covers some other bytes, and this pass has nothing to say about bytes.  A
-- volatile one is left alone, the point of one being that it happens as it was
-- written, and a load into nothing is left because there is nothing to
-- assemble.
wholeAccessesIn ::
  Maybe Layout -> Map Name Type -> Function -> [(Instruction, [Local])]
wholeAccessesIn layout types f =
  [ (i, slots)
  | b <- functionBlocks f
  , i <- blockInstructions b
  , let slots = wholeAccessTo layout types (slotsIn types f) i
  , not (null slots)
  ]

-- | Which slots this instruction reads or writes whole, where it does.
--
-- One for a load, a store or a fill, and two for a copy — the slot written and
-- the slot read.
wholeAccessTo ::
  Maybe Layout ->
  Map Name Type ->
  Map Local (Alloca (TypedValue Local), Type, [Type]) ->
  Instruction ->
  [Local]
wholeAccessTo layout types slots i = case instructionOperation i of
  OLoad l
    | not (loadVolatile l)
    , isJust (instructionResult i) ->
        naming (loadPointer l) (loadType l)
  OStore s
    | not (storeVolatile s) ->
        naming (storePointer s) (typedValueType (storeValue s))
  -- @llvm.memset(dst, value, size, isvolatile)@ and
  -- @llvm.memcpy(dst, src, size, isvolatile)@, each covering the whole of what
  -- it names and no more.
  OCall call -> case byteWise call of
    Just (Fill, [destination, filled, size, plain])
      | zero filled
      , plain == VBoolean False ->
          covering size destination
    -- The two ends of a copy must be slots holding the same struct: the fields
    -- of the one are then the fields of the other, so the copy is a copy per
    -- field and no byte of either is named except through a field.
    Just (Copy, [destination, source, size, plain])
      | plain == VBoolean False
      , [into] <- covering size destination
      , [from] <- covering size source
      , into /= from
      , Just (_, held, _) <- Map.lookup into slots
      , Just (_, other, _) <- Map.lookup from slots
      , held == other ->
          [into, from]
    _ -> []
  _ -> []
  where
    -- Whether the count covers the whole of the slot the address names, which
    -- is the one question the layout is asked.
    covering (VInteger count) (VLocal slot)
      | Just (_, held, _) <- Map.lookup slot slots
      , Just size <- (\known -> allocSize known held) =<< layout
      , count >= 0
      , fromIntegral count == size
      , names slot =
          [slot]
    covering _ _ = []

    naming (TypedValue _ (VLocal slot)) accessed
      | Just (_, held, _) <- Map.lookup slot slots
      , names slot
      , resolveNamed types accessed == held =
          [slot]
    naming _ _ = []

    -- One place names the slot, or a store writing the slot\'s own address into
    -- it would be read as an access and lose the other mention.  A copy names
    -- two slots and each of them once, so this is asked of each.
    names slot =
      length (filter (== slot) (localsUsedBy (instructionOperation i))) == 1

    zero value = value == VInteger 0 || value == VZeroInitializer

-- | Whether a call is to one of the two memory intrinsics, and what it was
-- handed.
byteWise :: Call (TypedValue Local) -> Maybe (ByteWise, [Value Local])
byteWise call = do
  VGlobal name <- Just (typedValue (callCallee call))
  kind <- case () of
    _ | called (nameText name) "llvm.memset" -> Just Fill
      | called (nameText name) "llvm.memcpy" -> Just Copy
      | otherwise -> Nothing
  pure (kind, map (typedValue . argumentValue) (callArguments call))
  where
    -- The overloaded name carries the types it was resolved at.
    called this base = this == base || T.isPrefixOf (base <> ".") this

-- | Which of the two.
data ByteWise = Fill | Copy
  deriving (Eq)

-- | The rewrite itself, for the slots named.
unpacking :: Maybe Layout -> Map Name Type -> Set.Set Local -> Function -> Function
unpacking layout types chosen f = f {functionBlocks = blocks}
  where
    slots = slotsIn types f
    Local start = nextLocal f
    (_, blocks) = mapAccumL block start (functionBlocks f)

    block n b = (after, b {blockInstructions = concat groups})
      where
        (after, groups) = mapAccumL instruction n (blockInstructions b)

    -- An access is written out only where every slot it names is one being
    -- unpacked, a copy between a slot that goes and one that stays being no
    -- fewer instructions than it was.
    instruction n i = case wholeAccessTo layout types slots i of
      [slot]
        | Set.member slot chosen
        , Just (a, _, fields) <- Map.lookup slot slots ->
            unpacked n i a fields
      [into, from]
        | Set.member into chosen
        , Set.member from chosen
        , Just (a, _, fields) <- Map.lookup into slots
        , Just (b, _, _) <- Map.lookup from slots ->
            copied n i a b fields
      _ -> (n, [i])

    -- The addresses come first, then what is done through them: a load reads
    -- each field and assembles them, a store takes the value apart and writes
    -- each field, a fill writes a zero into each.
    unpacked n i a fields = case instructionOperation i of
      OLoad l ->
        ( n + 3 * count - 1
        , steps (loadPointer l) <> [reading j | j <- indices] <> [assembling j | j <- indices]
        )
        where
          reading j =
            Instruction
              (Just (value j))
              ( OLoad
                  l
                    { loadType = fields !! fromIntegral j
                    , loadPointer = addressed n j (loadPointer l)
                    }
              )
              []
          assembling j =
            Instruction
              (Just (if j == last indices then result else Local (n + 2 * count + fromIntegral j)))
              ( OInsertValue
                  InsertValue
                    { insertValueAggregate = TypedValue (loadType l) (built j)
                    , insertValueValue = TypedValue (fields !! fromIntegral j) (VLocal (value j))
                    , insertValueIndices = [j]
                    }
              )
              []
          built 0 = VPoison
          built j = VLocal (Local (n + 2 * count + fromIntegral j - 1))
          result = case instructionResult i of
            Just r -> r
            Nothing -> Local n
      OStore s ->
        ( n + 2 * count
        , steps (storePointer s) <> concat [[taking j, writing j] | j <- indices]
        )
        where
          taking j =
            Instruction
              (Just (value j))
              (OExtractValue (ExtractValue (storeValue s) [j]))
              []
          writing j = written (fields !! fromIntegral j) (VLocal (value j)) j (storePointer s)
      -- A fill, whose destination is the first thing it was handed.  A zero of
      -- a field's type is written @zeroinitializer@ whatever that type is,
      -- which is the one spelling that needs to know nothing about how the type
      -- is laid out or how a literal of it is spelled.
      OCall call
        | destination : _ <- map argumentValue (callArguments call) ->
            ( n + count
            , steps destination
                <> [ written (fields !! fromIntegral j) VZeroInitializer j destination
                   | j <- indices
                   ]
            )
      _ -> (n, [i])
      where
        count = length fields
        indices = [0 .. fromIntegral count - 1]
        value j = Local (n + count + fromIntegral j)
        steps pointer = [stepping n (allocaType a) pointer j | j <- indices]
        written t held j pointer =
          Instruction
            Nothing
            ( OStore
                Store
                  { storeVolatile = False
                  , storeValue = TypedValue t held
                  , storePointer = addressed n j pointer
                  , storeAlignment = allocaAlignment a
                  }
            )
            []

    -- A copy, which is a step to each field of both ends, a load of each field
    -- of the one and a store into each field of the other.  Both hold the same
    -- struct, so one list of fields answers for both; the alignments are each
    -- slot's own.
    copied n i a b fields = case map argumentValue (maybe [] callArguments call) of
      destination : source : _ ->
        ( n + 3 * count
        , [stepping n (allocaType a) destination j | j <- indices]
            <> [stepping (n + count) (allocaType b) source j | j <- indices]
            <> concat [[reading j source, writing j destination] | j <- indices]
        )
        where
          reading j from =
            Instruction
              (Just (value j))
              ( OLoad
                  Load
                    { loadVolatile = False
                    , loadType = fields !! fromIntegral j
                    , loadPointer = addressed (n + count) j from
                    , loadAlignment = allocaAlignment b
                    }
              )
              []
          writing j into =
            Instruction
              Nothing
              ( OStore
                  Store
                    { storeVolatile = False
                    , storeValue = TypedValue (fields !! fromIntegral j) (VLocal (value j))
                    , storePointer = addressed n j into
                    , storeAlignment = allocaAlignment a
                    }
              )
              []
      _ -> (n, [i])
      where
        call = case instructionOperation i of
          OCall c -> Just c
          _ -> Nothing
        count = length fields
        indices = [0 .. fromIntegral count - 1]
        value j = Local (n + 2 * count + fromIntegral j)

    addressed base j (TypedValue t _) =
      TypedValue t (VLocal (Local (base + fromIntegral j)))

    -- The struct as the allocation wrote it, so a named type stays named and
    -- 'splittableIn' reads the step as one into the type it allocated.
    stepping base structType pointer j =
      Instruction
        (Just (Local (base + fromIntegral j)))
        ( OField
            Field
              { fieldFlags = []
              , fieldStructType = structType
              , fieldPointer = pointer
              , fieldIndex = j
              }
        )
        []

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
