-- | Removing instructions whose results nothing reads.
--
-- An instruction can go when nothing reads what it produces and running it
-- changes nothing else.  The second half is the whole difficulty: a store
-- writes memory, a call may do anything, and neither is dead however unread
-- its result.
--
-- __Live is asked at a point, and grown from nothing.__  Both halves matter and
-- the core is why.
--
-- Grown from nothing, because a value can be read only by the computation that
-- produces it.  A loop counter nothing else reads is exactly that: the
-- increment reads the counter and the counter is assigned what the increment
-- produced, so each is read by the other for ever.  Collecting everything
-- anything reads and keeping what is in it — a greatest fixed point — keeps
-- both.  Starting from nothing and adding what the terminators and the
-- instructions with effects read, then what /that/ is computed from, never
-- reaches such a cycle.
--
-- At a point, because a local here can be assigned in more than one place, and
-- "something reads this name" is then not a question about one value.  Loop
-- rotation writes the plainest case: the copy of the header it puts above the
-- loop assigns the same local the header does, so the guard's branch and the
-- loop's branch read one name — and a pass asking whether the name is read
-- anywhere concludes that the loop's assignment to it is needed by a branch
-- that runs before the loop.  Liveness is therefore the ordinary backward walk:
-- what a block needs on the way in, worked out from what its successors need,
-- until it settles.
--
-- The two together are what lets a counter go once the loop has stopped testing
-- it, which is what "Olivine.Core.Pass.StrengthReduce" leaves behind when it
-- rewrites the test to ask about the address instead.
--
-- What may go is judged by 'removableWhenUnused', which is cautious about
-- everything it cannot ask about.  A call it can ask about: what the whole
-- program says the callee does is "Olivine.Core.Effects", and a call that
-- writes no memory, always comes back and never throws is a computation like
-- any other once nothing reads its result.  That is exactly LLVM's own line —
-- @opt -passes=dce@ was given the same call with each of the three promises
-- missing in turn and keeps it every time.
--
-- __A lifetime marker is not a reader.__  It says where storage begins and
-- ends, so a pair of them around a slot nothing else in the function names is
-- a pair of them around nothing: the allocation they bracket is unread, and
-- they are the only reason it looks otherwise.  So the marked address is not
-- counted as a use, and a marker whose slot nothing else uses goes — which
-- leaves the allocation unused, and the sweep after this one takes it.  What
-- makes the case arise is the dead store pass: a slot whose every store it
-- removes is a slot with markers and nothing between them.  @opt@ removes both
-- as well, and promotion and splitting already drop the markers on the slots
-- they take, for the same reason said the other way round.
module Olivine.Core.Pass.DeadCode
  ( eliminateDeadCode
  , removableWhenUnused
  ) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Effects (Behaviour (..), Effects, behaviourOf, effectsOf)
import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Call (..), Load (..))
import Olivine.Syntax.Value (TypedValue)

eliminateDeadCode :: Program -> Program
eliminateDeadCode program =
  program {programEntries = map entry (programEntries program)}
  where
    -- What each call in the module does, read once for the whole program:
    -- every function is asked about every call it makes, and what a callee
    -- does is not a fact about the caller being looked at.
    effects = effectsOf program
    entry (EFunction f) = EFunction (settle effects f)
    entry retained = retained

-- | Removing one instruction can leave another with nothing reading it, so
-- this runs until a sweep finds nothing.
settle :: Effects -> Function -> Function
settle effects f
  | swept == f = f
  | otherwise = settle effects swept
  where
    swept = sweep effects f

sweep :: Effects -> Function -> Function
sweep effects f = f {functionBlocks = map prune (functionBlocks f)}
  where
    needed = liveIn effects f
    prune b = b {blockInstructions = kept effects (namedIn f) (leaving needed b) b}

-- | What is needed on the way out of a block: whatever its successors need on
-- the way in, and what its own terminator reads.
leaving :: Map Label (Set Local) -> Block -> Set Local
leaving needed b =
  Set.union
    (Set.fromList (localsUsedBy (terminatorTransfer (blockTerminator b))))
    (Set.unions [Map.findWithDefault Set.empty target needed | target <- targetsOf (blockTerminator b)])

-- | Every local the function names anywhere, markers aside.
--
-- Asked of the whole function rather than at a point, and only about lifetime
-- markers, which is the one question here that is not about a value: a pair of
-- them around a slot nothing else names is a pair around nothing, wherever the
-- two of them stand.
namedIn :: Function -> Set Local
namedIn f =
  Set.fromList
    ( concat
        [reading (instructionOperation i) | b <- functionBlocks f, i <- blockInstructions b]
        <> [ n
           | b <- functionBlocks f
           , n <- localsUsedBy (terminatorTransfer (blockTerminator b))
           ]
    )

