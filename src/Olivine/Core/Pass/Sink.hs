-- | One copy of what every way into a block ends with.
--
-- Where several blocks all branch to one place and all end by doing the same
-- thing, the thing is done once at the top of the place they branch to.  The
-- shape is what a threaded interpreter is made of — every arm of the dispatch
-- finishes by working out where to go next and jumping there — and a front end
-- leaves it wherever two paths do their own work and then the same work.  LLVM
-- does this in @SimplifyCFG@ under the name @SinkCommonCodeFromPredecessors@.
--
-- __Nothing moves, so nothing has to be proved about what is moved.__  An arm's
-- only successor is the join, so between the last instruction of an arm and the
-- first of the join there is nothing but a branch: running it at the top of the
-- join is running it where it ran.  That is why there is no 'speculatable' here
-- and no question put to the aliasing — a store, a call, an atomic and a fence
-- are as sinkable as an addition, and the only operations refused are the two
-- that mean something by the block they stand in.  An @alloca@ out of the entry
-- block is a frame that grows a turn at a time, and a landing pad is where an
-- unwinder resumes.
--
-- __Every way in must do it, or it is not done at all.__  A value that differs
-- between the arms becomes a phi at the join, and a phi needs a value on every
-- edge, so a join with a predecessor that does not take part has an edge with
-- nothing on it.  Rather than split such an edge this declines: every
-- predecessor must reach the join by an unconditional branch, and all of them
-- must agree.  That an arm branches nowhere else is also what makes one sweep
-- enough, since no block can then be an arm of two joins.
--
-- __A phi is an assignment, which is what makes this cheap.__  In single
-- assignment form sinking means building phi nodes at the join and rewriting the
-- sunk instruction to read them.  Here the operands the arms disagree about are
-- left in the arms as assignments to one fresh local, and reconstruction turns
-- those into a phi on the way out — so this pass writes no phi and knows nothing
-- about them.  The results are the mirror image: the arms assigned different
-- locals to what is now one instruction, so the instruction keeps the first arm's
-- name and an assignment at the join carries it into each of the others.  Those
-- cost nothing at all, reconstruction removing every assignment.
--
-- __What it is worth is counted, and the count is the whole budget.__  Sinking a
-- run of @k@ instructions from @n@ arms takes @(n - 1) * k@ of them away, and
-- each operand the arms disagree about puts one phi back.  Assignments are not
-- counted among the @k@, since they are not instructions in the output — but
-- they are sunk along with the rest all the same, because the assignments at the
-- end of an arm /are/ the join's phi, and a run that stopped underneath them
-- would never reach anything worth having.  A run of nothing but assignments is
-- refused, being a phi rewritten as itself.
--
-- __The longest run is not always the best one, so every length is costed.__
-- Each instruction in a run is another thing the arms have to agree about, and
-- also another value the run computes for itself rather than phis: an operand
-- naming something the run above it produced needs no phi, there being one such
-- value after sinking where there was one per arm.  That second effect is what
-- makes a dispatch tail worth sinking whole — taken an instruction at a time it
-- would pay for a phi at every step — and the two pull opposite ways, so the
-- answer is to price each length and take the best.
--
-- __What is declined and could be taken.__  A join some of whose predecessors
-- end with the run and some of which do not: LLVM splits an edge and sinks from
-- the ones that agree, where this asks all of them and takes nothing when one
-- disagrees.  And a run whose price comes out exactly even, which is a store or
-- a call the arms made with different operands and nothing else — one
-- instruction out against one phi in.  That one is worth having anyway when the
-- run is the whole of every arm, since the arms then hold nothing but
-- assignments and become a @select@ in "Olivine.Core.Pass.IfConversion"; it is
-- taken today only where an assignment the arms all made to one local pays for
-- the phi, which is the commoner way the same shape arrives.
module Olivine.Core.Pass.Sink
  ( sinkCommonTails
  ) where

import Control.Monad (guard)
import Data.Foldable (toList)
import Data.List (maximumBy)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust, listToMaybe, mapMaybe)
import Data.Ord (comparing)
import Data.Set qualified as Set
import Data.Traversable (mapAccumL)

import Olivine.Core.Blocks (predecessorsOf)
import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value (TypedValue (..), Value (..))

