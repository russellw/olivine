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
import Olivine.Core.Pass.ConstantFold (foldConstants)
import Olivine.Core.Pass.ControlFlow (simplifyControlFlow)
import Olivine.Core.Pass.DeadCode (eliminateDeadCode)
import Olivine.Core.Pass.DeadSymbols (eliminateDeadSymbols)
import Olivine.Core.Pass.Inline (inlineCalls)
import Olivine.Core.Pass.LoopInvariants (hoistLoopInvariants)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Pass.Redundancies (eliminateRedundancies)
import Olivine.Core.Program (Program)
import Olivine.Core.Raise (raise)
import Olivine.Syntax.Ast (Module)

data Pass = Pass
  { passName :: String
  , runPass :: Program -> Program
  }

-- | The pipeline.
passes :: [Pass]
-- Promotion first, because until a slot becomes a local nothing that follows
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
-- Dead symbols last, since it is the one pass that reads what the others
-- leave: folding a @select@ between two function pointers settles which of
-- them the program can still reach, a block that control flow removed makes
-- the calls in it no longer calls, and dead code removing the last load of a
-- global settles whether the global is read at all.  Nothing that runs before
-- it can know any of them.
passes =
  [ Pass "memory promotion" promoteMemory
  , Pass "inlining" inlineCalls
  , Pass "constant folding" foldConstants
  , Pass "control flow" simplifyControlFlow
  , Pass "redundancies" eliminateRedundancies
  , Pass "loop invariants" hoistLoopInvariants
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
stages :: Module -> [(String, Program)]
stages m = scanl step ("as read", lower m) passes
  where
    step (_, program) pass = ("after " <> passName pass, runPass pass program)

-- | Apply a transformation until it stops changing the program.
fixpoint :: Eq a => (a -> a) -> a -> a
fixpoint f x = let x' = f x in if x' == x then x else fixpoint f x'
