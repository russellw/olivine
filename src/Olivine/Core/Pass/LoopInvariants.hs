-- | Taking out of a loop the work that does not depend on going round it.
--
-- An instruction whose operands are the same on every iteration computes the
-- same value on every iteration, so it can be computed once before the loop is
-- entered instead of once per turn.  This is the first pass that moves an
-- instruction rather than rewriting one in place, and everything delicate about
-- it follows from that: what a computation is worth is a question the other
-- passes ask where it stands, and this one has to ask it somewhere else.
--
-- __Invariant means not assigned in the loop.__  A local the loop never
-- assigns holds, at every point inside it, what it held when control arrived —
-- so reading it before the loop reads the same value the instruction would have
-- read inside.  That is the whole of the analysis, and it is cheap for the
-- reason "Olivine.Core.Pass.Redundancies" is not: availability asks what /has
-- been/ computed on the way here, which every path has to agree on, while
-- invariance asks what is /never/ assigned in a set of blocks, which is one
-- sweep over them.
--
-- __The value goes in a preheader.__  Every edge into the header passes
-- through one block that goes nowhere else, so what it computes is computed
-- exactly when the loop is entered — including when the loop is entered a
-- second time, since an edge back in from outside is an edge into the header
-- like any other and is sent through the preheader too.  Where the loop is
-- already entered from a single block that branches nowhere else, that block
-- /is/ the preheader and the instructions are appended to it, which is the
-- usual case in what a front end emits and why this pass adds no block to most
-- functions.
--
-- __The result must be a local the function assigns in one place.__  Here is
-- the bill the non-SSA core presents this time.  Moving @%x := add %a, %b@
-- earlier moves /when @%x@ is written/, so any read of @%x@ between the loop
-- being entered and the instruction being reached sees the new value where it
-- saw the old one.  In single assignment form the question cannot arise.  The
-- condition that settles it is that nothing else in the function assigns @%x@
-- and that it is not a parameter: then a read that could have seen the old
-- value is a read of a local nothing has assigned, which is undefined
-- behaviour already, and refining that is allowed.  A local assigned twice —
-- what promotion makes of a variable, and what a phi is lowered to — is
-- declined, which is a refinement left for a liveness analysis rather than
-- something this pass cannot say.
--
-- __It may run where the original would not have.__  A loop whose test fails
-- the first time never runs its body, and an instruction in a block the body
-- only sometimes reaches may not have run either; hoisted, it runs whenever the
-- loop is reached.  For an operation that only computes a value that costs
-- nothing: an overflowing @add nsw@ hoisted out of a loop that never ran leaves
-- poison in a local nothing goes on to read.  For an operation that can
-- undefine the program it costs everything, so integer division is not hoisted
-- — dividing by zero is undefined behaviour rather than poison, and running it
-- where the program would not have is inventing that behaviour rather than
-- collecting on it.  Hoisting a division out of the header, which the loop
-- runs whenever it is entered at all, is sound and is a refinement for later.
--
-- __Memory is not hoisted.__  A load reads what memory holds, and a store or a
-- call anywhere in the loop may change it.  Saying otherwise takes aliasing,
-- which "Olivine.Core.Alias" now answers and this pass does not yet ask:
-- hoisting a load means asking it of every store and call in the loop rather
-- than of the instructions between two accesses, and then dealing with the same
-- must-execute question a division raises, a load being able to fault where a
-- division divides by zero.  A loop-invariant load is the single biggest thing
-- this pass leaves on the table, and no longer for want of the analysis.
--
-- __The copies come out first.__  An operand is rarely the value it stands
-- for.  Promotion replaces a load of a slot with a copy of the local the slot
-- became, standing where the load stood, so a loop reading a variable it never
-- writes reads a copy that the loop /does/ write, and the arithmetic on it is
-- invariant in nothing.  The redundancy pass answers this by resolving operands
-- through the copies for the purpose of comparing them, which it can do because
-- it rewrites nothing and moves nothing.  Moving an instruction is not that: an
-- operand written in the program has to mean, where the instruction is moved to,
-- what it meant where it stood.  So the copy is moved as well — it is invariant
-- exactly when what it copies is not assigned in the loop — and the round after
-- it finds the arithmetic reading a local the loop no longer assigns.  Hoisting a copy saves nothing by itself, since
-- reconstruction removes every assignment on the way out; what it buys is the
-- hoist after it.
--
-- __Innermost first, and iterated.__  An instruction is hoisted out of the
-- smallest loop it is invariant in, because a value that reaches the preheader
-- of an inner loop is then computed outside that loop, which can make it
-- invariant in the loop containing it.  So the loops are taken smallest first
-- and the whole thing runs again after each move: a chain of computations comes
-- out one instruction per round — the first has to leave the loop before the
-- second stops reading something the loop assigns — and a value in a nest of
-- loops comes out one loop per round.
--
-- The rounds are bounded by what a round achieves.  A hoist takes an
-- instruction out of one loop's body and puts it in a block outside it, so the
-- number of pairs of an instruction and a loop holding it goes down by at least
-- one; that number, counted once at the start, is therefore as many rounds as
-- there can be.  It is a bound rather than the argument itself because a loop
-- containing another contains its preheader only where the graph is reducible,
-- and everything a compiler emits is, but nothing here checks.
module Olivine.Core.Pass.LoopInvariants
  ( hoistLoopInvariants
  , hoistable
  ) where

