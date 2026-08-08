-- | Work in a loop that is a fixed amount further along each turn, computed by
-- going that much further rather than from the counter.
--
-- A loop over an array computes an address from its counter every turn:
-- multiply the counter by the stride, widen it, add it to the base.  None of
-- that depends on the counter except through what it was last turn, so it can
-- be done once where the loop is entered and then advanced — which is the
-- oldest loop optimization there is and is what the name means.  Two shapes are
-- taken, and they are the two a front end writes:
--
--   * @i * K@ for a constant @K@, which advances by @K * step@.
--   * @getelementptr T, base, i@, which advances by @step@ elements along the
--     pointer it already computed.  This is the one worth having: it takes the
--     multiply the stride implies /and/ the widening of the counter with it,
--     since nothing reads the widened counter afterwards.
--
-- __The counter is left alone.__  What is added is a second thing counted
-- beside it, not a replacement: the loop still tests the counter, and rewriting
-- that test in terms of the address is a further step — LLVM calls it linear
-- function test replacement — that has to know the loop is entered at all.  So
-- a loop keeps its counter and its increment, and what goes is the multiply and
-- the widening, which is where the work per turn actually is.
--
-- __Widening the counter needs the loop to promise it does not wrap.__  An
-- index arrives at a @getelementptr@ as @sext i32 %i to i64@, and
-- @sext (i + step)@ is @sext i + step@ only while the addition does not
-- overflow a signed @i32@.  That promise is the @nsw@ the front end writes on
-- the increment, and 'counterNoWrap' is it.  The same promise is wanted for an
-- unwidened index, for the same reason one step down: a @getelementptr@ reads a
-- narrow index as a signed number and scales it, so a counter that wrapped from
-- the top of @i32@ to the bottom names an address a long way below the last
-- one, where advancing names the address just above it.
--
-- A multiply wants no such promise.  Multiplication distributes over addition
-- in the wrapped arithmetic as well as the true kind, so @(i + step) * K@ and
-- @i * K + step * K@ are the same bits whether or not the counter wrapped.
--
-- __What the loop is entered with is computed, not worked out.__  The first
-- value goes in the preheader as the very computation it replaces, reading the
-- counter as it stands there — so nothing here has to know what the counter
-- starts at, and a loop whose start and bound are both unknown is reduced like
-- any other.  That is the difference between this and unrolling:
-- 'Olivine.Core.Induction.turnsOf' answers for the loops that can be run to the
-- end, 'countersOf' answers for the rest, and the rest is where the run time is.
module Olivine.Core.Pass.StrengthReduce
  ( reduceStrength
  ) where

import Control.Monad (guard)
import Data.List (find)
import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Induction
  ( Counter (..)
  , countersOf
  , enteringValues
  , originAt
  , producedAfter
  , producedAt
  )
import Olivine.Core.Instruction
import Olivine.Core.Loops (Loop (..), loopsOf, enterThrough, preheaderFor)
import Olivine.Core.Program
import Olivine.Syntax.Instruction
  ( Binary (..)
  , BinaryOp (..)
  , Compare (..)
  , Convert (..)
  , IntPredicate (..)
  )
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value (CastOp (..), TypedValue (..), Value (..), isConstant)

-- | What one computation in a loop becomes when it is counted beside the
-- counter instead of computed from it.
--
-- Both halves are given the same local to count in and compute into scratch
-- locals of their own beside it, because a local written twice must be written
-- by assignments both times — the core's one rule about reassignment.  So what
-- is computed where the loop is entered and what is computed at the end of it
-- are two instructions assigning two different locals, each followed by an
-- assignment to the one they are counted in.
data Reduction = Reduction
  { -- | The local in the loop whose computation this replaces.  It becomes a
    -- copy of what is counted, so everything reading it still reads it.
    reducedResult :: Local
  , -- | The type of what is counted, which the copies are written at.
    reducedType :: Type
  , -- | What goes where the loop is entered, ending in an assignment to the
    -- local it is given.
    reducedEntry :: Local -> [Instruction]
  , -- | What goes at the end of the loop, ending in an assignment to the same.
    reducedStep :: Local -> [Instruction]
  , -- | Where what is counted is a pointer walking an array, what it walks.
    -- 'replacingTest' is the only reader: to say where a walk ends you have to
    -- know what it started from and what it steps over.
    reducedWalk :: Maybe Walk
  }

-- | A pointer counted along an array: where it starts and what it steps over.
data Walk = Walk
  { walkBase :: Value Local
  , walkElement :: Type
  }

