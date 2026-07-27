-- | Instructions.
--
-- Nothing is modelled yet: an instruction is the line it was written on, held
-- verbatim, exactly as top-level constructs began as 'Olivine.Syntax.Ast.EOpaque'.
-- Instructions move out of 'IOpaque' one family at a time, and until they do
-- the indentation has to be carried along with the text, since only a typed
-- instruction can have its indentation regenerated.
--
-- One consequence of holding lines rather than instructions: a @switch@ spans
-- several lines, so it is currently several 'IOpaque' values rather than one.
-- That resolves itself when terminators are modelled.
module Olivine.Syntax.Instruction
  ( Instruction (..)
  ) where

import Data.Text (Text)

newtype Instruction
  = IOpaque Text
  deriving (Eq, Show)
