-- | Reading a value off the computation that already worked it out.
--
-- An instruction computing what an earlier one computed becomes an assignment
-- of what the earlier one left behind.  That is the same device folding uses,
-- and for the same reason: the core has assignment, so a pass that finds out
-- what an instruction comes to never has to move or delete anything to say
-- so.  Reconstruction carries the value to the uses and the dead code pass
-- takes away whatever was only computed to feed the instruction that is now a
-- copy.
--
-- __This is where the core's bargain comes due.__  In single assignment form
-- "computed already" is a lookup and nothing more: a name is a value, so two
-- instructions with the same operands compute the same thing wherever they
-- stand.  Here a local can be reassigned, so the question is availability —
-- whether on /every/ path that reaches this instruction the expression was
-- computed, and neither what it reads nor the local holding it has been
-- assigned since.  That is a forward dataflow analysis rather than a lookup,
-- which is exactly the cost CLAUDE.md called an acceptable trade, and this is
-- the first pass to pay it.
--
-- __Operands are read through the copies the core is full of.__  Two
-- expressions written identically in LLVM rarely arrive here identical.  A
-- @getelementptr@ is lowered to a chain of steps and folding replaces the
-- steps that move nowhere with assignments, so what LLVM wrote twice becomes
-- two chains reading two different locals that hold the same pointer.  So the
-- operands are resolved through what each local is known to be a copy of
-- before two expressions are compared.  Naming the same value the same way is
-- the whole of what makes them comparable, and it is why this is value
-- numbering rather than a text match on instructions.
--
-- Resolving them is for comparing, not for rewriting: the operands written in
-- the program are left as they are.  What a copy comes to is settled on the
-- way out of the core, where reconstruction removes every assignment by
-- carrying its value to the uses, and doing it again here would be a second
-- place to keep that right.
--
-- __Memory does not come into it.__  Nothing shareable reads memory, so a
-- store or a call standing between two computations invalidates nothing, and
-- availability here is about assignment alone.  A load is what it would take
-- to make memory matter, and a load is not shared: what it answers is what
-- memory holds, and this pass says nothing about memory.
--
-- __Nothing moves.__  Availability says the earlier computation already ran on
-- every path that arrives here, so no operation is hoisted anywhere and none
-- runs that would not have run.  A pass that shared a computation into a place
-- it might not have reached would be inventing work, and inventing poison
-- along with it where the operands only make sense on the path that guards
-- them.
--
-- __Equal, flags and all.__  @add nsw@ and @add@ are not the same expression
-- here, though they compute the same number whenever neither overflows.  Where
-- the @nsw@ one overflows it is poison and the plain one is a number, so
-- sharing in one direction — giving the later @nsw@ instruction the plain
-- result — replaces poison with a value and is sound, and sharing in the other
-- spreads poison to where there was none.  Requiring the operations to be
-- equal declines both.  Taking the sound half is a refinement for later, as is
-- reading @add %a, %b@ and @add %b, %a@ as one expression.
--
-- __One walk, so a loop recomputes what it carries in.__  The blocks are
-- walked once, in the order a value can be carried forwards in, and a back
-- edge answers nothing rather than guessing.  Within one turn of a loop that
-- costs nothing — what the body computes twice it computes on one path, and
-- the walk sees both — but an expression worked out before the loop is not
-- available inside it, because the block the loop begins at has a predecessor
-- the walk has not been to.
--
-- Settling that means iterating: initialize every block with everything the
-- function computes anywhere, and take facts away until the sets stop
-- changing, which is where a must-analysis of a graph with cycles has to
-- start.  One walk from nothing cannot reach it — starting empty and growing
-- gives the least solution, and the least solution is precisely the one that
-- says nothing crosses a back edge.  What one walk buys instead is that every
-- fact it has is grounded in a path from the entry that produced it, which is
-- why this is the half to write first.  Under-approximating availability
-- shares less and never shares wrongly.
module Olivine.Core.Pass.CommonSubexpressions
  ( eliminateCommonSubexpressions
  , shareable
  ) where

import Control.Monad (guard)
import Data.List (find, mapAccumL)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Olivine.Core.Blocks (predecessorsOf, reversePostorder)
import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value (TypedValue (..), Value (..))

eliminateCommonSubexpressions :: Program -> Program
eliminateCommonSubexpressions program =
  program {programEntries = map entry (programEntries program)}
  where
    types = namedTypes program
    entry (EFunction f) = EFunction (share types f)
    entry retained = retained

