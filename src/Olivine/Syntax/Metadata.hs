-- | Metadata nodes.
--
-- Only the tuple form is modelled: @!0 = !{...}@ and the named nodes that
-- point at it.  The specialized debug nodes — @!DILocation(line: 1, ...)@ and
-- the thirty-odd others — are a family of their own, each with its own set of
-- named fields, and a module compiled without @-g@ contains none of them.  A
-- line carrying one stays opaque.
--
-- Nothing needs to read them, because none of them survives being read:
-- "Olivine.Syntax.Debug" takes the debug information out of every module,
-- and recognizing a specialized node is recognizing the @!DI@ its line
-- begins with.  The one part of it that could not wait for a later step is
-- the debug /records/ in a body, since an unread line there takes the whole
-- function; those are dropped as they are read, see @pDebugRecord@.
module Olivine.Syntax.Metadata
  ( MetadataOperand (..)
  , Distinctness (..)
  ) where

import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Value (TypedValue)

data MetadataOperand
  = -- | @!0@, a reference to another node.
    MDRef Natural
  | -- | @!"..."@, with escapes left undecoded as elsewhere.
    MDString Text
  | -- | An ordinary value, as in the @i32 1@ of @!{i32 1, !"wchar_size"}@.
    MDValue (TypedValue Name)
  | -- | A null operand, which is written bare and carries no type.
    MDNull
  | -- | A tuple written inline rather than referenced.
    MDTuple [MetadataOperand]
  deriving (Eq, Show)

-- | Whether a node was marked @distinct@.
--
-- It is not decoration: two uniqued nodes with equal contents are the same
-- node, and a distinct one is not equal to anything but itself.  A pass that
-- dropped the marker would silently merge nodes that must stay apart.
data Distinctness
  = Uniqued
  | Distinct
  deriving (Eq, Show)
