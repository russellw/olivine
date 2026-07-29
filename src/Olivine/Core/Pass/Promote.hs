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
module Olivine.Core.Pass.Promote
  ( promoteMemory
  , promotableIn
  ) where

import Data.List (delete)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Alloca (..), Load (..), Store (..))
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value

promoteMemory :: Program -> Program
promoteMemory program =
  program {programEntries = map entry (programEntries program)}
  where
    entry (EFunction f) = EFunction (promoteIn f)
    entry retained = retained

promoteIn :: Function -> Function
promoteIn f
  | Map.null promoted = f
  | otherwise = f {functionBlocks = map rewrite (functionBlocks f)}
  where
    promoted = promotableIn f

    rewrite b = b {blockInstructions = map instruction (blockInstructions b)}

    -- The three shapes an access to a promoted slot takes, and nothing else
    -- can be one: the accesses are what 'promotableIn' enumerated to decide
    -- the slot was promotable, so a use of one reached here is a load, a
    -- store, or the allocation itself.
    instruction i = case instructionOperation i of
      OAlloca _
        | Just slot <- instructionResult i
        , Just t <- Map.lookup slot promoted ->
            assigning slot (TypedValue t VPoison)
      OStore s
        | Just slot <- slotOf (storePointer s) ->
            assigning slot (storeValue s)
      OLoad l
        | Just slot <- slotOf (loadPointer l)
        , Just result <- instructionResult i ->
            assigning result (TypedValue (loadType l) (VLocal slot))
      _ -> i
      where
        -- The metadata stays with the instruction it was attached to, as it
        -- does when folding replaces an operation.  A store's result was
        -- nothing and is now the slot, which is the one part of the record
        -- this has to set as well as the operation.
        assigning name value =
          i {instructionResult = Just name, instructionOperation = OAssign value}

    slotOf (TypedValue _ (VLocal n)) | Map.member n promoted = Just n
    slotOf _ = Nothing

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
-- * Every one of those accesses is at the allocated type.  Storing an @i8@
--   into an @i32@ slot writes part of it, and part of a local is not something
--   an assignment can name.
promotableIn :: Function -> Map Local Type
promotableIn f =
  Map.fromList
    [ (slot, allocaType a)
    | Instruction (Just slot) (OAlloca a) _ <- instructions
    , single a
    , Map.findWithDefault 0 slot definitions == 1
    , slot `notElem` functionParameters f
    , not (Set.member slot escaping)
    , all (== allocaType a) (Map.findWithDefault [] slot accesses)
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

    -- The types each slot is accessed at.  Gathered in one walk keyed by slot
    -- rather than looked up per candidate, since a function with many slots
    -- would otherwise walk itself once for each of them.
    --
    -- Only the accesses that count as accesses are here: a volatile one names
    -- no slot in 'addressedBy', having already put its pointer among the
    -- escaping.
    accesses :: Map Local [Type]
    accesses =
      Map.fromListWith
        (<>)
        [ (slot, [t])
        | i <- instructions
        , slot <- addressedBy i
        , t <- accessType (instructionOperation i)
        ]

    accessType operation = case operation of
      OLoad l -> [loadType l]
      OStore s -> [typedValueType (storeValue s)]
      _ -> []

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
