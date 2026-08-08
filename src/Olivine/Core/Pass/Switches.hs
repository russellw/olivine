-- | Turning a switch into arithmetic.
--
-- A @switch@ whose every case does nothing but leave a constant somewhere is
-- not a decision about where to go: it is a function from the value switched
-- on to a number, written as control flow because C has no other way to write
-- it.  Where the case values are consecutive and the constants they leave run
-- in step with them, that function is @a * (v - lo) + b@ guarded by a range
-- test, and the whole of the jump table goes away.
--
-- This is what clang does with the same shape, and it is worth stating what
-- it costs to leave undone: a dense switch that a back end turns into a jump
-- table is an indirect branch off a table in memory, against three or four
-- arithmetic instructions and no branch at all.
--
-- __It is the same reading "Olivine.Core.Pass.IfConversion" does, of a
-- terminator with more than two ways on.__  A side is a block reached only
-- from the switch that goes on to a join every other side also goes to; what
-- the switch decides is the local those sides assign; and the block that ends
-- in the switch is where the answer is computed instead.  What is different is
-- the answer: if-conversion picks between two values with a @select@, and a
-- chain of selects one per case is exactly what makes a switch not worth
-- converting that way.  Here there is one select, because the cases have been
-- read as a formula rather than as a list.
--
-- __What the sides may hold is assignments and nothing else.__  The point is
-- that every case leaves a constant, so an instruction on a side is a case
-- that does something, and this declines it rather than speculating it —
-- there is no budget here for the same reason there is no @select@ per case:
-- what is emitted does not depend on how many cases there are, so nothing
-- accumulates to be budgeted.  Assignments are resolved through each other
-- while the side is read, since promotion leaves @%t := 3@ and @r := %t@
-- rather than the one line the source wrote.
--
-- __A destination may be the join itself.__  Control flow simplification has
-- already taken away the block on a case that only branched onward, so a case
-- that leaves the value the block above it already left arrives as an edge
-- straight to the join.  What it contributes is then what the head block
-- leaves in the local, which has to be a constant like every other case.
-- That is not a corner: it is the first case of every switch clang writes
-- this way, the front end having assigned the default value before the
-- switch.
--
-- __Two formulas, and the third is not here.__  All the cases leaving one
-- constant is @select inRange, c, d@ and needs no arithmetic at all.  The
-- constants running in step is @a * (v - lo) + b@.  Anything else — the
-- constants in no order, which is the common case for a table of weights — is
-- what LLVM builds a lookup table in memory for, and building one means
-- putting a global into the module, which no pass here does.  It is declined
-- and it is the obvious next thing.
--
-- __Why the arithmetic is safe to write wrapped.__  The formula is checked
-- against the constants as exact integers, so the identity @c_j = a * j + b@
-- holds in the integers and therefore holds modulo two to the width; no flag
-- is written on the @mul@ or the @add@ because none is needed and one would
-- be a promise about values outside the range the select throws away.  The
-- range test is @(v - lo) \<u n@, which is exactly membership of the case
-- values as bit patterns however they wrap.
--
-- __It runs where if-conversion runs and for the same reason.__  The sides
-- have to be the real ones, so the graph must have been straightened first;
-- and what it leaves is a head that branches to a join it may now be the only
-- way to, which 'Olivine.Core.Blocks.mergeBlocks' puts together here rather
-- than being a reason to run a whole pass again.  Folding stands above it, so
-- the arithmetic it writes with a step of one or a base of zero is settled on
-- the round after — which is the pipeline iterating, not this pass's
-- business.
module Olivine.Core.Pass.Switches
  ( foldSwitches
  , caseFloor
  ) where

import Data.List (sortOn)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (listToMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Blocks (mergeBlocks, predecessorsOf)
import Olivine.Core.Instruction
import Olivine.Core.Pass.Fold (integerOf, valueOf, widthOf)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Compare (..), IntPredicate (..), Select (..))
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

-- | How few cases are not worth reading as a formula.
--
-- Two cases and a default are three comparisons at worst and a branch on
-- each, which is what the arithmetic costs anyway; the win is in the switch a
-- back end would have built a table for.  A first number rather than a
-- measured one, like 'Olivine.Core.Pass.IfConversion.armBudget': what would
-- make it measured is a model of what a jump table costs against a
-- mispredicted branch, and nothing here reads one.
caseFloor :: Int
caseFloor = 3

