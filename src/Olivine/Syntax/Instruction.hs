-- | Instructions, spelled the way LLVM spells them.
--
-- Terminators are not a type of their own.  They are a subset of the
-- instructions, and by the rule in CLAUDE.md a subset is one type plus a
-- predicate — here 'isTerminator', which is what LLVM's own @Instruction@
-- class does.  What makes that the right rule here and not in the core is
-- that this layer has to read back a block ending in the wrong thing, or in
-- nothing at all: the invalid case has to be representable to be reported.
-- Nothing constructs a core program but Olivine, so there the terminator is
-- a type of its own and the predicate is gone.
--
-- Whatever is not modelled is still the line it was written on, held verbatim
-- with its indentation, since only a modelled instruction can have its
-- indentation and its result name regenerated.
--
-- __Every record holding operands traverses what a local is called.__  Each of
-- them is parameterized by that and by nothing else, so the derived instances
-- reach exactly the locals: reading them off is 'Data.Foldable.toList' and
-- renaming them is 'fmap', at whichever end of the pipeline is asking.  These
-- records are the part of the instruction set that syntax and core genuinely
-- share — an @add@ is an @add@ whether its operands are called @%x@ or @%3@ —
-- so writing the walk once, and having the compiler write it, is what keeps
-- the two grammars above them from costing a second copy of it.
module Olivine.Syntax.Instruction
  ( Instruction (..)
  , Operation (..)
  , isTerminator
  , Binary (..)
  , BinaryOp (..)
  , Unary (..)
  , UnaryOp (..)
  , Convert (..)
  , Select (..)
  , ExtractElement (..)
  , InsertElement (..)
  , ShuffleVector (..)
  , Phi (..)
  , Call (..)
  , TailKind (..)
  , Argument (..)
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

import Olivine.Syntax.Attribute (AttributeItem, ParamAttribute)
import Olivine.Syntax.Linkage (CallingConvention)
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value (CastOp, GepFlag, TypedValue, Value)

data Instruction
  = -- | An operation, the name it assigns to its result if it has one, and
    -- the metadata attached to it.
    --
    -- Whether an operation may name a result is a verifier's business: a
    -- @store@ must not and a @load@ must, and neither is said here.
    IOperation (Maybe Name) (Operation Name) [MetadataAttachment]
  | -- | A line not yet modelled, kept as written.
    IOpaque Text
  deriving (Eq, Show)

-- | What an instruction does.
--
-- Of the terminators, only the ones that are purely control flow.  @invoke@
-- and @callbr@ are calls that happen to branch, and belong with @call@;
-- @resume@ and the @catch@ and @cleanup@ family belong with exception
-- handling.  Both wait for those, and a block ending in one stays opaque.
--
-- __A destination is a 'Name', because that is what was written.__  This
-- grammar reads LLVM back and writes it out, so everything it says is spelled
-- the way LLVM spells it.  What the optimizer works on is a grammar of its
-- own, "Olivine.Core.Instruction", where a destination is a number and there
-- is no @phi@; the two were one type parameterized by what a destination is
-- until the differences stopped being expressible that way.
data Operation local
  = -- | @ret void@, or @ret \<ty\> \<value\>@.
    ORet (Maybe (TypedValue local))
  | -- | @br label %dest@.
    OBr Name
  | -- | @br i1 \<cond\>, label %then, label %else@.
    OCondBr (TypedValue local) Name Name
  | -- | @switch \<ty\> \<value\>, label %default [ ... ]@.  LLVM requires the
    -- case values to be constants; 'Olivine.Syntax.Value.isConstant' is what
    -- asks, rather than the shape of the data.
    OSwitch (TypedValue local) Name [(TypedValue local, Name)]
  | -- | @indirectbr \<ty\> \<address\>, [label %a, label %b]@.
    OIndirectBr (TypedValue local) [Name]
  | OUnreachable
  | -- | @add nsw i32 %a, %b@ and its relatives, integer, bitwise and
    -- floating point alike.
    OBinary (Binary local)
  | -- | @fneg double %a@, the only unary arithmetic operation.
    OUnary (Unary local)
  | -- | @icmp slt i32 %a, %b@.
    OICmp (Compare IntPredicate local)
  | -- | @fcmp olt double %a, %b@.
    OFCmp (Compare FloatPredicate local)
  | -- | @zext nneg i32 %a to i64@ and the other conversions.
    OConvert (Convert local)
  | -- | @select [flags] \<selty\> \<cond\>, \<ty\> \<a\>, \<ty\> \<b\>@.
    OSelect (Select local)
  | -- | @extractelement \<n x ty\> \<vector\>, \<ty\> \<index\>@.
    OExtractElement (ExtractElement local)
  | -- | @insertelement \<n x ty\> \<vector\>, \<ty\> \<value\>, \<ty\> \<index\>@.
    OInsertElement (InsertElement local)
  | -- | @shufflevector \<n x ty\> \<a\>, \<n x ty\> \<b\>, \<m x i32\> \<mask\>@.
    OShuffleVector (ShuffleVector local)
  | -- | @phi \<ty\> [ \<value\>, %pred ], ...@.
    OPhi (Phi local)
  | -- | @call@, direct or indirect, with or without a result.
    OCall (Call local)
  | OAlloca (Alloca local)
  | OLoad (Load local)
  | OStore (Store local)
  | OGetElementPtr (GetElementPtr local)
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | Whether an operation ends its basic block.
--
-- That a block holds exactly one of these, last, is an invariant for a
-- verifier rather than something the syntax enforces: this layer has to be
-- able to read back a module that gets it wrong.
isTerminator :: Operation local -> Bool
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
isTerminator (OSelect _) = False
isTerminator (OExtractElement _) = False
isTerminator (OInsertElement _) = False
isTerminator (OShuffleVector _) = False
isTerminator (OPhi _) = False
isTerminator (OCall _) = False
isTerminator (OAlloca _) = False
isTerminator (OLoad _) = False
isTerminator (OStore _) = False
isTerminator (OGetElementPtr _) = False

-- | A binary operation: an opcode, its flags, the type both operands share,
-- and the operands.
data Binary local = Binary
  { binaryOp :: BinaryOp
  , binaryFlags :: [InstructionFlag]
  , binaryType :: Type
  , binaryLeft :: Value local
  , binaryRight :: Value local
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

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

data Unary local = Unary
  { unaryOp :: UnaryOp
  , unaryFlags :: [InstructionFlag]
  , unaryType :: Type
  , unaryOperand :: Value local
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

data UnaryOp
  = OpFNeg
  deriving (Eq, Show)

-- | @\<op\> [flags] \<ty\> \<value\> to \<ty\>@.
data Convert local = Convert
  { convertOp :: CastOp
  , convertFlags :: [InstructionFlag]
  , convertOperand :: TypedValue local
  , convertTarget :: Type
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | A comparison, parameterized by which set of predicates it draws on.
--
-- @icmp@ and @fcmp@ share their shape and differ only in that, so one record
-- serves both without letting an integer comparison take a floating point
-- predicate.
data Compare predicate local = Compare
  { compareFlags :: [InstructionFlag]
  , comparePredicate :: predicate
  , compareType :: Type
  , compareLeft :: Value local
  , compareRight :: Value local
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

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

-- | @select [flags] \<selty\> \<cond\>, \<ty\> \<a\>, \<ty\> \<b\>@.
--
-- The condition is @i1@ for a scalar select and a vector of @i1@ for an
-- elementwise one, so it carries its own type like the other operands.
data Select local = Select
  { selectFlags :: [InstructionFlag]
  , selectCondition :: TypedValue local
  , selectTrue :: TypedValue local
  , selectFalse :: TypedValue local
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

data ExtractElement local = ExtractElement
  { extractElementVector :: TypedValue local
  , extractElementIndex :: TypedValue local
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

data InsertElement local = InsertElement
  { insertElementVector :: TypedValue local
  , insertElementValue :: TypedValue local
  , insertElementIndex :: TypedValue local
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | The mask is an ordinary operand rather than a list of indices: LLVM
-- writes it as a vector constant, and @zeroinitializer@ is a common spelling
-- of one, which a list of numbers could not hold.
data ShuffleVector local = ShuffleVector
  { shuffleVectorLeft :: TypedValue local
  , shuffleVectorRight :: TypedValue local
  , shuffleVectorMask :: TypedValue local
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @phi [flags] \<ty\> [ \<value\>, %pred ], [ \<value\>, %pred ]@.
--
-- This is the construct the core representation exists to do without.  There,
-- locals have addresses and can be reassigned, so a value that depends on
-- which edge was taken is a store on each edge and a load after the join,
-- with no need to name the predecessors.
--
-- None of that belongs here.  Reading LLVM faithfully and representing a
-- program the way Olivine wants to are separate problems, and mixing them
-- would mean the round trip could no longer be checked by comparing the
-- output with the input.  The conversion is a lowering step between the two
-- representations, and this type is what it will consume.
data Phi local = Phi
  { phiFlags :: [InstructionFlag]
  , phiType :: Type
  , -- | The value arriving along each edge, and the block it comes from.
    phiIncoming :: [(Value local, Name)]
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @[tail] call [flags] [cconv] [ret attrs] \<ty\> \<callee\>(\<args\>) [attrs]@.
--
-- Inline assembly and operand bundles are not modelled; a call carrying
-- either stays opaque.  @invoke@ and @callbr@, which are calls that also
-- branch, are still to come.
data Call local = Call
  { callTail :: Maybe TailKind
  , callFlags :: [InstructionFlag]
  , callCallingConvention :: Maybe CallingConvention
  , callReturnAttributes :: [ParamAttribute]
  , callAddrSpace :: Maybe Natural
  , -- | The return type, or the whole function type when LLVM writes it out.
    --
    -- It writes the function type for a variadic callee, as in
    -- @call i32 (ptr, ...) \@printf@, and the return type alone otherwise.
    -- Both are types, so one field holds either.
    callType :: Type
  , -- | A global for a direct call, a local for an indirect one.
    callCallee :: Value local
  , callArguments :: [Argument local]
  , callAttributes :: [AttributeItem]
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

data TailKind
  = Tail
  | MustTail
  | NoTail
  deriving (Eq, Show)

-- | An argument at a call site: a type, any attributes, and the value.
--
-- Not the same as a 'Parameter', which names its value instead of giving one.
data Argument local = Argument
  { argumentType :: Type
  , argumentAttributes :: [ParamAttribute]
  , argumentValue :: Value local
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @alloca [inalloca] \<ty\> [, \<ty\> \<count\>] [, align N] [, addrspace(N)]@.
data Alloca local = Alloca
  { allocaInalloca :: Bool
  , allocaType :: Type
  , -- | The number of elements, when more than one is asked for.
    allocaElementCount :: Maybe (TypedValue local)
  , allocaAlignment :: Maybe Natural
  , allocaAddrSpace :: Maybe Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @load [volatile] \<ty\>, ptr \<pointer\> [, align N]@.
--
-- The atomic form, with its ordering and optional syncscope, is not modelled;
-- a line carrying one stays opaque.
data Load local = Load
  { loadVolatile :: Bool
  , -- | The type loaded, which since pointers became opaque is written out
    -- rather than being recoverable from the pointer.
    loadType :: Type
  , loadPointer :: TypedValue local
  , loadAlignment :: Maybe Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @store [volatile] \<ty\> \<value\>, ptr \<pointer\> [, align N]@.
data Store local = Store
  { storeVolatile :: Bool
  , storeValue :: TypedValue local
  , storePointer :: TypedValue local
  , storeAlignment :: Maybe Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @getelementptr [flags] \<ty\>, ptr \<pointer\>, \<ty\> \<index\>, ...@.
--
-- Read back as LLVM writes it, with all its indices.  The core representation
-- is to replace this with a form computing one offset at a time, which is a
-- lowering step rather than something to do while reading.
data GetElementPtr local = GetElementPtr
  { gepFlags :: [GepFlag]
  , -- | The type being indexed into, not the type of the result.
    gepSourceType :: Type
  , gepPointer :: TypedValue local
  , gepIndices :: [TypedValue local]
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @!dbg !5@, @!llvm.loop !6@ and the like, following an instruction.
--
-- Debug locations arrive through here on the same footing as @!tbaa@ and
-- @!llvm.loop@, which is what makes carrying them cost nothing extra.
data MetadataAttachment = MetadataAttachment
  { attachmentName :: Name
  , attachmentNode :: Natural
  }
  deriving (Eq, Show)
