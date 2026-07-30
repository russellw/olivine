-- | Turning a branch into a value.
--
-- A conditional that only computes — @x = c ? a : b@, and every @if@ whose two
-- sides do nothing but decide what a variable holds — arrives as four blocks: a
-- block that tests, a block on each side, and the block they meet at.  Nothing
-- in it needs control flow at all.  If-conversion runs both sides where the test
-- stood and picks between what they left with a @select@, so what was a
-- diamond is one block and what was a branch is an operand.
--
-- __The core is what makes this short.__  In single assignment form the values
-- to pick between are the operands of a phi, and finding them means reading the
-- phi at the join.  Here there is no phi: a value that depends on which way
-- control went is a local both sides assign, so the operands of the @select@ are
-- what each side was going to leave in the local, and they are found by looking
-- at the sides themselves.  Nothing here mentions the join except to branch to
-- it.
--
-- __Both sides run, so both sides must be runnable either way.__  Every
-- instruction in a side has to answer 'speculatable': it must leave the same
-- value whenever its operands are the same, and running it where control would
-- not have must change nothing else.  That rules out a call, a store, an
-- allocation, an integer division — which is undefined on zero rather than
-- poison, so running one the program would not have run is inventing
-- behaviour rather than collecting on it — and a load, which may fault at an
-- address the other path never went to.  What is left is arithmetic,
-- comparison, conversion, pointer stepping and assignment, which is what the
-- sides of a computed conditional hold.
--
-- A load is the one of those worth coming back for: @if (c) x = *p@ is common,
-- and "Olivine.Core.Pass.LoopInvariants" already knows two ways to say a load
-- cannot fault.  Neither applies here — one of them is about standing in a
-- loop's header and the other about reading a whole symbol — so this declines
-- every load, and a program that wants one converted wants dereferenceability:
-- what the pointer points into and how far along it, which
-- "Olivine.Core.Alias" answers, against how many bytes that object is, which
-- "Olivine.Core.Layout" answers.  Both are sayable now and neither is asked
-- here.
--
-- __What it costs is the other side's work.__  Whichever way the branch would
-- have gone, what if-conversion adds to that path is the instructions on the
-- side control did not take; what it removes is the branch.  A branch that
-- predicts well costs nothing and one that predicts badly costs tens of cycles,
-- and which of those a particular @if@ is cannot be read off the program, so the
-- bound is small and per side: 'armBudget' instructions that cost anything.
-- Assignments do not — reconstruction removes every one of them, so a side
-- holding nothing but assignments is exactly the phi this exists to remove and
-- costs nothing at all to convert — and neither does an instruction nothing
-- reads, which is dead either way.
--
-- Nothing else is measured, and nothing needs to be.  A speculated instruction
-- either feeds one of the selects or is read by nothing at all, since the
-- condition on the sides is that they have no effects; the second kind is dead
-- code that "Olivine.Core.Pass.DeadCode" takes away.
--
-- __Only what something else reads becomes a select.__  A local a side assigns
-- and only that side reads is a temporary, and merging it into the block above
-- leaves it a temporary — nothing outside can see which value it holds, so
-- nothing has to choose.  A local something else reads is the value the branch
-- was deciding, and that one gets a @select@.  The two are told apart by
-- looking: 'readBy' asks which locals any other block reads, which is cheap and
-- is exact for what it is asked, a side being one block.
--
-- The ones that get a select are written to names of their own inside the side
-- first, one name per assignment, so that the select has something to point at
-- and the local itself still holds what it held above the branch until the
-- select says otherwise.  That is also what makes the order of the two sides
-- immaterial: the side that runs second reads the same values it would have
-- read, because the side that ran first wrote only names nothing else names.
--
-- __The selects all read the condition, so they all come first.__  They stand
-- for what arrives at the join, and what arrives at the join arrives at once —
-- so a write-back must not be able to change what a later select reads, which it
-- could if the condition is itself one of the locals being decided.  Every
-- select is therefore emitted before every write-back.  It is the same hazard
-- 'Olivine.Core.Phi.eliminate' orders its copies against, in the one direction
-- that can arise here.
--
-- __A side may be empty.__  @if (c) x = 1@ has one side and no block on the
-- other: the branch goes straight to the join, and what the join sees along that
-- edge is whatever the local already held.  So a side with nothing on it
-- contributes the local itself as its operand, and the triangle needs no case of
-- its own beyond that.  Where the local was not assigned above the branch either,
-- reading it is reading a value the program left undefined on that path, which is
-- what the join read there before.
--
-- It is promotion that leaves this shape, and only promotion.  Written as a phi
-- the same @if@ has two sides: the value arriving from the block that tests is a
-- copy, and 'Olivine.Core.Phi.eliminate' has to put a copy leaving a block with
-- two successors on an edge of its own, which is a block on that side after all.
-- A variable that one side assigns and the other does not is the case where there
-- is nothing to put anywhere.
--
-- __The select assigns a name of its own and copies it back.__  A local that a
-- @select@ wrote directly would be a local written by an instruction and by the
-- assignments elsewhere that made it a decided value in the first place, and
-- reconstruction has no phi to put back for a local defined twice by
-- instructions.  So the select writes a fresh local and an assignment carries it
-- into the one the rest of the function reads, which is what
-- "Olivine.Core.Pass.LoopRotation" does with the header it copies and for the
-- same reason.  The assignment costs nothing.
--
-- __It runs after control flow simplification.__  The shape has to be the real
-- one: a side that is still a block forwarding to another block does not branch
-- to the join, and a @-O0@ front end writes exactly that — of the two sides of
-- an @else if@, one arrives as a detour.  So this wants the graph after
-- 'Olivine.Core.Pass.ControlFlow.simplifyControlFlow' has straightened it, and
-- for the same reason it cannot leave the cleaning up to that pass afterwards:
-- what it leaves is a head that branches to the join, which — for every
-- conditional that is not an arm of a larger one — is then reached from nowhere
-- else, and that is one block written as two.  'Olivine.Core.Blocks.mergeBlocks'
-- is what puts those together, and it is called here rather than being a reason
-- to run a whole pass twice.
--
-- __One at a time, and the nesting comes out by itself.__  Converting the inner
-- diamond of an @else if@ leaves its head holding a comparison and a select and
-- branching to the join, which is a side of the outer diamond that can be
-- speculated like any other; so a chain of conditionals collapses innermost
-- first without anything here looking for one.  Each conversion removes at least
-- the blocks on the sides, so the number of blocks the function started with is
-- as many rounds as there can be.
--
-- __What it declines and does not intend to take.__  A @switch@, whose sides
-- would be a chain of selects rather than one and whose cost is a jump table
-- against that chain.  And a side reached from anywhere but the block that tests,
-- which is not a side of this branch at all.
module Olivine.Core.Pass.IfConversion
  ( convertBranches
  , armBudget
  ) where

