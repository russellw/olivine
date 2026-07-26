-- | Function signatures.
--
-- Only @declare@ is modelled so far.  The signature itself is the whole of a
-- declaration and also the header of a definition, so 'Signature' is kept
-- separate from the entry that carries it, ready for @define@ to reuse.
module Olivine.Syntax.Function
  ( Signature (..)
  , Parameter (..)
  , SignatureAttribute (..)
  ) where

import Numeric.Natural (Natural)

import Olivine.Syntax.Attribute (FunctionAttribute, ParamAttribute)
import Olivine.Syntax.Linkage
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Arity, Type)

data Signature = Signature
  { signatureLinkage :: Maybe Linkage
  , signaturePreemption :: Maybe Preemption
  , signatureVisibility :: Maybe Visibility
  , signatureDLLStorage :: Maybe DLLStorage
  , signatureCallingConvention :: Maybe CallingConvention
  , signatureReturnAttributes :: [ParamAttribute]
  , signatureReturnType :: Type
  , signatureName :: Name
  , signatureParameters :: [Parameter]
  , -- | Whether the parameter list ended with @...@.
    signatureArity :: Arity
  , signatureUnnamedAddr :: Maybe UnnamedAddr
  , signatureAddrSpace :: Maybe Natural
  , -- | Attribute group references and attributes written out in full,
    -- kept in one list because LLVM's grammar puts them in one slot and
    -- either may come first.
    signatureAttributes :: [SignatureAttribute]
  }
  deriving (Eq, Show)

-- | One item of a signature's attribute slot.
data SignatureAttribute
  = -- | A reference to an attribute group, as in the @#1@ of
    -- @declare void \@free(ptr) #1@.
    SAGroup Natural
  | -- | An attribute written out on the function itself.
    SAAttribute FunctionAttribute
  deriving (Eq, Show)

data Parameter = Parameter
  { parameterType :: Type
  , parameterAttributes :: [ParamAttribute]
  , -- | Present in a definition, usually absent in a declaration.
    parameterName :: Maybe Name
  }
  deriving (Eq, Show)
