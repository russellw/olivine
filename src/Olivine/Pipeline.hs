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
  , fixpoint
  ) where

import Olivine.Core.Lower (lower)
import Olivine.Core.Program (Program)
import Olivine.Core.Raise (raise)
import Olivine.Syntax.Ast (Module)

data Pass = Pass
  { passName :: String
  , runPass :: Program -> Program
  }

-- | The pipeline.  Still empty: what exists so far is the road the program
-- travels, not anything done to it along the way.
passes :: [Pass]
passes = []

-- | Read a module, lower it to the core representation, run the passes, and
-- put it back.
--
-- Lowering and raising happen either side of the passes rather than being
-- each pass's business, so a pass never sees the syntax layer.
optimize :: Module -> Module
optimize = raise . flip (foldl' (flip runPass)) passes . lower

-- | Apply a transformation until it stops changing the program.
fixpoint :: Eq a => (a -> a) -> a -> a
fixpoint f x = let x' = f x in if x' == x then x else fixpoint f x'
