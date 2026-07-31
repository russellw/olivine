-- | Function signatures and definitions.
--
-- The signature is the whole of a declaration and also the header of a
-- definition, so it is kept separate from either and shared by both.
module Olivine.Syntax.Function
  ( Signature (..)
  , AttachmentPosition (..)
  , FunctionClause (..)
  , Parameter (..)
  , Definition (..)
  , BasicBlock (..)
  , BlockLabel (..)
  , entryBlockName
  ) where

import Data.Char (isDigit)
import Numeric.Natural (Natural)

import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Syntax.Attribute (AttributeItem, ParamAttribute)
import Olivine.Syntax.Instruction (Instruction, MetadataAttachment)
import Olivine.Syntax.Linkage
import Olivine.Syntax.Name (Name (..), Quoting (..))
import Olivine.Syntax.Type (Arity, Type)
import Olivine.Syntax.Value (TypedValue)

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
  , -- | @section@, @partition@, @comdat@ and @align@, the clauses a function
    -- shares with a global variable, both being global objects.
    --
    -- LLVM rejects a comdat on a @declare@ — a declaration defines nothing to
    -- put in a group — but a declaration and the header of a definition are
    -- one production, read here by one rule, so what that rule reads is the
    -- union and the verifier's is the judgement.
    signatureClauses :: [GlobalAttribute]
  , -- | @gc@, @prefix@, @prologue@ and @personality@: the clauses no global
    -- variable has, in the order LLVM writes them.
    --
    -- The same union as 'signatureClauses' and for the same reason — LLVM
    -- takes @gc@ and @prefix@ on a declaration and refuses @personality@,
    -- and one rule reads the header of either.
    signatureFunctionClauses :: [FunctionClause]
  , -- | The metadata attached to the function itself, @!dbg !10@ and its
    -- relatives.
    --
    -- The same shape as an instruction's attachments, because it is the same
    -- construct in the other place LLVM allows one.  Where it is written
    -- depends on which keyword introduced the signature; see
    -- 'AttachmentPosition'.
    signatureMetadata :: [MetadataAttachment]
  }
  deriving (Eq, Show)

-- | Where a function's own attachments stand, which is the one place a
-- declaration and a definition's header are not the same production.
--
-- On a definition they follow every other clause, at the end of the header:
-- @define void \@f() #0 !dbg !10 {@.  On a declaration they stand first,
-- immediately after the keyword: @declare !dbg !27 noalias ptr \@malloc(i64)@,
-- which is what clang writes for every declared function under @-g@.
--
-- The other spelling is not a declaration the verifier should complain about,
-- it is not a declaration at all: @llvm-as@ answers
-- @declare void \@f() !dbg !3@ with @expected '=' here@, having finished
-- reading the declaration before the attachment.  So the position is the
-- grammar's and a signature read in the wrong one falls to an opaque line,
-- the same as any other text this layer cannot read.
data AttachmentPosition
  = Leading
  | Trailing
  deriving (Eq, Show)

-- | A clause a function may carry and a global variable may not.
--
-- Each names something the function has beside its body: the collector its
-- frames are walked by, the data laid down before or after its entry point,
-- and the routine that decides what an unwinder does when an exception
-- reaches it.  Three of the four hold a constant, which is a value like any
-- other here — that it must be constant is 'Olivine.Syntax.Value.isConstant'
-- to ask, not this type to make unrepresentable.
data FunctionClause
  = -- | @gc "shadow-stack"@.
    FCGarbageCollector Text
  | -- | @prefix \<ty\> \<constant\>@.
    FCPrefix (TypedValue Name)
  | -- | @prologue \<ty\> \<constant\>@.
    FCPrologue (TypedValue Name)
  | -- | @personality \<ty\> \<constant\>@, the routine an unwinder asks what
    -- this function wants done.  A function holding a @landingpad@ must have
    -- one.
    FCPersonality (TypedValue Name)
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

-- | What LLVM calls a block written without a label.
--
-- Only the entry block can be written without one, having nothing that
-- branches to it, and anything asking what the blocks of a function are called
-- needs an answer for it too: the lowering, to find what a branch to it names,
-- and the verifier, to say which block a phi takes a value from.
--
-- LLVM numbers unnamed values in order, and a block takes a number like
-- anything else, so the entry block gets the one after the parameters.  A
-- parameter written @%0@ is an unnamed value whose number has been written
-- down rather than a parameter named zero, so it counts; one written @%x@ is
-- named and does not.
entryBlockName :: Signature -> Name
entryBlockName signature = Name Bare (T.pack (show (length numbered)))
  where
    numbered =
      [ ()
      | p <- signatureParameters signature
      , maybe True (T.all isDigit . nameText) (parameterName p)
      ]
