-- | The optimizer proper: a list of passes applied in order.
--
-- A pass is a pure function from program to program, so asking whether it
-- changed anything is just @(/=)@ on its result — passes never report that
-- themselves.  That is also what makes iterating to a fixed point safe to
-- express directly.
module Olivine.Pipeline
  ( Pass (..)
  , passes
  , optimize
  , stages
  , fixpoint
  ) where

import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.ControlFlow (simplifyControlFlow)
import Olivine.Core.Pass.DeadCode (eliminateDeadCode)
import Olivine.Core.Pass.DeadStores (eliminateDeadStores)
import Olivine.Core.Pass.DeadSymbols (eliminateDeadSymbols)
import Olivine.Core.Pass.Fold (foldOperations)
import Olivine.Core.Pass.IfConversion (convertBranches)
import Olivine.Core.Pass.Inline (inlineCalls)
import Olivine.Core.Pass.LoopInvariants (hoistLoopInvariants)
import Olivine.Core.Pass.LoopRotation (rotateLoops)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Pass.Redundancies (eliminateRedundancies)
import Olivine.Core.Pass.Split (splitAggregates)
import Olivine.Core.Pass.TailRecursion (eliminateTailRecursion)
import Olivine.Core.Program (Program)
import Olivine.Core.Raise (raise)
import Olivine.Syntax.Ast (Module)
import Olivine.Syntax.Debug (stripDebugInfo)

data Pass = Pass
  { passName :: String
  , runPass :: Program -> Program
  }

