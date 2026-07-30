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
-- __Every record holding operands is parameterized by the operand.__  Not by
-- what a local is called, and not by anything else: an operand slot holds the
-- parameter and nothing stands beside it describing it.  So the derived
-- instances reach exactly the operands, and every question anybody asks of an
-- operation — which values it reads, which locals, which globals, and what it
-- becomes when one is rewritten — is 'fmap', 'traverse' or
-- 'Data.Foldable.toList' over them.  None of it is written by hand, so adding
-- an instruction cannot leave one of those answers stale.
--
-- What it costs is that an operand carries its own type where LLVM writes the
-- type once for several — @add i32 %a, %b@ stores @i32@ twice.  That is the
-- price of the slot being uniform, and it is cheaper than the alternative,
-- which is one type standing apart from the operands it describes and going
-- stale the first time a pass rewrites one of them.
--
-- These records are the part of the instruction set that syntax and core
-- genuinely share — an @add@ is an @add@ whether its operands are called @%x@
-- or @%3@ — and both grammars instantiate them at their own operand.
module Olivine.Syntax.Instruction
  ( Instruction (..)
  , Operation (..)
  , isTerminator
  , destinationsOf
  , Binary (..)
  , BinaryOp (..)
  , Unary (..)
  , UnaryOp (..)
  , Convert (..)
  , Select (..)
  , ExtractElement (..)
  , InsertElement (..)
  , ExtractValue (..)
  , InsertValue (..)
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
  , AtomicOrdering (..)
  , AtomicLoad (..)
  , AtomicStore (..)
  , AtomicRmw (..)
  , RmwOp (..)
  , CmpXchg (..)
  , Fence (..)
  , GetElementPtr (..)
  , MetadataAttachment (..)
  ) where

import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Syntax.Attribute (AttributeItem, ParamAttribute)
import Olivine.Syntax.Linkage (CallingConvention)
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value (CastOp, GepFlag, TypedValue)

data Instruction
  = -- | An operation, the name it assigns to its result if it has one, and
    -- the metadata attached to it.
    --
    -- Whether an operation may name a result is a verifier's business: a
    -- @store@ must not and a @load@ must, and neither is said here.
    IOperation (Maybe Name) (Operation (TypedValue Name)) [MetadataAttachment]
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
data Operation operand
  = -- | @ret void@, or @ret \<ty\> \<value\>@.
    ORet (Maybe operand)
  | -- | @br label %dest@.
    OBr Name
  | -- | @br i1 \<cond\>, label %then, label %else@.
    OCondBr operand Name Name
  | -- | @switch \<ty\> \<value\>, label %default [ ... ]@.  LLVM requires the
    -- case values to be constants; 'Olivine.Syntax.Value.isConstant' is what
    -- asks, rather than the shape of the data.
    OSwitch operand Name [(operand, Name)]
  | -- | @indirectbr \<ty\> \<address\>, [label %a, label %b]@.
    OIndirectBr operand [Name]
  | OUnreachable
  | -- | @add nsw i32 %a, %b@ and its relatives, integer, bitwise and
    -- floating point alike.
    OBinary (Binary operand)
  | -- | @fneg double %a@, the only unary arithmetic operation.
    OUnary (Unary operand)
  | -- | @icmp slt i32 %a, %b@.
    OICmp (Compare IntPredicate operand)
  | -- | @fcmp olt double %a, %b@.
    OFCmp (Compare FloatPredicate operand)
  | -- | @zext nneg i32 %a to i64@ and the other conversions.
    OConvert (Convert operand)
  | -- | @select [flags] \<selty\> \<cond\>, \<ty\> \<a\>, \<ty\> \<b\>@.
    OSelect (Select operand)
  | -- | @extractelement \<n x ty\> \<vector\>, \<ty\> \<index\>@.
    OExtractElement (ExtractElement operand)
  | -- | @insertelement \<n x ty\> \<vector\>, \<ty\> \<value\>, \<ty\> \<index\>@.
    OInsertElement (InsertElement operand)
  | -- | @shufflevector \<n x ty\> \<a\>, \<n x ty\> \<b\>, \<m x i32\> \<mask\>@.
    OShuffleVector (ShuffleVector operand)
  | -- | @extractvalue \<aggty\> \<val\>, \<idx\>{, \<idx\>}*@.
    OExtractValue (ExtractValue operand)
  | -- | @insertvalue \<aggty\> \<val\>, \<ty\> \<elt\>, \<idx\>{, \<idx\>}*@.
    OInsertValue (InsertValue operand)
  | -- | @phi \<ty\> [ \<value\>, %pred ], ...@.
    OPhi (Phi operand)
  | -- | @call@, direct or indirect, with or without a result.
    OCall (Call operand)
  | OAlloca (Alloca operand)
  | OLoad (Load operand)
  | OStore (Store operand)
  | -- | The atomic accesses, each an ordering constraint as well as whatever
    -- it does to memory.
    OAtomicLoad (AtomicLoad operand)
  | OAtomicStore (AtomicStore operand)
  | OAtomicRmw (AtomicRmw operand)
  | OCmpXchg (CmpXchg operand)
  | -- | An ordering and nothing else.
    OFence Fence
  | OGetElementPtr (GetElementPtr operand)
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | Whether an operation ends its basic block.
--
-- That a block holds exactly one of these, last, is an invariant for a
-- verifier rather than something the syntax enforces: this layer has to be
-- able to read back a module that gets it wrong.
isTerminator :: Operation operand -> Bool
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
isTerminator (OExtractValue _) = False
isTerminator (OInsertValue _) = False
isTerminator (OPhi _) = False
isTerminator (OCall _) = False
isTerminator (OAlloca _) = False
isTerminator (OLoad _) = False
isTerminator (OStore _) = False
isTerminator (OAtomicLoad _) = False
isTerminator (OAtomicStore _) = False
isTerminator (OAtomicRmw _) = False
isTerminator (OCmpXchg _) = False
isTerminator (OFence _) = False
isTerminator (OGetElementPtr _) = False

