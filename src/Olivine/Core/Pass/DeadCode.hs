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

import Olivine.Core.Program
import Olivine.Syntax.Instruction (Load (..), Operation (..), isTerminator)
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Operands (localsUsedBy)
import Olivine.Syntax.Value (Value (..), typedValue)

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
        name `Set.member` used || not (removable (instructionOperation i))
    removable (Assign _) = True
    removable (Perform operation) = removableWhenUnused operation

-- | Every local the function reads.
usedIn :: Function -> Set Name
usedIn f =
  Set.fromList
    ( concat
        [ readBy (instructionOperation i)
        | b <- functionBlocks f
        , i <- blockInstructions b
        ]
        <> [ n
           | b <- functionBlocks f
           , n <- localsUsedBy (terminatorOperation (blockTerminator b))
           ]
    )
  where
    readBy (Perform operation) = localsUsedBy operation
    readBy (Assign value) = case typedValue value of
      VLocal n -> [n]
      _ -> []

-- | Whether an operation can be dropped when nothing reads its result.
--
-- A terminator never can: it is what carries control onwards, and its result
-- is not the point.  A store writes memory and a call may do anything.
--
-- The rest may go, including division, which is arithmetic that can divide by
-- zero — LLVM makes that undefined rather than a fault to be preserved, so an
-- unread division is as dead as an unread addition.  A load may go too, since
-- reading through a pointer that cannot be read is undefined in the same way,
-- but only when it is not volatile: a volatile load is a side effect that
-- happens to return something.
removableWhenUnused :: Syntax.Operation label -> Bool
removableWhenUnused operation
  | isTerminator operation = False
  | otherwise = case operation of
      OStore _ -> False
      OCall _ -> False
      OLoad l -> not (loadVolatile l)
      _ -> True
