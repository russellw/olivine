-- | Removing instructions whose results nothing reads.
--
-- An instruction can go when nothing reads what it produces and running it
-- changes nothing else.  The second half is the whole difficulty: a store
-- writes memory, a call may do anything, and neither is dead however unread
-- its result.
--
-- __What is live grows from what has to stay; it is not what is left after
-- removing the unread.__  The two are different wherever a value is read only
-- by the computation that produces it.  A loop counter nothing else reads is
-- exactly that: the increment reads the counter and the counter is assigned
-- what the increment produced, so each of the two is read by the other and a
-- sweep that keeps whatever anything reads keeps both for ever.  Starting from
-- the instructions that must stay — the ones with effects, and the terminators
-- — and adding what they read, then what /that/ is computed from, never reaches
-- a cycle nothing outside it needs.  That is the difference between a greatest
-- fixed point and a least one, and it is why a loop whose test has been
-- rewritten to ask about something else loses its counter here rather than
-- keeping it as a phi nobody reads.
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
    used = liveIn effects f
    prune b = b {blockInstructions = filter keep (blockInstructions b)}
    keep i = case instructionResult i of
      -- A marker on storage nothing else in the function names, which is
      -- storage with no life to say the bounds of.
      Nothing
        | Just slot <- lifetimeMarked (instructionOperation i) -> Set.member slot used
        | otherwise -> True
      Just name ->
        name `Set.member` used
          || not (removableWhenUnused (behaviourOf effects) (instructionOperation i))

-- | Every local the function needs the value of.
--
-- Grown rather than collected: what the terminators read and what the
-- instructions that cannot go read, and then whatever those are computed from,
-- until it stops growing.  Collecting instead — every local anything reads —
-- would answer with the locals a dead cycle reads of itself, which is the whole
-- point of doing it this way round; see the module header.
--
-- An instruction that stays for its effects contributes what it reads whether
-- or not anything reads /it/, since it is going to run.  An assignment to a
-- live local contributes too, and all of them do: a local the core assigns in
-- several places holds what any of them left, so needing its value needs every
-- one of them.
--
-- A lifetime marker reads nothing: see the module header.  The address it names
-- is passed over rather than counted, so that a slot the markers are all that
-- is left of is a slot nothing reads.
liveIn :: Effects -> Function -> Set Local
liveIn effects f = grow (Set.fromList (concatMap rooted instructions <> leaving))
  where
    instructions = [i | b <- functionBlocks f, i <- blockInstructions b]

    leaving =
      [ n
      | b <- functionBlocks f
      , n <- localsUsedBy (terminatorTransfer (blockTerminator b))
      ]

    -- What an instruction that is staying regardless reads.
    rooted i
      | removableWhenUnused (behaviourOf effects) (instructionOperation i) = []
      | otherwise = reading (instructionOperation i)

    grow known
      | Set.null added = known
      | otherwise = grow (Set.union known added)
      where
        added =
          Set.difference
            ( Set.fromList
                [ n
                | i <- instructions
                , Just name <- [instructionResult i]
                , Set.member name known
                , n <- reading (instructionOperation i)
                ]
            )
            known

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