-- | Replacing the loop's test with one on what is counted rather than on the
-- counter: what that adds where the loop is entered, what it adds at the end of
-- the block, and what the branch reads instead.
data Replacement = Replacement
  { replacementEntry :: [Instruction]
  , replacementStep :: [Instruction]
  , replacementCondition :: TypedValue Local
  }

reduceStrength :: Program -> Program
reduceStrength program =
  program {programEntries = map entry (programEntries program)}
  where
    entry (EFunction f) = EFunction (settle f)
    entry retained = retained

-- | One computation reduced at a time, and again until none is left.
--
-- One at a time because reducing one rewrites the block the next is found in,
-- and both the loops and the preheader are read off the function as it stands.
-- It stops because each round replaces a computation that reads the counter
-- with a copy, and what it writes into the loop reads only what it wrote there
-- the turn before — so the computations that qualify are one fewer each time.
settle :: Function -> Function
settle f = case mapMaybe (reduce f) (loopsOf f) of
  reduced : _ -> settle reduced
  [] -> f

-- | The first computation in this loop worth counting beside the counter,
-- rewritten to be counted — and, where it is a walk along an array and the
-- loop's test is on the counter alone, that test rewritten too.
reduce :: Function -> Loop -> Maybe Function
reduce f loop = do
  body <- find ((== loopHeader loop) . blockLabel) (functionBlocks f)
  preheader <- preheaderFor f loop
  counters <- Just (countersOf f loop)
  reduction <-
    firstOf
      [ candidates body (written body) (startedAt counter) counter
      | counter <- counters
      ]
  let counted = nextLocal f
      replacement =
        firstOf
          [ maybe [] pure (replacingTest body (written body) counter reduction counted)
          | counter <- counters
          ]
  pure
    ( enterThrough
        ( rewritten
            body
            reduction
            counted
            (reducedStep reduction counted <> foldMap replacementStep replacement)
            (fmap replacementCondition replacement)
        )
        loop
        preheader
        (reducedEntry reduction counted <> foldMap replacementEntry replacement)
        Nothing
    )
  where
    -- In the loop the computation becomes a copy of what is counted, and the
    -- step goes at the end of the block — after the counter's own increment, so
    -- that what stands at the top of the next turn is what that turn would have
    -- computed.  A replaced test goes after the step, since what it reads is
    -- what the step just left.
    rewritten body reduction counted advanced condition =
      f
        { functionBlocks =
            [ if blockLabel b == blockLabel body
                then
                  b
                    { blockInstructions = map replace (blockInstructions b) <> advanced
                    , blockTerminator = maybe (blockTerminator b) (asking b) condition
                    }
                else b
            | b <- functionBlocks f
            ]
        }
      where
        replace i
          | instructionResult i == Just (reducedResult reduction) =
              i
                { instructionOperation =
                    OAssign (TypedValue (reducedType reduction) (VLocal counted))
                }
          | otherwise = i

        asking b value = case terminatorTransfer (blockTerminator b) of
          CondBr _ takenIf takenElse ->
            (blockTerminator b) {terminatorTransfer = CondBr value takenIf takenElse}
          _ -> blockTerminator b

    written body =
      Set.fromList [name | i <- blockInstructions body, Just name <- [instructionResult i]]

    -- What the counter holds where the loop is entered, where the blocks above
    -- it settle that.  Writing the number down rather than reading the counter
    -- is worth doing because folding cannot find it: a constant assigned in one
    -- block and read in the preheader is exactly what block-local folding does
    -- not see, and what is left otherwise is a widening of a constant and a
    -- step of nothing, computed once and read once for no reason.
    startedAt counter =
      case Map.lookup (counterLocal counter) (enteringValues f loop) of
        Just value | isConstant value -> value
        _ -> VLocal (counterLocal counter)

    firstOf xs = case concat xs of
      x : _ -> Just x
      [] -> Nothing