sinkCommonTails :: Program -> Program
sinkCommonTails program =
  program {programEntries = map entry (programEntries program)}
  where
    -- What the module's named types stand for, which is what says the type a
    -- sunk result is carried at.  Read once for the program: no pass makes or
    -- unmakes a type definition.
    types = namedTypes program

    entry (EFunction f) = EFunction (sweep types f)
    entry retained = retained

-- | Every block in the function offered as a join, once each.
--
-- One sweep is enough, and that follows from the rule that every arm ends in an
-- unconditional branch to the join: an arm has one successor, so no block is an
-- arm of two joins and no sink can spoil or make another.  What is left at the
-- end of an arm afterwards is the assignments this minted, and a run of nothing
-- but assignments is refused — so there is no second run to find at the same
-- join either.
sweep :: Map Name Type -> Function -> Function
sweep types f = foldl' consider f (map blockLabel (functionBlocks f))
  where
    consider g label = maybe g id (sink types g label)

-- | What sinking one run comes to: what the join gains and what the arms keep.
data Sunk = Sunk
  { -- | The run itself, to stand at the top of the join.
    sunkRun :: [Instruction]
  , -- | The assignments carrying each sunk result into the name another arm gave
    -- it, to stand after the run and before the join's own instructions.
    sunkCopies :: [Instruction]
  , -- | What each arm's instructions become: what it had above the run, and then
    -- the assignments standing for the operands the arms disagreed about.
    sunkKept :: Map Label [Instruction]
  , -- | Instructions this takes out of the output, less the phis it puts in.
    sunkGain :: Int
  }

-- | What one operand of one sunk instruction reads.
data Slot
  = -- | Every arm said the same thing, once the run's own results are read as
    -- the one value they became.
    Same (TypedValue Local)
  | -- | The arms said different things, so each assigns what it said to this
    -- fresh local and the sunk instruction reads that.  This is the phi.
    Minted Local Type [TypedValue Local]

-- | Sink the best run every way into a block ends with, where one pays.
sink :: Map Name Type -> Function -> Label -> Maybe Function
sink types f label = do
  guard (any ((== label) . blockLabel) (functionBlocks f))
  -- A block whose address is taken may be arrived at in a way no terminator here
  -- says, and what the run belongs to is the arms.  Nothing may be put at the top
  -- of such a block on the strength of who branches to it.
  guard (not (Set.member label (pinnedIn f)))
  arms <- armsOf f label
  best <- bestRun types (nextLocal f) arms
  guard (sunkGain best > 0)
  pure f {functionBlocks = map (rebuild best) (functionBlocks f)}
  where
    rebuild best b
      | blockLabel b == label =
          b
            { blockInstructions =
                sunkRun best <> sunkCopies best <> blockInstructions b
            }
      | Just kept <- Map.lookup (blockLabel b) (sunkKept best) =
          b {blockInstructions = kept}
      | otherwise = b

-- | The blocks that reach a join, when every one of them reaches it by an
-- unconditional branch and there are at least two.
--
-- Two is the least there is anything to merge between; one is
-- 'Olivine.Core.Blocks.mergeBlocks' putting the two blocks together instead,
-- which is better than this in every way.  A block that branches to itself is
-- not an arm: sinking within one block would move the run above the instructions
-- it came after rather than below them.
armsOf :: Function -> Label -> Maybe [Block]
armsOf f label = do
  guard (length arms >= 2)
  -- And nothing else reaches the join.  A predecessor that is not an arm is an
  -- edge with no value on it for every phi this would make.
  guard (length arms == length (predecessorsOf (functionBlocks f) label))
  pure arms
  where
    arms =
      [ b
      | b <- functionBlocks f
      , blockLabel b /= label
      , Br target <- [terminatorTransfer (blockTerminator b)]
      , target == label
      ]

-- | The best sinkable run of the arms' tails, over every length there could be.
bestRun :: Map Name Type -> Local -> [Block] -> Maybe Sunk
bestRun types fresh arms
  | null candidates = Nothing
  | otherwise = Just (maximumBy (comparing sunkGain) candidates)
  where
    shortest = minimum (map (length . blockInstructions) arms)
    candidates = mapMaybe (runAt types fresh arms) [1 .. shortest]