-- | What is known at a point in a function.
--
-- Both halves are killed by the same event — an assignment to a local — which
-- is why they travel together rather than being two analyses.
data Known = Known
  { -- | The expressions worked out already, each with the local holding the
    -- answer and the type of what that local holds, indexed by the locals the
    -- expression reads.
    --
    -- The index is those locals rather than the expression itself for two
    -- reasons.  Keying on the expression would mean an ordering on
    -- operations, which would have to be invented for the calls, attributes
    -- and calling conventions that are never keyed on at all and where an
    -- order would mean nothing.  And the locals an expression reads are
    -- exactly what a reassignment has to invalidate, so the same index that
    -- finds an expression finds everything one assignment takes away.
    --
    -- Expressions reading no locals share the one empty bucket.  Those are
    -- the ones whose operands are all constants, which folding has already
    -- replaced with the value they come to, so the bucket stays as small as
    -- folding leaves it.
    expressions :: Map [Local] [(Operation (TypedValue Local), Local, Type)]
  , -- | What a local is a copy of, where it is a copy of something.  This is
    -- what lets two expressions written the same way be recognized as the
    -- same expression when the operands they read are different locals
    -- holding one value.
    copies :: Map Local (Value Local)
  }

nothingKnown :: Known
nothingKnown = Known Map.empty Map.empty

share :: Map Name Type -> Function -> Function
share types f = f {functionBlocks = map rewrite (functionBlocks f)}
  where
    blocks = functionBlocks f
    order = reversePostorder f
    reachable = Set.fromList order
    byLabel = Map.fromList [(blockLabel b, b) | b <- blocks]

    rewrite b = case Map.lookup (blockLabel b) walked of
      Just (instructions, _) -> b {blockInstructions = instructions}
      -- A block nothing reaches.  No walk arrives at one, so there is nothing
      -- known in it to share from, and nothing it computes reaches anywhere
      -- else to be shared to.
      Nothing -> b

    -- Every reachable block, with what it is left saying and what is known
    -- after it.
    walked :: Map Label ([Instruction], Known)
    walked = foldl' step Map.empty order
      where
        step seen label =
          let block = byLabel Map.! label
              (out, instructions) =
                mapAccumL instruction (entering seen label) (blockInstructions block)
           in Map.insert label (instructions, out) seen

    -- What is known on the way into a block: what every block control can
    -- arrive from was left knowing, and only where they agree.
    --
    -- A predecessor the walk has not reached is across a back edge, and it
    -- answers nothing: what it was left with is what the previous time round
    -- the loop left there, which this walk has not worked out.  The entry
    -- block answers nothing for the same reason read the other way — it has
    -- nothing before it at all.
    entering :: Map Label ([Instruction], Known) -> Label -> Known
    entering seen label =
      case traverse (\p -> snd <$> Map.lookup p seen) (predecessors label) of
        Just (arriving : rest) -> foldl' agreeing arriving rest
        _ -> nothingKnown

    -- Blocks nothing reaches are not predecessors.  The edge one carries is
    -- an edge control never takes, and counting it would leave a block that
    -- is reached with nothing known on the way in.
    predecessors label = filter (`Set.member` reachable) (predecessorsOf blocks label)

    instruction :: Known -> Instruction -> (Known, Instruction)
    instruction known i = (after, maybe i copy held)
      where
        -- The expression this instruction computes, with every operand read
        -- through what it is a copy of.
        operation = resolve known (instructionOperation i)

        -- The local already holding what this computes, if there is one.
        held = do
          guard (shareable operation)
          result <- instructionResult i
          (_, holder, t) <- lookupExpression operation known
          -- The expression can already be held in the very local this assigns
          -- to, which is nothing to rewrite: it is a copy of itself.
          guard (holder /= result)
          pure (TypedValue t (VLocal holder))

        copy value = i {instructionOperation = OAssign value}

        after = case instructionResult i of
          -- Assigns to nothing, so there is nothing it can invalidate.
          Nothing -> known
          Just result
            -- Now a copy of the local that holds the answer, and known to be.
            | Just value <- held -> noted result (typedValue value) remaining
            -- Was written as a copy.  A copy of a copy is a copy of what that
            -- one was a copy of, which resolving the operand has already made
            -- it say.
            | OAssign value <- operation -> noted result (typedValue value) remaining
            | shareable operation
            , -- An expression that reads the local it assigns to is not
              -- available after it.  @%a := add %a, 1@ leaves %a holding what
              -- the expression meant before it ran, and the expression now
              -- means something else.
              result `notElem` localsUsedBy operation ->
                record operation result (resultType types operation) remaining
            -- A call, a load, an allocation: nothing to say about what it left
            -- behind beyond what its assignment took away.
            | otherwise -> remaining
            where
              remaining = kill result known