-- | The instructions of a block that stay, given what is needed after it.
--
-- Walked backwards, which is the whole of how a point is told from a name: an
-- instruction assigning a local that nothing below it needs is dead however
-- much is read of that name above it or in another block.
kept :: Effects -> Set Local -> Set Local -> Block -> [Instruction]
kept effects named after b = snd (foldl step (after, []) (reverse (blockInstructions b)))
  where
    step (live, held) i
      | dead = (live, held)
      | otherwise = (Set.union (Set.difference live (defined i)) (Set.fromList (reading (instructionOperation i))), i : held)
      where
        dead = case instructionResult i of
          -- A marker on storage nothing else in the function names, which is
          -- storage with no life to say the bounds of.
          Nothing
            | Just slot <- lifetimeMarked (instructionOperation i) ->
                not (Set.member slot named)
            | otherwise -> False
          Just name ->
            not (Set.member name live)
              && removableWhenUnused (behaviourOf effects) (instructionOperation i)

    defined i = maybe Set.empty Set.singleton (instructionResult i)

-- | What each block needs on the way in.
--
-- The ordinary backward walk, settled by iteration: a block needs what its own
-- instructions read before writing, plus what its successors need and it does
-- not write.  Started from nothing needed anywhere, so what comes out is the
-- least such assignment — which is what leaves a cycle that reads only itself
-- out of it.
liveIn :: Effects -> Function -> Map Label (Set Local)
liveIn effects f = settleNeeds Map.empty
  where
    blocks = functionBlocks f

    settleNeeds needed
      | after == needed = needed
      | otherwise = settleNeeds after
      where
        after = foldl visit needed (reverse blocks)

    visit needed b = Map.insert (blockLabel b) (entering needed b) needed

    entering needed b = foldl step (leaving needed b) (reverse (blockInstructions b))
      where
        step live i
          | dead = live
          | otherwise =
              Set.union
                (Set.difference live (maybe Set.empty Set.singleton (instructionResult i)))
                (Set.fromList (reading (instructionOperation i)))
          where
            dead = case instructionResult i of
              Nothing -> False
              Just name ->
                not (Set.member name live)
                  && removableWhenUnused (behaviourOf effects) (instructionOperation i)

-- | What an instruction reads.
--
-- A lifetime marker reads nothing: see the module header.  The address it names
-- is passed over rather than counted, so that a slot the markers are all that
-- is left of is a slot nothing reads.
reading :: Operation (TypedValue Local) -> [Local]
reading operation = case lifetimeMarked operation of
  Just _ -> []
  Nothing -> localsUsedBy operation

-- | Whether an operation can be dropped when nothing reads its result, given
-- what the program says the calls in it do.
--
-- A store writes memory, so it is not dead however unread its result.  There
-- is no case for a terminator, because a terminator is not one of these: it is
-- a 'Transfer', in a slot of its own, and nothing can hand one to this — which
-- is also why a call standing where a branch stands is never removed here,
-- however little it does.
--
-- __A call goes when all three of its promises hold.__  Writing no memory is
-- not enough on its own: a call that never comes back is what the rest of the
-- function stands behind, and one that throws is a way out of the function
-- that the program can see the effects of.  Reading memory is no reason to
-- keep it, a read leaving nothing behind.
--
-- The rest may go, including division, which is arithmetic that can divide by
-- zero — LLVM makes that undefined rather than a fault to be preserved, so an
-- unread division is as dead as an unread addition.  A load may go too, since
-- reading through a pointer that cannot be read is undefined in the same way,
-- but only when it is not volatile: a volatile load is a side effect that
-- happens to return something.
removableWhenUnused ::
  (Call (TypedValue local) -> Behaviour) -> Operation (TypedValue local) -> Bool
removableWhenUnused made operation = case operation of
  OStore _ -> False
  OCall call ->
    not (writesMemory behaviour)
      && not (mayUnwind behaviour)
      && not (mayNotReturn behaviour)
    where
      behaviour = made call
  OLoad l -> not (loadVolatile l)
  -- An atomic is an ordering as much as an access, and an ordering nothing
  -- reads is not an ordering nothing does: another thread reads it.  That
  -- holds of the loads as much as of the writes, so none of them goes.
  OAtomicLoad _ -> False
  OAtomicStore _ -> False
  OAtomicRmw _ -> False
  OCmpXchg _ -> False
  OFence _ -> False
  -- A landing pad is where an unwinder resumes the function, so it is not a
  -- computation that can be skipped for being unread: taking it away leaves an
  -- invoke unwinding to a block that has none.
  OLandingPad _ -> False
  _ -> True
