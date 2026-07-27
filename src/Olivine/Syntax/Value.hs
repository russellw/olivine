-- | Operands: literals, constant expressions, and references to globals and
-- locals, all in one type.
--
-- LLVM makes constants a subtype of values, so a @switch@ case being a
-- constant costs it nothing to say.  Haskell has no subtyping, and encoding
-- the relation as two parallel types costs a conversion at every boundary and
-- a second copy of every function over operands — a recurring price paid for
-- a single check.  So the distinction lives in 'isConstant' instead, for a
-- verifier to apply where it matters.
--
-- This layer reads back what was written and does not judge it: it already
-- admits type mismatches, branches to blocks that do not exist, and function
-- types LLVM would reject, so refusing a local in a global initializer would
-- have closed one gap in a wall that is mostly gaps.
module Olivine.Syntax.Value
  ( Value (..)
  , TypedValue (..)
  , CastOp (..)
  , GepFlag (..)
  , isConstant
  ) where

import Data.Text (Text)

import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Packedness, Type)

data Value
  = VInteger Integer
  | -- | @true@ and @false@.
    VBoolean Bool
  | -- | A floating point literal, kept as the text that was written.
    --
    -- LLVM normalizes these when it prints — @1.0@ comes back as
    -- @1.000000e+00@ — so holding the source spelling keeps the round trip
    -- exact without reimplementing that formatting, and without ever
    -- rounding a literal by decoding and re-encoding it.
    VFloat Text
  | VNull
  | VNone
  | VUndef
  | VPoison
  | VZeroInitializer
  | -- | @c"..."@, with escapes left undecoded.
    VString Text
  | -- | @[i32 1, i32 2]@
    VArray [TypedValue]
  | -- | @\<i32 1, i32 2\>@
    VVector [TypedValue]
  | -- | @{ i32 1, ptr \@g }@ and its packed form.
    VStruct Packedness [TypedValue]
  | -- | A reference to a global, as in @\@counter@.
    VGlobal Name
  | -- | @%x@, naming a local.  In the core representation these will have
    -- addresses and be reassignable; here it is simply what was written.
    VLocal Name
  | -- | @ptrtoint (ptr \@g to i64)@ and the other surviving casts.
    VCast CastOp TypedValue Type
  | -- | @getelementptr inbounds (i8, ptr \@g, i64 8)@.  The 'Type' is the
    -- source element type; the operands are the pointer and the indices.
    VGetElementPtr [GepFlag] Type [TypedValue]
  deriving (Eq, Show)

-- | An operand written together with its type, which is how operands appear
-- everywhere except as a global's initializer, where the global already names
-- the type.
data TypedValue = TypedValue
  { typedValueType :: Type
  , typedValue :: Value
  }
  deriving (Eq, Show)

-- | The conversion opcodes, shared by the @\<op\> \<ty\> \<v\> to \<ty\>@
-- instruction and by the constant expression of the same shape.
--
-- Not every one of them survives as a constant expression — LLVM removed
-- @zext@ and others from that position — but that is a fact about where an
-- operation may appear, which the parser follows, rather than a reason for
-- two enumerations that would have to be converted between.
data CastOp
  = CastTrunc
  | CastZExt
  | CastSExt
  | CastFPTrunc
  | CastFPExt
  | CastFPToUI
  | CastFPToSI
  | CastUIToFP
  | CastSIToFP
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

-- | Whether an operand is a compile-time constant.
--
-- This is what a global initializer and a @switch@ case require, and what the
-- type deliberately no longer enforces.  Aggregates and constant expressions
-- are constant exactly when everything inside them is.
isConstant :: Value -> Bool
isConstant (VLocal _) = False
isConstant (VArray elements) = all (isConstant . typedValue) elements
isConstant (VVector elements) = all (isConstant . typedValue) elements
isConstant (VStruct _ fields) = all (isConstant . typedValue) fields
isConstant (VCast _ operand _) = isConstant (typedValue operand)
isConstant (VGetElementPtr _ _ operands) =
  all (isConstant . typedValue) operands
isConstant _ = True