import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Instruction
import Olivine.Core.Loops (Loop (..), loopsOf)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Binary (..), BinaryOp (..))

hoistLoopInvariants :: Program -> Program
hoistLoopInvariants program =
  program {programEntries = map entry (programEntries program)}
  where
    entry (EFunction f) = EFunction (settle (rounds f) f)
    entry retained = retained

-- | As many hoists as there can be: one instruction leaves one loop each time,
-- and this is how many of those there are to begin with.
rounds :: Function -> Int
rounds f =
  sum
    [ length (blockInstructions b)
    | loop <- loopsOf f
    , b <- functionBlocks f
    , Set.member (blockLabel b) (loopBody loop)
    ]

settle :: Int -> Function -> Function
settle remaining f
  | remaining <= 0 = f
  | otherwise = case candidates f of
      [] -> f
      (loop, preheader, moving) : _ ->
        settle (remaining - 1) (hoistFrom f loop preheader moving)

-- | The loops with something to take out of them, innermost first, each with
-- where what comes out of it goes.
candidates :: Function -> [(Loop, Preheader, [Instruction])]
candidates f =
  [ (loop, preheader, moving)
  | loop <- loopsOf f
  , Just preheader <- [preheaderFor f loop]
  , let moving = invariantIn f loop
  , not (null moving)
  ]

-- | Where a loop's hoisted instructions are put.
data Preheader
  = -- | The one block the loop is entered from, which branches nowhere but the
    -- header.  What is hoisted is appended to it, before its branch.
    Above Label
  | -- | A block to be made in front of the header, taking over the edges to
    -- the header from these blocks.
    Made [Label]

-- | The block a loop's invariant work belongs in, if there is one to be had.
--
-- 'Nothing' for a loop the function starts at, which is a loop whose header is
-- branched to and is the entry block — @Entry block to function must not have
-- predecessors@, says LLVM, so no valid module holds one and nothing Olivine
-- does makes one.  The block in front of the header would be in front of where
-- the function starts, so declining is not losing a hoist that could have
-- happened; it is not answering a question nothing asks.
preheaderFor :: Function -> Loop -> Maybe Preheader
preheaderFor f loop
  | entryLabel f == Just header = Nothing
  -- Entered from one block that branches nowhere else: that block already is
  -- what a preheader is, and its terminator reads nothing, so appending to it
  -- cannot come between an operand and what reads it.
  | [only] <- outside
  , [entering] <- [b | b <- functionBlocks f, blockLabel b == only]
  , Br target <- terminatorTransfer (blockTerminator entering)
  , target == header =
      Just (Above only)
  | otherwise = Just (Made outside)
  where
    header = loopHeader loop
    outside =
      [ blockLabel b
      | b <- functionBlocks f
      , not (Set.member (blockLabel b) (loopBody loop))
      , header `elem` targetsOf (blockTerminator b)
      ]

-- | The instructions in a loop that can be computed before it instead.
--
-- Everything collected in one round is independent of everything else in it: an
-- instruction reading what another one in the loop assigns is not invariant
-- yet, so nothing here reads anything else here, and the order they are
-- appended in cannot matter.
invariantIn :: Function -> Loop -> [Instruction]
invariantIn f loop =
  [ i
  | b <- functionBlocks f
  , Set.member (blockLabel b) (loopBody loop)
  , i <- blockInstructions b
  , hoistable (instructionOperation i)
  , Just result <- [instructionResult i]
  , Set.member result once
  , not (any (`Set.member` assigned) (localsUsedBy (instructionOperation i)))
  ]
  where
    once = writtenOnce f
    assigned = assignedIn f loop

-- | Every local the loop assigns, which is exactly what is not invariant in
-- it.
assignedIn :: Function -> Loop -> Set Local
assignedIn f loop =
  Set.fromList
    [ result
    | b <- functionBlocks f
    , Set.member (blockLabel b) (loopBody loop)
    , i <- blockInstructions b
    , Just result <- [instructionResult i]
    ]

-- | The locals the function assigns in one place and that are not parameters.
--
-- A parameter is assigned where the function is entered, which is before
-- anything this pass can move something to, so an instruction assigning to one
-- is assigning to it a second time whatever the blocks say.
writtenOnce :: Function -> Set Local
writtenOnce f =
  Set.difference
    (Set.fromList [local | (local, 1 :: Int) <- Map.toList counted])
    (Set.fromList (functionParameters f))
  where
    counted =
      Map.fromListWith
        (+)
        [ (result, 1)
        | b <- functionBlocks f
        , i <- blockInstructions b
        , Just result <- [instructionResult i]
        ]