-- | A switch that is a formula: where it stands, what it switches on, the
-- blocks that go when it does, where they all arrive, and what it leaves
-- behind.
data Table = Table
  { tableHead :: Label
  , -- | What is switched on, and so what the range test and the formula read.
    tableValue :: TypedValue Local
  , tableSides :: [Label]
  , tableJoin :: Label
  , -- | The local every case decides, and the type it holds it at.
    tableDecided :: Local
  , tableType :: Type
  , -- | The lowest case value, which the index is counted from.
    tableFloor :: Integer
  , -- | How many cases there are, which is the range the index must be in.
    tableCount :: Integer
  , -- | What the cases come to, read once where the table is.
    tableFormula :: Formula
  , -- | What is left when no case matches.
    tableDefault :: Integer
  }

foldSwitches :: Program -> Program
foldSwitches program =
  program {programEntries = map entry (programEntries program)}
  where
    entry (EFunction f) = EFunction (settle (length (functionBlocks f)) f)
    entry retained = retained

-- | Fold one switch, then look again.
--
-- One at a time for the reason if-conversion is: what the last one left is
-- the graph the next question is asked of.
settle :: Int -> Function -> Function
settle remaining f
  | remaining <= 0 = f
  | otherwise = case foldable f of
      [] -> f
      table : _ -> settle (remaining - 1) (mergeBlocks (rewrite f table))

-- | The switches that are formulas, in the order the blocks are written.
foldable :: Function -> [Table]
foldable f =
  [ table
  | h <- functionBlocks f
  , Switch value target cases <- [terminatorTransfer (blockTerminator h)]
  , Just table <- [readTable f h value target cases]
  ]

-- | Read a switch as a formula, or decline it.
readTable ::
  Function ->
  Block ->
  TypedValue Local ->
  Label ->
  [(TypedValue Local, Label)] ->
  Maybe Table
readTable f h value target cases = do
  width <- widthOf (typedValueType value)
  -- The values are read before anything else about the blocks, since a case
  -- on something that is not a constant integer settles the question by
  -- itself.
  written <- traverse (\(c, label) -> (,) <$> constant c <*> pure label) cases
  let sorted = sortOn fst written
      values = map fst sorted
      lo = minimum values
  -- Consecutive, and few enough that the count is a number of this width.
  guardOn (length sorted >= caseFloor)
  guardOn (values == take (length values) [lo ..])
  guardOn (toInteger (length values) < 2 ^ width)

  -- Where each destination arrives, and what stands on the way.
  let (fallback, whereDefaultArrives) = sideOf f h target
      arrivals = map (sideOf f h . snd) sorted
  join <- theSame (whereDefaultArrives : map snd arrivals)
  guardOn (join /= blockLabel h)

  -- What the sides decide between them, which has to be one local: two would
  -- be two formulas and two selects, and the case where that is worth having
  -- is the case where a lookup table is.
  let sides = [side | Just side <- fallback : map fst arrivals]
  guardOn (not (null sides))
  (decided, t) <- only (Map.toList (Map.fromList (concatMap (escapingIn f) sides)))

  -- What each case leaves in it.  The head block's own assignments are the
  -- starting point, since a case with no block of its own leaves exactly
  -- them.
  let above = heldBy (blockInstructions h) Map.empty
  leftByDefault <- resolve t decided above fallback
  results <- traverse (resolve t decided above . fst) arrivals
  shape <- formula (typedValueType value) t results
  pure
    Table
      { tableHead = blockLabel h
      , tableValue = value
      , tableSides = map blockLabel sides
      , tableJoin = join
      , tableDecided = decided
      , tableType = t
      , tableFloor = lo
      , tableCount = toInteger (length values)
      , tableFormula = shape
      , tableDefault = leftByDefault
      }
  where
    constant c = integerOf (typedValueType c) (typedValue c)

    -- The destinations all arrive at one block, or this is not a diamond with
    -- more than two sides and there is nothing to fold into.
    theSame (x : rest) | all (== x) rest = Just x
    theSame _ = Nothing

    only [x] = Just x
    only _ = Nothing

