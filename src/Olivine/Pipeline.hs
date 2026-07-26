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

import Olivine.Syntax.Ast (Module)

data Pass = Pass
  { passName :: String
  , runPass :: Module -> Module
  }

-- | The pipeline.  Empty for now: the first milestone is a faithful round
-- trip, and an empty pipeline is what makes @olivine in.ll -o out.ll@ testable
-- as the identity.
--
-- Passes will operate on the non-SSA core representation rather than on the
-- syntax layer; this signature moves once that core exists.
passes :: [Pass]
passes = []

optimize :: Module -> Module
optimize m = foldl' (flip runPass) m passes

-- | Apply a transformation until it stops changing the program.
fixpoint :: Eq a => (a -> a) -> a -> a
fixpoint f x = let x' = f x in if x' == x then x else fixpoint f x'
