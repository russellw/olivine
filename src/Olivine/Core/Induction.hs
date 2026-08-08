-- | How many times a loop goes round, where the loop's own arithmetic says.
--
-- __The count is found by running the counter, not by solving for it.__  The
-- usual way to answer this is a closed form: recognize an induction variable,
-- read a start, a step and a bound off it, and divide.  That wants a theory of
-- its own — which recurrences are recognized, what the closed form is for each,
-- what overflow does to it, whether the comparison is signed — and every line
-- of that theory is a line that can disagree with what the optimizer's own
-- arithmetic says an instruction comes to.  Here the block is interpreted
-- instead: hold the locals whose values are known, evaluate what can be
-- evaluated, ask the terminator whether control goes round again, and count.
--
-- What that buys is that there is exactly one implementation of LLVM's
-- arithmetic in Olivine and this is not it.  'foldOperation' is the evaluator,
-- so an @add nsw@ that overflows answers here the way it answers everywhere —
-- with no value at all, which stops the count rather than inventing one — and
-- a signed comparison is signed here because it is signed there.  A recurrence
-- nobody wrote a rule for, @i := i * 3 - 1@, costs no rule.
--
-- What it costs is that the answer is only ever a small number.  Interpreting
-- is one step per turn, so a loop of a thousand turns takes a thousand steps to
-- count and a loop of @n@ turns cannot be counted at all.  That is the right
-- trade for what asks: a count is wanted in order to write the turns out, and
-- nothing writes out a thousand of them.  A caller says how far it is prepared
-- to look and gets nothing if the loop goes further.
--
-- __A turn carries what is known at the top of it__, not just its number.  The
-- interpreter has the values in hand anyway, and they are what makes unrolling
-- worth doing: a copy of a body whose counter is still computed from the last
-- turn's is a copy of the same work, and the same copy with @i@ known to be 2
-- is three quarters of an address calculation that folding can settle.
--
-- __Counting a loop and having a counter are different questions__, and the
-- second is answered by 'countersOf' rather than by running anything.  A loop
-- whose bound is a parameter goes round a number of times nothing here will
-- ever know, and it still has a counter — a local that is a fixed amount larger
-- every turn than it was the turn before.  That is what a pass wants when it
-- rewrites the work in a loop rather than the loop itself, and it is available
-- for the loops that matter, which are the ones that are not countable.
module Olivine.Core.Induction
  ( Turn (..)
  , turnsOf
  , Counter (..)
  , countersOf
  , enteringValues
  , Producing
  , producedAt
  , originAt
  ) where

import Control.Monad (guard)
import Data.List (find)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Olivine.Core.Instruction
import Olivine.Core.Loops (Loop (..))
import Olivine.Core.Pass.Fold (foldOperation)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Binary (..), BinaryOp (..), InstructionFlag (..))
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value

-- | One turn of a loop, and what holds at the top of it.
--
-- Only the locals the interpreter could settle are here, and only those a
-- reader has any use for — a local the loop never assigns holds the same thing
-- on every turn and saying so once per turn says nothing.
newtype Turn = Turn
  { turnKnown :: Map Local (Value Local)
  }
  deriving (Eq, Show)

-- | The turns a loop makes, when the loop's own arithmetic settles how many.
--
-- 'Nothing' where it does not, which is most loops: a bound that is a
-- parameter, a counter whose start is not known where the loop is entered, a
-- test that reads memory, or more turns than the caller asked to look at.
--
-- __The loop has to be one block.__  Then a turn is that block run once, and
-- the interpreter is a fold over its instructions.  A loop of several blocks
-- would want the paths through it interpreted too, and the shape this is for —
-- a small counted loop after rotation and block merging — is one block by the
-- time anything asks.
--
-- What is known at the top of the first turn comes from the blocks the loop is
-- entered from, each interpreted from nothing known.  That is weak on purpose:
-- a value those blocks do not themselves compute is not known here, and not
-- knowing is what makes this decline rather than answer wrongly.  Where the
-- loop is entered from more than one block, only what they agree on is known.
turnsOf :: Int -> Function -> Loop -> Maybe [Turn]
turnsOf limit f loop = do
  guard (Set.size (loopBody loop) == 1)
  body <- find ((== header) . blockLabel) (functionBlocks f)
  CondBr condition takenIf takenElse <- Just (terminatorTransfer (blockTerminator body))
  -- One of the two ways out goes round again and the other leaves.  A block
  -- branching to itself both ways is a loop nothing leaves, and one branching
  -- to itself neither way is not the block this loop closes at.
  again <- case (takenIf == header, takenElse == header) of
    (True, False) -> Just True
    (False, True) -> Just False
    _ -> Nothing
  turn (written body) condition again 0 (enteringValues f loop)
  where
    header = loopHeader loop

    -- One turn: what is known at the top of it, then the block run over that,
    -- then the question the terminator asks.  A condition that cannot be
    -- settled is where this gives up, and it is where most loops give up.
    turn locals condition again n known
      | n >= limit = Nothing
      | otherwise = do
          body <- find ((== header) . blockLabel) (functionBlocks f)
          let after = interpret known (blockInstructions body)
              here = Turn (Map.restrictKeys known locals)
          VBoolean decided <- valueOf after condition
          if decided == again
            then (here :) <$> turn locals condition again (n + 1) after
            else Just [here]

    -- The locals the loop itself writes, which are the only ones whose value
    -- differs from one turn to the next and so the only ones worth saying.
    written body =
      Set.fromList [result | i <- blockInstructions body, Just result <- [instructionResult i]]