-- | What one destination of the switch holds, and where it arrives.
--
-- A block reached only from the switch that holds nothing but assignments and
-- goes on to a single place is a side; anything else the switch names is the
-- place itself, arrived at with nothing done on the way.  The same reading
-- 'Olivine.Core.Pass.IfConversion.sideOf' does, with the assignments in place
-- of a budget.
sideOf :: Function -> Block -> Label -> (Maybe Block, Label)
sideOf f h target = case armAt f h target of
  Just (side, join) -> (Just side, join)
  Nothing -> (Nothing, target)

armAt :: Function -> Block -> Label -> Maybe (Block, Label)
armAt f h target =
  listToMaybe
    [ (side, join)
    | side <- [b | b <- functionBlocks f, blockLabel b == target]
    , -- A function starts where its first block is, and a side stops
      -- existing; a block whose address is taken is reached by ways no branch
      -- here names.
      Just target /= entryLabel f
    , not (Set.member target (pinnedIn f))
    , predecessorsOf (functionBlocks f) target == [blockLabel h]
    , all (isAssignment . instructionOperation) (blockInstructions side)
    , Br join <- [terminatorTransfer (blockTerminator side)]
    ]

isAssignment :: Operation operand -> Bool
isAssignment (OAssign _) = True
isAssignment _ = False

-- | Which locals a side assigns that anything outside it reads, and the type
-- each is assigned at.
--
-- 'Olivine.Core.Pass.IfConversion.escapingIn' asks the same question and has
-- to look the type up, because what a side leaves there may be any operation.
-- Here a side holds assignments only, so the type is written on the operand.
escapingIn :: Function -> Block -> [(Local, Type)]
escapingIn f side =
  [ (result, typedValueType operand)
  | Instruction (Just result) (OAssign operand) _ <- blockInstructions side
  , Set.member result outside
  ]
  where
    outside = readBy (/= blockLabel side) f

-- | Every local read by the blocks the predicate accepts, terminators
-- included.
readBy :: (Label -> Bool) -> Function -> Set Local
readBy included f =
  Set.fromList
    [ local
    | b <- functionBlocks f
    , included (blockLabel b)
    , local <-
        concatMap (localsUsedBy . instructionOperation) (blockInstructions b)
          <> localsUsedBy (terminatorTransfer (blockTerminator b))
    ]

-- | What a block's assignments leave in each local it assigns.
--
-- Resolved through each other as the block is walked, since what promotion
-- leaves is a chain of them rather than the one the source wrote.  An
-- instruction that is not an assignment leaves something this cannot read, so
-- what it names stops being known.
heldBy ::
  [Instruction] ->
  Map Local (TypedValue Local) ->
  Map Local (TypedValue Local)
heldBy instructions start = foldl step start instructions
  where
    step held i = case (instructionResult i, instructionOperation i) of
      (Just result, OAssign operand) -> Map.insert result (through held operand) held
      (Just result, _) -> Map.delete result held
      (Nothing, _) -> held
    through held operand = case operand of
      TypedValue _ (VLocal local) | Just known <- Map.lookup local held -> known
      _ -> operand

-- | The number one case leaves in the decided local.
--
-- The side's assignments are read on top of the head block's, so a side that
-- does not assign the local leaves what the head block did — which is what a
-- case with no block of its own leaves, and why a missing side is spelled
-- 'Nothing' rather than being a case of its own here.
resolve ::
  Type ->
  Local ->
  Map Local (TypedValue Local) ->
  Maybe Block ->
  Maybe Integer
resolve t decided above side = do
  operand <- Map.lookup decided held
  guardOn (typedValueType operand == t)
  integerOf t (typedValue operand)
  where
    held = maybe above (\b -> heldBy (blockInstructions b) above) side

