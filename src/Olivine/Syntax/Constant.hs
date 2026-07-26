-- | Constants, as they appear in global initializers and, later, as
-- instruction operands.
--
-- Not every constant expression LLVM once had still exists: @zext@, @select@
-- and @icmp@ were removed, while @ptrtoint@, @inttoptr@ and @getelementptr@
-- remain.  Only the surviving forms are modelled, and the binary arithmetic
-- expressions (@add@, @sub@ and friends) are deliberately left out — LLVM
-- folds them away in all but a few cases, so they are rare in emitted code.
-- Anything unmodelled leaves its line opaque, which is the safe outcome.
module Olivine.Syntax.Constant
  ( Constant (..)
  , TypedConstant (..)
  , CastOp (..)
  , GepFlag (..)
  ) where

import Data.Text (Text)

import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Packedness, Type)

data Constant
  = CInteger Integer
  | -- | @true@ and @false@.
    CBoolean Bool
  | -- | A floating point literal, kept as the text that was written.
    --
    -- LLVM normalizes these when it prints — @1.0@ comes back as
    -- @1.000000e+00@ — so holding the source spelling keeps the round trip
    -- exact without reimplementing that formatting, and without ever
    -- rounding a literal by decoding and re-encoding it.
    CFloat Text
  | CNull
  | CNone
  | CUndef
  | CPoison
  | CZeroInitializer
  | -- | @c"..."@, with escapes left undecoded.
    CString Text
  | -- | @[i32 1, i32 2]@
    CArray [TypedConstant]
  | -- | @<i32 1, i32 2>@
    CVector [TypedConstant]
  | -- | @{ i32 1, ptr @@g }@ and its packed form.
    CStruct Packedness [TypedConstant]
  | -- | A reference to a global, as in @\@counter@.
    CGlobal Name
  | -- | @ptrtoint (ptr \@g to i64)@ and the other surviving casts.
    CCast CastOp TypedConstant Type
  | -- | @getelementptr inbounds (i8, ptr \@g, i64 8)@.  The 'Type' is the
    -- source element type; the operands are the pointer and the indices.
    CGetElementPtr [GepFlag] Type [TypedConstant]
  deriving (Eq, Show)

-- | A constant written together with its type, which is how constants appear
-- everywhere except as a global's initializer, where the global already
-- names the type.
data TypedConstant = TypedConstant
  { typedConstantType :: Type
  , typedConstantValue :: Constant
  }
  deriving (Eq, Show)

data CastOp
  = CastTrunc
  | CastPtrToInt
  | CastIntToPtr
  | CastBitcast
  | CastAddrSpaceCast
  deriving (Eq, Show)

data GepFlag
  = GepInbounds
  | GepNusw
  | GepNuw
  deriving (Eq, Show)