-- | Move the given instructions out of the loop and into its preheader.
--
-- They are identified by the local they assign rather than by what they are:
-- each is the only assignment to it in the function, which is what made it
-- hoistable, so no other instruction can be taken for one of these.
hoistFrom :: Function -> Loop -> Preheader -> [Instruction] -> Function
hoistFrom f loop preheader moving = case preheader of
  Above label -> f {functionBlocks = map (append label) stripped}
  Made outside -> f {functionBlocks = concatMap (inFront outside) stripped}
  where
    header = loopHeader loop
    moved = Set.fromList (mapMaybe instructionResult moving)

    stripped = map strip (functionBlocks f)
    strip b
      | Set.member (blockLabel b) (loopBody loop) =
          b {blockInstructions = filter (not . hoisted) (blockInstructions b)}
      | otherwise = b
    hoisted i = maybe False (`Set.member` moved) (instructionResult i)

    append label b
      | blockLabel b == label = b {blockInstructions = blockInstructions b <> moving}
      | otherwise = b

    -- The block made in front of the header, which the header's own place in
    -- the list is what puts in front of it.  Never in front of the first block:
    -- a function starts at its first block, and a loop the function starts at
    -- is one 'preheaderFor' has already declined.
    made =
      Block
        { blockLabel = nextLabel f
        , blockInstructions = moving
        , blockTerminator = Terminator (Br header) []
        }

    inFront outside b
      | blockLabel b == header = [made, redirect outside b]
      | otherwise = [redirect outside b]

    redirect outside b
      | blockLabel b `elem` outside =
          b
            { blockTerminator =
                retarget
                  (\label -> if label == header then blockLabel made else label)
                  (blockTerminator b)
            }
      | otherwise = b

-- | Whether an operation may be computed before a loop that would have
-- computed it inside.
--
-- Two questions at once, and an operation has to answer both: that it leaves
-- the same value behind whenever its operands are the same, and that running
-- it where the original would not have run it changes nothing else.  Written
-- out case by case with no catch-all, so that an operation added to the grammar
-- later fails to compile here rather than being quietly taken for one that can
-- be moved.
hoistable :: Operation operand -> Bool
hoistable operation = case operation of
  -- A copy saves nothing by being made earlier — reconstruction removes every
  -- assignment on the way out of the core, so there is no instruction here to
  -- pay for.  It is hoisted because it is what stands between the loop and the
  -- value it is invariant in.  Promotion turns every load of a slot into a copy
  -- where the load was, so a computation on a variable the loop never writes
  -- reads two copies made inside the loop and is invariant in nothing until
  -- they come out; taking them out is what makes the round after it see what
  -- the arithmetic really reads.
  OAssign _ -> True
  -- May do anything, and may answer differently each time it is asked.
  OCall _ -> False
  -- Fresh storage each time, so one allocation before the loop is not the
  -- allocations the loop asked for.
  OAlloca _ -> False
  -- The answer is whatever memory holds, and a store or a call in the loop may
  -- change that.  Nor is the pointer necessarily one that can be read at all
  -- when the loop is not entered.
  OLoad _ -> False
  -- Writes memory, so moving it changes when the write happens.
  OStore _ -> False
  OBinary b -> not (undefinedByZero (binaryOp b))
  OUnary _ -> True
  OICmp _ -> True
  OFCmp _ -> True
  OConvert _ -> True
  OSelect _ -> True
  OExtractElement _ -> True
  OInsertElement _ -> True
  OShuffleVector _ -> True
  -- Pointer arithmetic says where something is rather than what is there, and
  -- one that runs off the end of its object is poison rather than a fault.
  OOffset _ -> True
  OField _ -> True

-- | Whether an opcode undefines the program on operands it can be given.
--
-- The integer divisions, and only those: dividing by zero is undefined
-- behaviour in LLVM rather than poison, so one of these run where the program
-- would not have run it is behaviour invented rather than behaviour preserved.
-- Everything else here answers poison at worst — a shift past the width, an
-- @nsw@ addition that overflows — which is a value nothing reads when the loop
-- does not run.
--
-- Floating point division is not one of them: dividing by zero is an infinity,
-- and the default environment traps on nothing.
undefinedByZero :: BinaryOp -> Bool
undefinedByZero op = case op of
  OpUDiv -> True
  OpSDiv -> True
  OpURem -> True
  OpSRem -> True
  OpAdd -> False
  OpSub -> False
  OpMul -> False
  OpShl -> False
  OpLShr -> False
  OpAShr -> False
  OpAnd -> False
  OpOr -> False
  OpXor -> False
  OpFAdd -> False
  OpFSub -> False
  OpFMul -> False
  OpFDiv -> False
  OpFRem -> False
