-- | Attributes on a parameter or on a return value.
--
-- The two draw on the same vocabulary, so they share one type; which of them
-- are legal in which position is a matter for a verifier, not for reading
-- back what was written.
--
-- A few attributes take an argument that is a small language of its own —
-- @captures(address, provenance)@, @range(i32 0, 10)@, @nofpclass(nan inf)@,
-- @initializes((0, 4))@.  Those interiors are carried as the text between the
-- parentheses.  They are rare, none of them changes what the surrounding
-- signature means, and decoding them would be a grammar apiece for no gain
-- until a pass actually asks.
module Olivine.Syntax.Attribute
  ( ParamAttribute (..)
  ) where

import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Syntax.Type (Type)

data ParamAttribute
  = -- Flags.
    PAZeroExt
  | PASignExt
  | PANoExt
  | PAInReg
  | PANoAlias
  | PANoCapture
  | PANoFree
  | PANest
  | PAReturned
  | PANonNull
  | PANoUndef
  | PASwiftSelf
  | PASwiftAsync
  | PASwiftError
  | PAImmArg
  | PAAllocAlign
  | PAAllocPtr
  | PAReadNone
  | PAReadOnly
  | PAWriteOnly
  | PAWritable
  | PADeadOnUnwind
  | PADeadOnReturn
  | -- Attributes taking a number.
    PAAlign Natural
  | PAAlignStack Natural
  | PADereferenceable Natural
  | PADereferenceableOrNull Natural
  | -- Attributes taking a type.
    PAByVal Type
  | PAByRef Type
  | PAPreallocated Type
  | PAInAlloca Type
  | PASRet Type
  | PAElementType Type
  | -- Attributes whose argument is left as written.
    PACaptures Text
  | PARange Text
  | PANoFPClass Text
  | PAInitializes Text
  deriving (Eq, Show)