-- | What the locals are known to hold where the loop is entered.
--
-- Each block that branches into the loop is interpreted from nothing known,
-- and only what they all agree on is kept.  Starting from nothing is weak on
-- purpose: a value those blocks do not themselves compute is not known here,
-- and not knowing is what makes a reader decline rather than answer wrongly.
--
-- Two things want this and want it for opposite reasons.  Counting the turns
-- needs the counter's first value or there is nothing to count from.  A pass
-- that rewrites work in terms of the counter does not need it at all — it
-- computes what it starts from where the loop is entered — but writing the
-- value down where it is known saves the folding that would otherwise have to
-- find it, which it cannot, a constant assigned in one block and read in
-- another being exactly what block-local folding does not see.
enteringValues :: Function -> Loop -> Map Local (Value Local)
enteringValues f loop = case [interpret Map.empty (blockInstructions b) | b <- entering] of
  [] -> Map.empty
  first : rest -> foldl' agreeing first rest
  where
    header = loopHeader loop

    entering =
      [ b
      | b <- functionBlocks f
      , not (Set.member (blockLabel b) (loopBody loop))
      , header `elem` targetsOf (blockTerminator b)
      ]

    agreeing a b =
      Map.mapMaybeWithKey (\name v -> if Map.lookup name b == Just v then Just v else Nothing) a

-- | A local the loop makes a fixed amount larger every turn.
data Counter = Counter
  { counterLocal :: Local
  , -- | What it grows by, which the loop adds to it once a turn.
    counterStep :: Integer
  , -- | The type it is counted at.
    counterType :: Type
  , -- | Whether the loop promises the count does not overflow, which is the
    -- @nsw@ on the addition.  A reader that widens the counter needs it: a
    -- widening of a wrapped count is not the widened count plus a step.
    counterNoWrap :: Bool
  }
  deriving (Eq, Show)

-- | The counters of a loop.
--
-- A local qualifies when the loop's one block assigns it exactly once, by an
-- addition of a constant to what the local already held — read through the
-- copies, since after promotion the counter arrives at its own increment as a
-- copy of itself and leaves it as another.
--
-- __Nothing here says what it starts at__, and nothing needs to: a pass that
-- rewrites work in terms of a counter puts its own starting value where the
-- loop is entered, computing it from the counter as it stands there.  That is
-- what makes this answer for loops 'turnsOf' cannot answer for at all.
--
-- The single block is the same restriction 'turnsOf' makes and for a weaker
-- reason: with one block, "assigned once in the loop" and "assigned once on
-- every path round it" are the same statement, and the increment is reached
-- exactly once a turn.
countersOf :: Function -> Loop -> [Counter]
countersOf f loop
  | Set.size (loopBody loop) /= 1 = []
  | otherwise = case find ((== loopHeader loop) . blockLabel) (functionBlocks f) of
      Nothing -> []
      Just body ->
        [ counter
        | (i, known) <- producedAt (blockInstructions body)
        , Just name <- [instructionResult i]
        , writtenOnce body name
        , Just counter <- [stepOf known name (instructionOperation i)]
        ]
  where
    -- A local written twice in the block has no one step, and one written by
    -- something that is not an assignment is not reassigned at all: the core
    -- reassigns through assignments and nothing else.
    writtenOnce body name =
      length [() | i <- blockInstructions body, instructionResult i == Just name] == 1

    -- The assignment that closes the counter's turn, read back through the
    -- copies to the addition that made it, and that addition read for the local
    -- it adds to.  Both ends want reading: after promotion a counter arrives at
    -- its own increment as a copy of itself and leaves it as another.
    stepOf known name operation = do
      OAssign value <- Just operation
      VLocal from <- Just (typedValue value)
      OBinary b <- producing known from
      guard (binaryOp b == OpAdd)
      -- Either way round: @i + 1@ and @1 + i@ are one loop.
      step <- growing known name b
      pure
        Counter
          { counterLocal = name
          , counterStep = step
          , counterType = typedValueType (binaryLeft b)
          , counterNoWrap = FlagNSW `elem` binaryFlags b
          }

    growing known name b = case (holds known (binaryLeft b), typedValue (binaryRight b)) of
      (Just held, VInteger step) | held == name -> Just step
      _ -> case (typedValue (binaryLeft b), holds known (binaryRight b)) of
        (VInteger step, Just held) | held == name -> Just step
        _ -> Nothing

    holds known operand = case typedValue operand of
      VLocal name -> Just (originAt known name)
      _ -> Nothing

    producing known name = case Map.lookup name known of
      Just (OAssign (TypedValue _ (VLocal copied))) -> producing known copied
      other -> other