import Data.List (nubBy)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (listToMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Blocks (mergeBlocks, predecessorsOf)
import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Select (..))
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value (TypedValue (..), Value (..))

-- | How much work a side may hold and still be worth running either way.
--
-- Counted in instructions that are not assignments, since those are the only
-- ones that reach the output.  This is a first number, not a measured one: it
-- is set where the sides of a conditional expression go — a comparison and a
-- select, which is what the inner half of an @else if@ comes to — and anything
-- longer stays behind its branch.  What would make it a measured number is a
-- cost model for a mispredicted branch, which is a fact about a machine, and
-- nothing here reads one.
armBudget :: Int
armBudget = 2

-- | A branch that can be made into a value: the block that tests, what it tests,
-- the block on each side, and the block they meet at.
data Diamond = Diamond
  { diamondHead :: Block
  , diamondCondition :: TypedValue Local
  , -- | The side taken when the condition holds, if there is a block on it.
    -- Nothing is the triangle: that side goes straight to the join.
    diamondTrue :: Maybe Block
  , diamondFalse :: Maybe Block
  , diamondJoin :: Label
  }

convertBranches :: Program -> Program
convertBranches program =
  program {programEntries = map entry (programEntries program)}
  where
    -- What the module's named types stand for, which is what says the type a
    -- select produces.  Read once for the program: no pass makes or unmakes a
    -- type definition.
    types = namedTypes program

    entry (EFunction f) = EFunction (settle types (length (functionBlocks f)) f)
    entry retained = retained

