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
module Olivine.Core.Induction
  ( Turn (..)
  , turnsOf
  ) where

import Control.Monad (guard)
import Data.List (find, foldl')
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Olivine.Core.Instruction
import Olivine.Core.Loops (Loop (..))
import Olivine.Core.Pass.Fold (foldOperation)
import Olivine.Core.Program
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
  entered <- agreed [interpret Map.empty (blockInstructions b) | b <- entering]
  turn (written body) condition again 0 entered
  where
    header = loopHeader loop

    -- The blocks outside the loop that branch into it.
    entering =
      [ b
      | b <- functionBlocks f
      , not (Set.member (blockLabel b) (loopBody loop))
      , header `elem` targetsOf (blockTerminator b)
      ]

    -- What every way in agrees the local holds.  A loop nothing enters — which
    -- is a loop in unreachable code — agrees on nothing rather than on
    -- everything, since the answer would be about a turn that never happens.
    agreed [] = Nothing
    agreed (first : rest) = Just (foldl' agreeing first rest)
      where
        agreeing a b = Map.mapMaybeWithKey (\name v -> if Map.lookup name b == Just v then Just v else Nothing) a

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