-- | What produced each local at one point in a block.
type Producing = Map Local (Operation (TypedValue Local))

-- | What a local ultimately names here, following the copies back.
--
-- Promotion turns every load of a slot into a copy and every store into
-- another, so a loop reads its counter through one copy and writes it through
-- a second; a pass asking whether an operand /is/ the counter is asking this.
originAt :: Producing -> Local -> Local
originAt known name = case Map.lookup name known of
  Just (OAssign (TypedValue _ (VLocal copied))) -> originAt known copied
  _ -> name

-- | Each instruction of a block with what produced each local /where that
-- instruction stands/.
--
-- Positional, and it has to be.  A whole-block map would say that the counter
-- is a copy of the value its own increment produces, since that is what the
-- last assignment in the turn makes it; walking the copies back through that
-- goes round the loop rather than up the block.  Assigning to a local takes
-- away what was held in it and every definition that reads it, which is the
-- same rule "Olivine.Core.Pass.Fold" keeps while it sweeps and for the same
-- reason.
producedAt :: [Instruction] -> [(Instruction, Producing)]
producedAt = go Map.empty
  where
    go _ [] = []
    go known (i : rest) = (i, known) : go (record i known) rest

    record i known = case instructionResult i of
      Nothing -> known
      Just result
        | result `elem` localsUsedBy operation -> remaining result known
        | otherwise -> Map.insert result operation (remaining result known)
      where
        operation = instructionOperation i

    remaining result =
      Map.filterWithKey (\name operation -> name /= result && result `notElem` localsUsedBy operation)

-- | The block run over the values in hand, leaving the values it settles.
--
-- An instruction whose result cannot be settled takes the local it assigns out
-- of what is known, which is the whole of what makes a reassignment safe here:
-- the value under a local is what that local holds at this point, never what it
-- held before.
interpret :: Map Local (Value Local) -> [Instruction] -> Map Local (Value Local)
interpret = foldl' step
  where
    step known i = case instructionResult i of
      Nothing -> known
      Just result -> case settle known (instructionOperation i) of
        Just value -> Map.insert result value known
        Nothing -> Map.delete result known

-- | What an operation comes to, when what its operands hold is known.
--
-- The evaluator is folding's, so this cannot disagree with what the folding
-- pass would make of the same instruction, and an operation whose answer is
-- poison has no answer here either.
settle :: Map Local (Value Local) -> Operation (TypedValue Local) -> Maybe (Value Local)
settle known operation = case fmap resolved operation of
  -- An assignment is not an operation folding has anything to say about, and
  -- it is how every value promotion left behind arrives.
  OAssign (TypedValue _ value) | isConstant value -> Just value
  resolvedOperation -> do
    TypedValue _ value <- foldOperation resolvedOperation
    guard (isConstant value)
    pure value
  where
    resolved (TypedValue t value) = TypedValue t (resolve known value)

-- | An operand written as what it holds, where that is known.
valueOf :: Map Local (Value Local) -> TypedValue Local -> Maybe (Value Local)
valueOf known (TypedValue _ value) = case resolve known value of
  resolved | isConstant resolved -> Just resolved
  _ -> Nothing

resolve :: Map Local (Value Local) -> Value Local -> Value Local
resolve known (VLocal name) = Map.findWithDefault (VLocal name) name known
resolve _ value = value
