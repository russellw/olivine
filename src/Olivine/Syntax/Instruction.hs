-- | Instructions.
--
-- Terminators are not a type of their own.  They are a subset of the
-- instructions, and by the rule in CLAUDE.md a subset is one type plus a
-- predicate — here 'isTerminator', which is what LLVM's own @Instruction@
-- class does.  Keeping them apart would mean every function over instructions
-- carrying two cases forever, and the result name and the metadata living in
-- two places.
--
-- Whatever is not modelled is still the line it was written on, held verbatim
-- with its indentation, since only a modelled instruction can have its
-- indentation and its result name regenerated.
module Olivine.Syntax.Instruction
  ( Instruction (..)
  , Operation (..)
  , isTerminator
  , Alloca (..)
  , Load (..)
  , Store (..)
  , GetElementPtr (..)
  , MetadataAttachment (..)
  ) where

import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value (GepFlag, TypedValue)

data Instruction
  = -- | An operation, the name it assigns to its result if it has one, and
    -- the metadata attached to it.
    --
    -- Whether an operation may name a result is a verifier's business: a
    -- @store@ must not and a @load@ must, and neither is said here.
    IOperation (Maybe Name) Operation [MetadataAttachment]
  | -- | A line not yet modelled, kept as written.
    IOpaque Text
  deriving (Eq, Show)

-- | What an instruction does.
--
-- Of the terminators, only the ones that are purely control flow.  @invoke@
-- and @callbr@ are calls that happen to branch, and belong with @call@;
-- @resume@ and the @catch@ and @cleanup@ family belong with exception
-- handling.  Both wait for those, and a block ending in one stays opaque.
data Operation
  = -- | @ret void@, or @ret \<ty\> \<value\>@.
    ORet (Maybe TypedValue)
  | -- | @br label %dest@.
    OBr Name
  | -- | @br i1 \<cond\>, label %then, label %else@.
    OCondBr TypedValue Name Name
  | -- | @switch \<ty\> \<value\>, label %default [ ... ]@.  LLVM requires the
    -- case values to be constants; 'Olivine.Syntax.Value.isConstant' is what
    -- asks, rather than the shape of the data.
    OSwitch TypedValue Name [(TypedValue, Name)]
  | -- | @indirectbr \<ty\> \<address\>, [label %a, label %b]@.
    OIndirectBr TypedValue [Name]
  | OUnreachable
  | OAlloca Alloca
  | OLoad Load
  | OStore Store
  | OGetElementPtr GetElementPtr
  deriving (Eq, Show)

-- | Whether an operation ends its basic block.
--
-- That a block holds exactly one of these, last, is an invariant for a
-- verifier rather than something the syntax enforces: this layer has to be
-- able to read back a module that gets it wrong.
isTerminator :: Operation -> Bool
isTerminator (ORet _) = True
isTerminator (OBr _) = True
isTerminator (OCondBr _ _ _) = True
isTerminator (OSwitch _ _ _) = True
isTerminator (OIndirectBr _ _) = True
isTerminator OUnreachable = True
isTerminator (OAlloca _) = False
isTerminator (OLoad _) = False
isTerminator (OStore _) = False
isTerminator (OGetElementPtr _) = False

-- | @alloca [inalloca] \<ty\> [, \<ty\> \<count\>] [, align N] [, addrspace(N)]@.
data Alloca = Alloca
  { allocaInalloca :: Bool
  , allocaType :: Type
  , -- | The number of elements, when more than one is asked for.
    allocaElementCount :: Maybe TypedValue
  , allocaAlignment :: Maybe Natural
  , allocaAddrSpace :: Maybe Natural
  }
  deriving (Eq, Show)

-- | @load [volatile] \<ty\>, ptr \<pointer\> [, align N]@.
--
-- The atomic form, with its ordering and optional syncscope, is not modelled;
-- a line carrying one stays opaque.
data Load = Load
  { loadVolatile :: Bool
  , -- | The type loaded, which since pointers became opaque is written out
    -- rather than being recoverable from the pointer.
    loadType :: Type
  , loadPointer :: TypedValue
  , loadAlignment :: Maybe Natural
  }
  deriving (Eq, Show)

-- | @store [volatile] \<ty\> \<value\>, ptr \<pointer\> [, align N]@.
data Store = Store
  { storeVolatile :: Bool
  , storeValue :: TypedValue
  , storePointer :: TypedValue
  , storeAlignment :: Maybe Natural
  }
  deriving (Eq, Show)

-- | @getelementptr [flags] \<ty\>, ptr \<pointer\>, \<ty\> \<index\>, ...@.
--
-- Read back as LLVM writes it, with all its indices.  The core representation
-- is to replace this with a form computing one offset at a time, which is a
-- lowering step rather than something to do while reading.
data GetElementPtr = GetElementPtr
  { gepFlags :: [GepFlag]
  , -- | The type being indexed into, not the type of the result.
    gepSourceType :: Type
  , gepPointer :: TypedValue
  , gepIndices :: [TypedValue]
  }
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