-- | The blocks an operation may transfer control to, in the order written,
-- once for each edge rather than once for each block.
--
-- A block written twice is two edges — @br i1 %c, label %j, label %j@ is one
-- of them, and a @switch@ sending two cases to one place is another — and
-- LLVM counts them that way where it matters, which is that a phi has one
-- entry for each.  A destination is a 'Name' here and not a block, so nothing
-- but the function it belongs to can say what it refers to.
destinationsOf :: Operation operand -> [Name]
destinationsOf operation = case operation of
  OBr destination -> [destination]
  OCondBr _ ifTrue ifFalse -> [ifTrue, ifFalse]
  OSwitch _ fallback cases -> fallback : map snd cases
  OIndirectBr _ destinations -> destinations
  _ -> []

-- | A binary operation: an opcode, its flags, and the operands.
--
-- LLVM writes the type once — @add i32 %a, %b@ — and this used to store it
-- once to match.  It is on each operand instead, because an operand carrying
-- its own type is what lets the compiler write the walk over them, and
-- because one type standing apart from the operands it describes is a second
-- thing to keep true when a pass rewrites one of them.  The printer takes the
-- type it writes from the left operand.
data Binary operand = Binary
  { binaryOp :: BinaryOp
  , binaryFlags :: [InstructionFlag]
  , binaryLeft :: operand
  , binaryRight :: operand
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

data Unary operand = Unary
  { unaryOp :: UnaryOp
  , unaryFlags :: [InstructionFlag]
  , unaryOperand :: operand
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

data UnaryOp
  = OpFNeg
  deriving (Eq, Show)

-- | @\<op\> [flags] \<ty\> \<value\> to \<ty\>@.
data Convert operand = Convert
  { convertOp :: CastOp
  , convertFlags :: [InstructionFlag]
  , convertOperand :: operand
  , convertTarget :: Type
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | A comparison, parameterized by which set of predicates it draws on.
--
-- @icmp@ and @fcmp@ share their shape and differ only in that, so one record
-- serves both without letting an integer comparison take a floating point
-- predicate.
data Compare predicate operand = Compare
  { compareFlags :: [InstructionFlag]
  , comparePredicate :: predicate
  , compareLeft :: operand
  , compareRight :: operand
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
data Select operand = Select
  { selectFlags :: [InstructionFlag]
  , selectCondition :: operand
  , selectTrue :: operand
  , selectFalse :: operand
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

data ExtractElement operand = ExtractElement
  { extractElementVector :: operand
  , extractElementIndex :: operand
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

data InsertElement operand = InsertElement
  { insertElementVector :: operand
  , insertElementValue :: operand
  , insertElementIndex :: operand
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | Reading a field out of an aggregate /value/, which is what a struct small
-- enough to travel in registers becomes: a returned pair arrives as one of
-- these rather than through memory.
--
-- __The indices stay a list.__  This is where @getelementptr@'s walk was
-- split into one step at a time, and the reason not to do the same here is
-- that the other half of the pair could not follow: @insertvalue@ into a
-- nested aggregate is not a sequence of inserts but a read of the inner
-- value, an insert into that, and an insert of the result back, so splitting
-- would write out a different program rather than the same one said plainly.
-- The indices are numbers because LLVM requires constants there, unlike a
-- vector's index, which may be computed.
data ExtractValue operand = ExtractValue
  { extractValueAggregate :: operand
  , extractValueIndices :: [Natural]
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | Writing a field into an aggregate value, giving back the whole of it.
--
-- The value written carries its own type, the aggregate carries the type the
-- path is read against, and neither says what the other is.
data InsertValue operand = InsertValue
  { insertValueAggregate :: operand
  , insertValueValue :: operand
  , insertValueIndices :: [Natural]
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | The mask is an ordinary operand rather than a list of indices: LLVM
-- writes it as a vector constant, and @zeroinitializer@ is a common spelling
-- of one, which a list of numbers could not hold.
data ShuffleVector operand = ShuffleVector
  { shuffleVectorLeft :: operand
  , shuffleVectorRight :: operand
  , shuffleVectorMask :: operand
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
data Phi operand = Phi
  { phiFlags :: [InstructionFlag]
  , -- | Kept although each operand carries its own, because a phi with no
    -- incoming edges would otherwise have no type at all.  Nothing rewrites a
    -- phi's operands — the core has no phi to rewrite — so the two cannot
    -- drift apart the way an arithmetic operation's would.
    phiType :: Type
  , -- | The value arriving along each edge, and the block it comes from.
    phiIncoming :: [(operand, Name)]
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @[tail] call [flags] [cconv] [ret attrs] \<ty\> \<callee\>(\<args\>) [attrs]@.
--
-- Inline assembly and operand bundles are not modelled; a call carrying
-- either stays opaque.  @invoke@ and @callbr@, which are calls that also
-- branch, are still to come.
data Call operand = Call
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
    --
    -- Not the callee's own type, which is why this stays a field of its own
    -- while the arithmetic operations lost theirs: the callee is a pointer
    -- and this is what the call returns.
    callType :: Type
  , -- | A global for a direct call, a local for an indirect one.
    --
    -- An operand like any other, carrying the pointer type it has.  LLVM does
    -- not write that type here, so the printer does not either.
    callCallee :: operand
  , callArguments :: [Argument operand]
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
data Argument operand = Argument
  { argumentAttributes :: [ParamAttribute]
  , argumentValue :: operand
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @alloca [inalloca] \<ty\> [, \<ty\> \<count\>] [, align N] [, addrspace(N)]@.
data Alloca operand = Alloca
  { allocaInalloca :: Bool
  , -- | The type allocated, which is not any operand's type.
    allocaType :: Type
  , -- | The number of elements, when more than one is asked for.
    allocaElementCount :: Maybe operand
  , allocaAlignment :: Maybe Natural
  , allocaAddrSpace :: Maybe Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | How strongly an atomic operation is ordered against the others.
--
-- Written as LLVM writes it, which for two of them is not the words they are
-- named by: @acq_rel@ and @seq_cst@.
data AtomicOrdering
  = Unordered
  | Monotonic
  | Acquire
  | Release
  | AcquireRelease
  | SequentiallyConsistent
  deriving (Eq, Show)

-- | @load atomic [volatile] \<ty\>, ptr \<pointer\> [syncscope(\"s\")]
-- \<ordering\> [, align N]@.
--
-- An operation of its own rather than a flag on 'Load', although LLVM writes
-- it as one word.  What it buys is that every place a pass decides something
-- about a load has to say what it decides about this separately: an atomic
-- access is an ordering constraint as well as an access, and the answers a
-- plain load gets — that two of them may share a value, that one may be
-- hoisted out of a loop — are not answers to give here.  A flag would have
-- been read by whoever remembered to read it.
--
-- The scope is the text between the quotes.  Which scopes a target has is the
-- target's business and nothing here decides anything by them.
data AtomicLoad operand = AtomicLoad
  { atomicLoadVolatile :: Bool
  , atomicLoadType :: Type
  , atomicLoadPointer :: operand
  , atomicLoadScope :: Maybe Text
  , atomicLoadOrdering :: AtomicOrdering
  , atomicLoadAlignment :: Maybe Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @store atomic [volatile] \<ty\> \<value\>, ptr \<pointer\>
-- [syncscope(\"s\")] \<ordering\> [, align N]@.
data AtomicStore operand = AtomicStore
  { atomicStoreVolatile :: Bool
  , atomicStoreValue :: operand
  , atomicStorePointer :: operand
  , atomicStoreScope :: Maybe Text
  , atomicStoreOrdering :: AtomicOrdering
  , atomicStoreAlignment :: Maybe Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @atomicrmw [volatile] \<op\> ptr \<pointer\>, \<ty\> \<value\>
-- [syncscope(\"s\")] \<ordering\> [, align N]@.
--
-- Reads, computes, and writes back in one indivisible step, answering with
-- what was there before.
data AtomicRmw operand = AtomicRmw
  { atomicRmwVolatile :: Bool
  , atomicRmwOp :: RmwOp
  , atomicRmwPointer :: operand
  , atomicRmwValue :: operand
  , atomicRmwScope :: Maybe Text
  , atomicRmwOrdering :: AtomicOrdering
  , atomicRmwAlignment :: Maybe Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | What an @atomicrmw@ does to the value it finds.
--
-- The whole list LLVM has, confirmed one spelling at a time by handing each to
-- @llvm-as@: an opcode missing from here is a line that stays opaque, and a
-- line that stays opaque is a whole function the optimizer passes over.
data RmwOp
  = RmwXchg
  | RmwAdd
  | RmwSub
  | RmwAnd
  | RmwNand
  | RmwOr
  | RmwXor
  | RmwMax
  | RmwMin
  | RmwUMax
  | RmwUMin
  | RmwFAdd
  | RmwFSub
  | RmwFMax
  | RmwFMin
  | RmwFMaximum
  | RmwFMinimum
  | RmwUIncWrap
  | RmwUDecWrap
  | RmwUSubCond
  | RmwUSubSat
  deriving (Eq, Show)

-- | @cmpxchg [weak] [volatile] ptr \<pointer\>, \<ty\> \<compare\>, \<ty\>
-- \<new\> [syncscope(\"s\")] \<success\> \<failure\> [, align N]@.
--
-- Answers with a pair: what was there, and whether it was replaced.  Reading
-- that pair apart is @extractvalue@, which is why the aggregate operations and
-- this arrive together in real code.
data CmpXchg operand = CmpXchg
  { cmpXchgWeak :: Bool
  , cmpXchgVolatile :: Bool
  , cmpXchgPointer :: operand
  , cmpXchgCompare :: operand
  , cmpXchgReplacement :: operand
  , cmpXchgScope :: Maybe Text
  , cmpXchgSuccess :: AtomicOrdering
  , cmpXchgFailure :: AtomicOrdering
  , cmpXchgAlignment :: Maybe Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @fence [syncscope(\"s\")] \<ordering\>@.
--
-- Touches no address and names no operand: it orders the accesses either side
-- of it and does nothing else.  Not parameterized by the operand type for
-- exactly that reason.
data Fence = Fence
  { fenceScope :: Maybe Text
  , fenceOrdering :: AtomicOrdering
  }
  deriving (Eq, Show)

-- | @load [volatile] \<ty\>, ptr \<pointer\> [, align N]@.
--
-- The atomic form is 'AtomicLoad', which is an operation of its own.
data Load operand = Load
  { loadVolatile :: Bool
  , -- | The type loaded, which since pointers became opaque is written out
    -- rather than being recoverable from the pointer.
    loadType :: Type
  , loadPointer :: operand
  , loadAlignment :: Maybe Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @store [volatile] \<ty\> \<value\>, ptr \<pointer\> [, align N]@.
data Store operand = Store
  { storeVolatile :: Bool
  , storeValue :: operand
  , storePointer :: operand
  , storeAlignment :: Maybe Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @getelementptr [flags] \<ty\>, ptr \<pointer\>, \<ty\> \<index\>, ...@.
--
-- Read back as LLVM writes it, with all its indices.  The core representation
-- is to replace this with a form computing one offset at a time, which is a
-- lowering step rather than something to do while reading.
data GetElementPtr operand = GetElementPtr
  { gepFlags :: [GepFlag]
  , -- | The type being indexed into, not the type of the result.
    gepSourceType :: Type
  , gepPointer :: operand
  , gepIndices :: [operand]
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