-- | Whether two runs of an operation with the same operands leave the same
-- value behind.
--
-- Written out case by case with no catch-all, so that an operation added to
-- the grammar later fails to compile here rather than being quietly taken for
-- one whose answer can be reused.
shareable :: Operation operand -> Bool
shareable operation = case operation of
  -- Already an assignment of the value it holds; there is no computation to
  -- do twice.  What it is a copy of is noted rather than shared.
  OAssign _ -> False
  -- May do anything, and may answer differently each time it is asked.
  OCall _ -> False
  -- Fresh storage each time, so two allocations are two objects however alike
  -- the instructions asking for them.
  OAlloca _ -> False
  -- The answer is whatever memory holds, and memory is not what this pass
  -- watches.
  OLoad _ -> False
  -- Leaves nothing behind to share.
  OStore _ -> False
  OBinary _ -> True
  OUnary _ -> True
  OICmp _ -> True
  OFCmp _ -> True
  OConvert _ -> True
  OSelect _ -> True
  OExtractElement _ -> True
  OInsertElement _ -> True
  OShuffleVector _ -> True
  -- Pointer arithmetic reads no memory: it says where something is, not what
  -- is there.
  OOffset _ -> True
  OField _ -> True

-- | An operation with every operand naming the value it stands for, rather
-- than a local that is a copy of it.
--
-- Only an operand that is a local outright is resolved.  One naming a local
-- from inside a constant aggregate is left alone, which shares less and never
-- shares wrongly — and 'localsUsedBy' reaches it anyway, so an assignment to
-- it still invalidates the expression that holds it.
resolve :: Known -> Operation (TypedValue Local) -> Operation (TypedValue Local)
resolve known = fmap (\(TypedValue t value) -> TypedValue t (through value))
  where
    through (VLocal n) = Map.findWithDefault (VLocal n) n (copies known)
    through value = value

lookupExpression ::
  Operation (TypedValue Local) ->
  Known ->
  Maybe (Operation (TypedValue Local), Local, Type)
lookupExpression operation known =
  find
    (\(candidate, _, _) -> candidate == operation)
    (Map.findWithDefault [] (localsUsedBy operation) (expressions known))

record ::
  Operation (TypedValue Local) -> Local -> Type -> Known -> Known
record operation result t known =
  known
    { expressions =
        Map.insertWith
          (<>)
          (localsUsedBy operation)
          [(operation, result, t)]
          (expressions known)
    }

-- | Note that a local holds what a value holds.
--
-- A local said to be a copy of itself is no copy, and saying so would be a
-- name that resolves to itself.
noted :: Local -> Value Local -> Known -> Known
noted result value known
  | value == VLocal result = known
  | otherwise = known {copies = Map.insert result value (copies known)}

-- | What is left known by an assignment to a local.
--
-- Three things go: every expression that reads it, which now means something
-- else; every expression held in it, since it now holds something else; and
-- every copy either of it or of something it was a copy of, for both reasons
-- at once.
kill :: Local -> Known -> Known
kill assigned known =
  Known
    { expressions =
        Map.filter (not . null) $
          Map.map (filter (\(_, holder, _) -> holder /= assigned)) $
            Map.filterWithKey (\localsRead _ -> assigned `notElem` localsRead) $
              expressions known
    , copies =
        Map.filterWithKey
          (\target value -> target /= assigned && value /= VLocal assigned)
          (copies known)
    }

-- | What two paths agree on: the same expression, held in the same local, on
-- both, and the same copies on both.
--
-- Two blocks that worked the same expression out into different locals leave
-- nothing a block below them can name — there is no one local that holds it
-- however control arrived — so requiring the holders to agree is not caution
-- but the whole of what makes the answer nameable.
agreeing :: Known -> Known -> Known
agreeing a b =
  Known
    { expressions =
        Map.filter (not . null) $
          Map.intersectionWith
            (\xs ys -> filter (`elem` ys) xs)
            (expressions a)
            (expressions b)
    , copies =
        Map.mapMaybe id $
          Map.intersectionWith
            (\x y -> if x == y then Just x else Nothing)
            (copies a)
            (copies b)
    }
