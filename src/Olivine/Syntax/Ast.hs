-- | A faithful syntactic representation of an LLVM @.ll@ module.
--
-- This layer mirrors LLVM's textual form closely, phi nodes and all.  It is
-- deliberately /not/ the representation the optimizer passes work on: those
-- use a separate non-SSA core in which locals have addresses and can be
-- reassigned.  Lowering between the two is its own step, so that a failure in
-- the round trip is never ambiguous between a parsing bug and a lowering bug.
--
-- Every construct starts life as an 'EOpaque' holding its source text
-- verbatim.  That makes the round trip total from the first commit; structure
-- is then added by moving one construct at a time out of 'EOpaque' into a
-- typed constructor, with a matching printer case.  The round-trip test stays
-- green throughout.
module Olivine.Syntax.Ast
  ( Module (..)
  , Entry (..)
  ) where

import Data.Text (Text)

-- | A whole translation unit.  Olivine optimizes whole programs, so a
-- complete input is eventually a set of these linked together; for now one
-- module is one file.
newtype Module = Module
  { moduleEntries :: [Entry]
  }
  deriving (Eq, Show)

-- | A single top-level construct.
data Entry
  = -- | Source text not yet modelled, retained exactly as written.
    EOpaque Text
  deriving (Eq, Show)
