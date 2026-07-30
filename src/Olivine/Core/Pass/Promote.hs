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
-- What it still declines is a store narrower than the slot's widest, which is
-- not an assignment to the local but an assignment to some of its bits — read,
-- mask, or, and write back.  That is expressible and is not obviously worth
-- it: it turns one instruction into three, and buys the surrounding stores and
-- loads only where the slot becomes promotable because of it.
module Olivine.Core.Pass.Promote
  ( promoteMemory
  , promotableIn
  ) where

import Control.Monad (guard)
import Data.List (delete, mapAccumL)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust, listToMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Instruction
import Olivine.Core.Layout (Endianness (..), endiannessOf, scalarBits)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Alloca (..), Convert (..), Load (..), Store (..))
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

    entry (EFunction f) = EFunction (promoteIn order f)
    entry retained = retained

promoteIn :: Maybe Endianness -> Function -> Function
promoteIn order f
  | Map.null promoted = f
  | otherwise = f {functionBlocks = snd (mapAccumL block next (functionBlocks f))}
  where
    promoted = promotableIn order f

    -- Where the names the conversions assign to start.  A conversion cannot
    -- write to the local the load named, since that local is what the rest of
    -- the function reads and a local an instruction writes is a local nothing
    -- else may write; so it writes a name of its own and an assignment carries
    -- it over, as "Olivine.Core.Pass.IfConversion" does with a select.
    Local next = nextLocal f

    block n b =
      let (n', made) = mapAccumL instruction n (blockInstructions b)
       in (n', b {blockInstructions = concat made})

    -- The three shapes an access to a promoted slot takes, and nothing else
    -- can be one: the accesses are what 'promotableIn' enumerated to decide
    -- the slot was promotable, so a use of one reached here is a load, a
    -- store, or the allocation itself.
    instruction n i = case instructionOperation i of
      OAlloca _
        | Just slot <- instructionResult i
        , Just t <- Map.lookup slot promoted ->
            (n, [assigning slot (TypedValue t VPoison)])
      OStore s
        | Just slot <- slotOf (storePointer s)
        , Just t <- Map.lookup slot promoted ->
            reinterpreting n (storeValue s) t (assigning slot)
      OLoad l
        | Just slot <- slotOf (loadPointer l)
        , Just t <- Map.lookup slot promoted
        , Just result <- instructionResult i ->
            reinterpreting n (TypedValue t (VLocal slot)) (loadType l) (assigning result)
      _ -> (n, [i])
      where
        -- The metadata stays with the instruction it was attached to, as it
        -- does when folding replaces an operation.  A store's result was
        -- nothing and is now the slot, which is the one part of the record
        -- this has to set as well as the operation.
        assigning name value =
          i {instructionResult = Just name, instructionOperation = OAssign value}

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

    slotOf (TypedValue _ (VLocal n)) | Map.member n promoted = Just n
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
--   writes.  Anything else — passed to a call, returned, offset into,
--   compared, stored somewhere — is the address escaping to code that could
--   reach the storage by other means than the accesses counted here.  A
--   volatile access counts as an escape too, since the point of one is that it
--   happens, and an assignment does not happen anywhere.
--
-- * The accesses agree on what the slot holds, which 'heldType' decides: they
--   are all at the allocated type, or they are all at types a value can be
--   converted between, with every store at the widest of them.  Storing an
--   @i8@ into an @i32@ slot writes part of it, and part of a local is not
--   something an assignment can name.
promotableIn :: Maybe Endianness -> Function -> Map Local Type
promotableIn order f =
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

    single a =
      not (allocaInalloca a) && case allocaElementCount a of
        Nothing -> True
        Just (TypedValue _ (VInteger 1)) -> True
        Just _ -> False

    definitions :: Map Local Int
    definitions =
      Map.fromListWith (+) [(slot, 1) | Just slot <- map instructionResult instructions]

    -- Every local read anywhere other than as an address loaded from or
    -- stored to.  A terminator reads no address in that sense, so everything
    -- it names is here.
    escaping :: Set Local
    escaping =
      Set.fromList
        ( concatMap escapingFrom instructions
            <> [ local
               | b <- functionBlocks f
               , local <- localsUsedBy (terminatorTransfer (blockTerminator b))
               ]
        )

    -- Written as a difference rather than by case, so that a slot appearing
    -- twice in one instruction is counted twice: @store ptr %a, ptr %a@ puts
    -- a slot's own address in it, and the value operand is an escape although
    -- the pointer operand is not.
    escapingFrom i =
      foldr delete (localsUsedBy (instructionOperation i)) (addressedBy i)

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
        [ (slot, [access])
        | i <- instructions
        , slot <- addressedBy i
        , access <- accessOf (instructionOperation i)
        ]

    accessOf operation = case operation of
      OLoad l -> [Loaded (loadType l)]
      OStore s -> [Stored (typedValueType (storeValue s))]
      _ -> []

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
-- Otherwise the local holds what the stores put there, which the loads then
-- read some or all of.  That needs every store at one width — a narrower one
-- would leave the bits it did not write, which an assignment cannot do — and
-- every load at a type 'reinterpretation' can reach from it.  The type is the
-- first store's rather than the allocated one: the allocation is a @union@ or
-- a struct whose size nothing here knows, and what the stores agree on is a
-- scalar whose width is its own.
heldType :: Maybe Endianness -> Type -> [Access] -> Maybe Type
heldType order allocated as
  | all ((== allocated) . accessType) as = Just allocated
  | otherwise = do
      held <- listToMaybe [t | Stored t <- as]
      width <- scalarBits held
      guard (all ((== Just width) . scalarBits) [t | Stored t <- as])
      guard (all (isJust . reinterpretation order held) [t | Loaded t <- as])
      pure held

-- | The slot an instruction reaches by nothing but its address.
--
-- The pointer operand of a plain load or store, when it is a local, and
-- nothing in any other position of any other instruction.  A load assigning
-- to nothing is not one of these: the rewrite has no name to give what it
-- read, so the load has to stay, and a slot it reads has to stay a slot.
addressedBy :: Instruction -> [Local]
addressedBy i = case instructionOperation i of
  OLoad l
    | not (loadVolatile l)
    , Just _ <- instructionResult i ->
        pointer (loadPointer l)
  OStore s | not (storeVolatile s) -> pointer (storePointer s)
  _ -> []
  where
    pointer (TypedValue _ (VLocal n)) = [n]
    pointer _ = []
