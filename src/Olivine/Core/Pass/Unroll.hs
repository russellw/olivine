-- | Loops written out turn by turn, where the turns are countable and few.
--
-- What a loop costs beyond the work in it is a test and a branch per turn, and
-- for a body of three instructions that is most of what runs.  Writing the
-- turns out one after another takes the test and the branch away, and it does
-- something worth more than either: it puts every turn in one block, where the
-- passes below can see them together.  Two turns reading the same address are
-- two loads one walk can answer; a counter that was a different number each
-- time round is a different constant in each copy, and an address computed from
-- it is an address folding settles.
--
-- __The counter's value is written down, not worked out again.__  Each copy
-- opens with an assignment saying what the loop's own locals hold at the top of
-- that turn, which "Olivine.Core.Induction" had to know in order to count the
-- turns at all.  Without it a copy is the same work as the turn it copies —
-- the counter still computed from the last one — and the pass would trade a
-- branch for a block four times the size.  With it the copies are what folding
-- reads through, and this is the pass that makes constants of a loop's
-- arithmetic rather than the pass that removes a branch.
--
-- The assignments say nothing that was not already true: a local holds what the
-- interpreter says it holds at the top of that turn, or it is not mentioned.
--
-- __What is written out is bounded twice__, by 'turnLimit' on how many turns
-- there may be and by 'bodyBudget' on how much may be written out in total.
-- Unrolling is the one transformation here that makes a function bigger on
-- purpose, so the bound is what says how much bigger; and unlike the other
-- bounds in the optimizer it is also what makes an analysis terminate, since
-- counting the turns of a loop means running them.
--
-- __The loop has to be one block that branches to itself.__  That is what a
-- small counted loop is by the time this runs — rotation puts the test at the
-- bottom and block merging makes the body and the test one block — and it is
-- what makes writing the turns out a matter of putting the copies in a row.  A
-- loop of several blocks would want its paths copied and its labels reissued,
-- which is a different pass; nothing in the corpus wants it yet.
module Olivine.Core.Pass.Unroll
  ( unrollLoops
  , turnLimit
  , bodyBudget
  ) where

import Data.List (find)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Olivine.Core.Induction (Turn (..), turnsOf)
import Olivine.Core.Instruction
import Olivine.Core.Loops (Loop (..), loopsOf)
import Olivine.Core.Program
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value (TypedValue (..))

-- | How many turns a loop may make and still be written out.
--
-- The number is what a body of a few instructions is worth writing out that
-- many copies of, and it is also how far 'turnsOf' is asked to interpret,
-- which is the whole cost of asking.
turnLimit :: Int
turnLimit = 8

-- | How many instructions all the copies together may come to.
--
-- Counted on the loop as written rather than on what is left after folding,
-- because what folding will make of a copy is not known until it has run.  The
-- copies are what pays for the branch and the counter, so the budget is the
-- point at which a bigger function stops being a faster one.
bodyBudget :: Int
bodyBudget = 40

unrollLoops :: Program -> Program
unrollLoops program =
  program {programEntries = map entry (programEntries program)}
  where
    types = namedTypes program
    entry (EFunction f) = EFunction (settle types f)
    entry retained = retained

-- | Writing one loop out may leave a block that is another loop's whole body,
-- so this runs until a sweep finds nothing.  A sweep that writes a loop out
-- removes a back edge and adds none, so the sweeps stop.
settle :: Map Name Type -> Function -> Function
settle types f = case [written | loop <- loopsOf f, Just written <- [unroll types f loop]] of
  written : _ -> settle types written
  [] -> f

-- | One loop written out, if it is one of the loops this is for.
unroll :: Map Name Type -> Function -> Loop -> Maybe Function
unroll types f loop = do
  body <- find ((== header) . blockLabel) (functionBlocks f)
  turns <- turnsOf turnLimit f loop
  leaving <- wayOut body
  let instructions = blockInstructions body
  -- The budget is against what will be written, which is the body once per
  -- turn — but only the part of it that costs anything.  An assignment is not
  -- an instruction in the output: reconstruction takes every one of them away,
  -- and a body a front end wrote is mostly the assignments promotion left where
  -- its loads and stores were.  Counting those would refuse to write out a loop
  -- whose real body is five instructions because it is written in thirteen.
  guardOn (length turns * length (filter costly instructions) <= bodyBudget)
  let Local next = nextLocal f
      copies =
        concat
          [ known turn <> namedApart types (Local (next + n * length instructions)) instructions
          | (n, turn) <- zip [0 ..] turns
          ]
  pure
    f
      { functionBlocks =
          [ if blockLabel b == header
              then
                b
                  { blockInstructions = copies
                  , -- The loop is gone, so what it promised about itself goes
                    -- with it: a @!llvm.loop@ left on a branch that closes
                    -- nothing is a promise about a loop nobody can find.
                    blockTerminator = Terminator (Br leaving) []
                  }
              else b
          | b <- functionBlocks f
          ]
      }
  where
    header = loopHeader loop

    -- Where control goes when the loop is done, which is the way out of the
    -- block that is not back into it.
    wayOut body = case terminatorTransfer (blockTerminator body) of
      CondBr _ takenIf takenElse
        | takenIf == header, takenElse /= header -> Just takenElse
        | takenElse == header, takenIf /= header -> Just takenIf
      _ -> Nothing

    -- What the turn is known to hold, said as assignments at the top of the
    -- copy.  A type is wanted for each and the local's own type is what the
    -- instruction that assigns it in the body gives.
    known turn =
      [ Instruction (Just name) (OAssign (TypedValue t value)) []
      | (name, value) <- Map.toList (turnKnown turn)
      , Just t <- [typeOf name]
      ]

    typeOf name =
      case [ resultType types (instructionOperation i)
           | b <- functionBlocks f
           , Set.member (blockLabel b) (loopBody loop)
           , i <- blockInstructions b
           , instructionResult i == Just name
           ] of
        t : _ -> Just t
        [] -> Nothing

    costly i = case instructionOperation i of
      OAssign _ -> False
      _ -> True

    guardOn condition = if condition then Just () else Nothing
