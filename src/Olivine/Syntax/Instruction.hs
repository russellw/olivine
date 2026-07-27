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
  , Binary (..)
  , BinaryOp (..)
  , Unary (..)
  , UnaryOp (..)
  , Convert (..)
  , Compare (..)
  , IntPredicate (..)
  , FloatPredicate (..)
  , InstructionFlag (..)
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
import Olivine.Syntax.Value (CastOp, GepFlag, TypedValue, Value)

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
  | -- | @add nsw i32 %a, %b@ and its relatives, integer, bitwise and
    -- floating point alike.
    OBinary Binary
  | -- | @fneg double %a@, the only unary arithmetic operation.
    OUnary Unary
  | -- | @icmp slt i32 %a, %b@.
    OICmp (Compare IntPredicate)
  | -- | @fcmp olt double %a, %b@.
    OFCmp (Compare FloatPredicate)
  | -- | @zext nneg i32 %a to i64@ and the other conversions.
    OConvert Convert
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
isTerminator (OBinary _) = False
isTerminator (OUnary _) = False
isTerminator (OICmp _) = False
isTerminator (OFCmp _) = False
isTerminator (OConvert _) = False
isTerminator (OAlloca _) = False
isTerminator (OLoad _) = False
isTerminator (OStore _) = False
isTerminator (OGetElementPtr _) = False

-- | A binary operation: an opcode, its flags, the type both operands share,
-- and the operands.
data Binary = Binary
  { binaryOp :: BinaryOp
  , binaryFlags :: [InstructionFlag]
  , binaryType :: Type
  , binaryLeft :: Value
  , binaryRight :: Value
  }
  deriving (Eq, Show)

data BinaryOp
  = OpAdd
  | OpSub
  | OpMul
  | OpUDiv
  | OpSDiv
  | OpURem
  | OpSRem
  | OpShl
  | OpLShr
  | OpAShr
  | OpAnd
  | OpOr
  | OpXor
  | OpFAdd
  | OpFSub
  | OpFMul
  | OpFDiv
  | OpFRem
  deriving (Eq, Show)

data Unary = Unary
  { unaryOp :: UnaryOp
  , unaryFlags :: [InstructionFlag]
  , unaryType :: Type
  , unaryOperand :: Value
  }
  deriving (Eq, Show)

data UnaryOp
  = OpFNeg
  deriving (Eq, Show)

-- | @\<op\> [flags] \<ty\> \<value\> to \<ty\>@.
data Convert = Convert
  { convertOp :: CastOp
  , convertFlags :: [InstructionFlag]
  , convertOperand :: TypedValue
  , convertTarget :: Type
  }
  deriving (Eq, Show)

-- | A comparison, parameterized by which set of predicates it draws on.
--
-- @icmp@ and @fcmp@ share their shape and differ only in that, so one record
-- serves both without letting an integer comparison take a floating point
-- predicate.
data Compare predicate = Compare
  { compareFlags :: [InstructionFlag]
  , comparePredicate :: predicate
  , compareType :: Type
  , compareLeft :: Value
  , compareRight :: Value
  }
  deriving (Eq, Show)

data IntPredicate
  = IEq
  | INe
  | IUgt
  | IUge
  | IUlt
  | IUle
  | ISgt
  | ISge
  | ISlt
  | ISle
  deriving (Eq, Show)

data FloatPredicate
  = FFalse
  | FOeq
  | FOgt
  | FOge
  | FOlt
  | FOle
  | FOne
  | FOrd
  | FUeq
  | FUgt
  | FUge
  | FUlt
  | FUle
  | FUne
  | FUno
  | FTrue
  deriving (Eq, Show)

-- | The keywords that qualify an operation: the integer wrapping flags, the
-- exactness and disjointness flags, @samesign@, and the fast-math set.
--
-- Which of them an operation may carry is a verifier's business.  Splitting
-- them by operation would mean a type per group and a conversion wherever
-- flags are handled generically, for a check a verifier makes anyway.
data InstructionFlag
  = FlagNUW
  | FlagNSW
  | FlagExact
  | FlagDisjoint
  | FlagSameSign
  | FlagNNeg
  | FlagNNaN
  | FlagNInf
  | FlagNSZ
  | FlagARcp
  | FlagContract
  | FlagAFn
  | FlagReassoc
  | FlagFast
  deriving (Eq, Show)

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
