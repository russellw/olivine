-- | Removing instructions whose results nothing reads.
--
-- An instruction can go when nothing reads what it produces and running it
-- changes nothing else.  The second half is the whole difficulty: a store
-- writes memory, a call may do anything, and neither is dead however unread
-- its result.
--
-- What may go is judged by 'removableWhenUnused', which is deliberately
-- cautious.  It says nothing about calls, so no call is ever removed, even
-- one to a function that plainly does nothing — proving that is a question
-- about the whole program and this pass looks at one function at a time.
module Olivine.Core.Pass.DeadCode
  ( eliminateDeadCode
  , removableWhenUnused
  ) where

import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Load (..))

eliminateDeadCode :: Program -> Program
eliminateDeadCode program =
  program {programEntries = map entry (programEntries program)}
  where
    entry (EFunction f) = EFunction (settle f)
    entry retained = retained

-- | Removing one instruction can leave another with nothing reading it, so
-- this runs until a sweep finds nothing.
settle :: Function -> Function
settle f
  | swept == f = f
  | otherwise = settle swept
  where
    swept = sweep f

sweep :: Function -> Function
sweep f = f {functionBlocks = map prune (functionBlocks f)}
  where
    used = usedIn f
    prune b = b {blockInstructions = filter keep (blockInstructions b)}
    keep i = case instructionResult i of
      Nothing -> True
      Just name ->
        name `Set.member` used || not (removableWhenUnused (instructionOperation i))

-- | Every local the function reads.
usedIn :: Function -> Set Local
usedIn f =
  Set.fromList
    ( concat
        [ localsUsedBy (instructionOperation i)
        | b <- functionBlocks f
        , i <- blockInstructions b
        ]
        <> [ n
           | b <- functionBlocks f
           , n <- localsUsedBy (terminatorTransfer (blockTerminator b))
           ]
    )

-- | Whether an operation can be dropped when nothing reads its result.
--
-- A store writes memory and a call may do anything, so neither is dead
-- however unread its result.  There is no case for a terminator, because a
-- terminator is not one of these: it is a 'Transfer', in a slot of its own,
-- and nothing can hand one to this.
--
-- The rest may go, including division, which is arithmetic that can divide by
-- zero — LLVM makes that undefined rather than a fault to be preserved, so an
-- unread division is as dead as an unread addition.  A load may go too, since
-- reading through a pointer that cannot be read is undefined in the same way,
-- but only when it is not volatile: a volatile load is a side effect that
-- happens to return something.
removableWhenUnused :: Operation local -> Bool
removableWhenUnused operation = case operation of
  OStore _ -> False
  OCall _ -> False
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
