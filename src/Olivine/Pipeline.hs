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
import Olivine.Core.Pass.Promote (promoteMemory)
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