-- | Sinking exactly the last @depth@ instructions of every arm, where that can
-- be done at all.
runAt :: Map Name Type -> Local -> [Block] -> Int -> Maybe Sunk
runAt types (Local fresh) arms depth = do
  leading <- listToMaybe runs
  -- The same operations said the same way, each assigning to something or to
  -- nothing as the others do.  Every field but the operands is compared by
  -- erasing the operands, so an operation that gains a field is compared by it
  -- here without this having to name it.
  guard (all (alike leading) runs)
  -- Asked of the first arm alone, which is enough: the shapes agree, so an
  -- allocation in one arm's run is an allocation in every arm's.
  guard (all (allowed . instructionOperation) leading)
  -- A run of nothing but assignments is the join's own phi written as itself.
  guard (any (not . isAssignment . instructionOperation) leading)
  -- Nothing in the run may read what the run defines at or below it.  Within a
  -- block that names a value from the turn before, and where the read now stands
  -- the sunk run has not produced it yet.
  guard (and (zipWith inOrder defined runs))
  -- Nor may the arm above the run read what the run defines, which is the same
  -- hazard one turn out: the definition would move below a read that was above
  -- it.  The terminator is not asked, being an unconditional branch that reads
  -- nothing.
  guard (and (zipWith apart defined kept))
  (_, rows) <- decide fresh (map (const Map.empty) arms) 0
  pure
    Sunk
      { sunkRun = [built leading position row | (position, row) <- zip [0 ..] rows]
      , sunkCopies = concatMap carried [0 .. depth - 1]
      , sunkKept =
          Map.fromList
            [ (blockLabel a, keep <> minted rows arm)
            | (arm, a, keep) <- zip3 [0 ..] arms kept
            ]
      , sunkGain = (length arms - 1) * costing - (phis rows - saved)
      }
  where
    -- The last @depth@ instructions of each arm, and what it keeps above them.
    -- An arm with fewer than that has no run at all, which makes this length a
    -- refusal rather than silently a shorter one.
    runs
      | all ((>= depth) . length . blockInstructions) arms =
          [drop (length is - depth) is | a <- arms, let is = blockInstructions a]
      | otherwise = []
    kept = [take (length is - depth) is | a <- arms, let is = blockInstructions a]

    costing =
      length
        [ i
        | run <- take 1 runs
        , i <- run
        , not (isAssignment (instructionOperation i))
        ]

    defined = [Set.fromList (mapMaybe instructionResult run) | run <- runs]

    -- A position every arm assigns one and the same local at /is/ the join's phi,
    -- written the way this core writes one, and taking it out of the arms is what
    -- stops it being one: the local is then assigned in a single place and
    -- reconstruction has a copy to remove rather than a phi to build.  So a phi
    -- minted here in place of one that goes is no cost at all, which is what lets
    -- a run pay whose only gain is that the arms did the same work with different
    -- operands.
    saved =
      length
        [ ()
        | position <- [0 .. depth - 1]
        , all (isAssignment . instructionOperation . (!! position)) runs
        , sameResult position
        ]

    sameResult position = case [instructionResult (run !! position) | run <- runs] of
      first : rest -> isJust first && all (== first) rest
      [] -> False

    -- * What may be sunk

    alike a b = length a == length b && and (zipWith sameShape a b)

    sameShape i j =
      (() <$ instructionOperation i) == (() <$ instructionOperation j)
        && isJust (instructionResult i) == isJust (instructionResult j)

    inOrder own = go Set.empty
      where
        go _ [] = True
        go above (i : rest) =
          all reachable (localsUsedBy (instructionOperation i))
            && go (maybe above (`Set.insert` above) (instructionResult i)) rest
          where
            reachable local = not (Set.member local own) || Set.member local above

    apart own above =
      Set.null
        ( Set.intersection
            own
            (Set.fromList (concatMap (localsUsedBy . instructionOperation) above))
        )

    -- * What each operand of the sunk run reads
    --
    -- Walked from the top of the run down, carrying for each arm what its run has
    -- defined so far under the name the first arm gave it.  That map is what lets
    -- an operand naming a value the run itself produced be read as the one value
    -- it now is, which is where the length of a run pays for itself.

    decide next subs position
      | position >= depth = Just (next, [])
      | otherwise = do
          (after, row) <- row' next subs position 0
          (final, rest) <- decide after (zipWith (learn position) subs runs) (position + 1)
          pure (final, row : rest)

    row' next subs position index
      | index >= arity position = Just (next, [])
      | otherwise = do
          slot <- slotAt next subs position index
          (after, rest) <- row' (advance next slot) subs position (index + 1)
          pure (after, slot : rest)

    advance next (Minted _ _ _) = next + 1
    advance next (Same _) = next

    arity position =
      length
        (concat [toList (instructionOperation (run !! position)) | run <- take 1 runs])

    canonical position =
      listToMaybe [result | run <- take 1 runs, Just result <- [instructionResult (run !! position)]]

    learn position sub run = case (canonical position, instructionResult (run !! position)) of
      (Just canon, Just result) -> Map.insert result canon sub
      _ -> sub

    -- One operand of one instruction, across every arm.  Where they agree the
    -- sunk instruction reads what they agreed on; where they do not, each arm
    -- assigns what it read to a fresh local and the sunk instruction reads that.
    slotAt next subs position index = case mapped of
      [] -> Nothing
      leading : _
        | all (== leading) mapped -> Just (Same leading)
        -- An operand the run itself defines cannot be assigned to a fresh local
        -- in the arm, the arm no longer defining it.  Where two arms disagree
        -- about one there is nothing to be done at this length, and a shorter
        -- run — whose results these are not — may fare better.
        | or (zipWith produced subs raw) -> Nothing
        | all ((== typedValueType leading) . typedValueType) raw ->
            Just (Minted (Local next) (typedValueType leading) raw)
        | otherwise -> Nothing
      where
        raw = [toList (instructionOperation (run !! position)) !! index | run <- runs]
        mapped = zipWith resolve subs raw

    resolve sub operand = case operand of
      TypedValue t (VLocal local)
        | Just canon <- Map.lookup local sub -> TypedValue t (VLocal canon)
      _ -> operand

    produced sub operand = case operand of
      TypedValue _ (VLocal local) -> Map.member local sub
      _ -> False

    -- * What comes out

    built leading position row =
      Instruction
        { instructionResult = instructionResult (leading !! position)
        , instructionOperation =
            withOperands (instructionOperation (leading !! position)) (map operandOf row)
        , -- Metadata is an assertion about the value, so keeping one arm's where
          -- the arms wrote different ones would be asserting on a path that never
          -- said it.  Where they all wrote the same thing it is true of all of
          -- them, and otherwise it goes: that loses information and says nothing
          -- false.
          instructionMetadata = shared position
        }

    operandOf (Same operand) = operand
    operandOf (Minted local t _) = TypedValue t (VLocal local)

    shared position = case [instructionMetadata (run !! position) | run <- runs] of
      attached : rest | all (== attached) rest -> attached
      _ -> []

    carried position =
      [ Instruction
          (Just result)
          (OAssign (TypedValue (resultType types (instructionOperation i)) (VLocal canon)))
          []
      | leading <- take 1 runs
      , let i = leading !! position
      , Just canon <- [instructionResult i]
      , run <- drop 1 runs
      , Just result <- [instructionResult (run !! position)]
      , result /= canon
      ]

    minted rows arm =
      [ Instruction (Just local) (OAssign (raw !! arm)) []
      | row <- rows
      , Minted local _ raw <- row
      ]

    phis rows = length [() | row <- rows, Minted {} <- row]

-- | Whether an operation may be sunk at all.
--
-- The default is that it may, and that is not laziness: an arm's only successor
-- is the join, so a sunk instruction runs where it ran, and no property of what
-- it does can be disturbed by a move that is not a move.  What the two refusals
-- have in common is that they mean something by the block they stand in rather
-- than by what runs before them — an @alloca@ in the entry block is the frame,
-- and a landing pad is where an unwinder resumes.
allowed :: Operation operand -> Bool
allowed operation = case operation of
  OAlloca _ -> False
  OLandingPad _ -> False
  _ -> True

isAssignment :: Operation operand -> Bool
isAssignment (OAssign _) = True
isAssignment _ = False

-- | An operation with its operands replaced, position for position.
--
-- The operands are visited in the order the derived 'Traversable' visits them,
-- which is the order the derived 'Foldable' produced them in — so an operation
-- taken apart by 'toList' is put back together by this.
withOperands :: Operation operand -> [operand] -> Operation operand
withOperands operation news = snd (mapAccumL step news operation)
  where
    step (n : rest) _ = (rest, n)
    step [] old = ([], old)