-- | The loop's test rewritten to ask about the walk rather than about the
-- counter, so that nothing reads the counter and it goes.
--
-- __Only where the counter steps by one.__  The test becomes @p \< end@ with
-- @end@ the address the counter's bound names, and that is the same question as
-- @i \< n@ only while the addresses run in the same order as the indices.  For
-- a step of one every address compared lies between the base and one past the
-- last element the loop reads, which are addresses of one object — objects do
-- not wrap, so the order is the index order.  A larger step can land further
-- past the end than that, where the argument runs out; LLVM's own replacement
-- handles it by working out the exit value exactly, which is the closed form
-- this module does without.
--
-- __And only where the test is what closes the loop.__  What is read is the
-- condition of the branch that goes round again, at the end of the block, where
-- the counter has already been stepped — so the comparison is on the value the
-- next turn would start with, which is what the walk holds after its own step.
replacingTest :: Block -> Set Local -> Counter -> Reduction -> Local -> Maybe Replacement
replacingTest body inLoop counter reduction counted = do
  walk <- reducedWalk reduction
  guard (counterStep counter == 1)
  CondBr condition takenIf takenElse <- Just (terminatorTransfer (blockTerminator body))
  -- The true edge has to be the one that goes round.  Where it is the false
  -- edge the test says when to leave, and the replacement would have to be the
  -- other comparison; rotation writes the first shape and this declines the
  -- second rather than working out its opposite.
  guard (takenIf == blockLabel body && takenElse /= blockLabel body)
  (known, test) <- comparing condition
  guard (comparePredicate test == ISlt)
  guard (againstCounter known (compareLeft test))
  bound <- invariant known (compareRight test)
  pure
    Replacement
      { replacementEntry =
          [ Instruction
              (Just ending)
              ( OOffset
                  Offset
                    { offsetFlags = []
                    , offsetElementType = walkElement walk
                    , offsetPointer = TypedValue (reducedType reduction) (walkBase walk)
                    , offsetIndex = bound
                    }
              )
              []
          ]
      , replacementStep =
          [ Instruction
              (Just asked)
              ( OICmp
                  Compare
                    { compareFlags = []
                    , comparePredicate = IUlt
                    , compareLeft = TypedValue (reducedType reduction) (VLocal counted)
                    , compareRight = TypedValue (reducedType reduction) (VLocal ending)
                    }
              )
              []
          ]
      , replacementCondition = TypedValue (TInteger 1) (VLocal asked)
      }
  where
    Local next = counted
    ending = Local (next + 4)
    asked = Local (next + 5)

    -- The condition as it stands at the end of the block, which is where the
    -- branch reads it, together with what was in hand there.
    comparing condition = case typedValue condition of
      VLocal held -> case producing known held of
        Just (OICmp test) -> Just (known, test)
        _ -> Nothing
        where
          known = producedAfter (blockInstructions body)
      _ -> Nothing

    -- The test asks about the counter as it stands at the end of the block,
    -- which is the value the next turn starts with and not the local's name:
    -- the counter has been assigned again by then, so what it holds there is
    -- what its increment produced.  Asking whether the operand and the counter
    -- name one value /at that point/ is the whole of the condition, and it is
    -- why both sides are read through 'originAt' rather than one of them
    -- compared to a name.
    againstCounter known operand = case typedValue operand of
      VLocal held -> originAt known held == originAt known (counterLocal counter)
      _ -> False

    -- The bound as the block above the loop can name it: a constant, or a local
    -- the loop does not itself assign.
    invariant known operand = case typedValue operand of
      VLocal held
        | let base = originAt known held
        , not (Set.member base inLoop) ->
            Just operand {typedValue = VLocal base}
      VLocal _ -> Nothing
      _ -> Just operand

    producing known held = case Map.lookup held known of
      Just (OAssign (TypedValue _ (VLocal copied))) -> producing known copied
      other -> other

