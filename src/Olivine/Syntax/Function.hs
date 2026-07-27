-- | Function signatures and definitions.
--
-- The signature is the whole of a declaration and also the header of a
-- definition, so it is kept separate from either and shared by both.
module Olivine.Syntax.Function
  ( Signature (..)
  , Parameter (..)
  , Definition (..)
  , BasicBlock (..)
  , BlockLabel (..)
  ) where

import Numeric.Natural (Natural)

import Data.Text (Text)

import Olivine.Syntax.Attribute (AttributeItem, ParamAttribute)
import Olivine.Syntax.Instruction (Instruction)
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
  , -- | The attribute slot: group references and attributes written out,
    -- in the order they appear.
    signatureAttributes :: [AttributeItem]
  }
  deriving (Eq, Show)

data Parameter = Parameter
  { parameterType :: Type
  , parameterAttributes :: [ParamAttribute]
  , -- | Present in a definition, usually absent in a declaration.
    parameterName :: Maybe Name
  }
  deriving (Eq, Show)

data Definition = Definition
  { definitionSignature :: Signature
  , definitionBlocks :: [BasicBlock]
  }
  deriving (Eq, Show)

data BasicBlock = BasicBlock
  { -- | Absent only for an entry block that was written without one, which
    -- is how LLVM prints a function whose blocks are all numbered.
    blockLabel :: Maybe BlockLabel
  , blockBody :: [Instruction]
  }
  deriving (Eq, Show)

data BlockLabel = BlockLabel
  { blockLabelName :: Name
  , -- | The comment LLVM writes after a label, @; preds = %1@ or
    -- @; No predecessors!@.
    --
    -- It is derived from the control flow graph, so it will have to be
    -- regenerated rather than carried once terminators are modelled and a
    -- pass can change which blocks reach this one.  Until then carrying it
    -- is what keeps the round trip exact.
    blockLabelComment :: Maybe Text
  }
  deriving (Eq, Show)