-- | The pipeline.
passes :: [Pass]
-- Splitting first, because it is what turns a struct a front end put on the
-- stack into storage promotion can take at all.  A slot holding a whole struct
-- is not a local waiting to be found: it is one allocation the program reads a
-- field at a time, and every one of those reads is a step off its address that
-- promotion has to treat as an escape.  Splitting is the only pass that makes
-- another slot promotable, which is why it goes above the pass the whole order
-- below is built on rather than being another thing to run again afterwards.
--
-- Promotion next, because until a slot becomes a local nothing that follows
-- can see through it: a value arrives at a use through a store and a load, and
-- folding reads operands.  This is the ordering the whole pipeline stands on —
-- unoptimized input is mostly memory traffic, and every pass after this one
-- works on what promotion turns that traffic into.
--
-- Inlining second, because it is what gives the passes after it something to
-- work on that they could not otherwise see: an argument becomes an
-- assignment, so a constant handed to a function is a constant inside it, and
-- everything below reads operands.  It runs after promotion rather than before
-- so that the size it judges a callee by is the size of what the callee does,
-- not the size of the memory traffic an unoptimized front end wrapped it in.
--
-- What that order costs is the other direction: a slot whose address is only
-- ever handed to a function that gets inlined becomes promotable exactly then,
-- and promotion has already run.  That is the same argument promotion makes
-- about the dead code pass, and the same answer — a reason to run the pipeline
-- again, not to run a pass twice inside it.
--
-- Folding next, since it leaves the instructions it replaced assigning to
-- nothing anyone reads, which is exactly what the dead code pass takes away.
-- What it settles is not only the computations whose operands are constants:
-- an operation an operand makes do nothing comes to that operand, and a
-- conversion of a conversion comes to one conversion or none.  Inlining is
-- what puts a caller's constant into a callee's arithmetic, and promotion is
-- what makes a value that travelled through a slot into an operand at all, so
-- both of those give this more to work on than the source had.
--
-- Tail recursion next, because what it makes is a loop and everything below
-- here that knows about loops is below here.  It comes after inlining, which is
-- what can put a call to @f@ in @f@ by copying in a body that made one, and
-- after promotion, which is what turns the slot a front end returns through
-- into the assignments this has to read the call's result through: at @-O0@ the
-- value goes call, store, load, @ret@, and only the middle two of those go away.
-- Folding first buys nothing in particular and costs nothing either; what it
-- would cost to run this later is the whole of what the loop passes do with the
-- loop it makes.
--
-- Loop rotation after those and before the rest, because what it does for the
-- passes below it is change the shape of a loop rather than anything in it.  It
-- comes after inlining, which is what brings a loop into the function that will
-- run it, and after folding, so that the copy it makes of a header is a copy of
-- the folded one.  It comes before control flow because it leaves the loop as
-- two blocks the graph has no reason to keep apart, and merging them is what
-- makes the body and the test one block; before the redundancies for the same
-- reason, that pass reading a block at a time; and before hoisting, which is
-- what collects on all of it.  A body that may never run holds loads that
-- cannot be taken out of the loop, and rotating makes the body the block the
-- loop is certain to run.
--
-- Control flow after inlining as well as after folding: inlining leaves the
-- block it split in two joined by an unconditional branch, and a callee of one
-- block joined to both halves the same way, which is precisely what block
-- merging puts back together.
--
-- Control flow after that, because what folding settles about a condition is
-- of no use until the branch on it is rewritten, and folding will not do that:
-- a branch is the shape of the function rather than a value in it.  The cost of
-- this order rather than the other is that a slot whose address escapes only in
-- a block nothing reaches is not promoted, since promotion runs before the
-- block goes.
--
-- If-conversion after control flow, because the diamond it looks for has to be
-- the real one: at @-O0@ one of the two sides of an @else if@ arrives as a block
-- that forwards to the side proper, and a side that does not branch to the join
-- is not recognized as one.  It is the same reason hoisting wants that pass to
-- have run.  What it leaves behind is a block that branches to a join reached
-- from nowhere else, and it puts those together itself rather than being a reason
-- to run control flow a second time.
--
-- Before the redundancies, so that the two sides brought into one block are one
-- block for the availability walk to look at, and so that what the selects read
-- is what everything else in that block reads.  And before hoisting, which
-- collects on it twice over: a conditional in a loop body that becomes a select
-- is a body with no branch left in it, and the block it becomes is the header of
-- a rotated loop, where a load may be taken out.
--
-- Redundancies after all of those, because every one of them makes two
-- computations that were written differently into the same expression:
-- promotion turns a value that travelled through memory into the local both
-- sides read, inlining brings two copies of a callee's arithmetic into one
-- function with the same arguments bound in each, folding settles the indices
-- of two pointer steps to the same constant, and merging two blocks into one
-- puts both computations where a single walk of the blocks sees them.
--
-- What that pass says about memory wants the same order for a reason of its
-- own.  A load it can answer from an earlier access is one whose address it can
-- tell from the addresses written in between, and promotion has already taken
-- away the traffic where the question does not arise — a slot that became a
-- local is not memory any more.  What is left is the accesses that go through a
-- pointer, and inlining is what brings a callee's into the same function as the
-- caller's, where one can answer the other and where the callee's own storage
-- is storage this function can see the whole life of.
--
-- Hoisting loop invariants after those, and after the redundancies in
-- particular.  A computation written twice in a loop body is one computation and
-- one copy of it by the time this sees it, so what leaves the loop is one
-- arithmetic instruction and a copy that costs nothing; without sharing first it
-- would be the same computation hoisted twice.  The same holds of the loads it
-- takes out, and for the same reason with memory in it: two reads of one address
-- in a body are one read and a copy already, and promotion has taken away the
-- traffic through slots that became locals, so what this has to ask the aliasing
-- about is what is genuinely left.  It also wants the control flow
-- graph to be the real one, since what it moves and where it moves it are both
-- decided by the graph: a detour block that forwarding has not yet removed is a
-- block in the loop body, and a block nothing reaches is a predecessor of the
-- header that a preheader would have to be put in front of.
--
-- Most loops cost it no block at all: a loop a front end wrote is entered from
-- one block that branches nowhere else, and that block is the preheader
-- already.  Where the loop is entered from a branch, or from two places, the
-- block it makes stays — merging will not take it back, the block above it
-- having somewhere else to go — and that is the price of there being anywhere to
-- put the value at all.
--
-- And before the dead code pass, which is what collects on it: an instruction
-- that becomes a copy of an earlier result stops reading the operands it was
-- computed from, and whatever was computed only to be one of those operands is
-- then read by nothing.
--
-- Dead stores after all of the above and before the dead code pass, for the
-- same reason and one of its own.  The reason of its own is that it reads
-- memory backwards where the redundancies pass reads it forwards, and what
-- that pass leaves is a function with fewer loads in it: a load it answered
-- from an earlier access is now a copy, and every load it removes is a read
-- that no longer keeps a store above it alive.  The shared reason is that a
-- store it takes away was the only thing reading the value stored and often
-- the only thing reading the address, and the pass that collects those is the
-- next one.
--
-- Dead symbols last, since it is the one pass that reads what the others
-- leave: folding a @select@ between two function pointers settles which of
-- them the program can still reach, a block that control flow removed makes
-- the calls in it no longer calls, and dead code removing the last load of a
-- global settles whether the global is read at all.  Nothing that runs before
-- it can know any of them.
passes =
  [ Pass "aggregate splitting" splitAggregates
  , Pass "memory promotion" promoteMemory
  , Pass "inlining" inlineCalls
  , Pass "folding" foldOperations
  , Pass "tail recursion" eliminateTailRecursion
  , Pass "loop rotation" rotateLoops
  , Pass "control flow" simplifyControlFlow
  , Pass "if conversion" convertBranches
  , Pass "redundancies" eliminateRedundancies
  , Pass "loop invariants" hoistLoopInvariants
  , Pass "dead stores" eliminateDeadStores
  , Pass "dead code" eliminateDeadCode
  , Pass "dead symbols" eliminateDeadSymbols
  ]

-- | Read a module, lower it to the core representation, run the passes, and
-- put it back.
--
-- Lowering and raising happen either side of the passes rather than being
-- each pass's business, so a pass never sees the syntax layer.
optimize :: Module -> Module
optimize = raise . snd . last . stages

-- | The core program at every point something can look at it: as it was read,
-- and then as each pass in turn leaves it, under a label saying which that is.
--
-- What wants this is the verifier.  A program that arrives whole and leaves
-- broken was broken by one particular pass, and the only way to say which is
-- to look in between; a pass being a pure function from program to program is
-- what makes the intermediate results there to be looked at.
-- The debug information goes before the lowering rather than in a pass of its
-- own, because it is not an optimization and there is no point in the
-- pipeline at which keeping it would have been useful.  A pass is a function
-- from program to program and this is a function from module to module: what
-- it takes out lives in the syntax layer, where a metadata node is an entry
-- and an attachment is a field, and the core carries both through untouched.
-- See "Olivine.Syntax.Debug" for what goes and what stays.
stages :: Module -> [(String, Program)]
stages m = scanl step ("as read", lower (stripDebugInfo m)) passes
  where
    step (_, program) pass = ("after " <> passName pass, runPass pass program)

-- | Apply a transformation until it stops changing the program.
fixpoint :: Eq a => (a -> a) -> a -> a
fixpoint f x = let x' = f x in if x' == x then x else fixpoint f x'