-- | The computations in this block that are a fixed amount further along each
-- turn.
--
-- Operands are read through the copies, which is not optional: promotion turns
-- every load of the counter's slot into a copy, so the index of the very
-- @getelementptr@ this is looking for names a copy of the counter and never the
-- counter.  Reading them positionally is what keeps that from also matching the
-- counter's own increment, whose operand is a copy too — see 'originAt'.
--
-- What is written where the loop is entered therefore reads the counter itself
-- rather than the operand as written, since the copy is made inside the loop
-- and a block above it cannot read what that holds.  Same for the base of the
-- step: a base the loop computes is declined, and a base the loop copies is
-- read as what it copies.
candidates :: Block -> Set Local -> Value Local -> Counter -> [Reduction]
candidates body inLoop start counter =
  [ reduction
  | (i, known) <- producedAt (blockInstructions body)
  , Just result <- [instructionResult i]
  , Just reduction <- [reductionFor known result (instructionOperation i)]
  ]
  where
    name = counterLocal counter
    step = counterStep counter

    reductionFor known result operation = case operation of
      -- @i * K@, which advances by @K * step@ a turn and wants no promise about
      -- wrapping: multiplication distributes over addition in the wrapped
      -- arithmetic as well as the true kind.
      OBinary b
        | binaryOp b == OpMul
        , Just k <- multiplier known b ->
            Just
              Reduction
                { reducedResult = result
                , reducedType = counted
                , reducedEntry = \into ->
                    computing
                      into
                      1
                      ( OBinary
                          b
                            { binaryLeft = TypedValue counted start
                            , binaryRight = TypedValue counted (VInteger k)
                            }
                      )
                      counted
                , reducedStep = \into ->
                    computing
                      into
                      3
                      ( OBinary
                          Binary
                            { binaryOp = OpAdd
                            , -- The multiply's flags say nothing about this
                              -- addition, which is another operation on other
                              -- numbers.
                              binaryFlags = []
                            , binaryLeft = TypedValue counted (VLocal into)
                            , binaryRight = TypedValue counted (VInteger (k * step))
                            }
                      )
                      counted
                , reducedWalk = Nothing
                }
        where
          counted = typedValueType (binaryLeft b)
      -- A step along a pointer by the counter, which advances by @step@
      -- elements a turn.
      OOffset o
        | counterNoWrap counter
        , Just base <- outsideBase known o
        , Just widened <- indexing known o ->
            Just
              Reduction
                { reducedResult = result
                , reducedType = pointer
                , reducedEntry = \into ->
                    widened into
                      <> computing
                        into
                        2
                        ( OOffset
                            o
                              { offsetPointer = TypedValue pointer base
                              , offsetIndex = TypedValue indexType (started into)
                              }
                        )
                        pointer
                , reducedStep = \into ->
                    computing
                      into
                      3
                      ( OOffset
                          o
                            { -- The flags go.  What the original promised was
                              -- about the one step it made from the base; this
                              -- steps from wherever the last turn left off, and
                              -- the last step of all lands one place past
                              -- anything a turn read.
                              offsetFlags = []
                            , offsetPointer = TypedValue pointer (VLocal into)
                            , offsetIndex = TypedValue indexType (VInteger step)
                            }
                      )
                      pointer
                , reducedWalk = Just Walk {walkBase = base, walkElement = offsetElementType o}
                }
        where
          pointer = typedValueType (offsetPointer o)
          indexType = typedValueType (offsetIndex o)
          -- The counter itself where the index was the counter, and the
          -- widening made again above the loop where it was widened.
          started into
            | widensHere = VLocal (at into 1)
            | otherwise = start
          widensHere = case typedValue (offsetIndex o) of
            VLocal held -> originAt known held /= name
            _ -> False
      _ -> Nothing

    -- An instruction computing into a scratch local, and the assignment that
    -- makes what it computed the value counted.
    computing into offset operation t =
      [ Instruction (Just (at into offset)) operation []
      , Instruction (Just into) (OAssign (TypedValue t (VLocal (at into offset)))) []
      ]

    at (Local n) k = Local (n + k)

    multiplier known b = case (resolved known (binaryLeft b), typedValue (binaryRight b)) of
      (Just held, VInteger k) | held == name -> Just k
      _ -> case (typedValue (binaryLeft b), resolved known (binaryRight b)) of
        (VInteger k, Just held) | held == name -> Just k
        _ -> Nothing

    resolved known operand = case typedValue operand of
      VLocal held -> Just (originAt known held)
      _ -> Nothing

    -- The base as something the block above the loop can name: what the operand
    -- ultimately names, and only if the loop does not compute it.
    outsideBase known o = case typedValue (offsetPointer o) of
      VLocal held
        | let base = originAt known held
        , not (Set.member base inLoop) ->
            Just (VLocal base)
      VLocal _ -> Nothing
      constant -> Just constant

    -- The index is the counter, or the counter widened.  Where it is widened,
    -- the widening is made again where the loop is entered.
    indexing known o = case typedValue (offsetIndex o) of
      VLocal held
        | originAt known held == name -> Just (const [])
        | otherwise -> case widening known held of
            Just c ->
              Just
                ( \into ->
                    [ Instruction
                        (Just (at into 1))
                        (OConvert c {convertOperand = TypedValue (counterType counter) start})
                        []
                    ]
                )
            Nothing -> Nothing
      _ -> Nothing

    -- Only a signed widening, and only of the counter.  An unsigned one is not
    -- covered by the promise read here: @nsw@ says the count does not overflow
    -- read as signed, and a counter stepping from below zero to above it wraps
    -- an unsigned widening while keeping that promise.
    widening known held = case producing known held of
      Just (OConvert c)
        | convertOp c == CastSExt
        , Just from <- resolved known (convertOperand c)
        , from == name ->
            Just c
      _ -> Nothing

    producing known held = case Map.lookup held known of
      Just (OAssign (TypedValue _ (VLocal copied))) -> producing known copied
      other -> other
