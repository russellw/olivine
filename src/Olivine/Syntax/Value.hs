-- | Instruction operands.
--
-- Kept apart from 'Olivine.Syntax.Constant.TypedConstant' rather than merged
-- with it, because the difference is real: an instruction may name a local,
-- a global initializer may not.  Sharing one type would make that distinction
-- something to check rather than something the syntax already guarantees.
module Olivine.Syntax.Value
  ( Value (..)
  , TypedValue (..)
  ) where

import Olivine.Syntax.Constant (Constant)
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)

data Value
  = -- | @%x@, naming a local.  In the core representation these will have
    -- addresses and be reassignable; here it is simply what was written.
    VLocal Name
  | -- | A literal, or a reference to a global.
    VConstant Constant
  deriving (Eq, Show)

data TypedValue = TypedValue
  { typedValueType :: Type
  , typedValue :: Value
  }
  deriving (Eq, Show)
