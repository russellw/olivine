-- | Turning storage the function only ever loads from and stores to into a
-- local it assigns.
--
-- This is the pass the core representation was shaped for.  LLVM calls it
-- @mem2reg@, and almost all of the work in it there is placing phi nodes: a
-- slot written on two paths and read after they meet needs one where they
-- meet, so nothing can be rewritten until the dominance frontiers of the
-- writes are known.  Here a local can be reassigned.  A store becomes an
-- assignment to the slot, a load becomes an assignment from it, the allocation
-- goes, and that is the whole rewrite — there is no phi to place because there
-- is nowhere in the core to write one.  "Olivine.Core.Ssa" puts them back on
-- the way out, for every local at once, which it had to do anyway.
--
-- __The slot keeps its own local.__  @%a = alloca i32@ becomes an assignment
-- to @%a@, which afterwards holds the @i32@ rather than its address.  That
-- nothing reads it as an address is the condition for being promoted at all,
-- so taking the number over is free, and it leaves the value where a reader of
-- the output would look for it.
--
-- __The allocation becomes poison, not nothing.__  Fresh storage holds
-- whatever it holds, and reading it before anything is written is undefined;
-- a local assigned poison says that and nothing more.  Removing the
-- allocation outright would say something else wherever it is reached twice —
-- an @alloca@ in a loop is a new object each time round, and the local
-- standing for it has to forget each time what the last iteration left there.
--
-- __One sweep.__  Promoting a slot cannot make another promotable: what stops
-- one is being read as something other than an address, and this rewrite
-- turns such a read into an assignment rather than removing it.  What can is
-- the dead code pass afterwards taking away the last such read — a slot whose
-- address was stored into another slot that turned out to be unread — and that
-- is an argument for running the pipeline again, not for iterating here.
--
-- __A slot read at a type other than the one written to it is still a local.__
-- A union punned through, a bit field, a @_Bool@ in a byte: the front end
-- writes an @i32@ and reads an @i8@, and what the read gets is part of the
-- bits of what was written.  So the local holds the type the stores are at,
-- and a load at another type becomes the conversion that says the same thing
-- about a value that the memory said about the bytes — a @bitcast@ where the
-- two are the same width, a @trunc@ where the read is narrower.
--
-- That works here without any notion of a type's size because of what
-- 'addressedBy' already demands: every access to a promotable slot is at the
-- slot's own address.  An access reached by a step is a step off the local,
-- which is an escape, so there is no offset to know — the only question left
-- is which end of the value the address is, and that is the byte order, one
-- component of the data layout that 'Olivine.Core.Layout.endiannessOf' can
-- pick out without reading the rest.  A module that does not say declines,
-- and so does a big endian one, whose narrower read takes the high bits
-- instead: it would be a shift and a truncation rather than a truncation, and
-- nothing here has ever been run against such a target.
--
-- __A store narrower than the slot writes some of its bits.__  That is not an
-- assignment to the local, so it is written as what it does: read the local
-- back, mask off where the store lands, and put the two together.  One
-- instruction becomes three, which pays only because the slot becomes a local
-- at all — a bit field assignment is a load, a mask and a store of the word
-- holding it, and until this the word stayed in memory for the sake of the one
-- store.  The slot then begins as @undef@ rather than @poison@: what the store
-- leaves alone is what the storage held, and @and poison, m@ is poison where
-- @and undef, m@ is the zeroes the mask asks for, so poison would spread out of
-- the bits nobody wrote into the ones somebody did.
--
-- __A byte copy that covers a slot exactly is an access to it.__  A @memcpy@ is
-- a call, and a call naming an address is the one thing that stops a slot being
-- promoted at all; but a copy of exactly the bytes the slot holds reads or
-- writes the whole of it and nothing else, which is what a load or a store
-- does.  So it counts as one, at an integer of the width it moved — a copy says
-- nothing about what the bytes mean and an integer says the same — and the call
-- becomes the load, the store or the plain assignment that moves the value.
-- This is how a struct returned or passed by value reaches the local it was
-- built in, and it is the one question this pass asks
-- "Olivine.Core.Layout": how big what the slot holds is.  See 'wholeCopy'.
--
-- What it still declines is a store or a load at an offset into the slot.
-- Holding the slot as its bits and writing each access into its own is a larger
-- change than either of the two above, since it needs every access placed as
-- well as measured; "Olivine.Core.Pass.Split" takes the slots whose parts the
-- program named instead.
--
-- __A function that calls @setjmp@ is promoted like any other.__  It looks as
-- though it should not be: control arrives at the call a second time with the
-- frame as @longjmp@ left it, so a slot written in between holds the written
-- value and a local standing for it does not.  The answer is that this is the
-- one thing every language says out loud — C makes such a function's own
-- non-@volatile@ locals indeterminate after the second return, which is
-- exactly the licence to hold them in a local here, and a program wanting the
-- written value has to say @volatile@, which this pass already refuses to
-- touch.  Checked against LLVM rather than reasoned from: @opt -passes=mem2reg@
-- promotes both slots of a @setjmp@ function and @-O2@ forwards a store across
-- the call.  What that licence does /not/ cover is anybody else's locals,
-- which is why "Olivine.Core.Pass.Inline" will not copy such a body into a
-- caller.
module Olivine.Core.Pass.Promote
  ( promoteMemory
  , promotableIn
  ) where