-- | Put the formula where the switch stood, and take the sides away.
rewrite :: Function -> Table -> Function
rewrite f table =
  f
    { functionBlocks =
        [ replace b
        | b <- functionBlocks f
        , blockLabel b `notElem` tableSides table
        ]
    }
  where
    replace b
      | blockLabel b == tableHead table =
          b
            { blockInstructions = blockInstructions b <> written
            , blockTerminator =
                (blockTerminator b) {terminatorTransfer = Br (tableJoin table)}
            }
      | otherwise = b

    t = tableType table
    switched = typedValueType (tableValue table)
    lo = tableFloor table
    count = tableCount table

    Local next = nextLocal f

    -- The index into the cases, which both the range test and the formula
    -- read.  Where the cases start at zero the value is the index already.
    (index, offsetting)
      | lo == 0 = (tableValue table, [])
      | otherwise =
          ( TypedValue switched (VLocal (Local next))
          , [ assigning
                (Local next)
                Syntax.OpSub
                (tableValue table)
                (TypedValue switched (valueOf switched lo))
            ]
          )

    inRange =
      Instruction
        (Just (Local (next + 1)))
        ( OICmp
            Compare
              { compareFlags = []
              , comparePredicate = IUlt
              , compareLeft = index
              , compareRight = TypedValue switched (valueOf switched count)
              }
        )
        []

    -- What the cases come to, as an operand: one constant where they all
    -- leave the same number, and the linear map otherwise.  A run that is
    -- neither is not a table this pass built.
    (chosen, computing) = case tableFormula table of
      Same c -> (TypedValue t (valueOf t c), [])
      Step base step ->
        ( TypedValue t (VLocal (Local (next + 3)))
        , [ assigning (Local (next + 2)) Syntax.OpMul index (TypedValue t (valueOf t step))
          , assigning
              (Local (next + 3))
              Syntax.OpAdd
              (TypedValue t (VLocal (Local (next + 2))))
              (TypedValue t (valueOf t base))
          ]
        )

    picked =
      Instruction
        (Just (Local (next + 4)))
        ( OSelect
            Select
              { selectFlags = []
              , selectCondition = TypedValue (TInteger 1) (VLocal (Local (next + 1)))
              , selectTrue = chosen
              , selectFalse = TypedValue t (valueOf t (tableDefault table))
              }
        )
        []

    -- The select writes a name of its own and an assignment carries it into
    -- the local the rest of the function reads, for the reason if-conversion
    -- does the same: a local an instruction writes and an assignment
    -- elsewhere also writes is one reconstruction has no phi to put back for.
    writeBack =
      Instruction
        (Just (tableDecided table))
        (OAssign (TypedValue t (VLocal (Local (next + 4)))))
        []

    written = offsetting <> [inRange] <> computing <> [picked, writeBack]

    assigning result op left right =
      Instruction
        (Just result)
        ( OBinary
            Syntax.Binary
              { Syntax.binaryOp = op
              , Syntax.binaryFlags = []
              , Syntax.binaryLeft = left
              , Syntax.binaryRight = right
              }
        )
        []

-- | What a run of case results comes to.
--
-- There is no third constructor for the run that is neither, and that is the
-- point: a table this cannot read is one 'formula' declines, so nothing
-- downstream has to have an answer for it.  What is missing is the lookup
-- table LLVM builds — a global holding the results, indexed by the same
-- index this computes with — and building one means putting a symbol into the
-- module, which no pass here does.
data Formula
  = -- | Every case leaves the same number.
    Same Integer
  | -- | The @j@th case leaves @base + j * step@.
    Step Integer Integer

-- | Read a run of results as a formula, or decline it.
--
-- The identity is checked in the integers, which is what licenses writing the
-- arithmetic wrapped and without flags: what holds exactly holds modulo the
-- width.  A step is only offered where the formula is computed at the width
-- the switch is on, since the index is a value of that type and converting it
-- would cost the instruction the formula saves.
formula :: Type -> Type -> [Integer] -> Maybe Formula
formula switched t results = case results of
  [] -> Nothing
  first : rest
    | all (== first) rest -> Just (Same first)
    | switched /= t -> Nothing
    | second : _ <- rest
    , let step = second - first
    , and [c == first + toInteger j * step | (j, c) <- zip [0 :: Int ..] results] ->
        Just (Step first step)
    | otherwise -> Nothing

guardOn :: Bool -> Maybe ()
guardOn True = Just ()
guardOn False = Nothing