-- | Convert one branch, then look again.
--
-- One at a time because each conversion changes the graph the next question is
-- asked of: the sides of the branch just converted are gone, and the head they
-- were merged into is a side of whatever tested above it.
settle :: Map Name Type -> Int -> Function -> Function
settle types remaining f
  | remaining <= 0 = f
  | otherwise = case convertible f of
      [] -> f
      diamond : _ -> settle types (remaining - 1) (mergeBlocks (convert types f diamond))

-- | The branches worth converting, in the order the blocks are written.
convertible :: Function -> [Diamond]
convertible f =
  [ Diamond h condition true false join
  | h <- functionBlocks f
  , CondBr condition yes no <- [terminatorTransfer (blockTerminator h)]
  , -- A branch to one block either way decides nothing, and there is no second
    -- side to pick against.  Control flow simplification has already made such a
    -- branch unconditional; saying so here is what keeps this from taking the
    -- one side for two.
    yes /= no
  , let (true, join) = sideOf f h yes
  , let (false, join') = sideOf f h no
  , join == join'
  , -- A join above the branch is a loop rather than a meeting point, and one
    -- block branching to itself for ever is not what this is for.
    join /= blockLabel h
  , all (runnableEitherWay anythingReads) [side | Just side <- [true, false]]
  ]
  where
    -- What the function reads anywhere, which is what says whether an
    -- instruction on a side costs anything.  Read once for the function rather
    -- than once for each branch in it.
    anythingReads = readBy (const True) f

-- | What one side of a branch holds, and where that side arrives.
--
-- A block reached from the branch and from nowhere else, that goes on to one
-- place, is a side; the place it goes on to is where the branch's two sides
-- meet.  Anything else the branch names is the meeting point itself, reached
-- with nothing done on the way.
--
-- Which of the two it is cannot be in doubt: a block reached only from the
-- branch is a block the other side does not reach, so a side is never also a
-- join.
sideOf :: Function -> Block -> Label -> (Maybe Block, Label)
sideOf f h target = case armAt f h target of
  Just (side, join) -> (Just side, join)
  Nothing -> (Nothing, target)

-- | The block on a side, when the branch is the only way to it and it goes on to
-- a single place.
--
-- The entry block is never one, whatever the graph says: a side is merged into
-- the block above it and stops existing, and a function starts where its first
-- block is.  LLVM forbids a branch to the entry block, so this only declines
-- what the verifier is already complaining about.
armAt :: Function -> Block -> Label -> Maybe (Block, Label)
armAt f h target =
  listToMaybe
    [ (side, join)
    | side <- [b | b <- functionBlocks f, blockLabel b == target]
    , Just target /= entryLabel f
    , predecessorsOf (functionBlocks f) target == [blockLabel h]
    , Br join <- [terminatorTransfer (blockTerminator side)]
    ]

-- | Whether a side can be run when control would not have taken it, and is
-- small enough to be worth running then.
--
-- What is counted against 'armBudget' is what the other path would have to run
-- for nothing: an instruction that is not an assignment and whose result
-- something reads.  An assignment is not an instruction in the output, and an
-- instruction nothing reads is dead code whether it is speculated or not — a
-- @-O0@ front end leaves one on the side of every second conditional, and a
-- budget spent on those is a budget spent on nothing.
runnableEitherWay :: Set Local -> Block -> Bool
runnableEitherWay anythingReads side =
  all (speculatable . instructionOperation) instructions
    && length (filter costly instructions) <= armBudget
  where
    instructions = blockInstructions side
    costly i =
      not (isAssignment (instructionOperation i))
        && maybe False (`Set.member` anythingReads) (instructionResult i)

isAssignment :: Operation operand -> Bool
isAssignment (OAssign _) = True
isAssignment _ = False

-- | Put both sides of a branch in the block that tested, and pick between what
-- they leave.
convert :: Map Name Type -> Function -> Diamond -> Function
convert types f d =
  f {functionBlocks = [rebuild b | b <- functionBlocks f, blockLabel b `notElem` gone]}
  where
    h = diamondHead d
    gone = [blockLabel side | Just side <- [diamondTrue d, diamondFalse d]]

    rebuild b
      | blockLabel b == blockLabel h =
          b
            { blockInstructions =
                blockInstructions b <> ranTrue <> ranFalse <> selects <> writeBacks
            , blockTerminator =
                (blockTerminator b) {terminatorTransfer = Br (diamondJoin d)}
            }
      | otherwise = b

    -- Every local either side leaves for something else to read, with the type
    -- it is assigned at.  The order is the order they are assigned in, so that
    -- what comes out does not depend on how a set happens to be ordered.
    decided =
      nubBy
        sameLocal
        (escapingIn types f (diamondTrue d) <> escapingIn types f (diamondFalse d))
    sameLocal (local, _) (other, _) = local == other
    wanted = Set.fromList (map fst decided)

    Local next = nextLocal f
    (afterTrue, ranTrue, leftByTrue) = renameEscaping wanted next (instructionsOf (diamondTrue d))
    (afterFalse, ranFalse, leftByFalse) = renameEscaping wanted afterTrue (instructionsOf (diamondFalse d))

    -- One select for each decided local, then one assignment carrying each into
    -- the local itself.  Every select stands before every assignment because
    -- they all read the condition, which an assignment may be writing.
    chosen = zip decided (map Local [afterFalse ..])

    selects =
      [ Instruction
          (Just result)
          ( OSelect
              Select
                { selectFlags = []
                , selectCondition = diamondCondition d
                , selectTrue = held leftByTrue local t
                , selectFalse = held leftByFalse local t
                }
          )
          []
      | ((local, t), result) <- chosen
      ]

    writeBacks =
      [ Instruction (Just local) (OAssign (TypedValue t (VLocal result))) []
      | ((local, t), result) <- chosen
      ]

    -- What a side leaves in a local: the name it wrote it under, or — for a side
    -- that does not assign it, an empty side included — the local itself, which
    -- still holds what it held above the branch.
    held left local t = TypedValue t (VLocal (Map.findWithDefault local local left))


    instructionsOf = maybe [] blockInstructions

-- | Which locals a side assigns that anything outside it reads, and the type
-- each is assigned at.
--
-- These are the values the branch was deciding.  Everything else a side assigns
-- is a temporary of that side, which stays a temporary once the side is merged
-- into the block above it.
escapingIn :: Map Name Type -> Function -> Maybe Block -> [(Local, Type)]
escapingIn _ _ Nothing = []
escapingIn types f (Just side) =
  [ (result, resultType types (instructionOperation i))
  | i <- blockInstructions side
  , Just result <- [instructionResult i]
  , Set.member result outside
  ]
  where
    outside = readBy (/= blockLabel side) f

-- | Every local read by the blocks the predicate accepts.
--
-- Asked two ways.  Of every block but one, to say which of a side's results
-- something else reads, which is what makes them values the branch decided; and
-- of the whole function, to say which of them anything reads at all, which is
-- what makes them worth counting against the budget.
--
-- The terminators are read as well as the instructions, and the branch being
-- converted is one of them: a condition that some side also assigns is a value
-- read outside that side, and it has to be decided like any other.
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

-- | A side's instructions, with the locals it must not write yet written to
-- names of their own.
--
-- One name per assignment rather than one per local, so that each of them is
-- still written in one place: two instructions writing one local is what
-- reconstruction has no phi to put back for, and what the select wants is the
-- last of them, which is what the name issued last holds.
--
-- Reads follow the writes: an instruction reading a local the side has already
-- assigned reads the name that assignment now uses, and one reading it before
-- then reads the local itself, which is still what it was above the branch.
--
-- The names are issued from the number given, upwards, so two calls want two
-- ranges that do not meet.
renameEscaping ::
  Set Local -> Int -> [Instruction] -> (Int, [Instruction], Map Local Local)
renameEscaping wanted = go Map.empty
  where
    go left n [] = (n, [], left)
    go left n (i : rest) = case instructionResult i of
      Just result
        | Set.member result wanted ->
            let (n', following, final) = go (Map.insert result (Local n) left) (n + 1) rest
             in (n', reading left i {instructionResult = Just (Local n)} : following, final)
      _ ->
        let (n', following, final) = go left n rest
         in (n', reading left i : following, final)

    reading left i =
      i {instructionOperation = fmap (substitute left) (instructionOperation i)}

    substitute left operand = case operand of
      TypedValue t (VLocal local)
        | Just renamed <- Map.lookup local left -> TypedValue t (VLocal renamed)
      _ -> operand