import Control.Monad (guard)
import Data.Foldable (toList)
import Data.List (delete, mapAccumL)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust, listToMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Data.Text qualified as T
import Numeric.Natural (Natural)

import Olivine.Core.Instruction
import Olivine.Core.Layout
  ( Endianness (..)
  , Layout
  , allocSize
  , endiannessOf
  , layoutOf
  , scalarBits
  )
import Olivine.Core.Program
import Olivine.Syntax.Attribute (ParamAttribute (..))
import Olivine.Syntax.Instruction
  ( Alloca (..)
  , Argument (..)
  , Binary (..)
  , BinaryOp (..)
  , Call (..)
  , Convert (..)
  , Load (..)
  , Store (..)
  )
import Olivine.Syntax.Name (nameText)
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value

promoteMemory :: Program -> Program
promoteMemory program =
  program {programEntries = map entry (programEntries program)}
  where
    -- Which end of a stored value a narrower read of it gets, asked once for
    -- the program: it is a property of the target, and every function in a
    -- module is compiled for the same one.
    order = endiannessOf program

    -- And how big what a slot holds is, which is the one question a byte count
    -- has to be answered against.
    layout = layoutOf program

    entry (EFunction f) = EFunction (promoteIn order layout f)
    entry retained = retained

promoteIn :: Maybe Endianness -> Maybe Layout -> Function -> Function
promoteIn order layout f
  | Map.null promoted = f
  | otherwise = f {functionBlocks = snd (mapAccumL block next (functionBlocks f))}
  where
    promoted = promotableIn order layout f

    -- What each slot was allocated as, which is what a byte count is measured
    -- against.  Asked through 'rooted', so that a copy naming a step of zero
    -- names the slot it steps from.
    holding n = Map.lookup (rooted n) (allocatedIn f)

    -- What each local that is a step of zero names, which is how an access
    -- written through one is seen to be an access to the slot.
    rooted = rootOf (zeroSteps f)

    -- The slots some store writes only some of the bits of.
    --
    -- Such a slot starts as @undef@ rather than @poison@, which is the one
    -- place the two differ here.  What a narrow store leaves alone is what the
    -- storage held, and 'inserting' says that by masking the old value: @and
    -- undef, m@ is the zeroes the mask asks for, and @and poison, m@ is poison,
    -- which would then spread from the bits nobody ever wrote into the ones
    -- somebody just did.  Fresh storage read before anything is written is
    -- undefined either way, which is all the allocation ever claimed.
    partly =
      Set.fromList
        [ slot
        | i <- [x | b <- functionBlocks f, x <- blockInstructions b]
        , (named, Stored t) <- reaching layout holding i
        , let slot = rooted named
        , Just held <- [Map.lookup slot promoted]
        , scalarBits t /= scalarBits held
        ]

    -- Where the names the conversions assign to start.  A conversion cannot
    -- write to the local the load named, since that local is what the rest of
    -- the function reads and a local an instruction writes is a local nothing
    -- else may write; so it writes a name of its own and an assignment carries
    -- it over, as "Olivine.Core.Pass.IfConversion" does with a select.
    Local next = nextLocal f

    block n b =
      let (n', made) = mapAccumL instruction n (blockInstructions b)
       in (n', b {blockInstructions = concat made})

    -- The four shapes an instruction naming a promoted slot takes, and nothing
    -- else can be one: the accesses are what 'promotableIn' enumerated to
    -- decide the slot was promotable, so what is reached here is a load, a
    -- store, the allocation itself, or a step of zero on the way to one of
    -- them.  The step goes: it named an address, there is no longer an address
    -- to name, and what read its result was an access this rewrote or another
    -- step this dropped — anything else would have been an escape.
    instruction n i = case instructionOperation i of
      OAlloca _
        | Just slot <- instructionResult i
        , Just t <- Map.lookup slot promoted ->
            (n, [assigning slot (TypedValue t (nothingYet slot))])
      OStore s
        | Just slot <- slotOf (storePointer s)
        , Just t <- Map.lookup slot promoted ->
            if scalarBits (typedValueType (storeValue s)) == scalarBits t
              then reinterpreting n (storeValue s) t (assigning slot)
              else inserting n (storeValue s) slot t
      OLoad l
        | Just slot <- slotOf (loadPointer l)
        , Just t <- Map.lookup slot promoted
        , Just result <- instructionResult i ->
            reinterpreting n (TypedValue t (VLocal slot)) (loadType l) (assigning result)
      -- A copy that covers a slot at either end, where that end became a
      -- local: what the copy moved is what the local holds, so the read is the
      -- local or a load of the bits, and the write is an assignment or a store
      -- of them.  Both ends being slots makes the whole call one assignment.
      OCall _
        | Just c <- wholeCopy layout holding (instructionOperation i)
        , isJust (slotOf (copyInto c)) || isJust (slotOf (copyFrom c)) ->
            copying n c
      operation
        | Just result <- instructionResult i
        , _ : _ <- steppingFrom operation
        , Map.member (rooted result) promoted ->
            (n, [])
      -- A marker on storage that is no longer storage.  What it said was where
      -- the object's contents begin and end being anyone's business, and a
      -- local has no such span: it holds poison from the allocation the
      -- assignment replaced until something assigns to it.  LLVM's mem2reg
      -- deletes them for the same reason, which @opt -passes=mem2reg@ was
      -- asked to confirm on a slot bracketed by a pair.
      operation
        | Just marked <- lifetimeMarked operation
        , Map.member (rooted marked) promoted ->
            (n, [])
      _ -> (n, [i])
      where
        -- The metadata stays with the instruction it was attached to, as it
        -- does when folding replaces an operation.  A store's result was
        -- nothing and is now the slot, which is the one part of the record
        -- this has to set as well as the operation.
        assigning name value =
          i {instructionResult = Just name, instructionOperation = OAssign value}

        -- What an allocation leaves in the local until something writes it.
        nothingYet slot
          | Set.member slot partly = VUndef
          | otherwise = VPoison

        -- A store of fewer bits than the local holds, which is an assignment
        -- to some of its bits and not to the local: what it does not write is
        -- what the storage held, so the old value is read back, masked where
        -- the store lands, and the two are put together.
        --
        -- The bits it lands in are the low ones, which is the little endian
        -- assumption 'heldType' checked — and the same one 'reinterpretation'
        -- makes for a load of fewer bits than are there.  Floating point costs
        -- a bitcast at each end and nothing else: the masking is arithmetic on
        -- bits, and which bits a float has is not in question.
        inserting m value slot held = fromMaybe (m, [i]) $ do
          narrow <- scalarBits (typedValueType value)
          wide <- scalarBits held
          let wideBits = TInteger wide
              (m1, saidNarrow, asBits) = saying m value (TInteger narrow)
              (m2, widening, widened) =
                one m1 wideBits (OConvert (Convert CastZExt [] asBits wideBits))
              (m3, saidWide, old) = saying m2 (TypedValue held (VLocal slot)) wideBits
              (m4, masking, kept) =
                one
                  m3
                  wideBits
                  ( OBinary
                      (Binary OpAnd [] old (TypedValue wideBits (VInteger (negate (2 ^ narrow)))))
                  )
              (m5, joining, joined) = one m4 wideBits (OBinary (Binary OpOr [] kept widened))
              (m6, saidBack, final) = saying m5 joined held
          pure
            ( m6
            , saidNarrow
                <> [widening]
                <> saidWide
                <> [masking, joining]
                <> saidBack
                <> [assigning slot final]
            )

        -- The same value said at another type of the same width, which is a
        -- bitcast or nothing at all.
        saying m value target =
          converting m value (fromMaybe [] (reinterpretation order (typedValueType value) target))

        -- One instruction computing something, and the value it leaves.
        one m t operation =
          ( m + 1
          , Instruction (Just (Local m)) operation []
          , TypedValue t (VLocal (Local m))
          )

        -- The two halves of a copy, each written as what its end now is.
        --
        -- The instructions are made rather than taken from the call, which is
        -- where this differs from the other rewrites: what a copy carried was
        -- @!tbaa.struct@, which describes a struct being moved and says nothing
        -- a load or a store could carry, so it is dropped.  Dropping metadata
        -- is always allowed.
        copying m c = (m2, loaded <> written)
          where
            bits = TInteger (copyBits c)

            (m1, loaded, value) = case slotOf (copyFrom c) of
              Just from -> (m, [], TypedValue (held from) (VLocal from))
              Nothing ->
                ( m + 1
                , [ Instruction
                      (Just (Local m))
                      ( OLoad
                          Load
                            { loadVolatile = False
                            , loadType = bits
                            , loadPointer = copyFrom c
                            , loadAlignment = Just (copyFromAlign c)
                            }
                      )
                      []
                  ]
                , TypedValue bits (VLocal (Local m))
                )

            (m2, written) = case slotOf (copyInto c) of
              Just into -> reinterpreting m1 value (held into) (assigned into)
              Nothing -> reinterpreting m1 value bits stored

            assigned into v = Instruction (Just into) (OAssign v) []

            stored v =
              Instruction
                Nothing
                ( OStore
                    Store
                      { storeVolatile = False
                      , storeValue = v
                      , storePointer = copyInto c
                      , storeAlignment = Just (copyIntoAlign c)
                      }
                )
                []

            held slot = Map.findWithDefault (TInteger (copyBits c)) slot promoted

        -- The value the access moves, said at the type the other end wants,
        -- and then whatever the caller does with it.  The conversions come
        -- first and are instructions of their own; the assignment is the one
        -- the access became.
        reinterpreting m value target finish =
          let (m', made, final) =
                -- Nothing is not reachable: the pairs of types here are the
                -- ones 'promotableIn' admitted the slot for.
                case reinterpretation order (typedValueType value) target of
                  Just chain -> converting m value chain
                  Nothing -> (m, [], value)
           in (m', made <> [finish final])

    slotOf (TypedValue _ (VLocal n)) | Map.member (rooted n) promoted = Just (rooted n)
    slotOf _ = Nothing

-- | Write a chain of conversions out as instructions, and say what the last
-- one assigned to.
converting ::
  Int ->
  TypedValue Local ->
  [(CastOp, Type)] ->
  (Int, [Instruction], TypedValue Local)
converting n value [] = (n, [], value)
converting n value ((op, target) : rest) =
  let made = Instruction (Just (Local n)) (OConvert (Convert op [] value target)) []
      (n', more, final) = converting (n + 1) (TypedValue target (VLocal (Local n))) rest
   in (n', made : more, final)

-- | How to say of a value of one type what the same bits say read as another,
-- or Nothing where this cannot say it.
--
-- The two are at one address, so the answer is a conversion of the value
-- rather than anything about where in it the second access lands: at equal
-- widths the bits are the same bits, and at a narrower width they are the ones
-- the byte order puts first.  A read wider than what is there declines — the
-- bits above are whatever the storage held, and a value has no such thing.
reinterpretation :: Maybe Endianness -> Type -> Type -> Maybe [(CastOp, Type)]
reinterpretation order from to
  | from == to = Just []
  | otherwise = do
      wide <- scalarBits from
      narrow <- scalarBits to
      case compare narrow wide of
        EQ -> Just [(CastBitcast, to)]
        GT -> Nothing
        LT -> do
          guard (order == Just LittleEndian)
          -- Truncation is an operation on integers, so a floating point value
          -- is taken to its bits first and a floating point result is made
          -- from them last.  Neither costs anything: a bitcast is a way of
          -- speaking about a value rather than something a machine does.
          pure
            ( [(CastBitcast, TInteger wide) | not (isInteger from)]
                <> [(CastTrunc, TInteger narrow)]
                <> [(CastBitcast, to) | not (isInteger to)]
            )
  where
    isInteger (TInteger _) = True
    isInteger _ = False

-- | The slots a function's storage can become locals, and the type each one
-- then holds.
--
-- An @alloca@ qualifies when all of the following hold.
--
-- * It allocates one object.  @alloca i32, i32 %n@ is an array whose length is
--   not known here, and @inalloca@ storage is how an argument is passed rather
--   than something the function owns.
--
-- * Nothing else assigns to the local it names.  The rewrite makes the local
--   be the value in the slot, which it cannot be if something else puts
--   something else there.
--
-- * The local is read only as the address a plain load reads or a plain store
--   writes, or as the address a step of zero steps from — which is the same
--   address, so what reads that is reading this.  Anything else — passed to a
--   call, returned, stepped somewhere else, compared, stored somewhere — is
--   the address escaping to code that could reach the storage by other means
--   than the accesses counted here.  A volatile access counts as an escape
--   too, since the point of one is that it happens, and an assignment does not
--   happen anywhere.
--
-- * The accesses agree on what the slot holds, which 'heldType' decides: they
--   are all at the allocated type, or they are all at types a value can be
--   converted between, with every store at the widest of them.  Storing an
--   @i8@ into an @i32@ slot writes part of it, and part of a local is not
--   something an assignment can name.
promotableIn :: Maybe Endianness -> Maybe Layout -> Function -> Map Local Type
promotableIn order layout f =
  Map.fromList
    [ (slot, t)
    | Instruction (Just slot) (OAlloca a) _ <- instructions
    , single a
    , Map.findWithDefault 0 slot definitions == 1
    , slot `notElem` functionParameters f
    , not (Set.member slot escaping)
    , Just t <- [heldType order (allocaType a) (Map.findWithDefault [] slot accesses)]
    ]
  where
    instructions = [i | b <- functionBlocks f, i <- blockInstructions b]

    rooted = rootOf (zeroSteps f)

    holding n = Map.lookup (rooted n) (allocatedIn f)

    single a =
      not (allocaInalloca a) && case allocaElementCount a of
        Nothing -> True
        Just (TypedValue _ (VInteger 1)) -> True
        Just _ -> False

    definitions :: Map Local Int
    definitions =
      Map.fromListWith (+) [(slot, 1) | Just slot <- map instructionResult instructions]

    -- Every local read anywhere other than as an address loaded from or
    -- stored to, said as the local whose address that is.  A terminator reads
    -- no address in that sense, so everything it names is here.
    escaping :: Set Local
    escaping =
      Set.fromList
        ( map rooted
            ( concatMap escapingFrom instructions
                <> [ local
                   | b <- functionBlocks f
                   , local <- localsUsedBy (terminatorTransfer (blockTerminator b))
                   ]
            )
        )

    -- Written as a difference rather than by case, so that a slot appearing
    -- twice in one instruction is counted twice: @store ptr %a, ptr %a@ puts
    -- a slot's own address in it, and the value operand is an escape although
    -- the pointer operand is not.
    --
    -- A step of zero reads its pointer as an address, like an access, and
    -- unlike an access it also names one: whatever reads its result is the
    -- escape or the access, and 'rooted' is what says the two are about the
    -- same storage.
    --
    -- A lifetime marker names an address and does nothing with it, so it is
    -- subtracted here as well although it is a call, and the rewrite below
    -- drops it.  What it would otherwise say is that the address reached a
    -- call, which is the one thing that stops a slot being promoted at all.
    escapingFrom i =
      foldr
        delete
        (localsUsedBy (instructionOperation i))
        ( map fst (reaching layout holding i)
            <> steppingFrom (instructionOperation i)
            <> toList (lifetimeMarked (instructionOperation i))
        )

    -- What each slot is accessed at, and which way round.  Gathered in one
    -- walk keyed by slot rather than looked up per candidate, since a function
    -- with many slots would otherwise walk itself once for each of them.
    --
    -- Only the accesses that count as accesses are here: a volatile one names
    -- no slot in 'addressedBy', having already put its pointer among the
    -- escaping.
    accesses :: Map Local [Access]
    accesses =
      Map.fromListWith
        (<>)
        [ (rooted slot, [access])
        | i <- instructions
        , (slot, access) <- reaching layout holding i
        ]

-- | An access to a slot, at the type it is made at.
--
-- The direction matters to 'heldType' and to nothing else: a load may be
-- narrower than what the slot holds, since the bits it wants are there, and a
-- store may not, since the bits it does not write are still there afterwards.
data Access
  = Loaded Type
  | Stored Type
  deriving (Eq, Show)

accessType :: Access -> Type
accessType (Loaded t) = t
accessType (Stored t) = t

-- | What a local standing for the slot would hold, given what the slot was
-- allocated as and every access made to it.
--
-- Two ways to answer, and the first is the whole of what this pass used to do:
-- where every access is at the allocated type, that type is what the local
-- holds and nothing is converted anywhere.
--
-- Otherwise the local holds what the widest store puts there, which the loads
-- then read some or all of, and which a narrower store writes some of the bits
-- of.  That needs every access at a width this knows and none wider than the
-- widest store: a load of more bits than were put there would be reading what
-- the storage held, and a value has no such thing.  The type is a store's
-- rather than the allocated one: the allocation is a @union@ or a struct whose
-- size nothing here knows, and what the stores agree on is a scalar whose width
-- is its own.
heldType :: Maybe Endianness -> Type -> [Access] -> Maybe Type
heldType order allocated as
  | all ((== allocated) . accessType) as = Just allocated
  | otherwise = do
      width <- widest [t | Stored t <- as]
      held <- listToMaybe [t | Stored t <- as, scalarBits t == Just width]
      guard (all (fits width) [t | Stored t <- as])
      guard (all (isJust . reinterpretation order held) [t | Loaded t <- as])
      -- A store of all of them needs no byte order; one of some of them takes
      -- the ones the order puts first, which is 'inserting''s mask and the
      -- same little endian assumption 'reinterpretation' makes the other way.
      guard (all ((== Just width) . scalarBits) [t | Stored t <- as] || order == Just LittleEndian)
      pure held
  where
    widest ts = case [n | Just n <- map scalarBits ts] of
      [] -> Nothing
      ns | length ns == length ts -> Just (maximum ns)
      _ -> Nothing

    fits width t = maybe False (<= width) (scalarBits t)

-- | The slots an instruction reaches by nothing but their address, and what
-- each access does to the one it reaches.
--
-- The pointer operand of a plain load or store, when it is a local, and
-- nothing in any other position of any other instruction.  A load assigning
-- to nothing is not one of these: the rewrite has no name to give what it
-- read, so the load has to stay, and a slot it reads has to stay a slot.
--
-- __And both ends of a byte copy that covers a slot exactly.__  A @memcpy@ is
-- a call, and a call naming an address is what stops a slot being promoted at
-- all; but one that moves exactly the bytes a slot holds reads or writes the
-- whole of it and nothing else, which is what a load or a store of the slot
-- does.  So it is counted as one, at an integer of the width it moved — the
-- copy says nothing about what the bytes mean, and an integer is the type that
-- says the same.
reaching :: Maybe Layout -> (Local -> Maybe Type) -> Instruction -> [(Local, Access)]
reaching layout holding i = case instructionOperation i of
  OLoad l
    | not (loadVolatile l)
    , Just _ <- instructionResult i ->
        [(n, Loaded (loadType l)) | n <- pointer (loadPointer l)]
  OStore s
    | not (storeVolatile s) ->
        [(n, Stored (typedValueType (storeValue s))) | n <- pointer (storePointer s)]
  operation
    | Just c <- wholeCopy layout holding operation ->
        [(n, Stored (TInteger (copyBits c))) | n <- covered (copyInto c)]
          <> [(n, Loaded (TInteger (copyBits c))) | n <- covered (copyFrom c)]
  _ -> []
  where
    pointer (TypedValue _ (VLocal n)) = [n]
    pointer _ = []

    -- Only the ends that are slots of this function: the other end is a
    -- pointer like any other, and what it points at is nobody's business
    -- here.
    covered end = [n | n <- pointer end, isJust (holding n)]

-- | A byte copy that moves exactly what a slot holds, at whichever end names
-- one.
data Copy = Copy
  { copyInto :: TypedValue Local
  , copyFrom :: TypedValue Local
  , -- | How wide the integer that says what moved is.
    copyBits :: Natural
  , copyIntoAlign :: Natural
  , copyFromAlign :: Natural
  }

-- | Whether an operation is such a copy.
--
-- __The count has to cover a slot exactly.__  Fewer bytes than the slot holds
-- is a write to part of it, which is not something an assignment can say, and
-- more is a write past its end.  So the count is measured against what the
-- slot was allocated as, which is the one question this asks
-- "Olivine.Core.Layout" — a module with no layout string promotes everything
-- else exactly as before and declines these.
--
-- __And be a width a target has.__  One, two, four or eight bytes, which is
-- where @opt -passes=instcombine@ draws the same line when it turns a small
-- copy into a load and a store.  A copy of three bytes could be said as an
-- @i24@ and a copy of a kilobyte as an @i8192@; neither is a value a machine
-- moves, and the point of this is to stop moving bytes.
--
-- The two ends must be different slots, or the same slot would be counted both
-- ways and the escape accounting, which works by subtraction, would lose one
-- of the two mentions.  A copy from a slot to itself is undefined anyway: the
-- promise @memcpy@ makes is that the two do not overlap.
--
-- What the alignments say is what each end promised, and a copy promises
-- nothing beyond @align 1@ unless the argument says otherwise.  The load and
-- the store that replace it therefore say what it said, rather than leaving
-- the alignment out and claiming the type's own.
wholeCopy :: Maybe Layout -> (Local -> Maybe Type) -> Operation (TypedValue Local) -> Maybe Copy
wholeCopy layout holding operation = do
  OCall call <- Just operation
  VGlobal name <- Just (typedValue (callCallee call))
  guard (nameText name == "llvm.memcpy" || T.isPrefixOf "llvm.memcpy." (nameText name))
  [into, from, size, plain] <- Just (callArguments call)
  VInteger bytes <- Just (typedValue (argumentValue size))
  guard (typedValue (argumentValue plain) == VBoolean False)
  guard (bytes `elem` [1, 2, 4, 8])
  guard (any (covers (fromIntegral bytes)) [argumentValue into, argumentValue from])
  guard (distinct (argumentValue into) (argumentValue from))
  pure
    Copy
      { copyInto = argumentValue into
      , copyFrom = argumentValue from
      , copyBits = 8 * fromIntegral bytes
      , copyIntoAlign = promised into
      , copyFromAlign = promised from
      }
  where
    covers bytes (TypedValue _ (VLocal n)) =
      Just bytes == ((\known -> allocSize known =<< holding n) =<< layout)
    covers _ _ = False

    distinct (TypedValue _ (VLocal a)) (TypedValue _ (VLocal b)) = a /= b
    distinct _ _ = True

    promised argument =
      maximum (1 : [n | PAAlign n <- argumentAttributes argument])

-- | The pointer a step of zero steps from, which is the address the step
-- names.
--
-- @getelementptr T, ptr %p, i64 0@ is @%p@ whatever @T@ is, and field zero of
-- a struct begins where the struct begins whether or not it is packed.  Both
-- are true without knowing any type's size, which is why they are here and why
-- no other step is.  "Olivine.Core.Layout" would now say where field one
-- begins, but a step to it is a step to part of the slot, and part of a local
-- is not something an assignment can name: what this pass would need in order
-- to take one is to hold the slot as its bits and write each access into its
-- own, which is a larger change than knowing the offset.
--
-- A front end writes a step of zero wherever a program names the first element
-- of an array or the first member of a union, and until this was here the slot
-- behind one could not be promoted at all: @u.b[0]@ read the storage by an
-- address the pass could not tell from any other.
steppingFrom :: Operation (TypedValue Local) -> [Local]
steppingFrom operation = case operation of
  OOffset o | TypedValue _ (VInteger 0) <- offsetIndex o -> pointer (offsetPointer o)
  OField x | fieldIndex x == 0 -> pointer (fieldPointer x)
  _ -> []
  where
    pointer (TypedValue _ (VLocal n)) = [n]
    pointer _ = []

-- | What each of a function's allocations was allocated as.
allocatedIn :: Function -> Map Local Type
allocatedIn f =
  Map.fromList
    [ (slot, allocaType a)
    | b <- functionBlocks f
    , Instruction (Just slot) (OAlloca a) _ <- blockInstructions b
    ]

-- | Which local each local that is a step of zero names the address of.
--
-- Only where the stepping local is assigned once, since otherwise what it
-- names depends on how it was reached, and this map answers without asking
-- where.
zeroSteps :: Function -> Map Local Local
zeroSteps f =
  Map.fromList
    [ (result, from)
    | Instruction (Just result) operation _ <- instructions
    , Map.findWithDefault (0 :: Int) result definitions == 1
    , from <- steppingFrom operation
    ]
  where
    instructions = [i | b <- functionBlocks f, i <- blockInstructions b]

    definitions =
      Map.fromListWith (+) [(result, 1) | Just result <- map instructionResult instructions]

-- | What a local finally names, following the steps of zero.
--
-- Bounded by how many there are rather than run to the end, since two steps
-- may name each other — a chain that long has been round a cycle, which
-- nothing a program means can contain and which this must not hang on.
rootOf :: Map Local Local -> Local -> Local
rootOf steps = walk (Map.size steps)
  where
    walk :: Int -> Local -> Local
    walk 0 local = local
    walk fuel local = maybe local (walk (fuel - 1)) (Map.lookup local steps)
