-- | Instructions.
--
-- Terminators are modelled; everything else is still the line it was written
-- on, held verbatim, exactly as top-level constructs began as
-- 'Olivine.Syntax.Ast.EOpaque'.  An opaque instruction has to carry its own
-- indentation, since only a modelled one can have indentation regenerated.
module Olivine.Syntax.Instruction
  ( Instruction (..)
  , Terminator (..)
  , MetadataAttachment (..)
  ) where

import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Value (TypedValue)

data Instruction
  = -- | A terminator and the metadata attached to it.
    ITerminator Terminator [MetadataAttachment]
  | -- | A line not yet modelled, kept as written.
    IOpaque Text
  deriving (Eq, Show)

-- | The instructions that end a basic block.
--
-- Only the ones that are purely control flow.  @invoke@ and @callbr@ are
-- calls that happen to branch, and belong with @call@; @resume@ and the
-- @catch@ and @cleanup@ family belong with exception handling.  Both wait
-- for those, and a block ending in one stays opaque meanwhile.
data Terminator
  = -- | @ret void@, or @ret \<ty\> \<value\>@.
    TRet (Maybe TypedValue)
  | -- | @br label %dest@.
    TBr Name
  | -- | @br i1 \<cond\>, label %then, label %else@.
    TCondBr TypedValue Name Name
  | -- | @switch \<ty\> \<value\>, label %default [ ... ]@.  LLVM requires the
    -- case values to be constants; that is a verifier's business rather than
    -- the syntax's, and 'Olivine.Syntax.Value.isConstant' is what asks.
    TSwitch TypedValue Name [(TypedValue, Name)]
  | -- | @indirectbr \<ty\> \<address\>, [label %a, label %b]@.
    TIndirectBr TypedValue [Name]
  | TUnreachable
  deriving (Eq, Show)

-- | @!dbg !5@, @!llvm.loop !6@ and the like, following an instruction.
--
-- Debug locations arrive through here on the same footing as @!tbaa@ and
-- @!llvm.loop@, which is what makes carrying them cost nothing extra.
data MetadataAttachment = MetadataAttachment
  { attachmentName :: Name
  , attachmentNode :: Natural
  }
  deriving (Eq, Show)
