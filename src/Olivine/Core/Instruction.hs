-- | What the optimizer works on: LLVM's instruction set, less what the core
-- does without and plus the one thing it adds.
--
-- __There is no phi.__  A value that depends on which edge was taken is an
-- assignment on each edge, which is possible because a local here can be
-- reassigned.  That is the one operation the core has and LLVM does not: LLVM
-- has no copy instruction, because in single assignment form it would have
-- nothing to do.  Putting the phis back is "Olivine.Core.Phi"'s business, at
-- the two boundaries, and there is nowhere between them to write one.
--
-- __A terminator is a type of its own.__  In "Olivine.Syntax.Instruction" it
-- is a subset of the instructions marked by a predicate, because that layer
-- has to read back a block that ends in the wrong thing.  Here it cannot: a
-- block holds a 'Transfer' in a slot of its own, so an instruction cannot be
-- one and a block cannot lack one.  This is the other side of the rule in
-- CLAUDE.md — a predicate is right where invalid input must survive, and
-- structure is right where it cannot arise.
--
-- __A destination is a number.__  Nothing here reads a block's spelling, and
-- passes move code between blocks freely, so what a block was called in the
-- source is not information the optimizer can keep true.  The consequence
-- worth stating is that 'Label' is not the type parameter: what the derived
-- instances reach is the operands and only the operands, so rewriting them is
-- 'fmap' and cannot touch control flow, and moving control flow is
-- 'retarget' and cannot touch operands.
--
-- __Nothing here walks an operation.__  The operand is the type parameter and
-- every operand slot holds it, so every question a pass asks of an operation
-- is a derived instance: rewriting the operands is 'fmap', reading them off is
-- 'Data.Foldable.toList', and 'localsUsedBy' and 'globalsUsedBy' are those
-- composed with the operand's own.  Adding an instruction to this grammar is
-- one constructor and nothing else — there is no list of operations anywhere
-- that a new one could be left out of, which there was until the operands
-- became uniform enough for the compiler to write the walk.
module Olivine.Core.Instruction
  ( Local (..)
  , Label (..)
  , Instruction (..)
  , Operation (..)
  , Offset (..)
  , Field (..)
  , Terminator (..)
  , Transfer (..)
  , targetsOf
  , retarget
  , resultOf
  , localsUsedBy
  , globalsUsedBy
  , resultType
  , speculatable
  ) where

import Data.Foldable (toList)
import Data.Map.Strict (Map)
import Numeric.Natural (Natural)

import Olivine.Syntax.Instruction
  ( Alloca (..)
  , AtomicLoad (..)
  , AtomicRmw (..)
  , AtomicStore (..)
  , Binary (..)
  , BinaryOp (..)
  , Call (..)
  , CmpXchg (..)
  , Compare (..)
  , Convert (..)
  , Fence (..)
  , ExtractElement (..)
  , ExtractValue (..)
  , FloatPredicate
  , InsertElement (..)
  , InsertValue (..)
  , IntPredicate
  , LandingPad (..)
  , Load (..)
  , MetadataAttachment
  , Select (..)
  , ShuffleVector (..)
  , Store (..)
  , Unary (..)
  )
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Packedness (..), Type (..), elementOf, insideOf, resolveNamed)
import Olivine.Syntax.Value (GepFlag, TypedValue (..), globalsIn)

-- | What an instruction assigns to, and what an operand names when it names
-- something the function computed.
--
-- An integer rather than a 'Name' because a local's name is its identity and
-- nothing else — unlike a global's, which is how the rest of the world refers
-- to it.  What that buys beyond tidiness is that a pass needing a new local
-- asks for one, where a pass inventing a name had to hope the source had not
-- chosen it already.
--
-- Parameters are locals as much as results are: they are what the body reads
-- them by, and the signature's own names are written afresh on the way out.
newtype Local = Local Int
  deriving (Eq, Ord, Show)

-- | What a branch names when it names a block.
--
-- All the identity a block has here: two blocks are the same block when their
-- labels are equal, and nothing else about a label means anything.  It also
-- puts minting one out of reach of collision — a pass needing a new block asks
-- for the next number.
newtype Label = Label Int
  deriving (Eq, Ord, Show)

-- | An operation and the name it assigns to its result, if any.
data Instruction = Instruction
  { instructionResult :: Maybe Local
  , instructionOperation :: Operation (TypedValue Local)
  , instructionMetadata :: [MetadataAttachment]
  }
  deriving (Eq, Show)

-- | What an instruction does.
--
-- LLVM's instruction set without the terminators, without @phi@, and with
-- assignment.
data Operation operand
  = -- | @r := value@.
    --
    -- A local may be assigned more than once, so this needs no counterpart in
    -- LLVM and has none.  It is what a phi becomes: an assignment on each
    -- edge that reaches the block the phi was at the head of.
    OAssign operand
  | OBinary (Binary operand)
  | OUnary (Unary operand)
  | OICmp (Compare IntPredicate operand)
  | OFCmp (Compare FloatPredicate operand)
  | OConvert (Convert operand)
  | OSelect (Select operand)
  | OExtractElement (ExtractElement operand)
  | OInsertElement (InsertElement operand)
  | OShuffleVector (ShuffleVector operand)
  | -- | Reading a field out of an aggregate held as a value, and writing one
    -- into it.  What a struct small enough to travel in registers is passed
    -- and returned as.
    OExtractValue (ExtractValue operand)
  | OInsertValue (InsertValue operand)
  | OCall (Call operand)
  | OAlloca (Alloca operand)
  | OLoad (Load operand)
  | OStore (Store operand)
  | -- | The atomic accesses.  Each is an ordering constraint as well as
    -- whatever it does to memory, which is why none of them is a flag on the
    -- plain access it resembles: a pass deciding something about a load has
    -- to decide it about these separately or not at all.
    OAtomicLoad (AtomicLoad operand)
  | OAtomicStore (AtomicStore operand)
  | OAtomicRmw (AtomicRmw operand)
  | OCmpXchg (CmpXchg operand)
  | -- | An ordering and nothing else: it names no address.
    OFence Fence
  | -- | One step along a pointer, and the reason this grammar exists
    -- separately from LLVM's.
    OOffset (Offset operand)
  | -- | One step into a struct.
    OField (Field operand)
  | -- | What an unwinder leaves at the head of a block it resumes the
    -- function in.
    --
    -- An instruction and not a slot on the block, although LLVM requires it
    -- to stand first: a block that holds one is thereby not empty, and the
    -- passes that take a block out of the graph are the ones that ask whether
    -- it holds anything.  That it stands first is the core verifier's to say,
    -- and it says it after every pass.
    OLandingPad (LandingPad operand)
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @p + index * sizeof(ty)@.
--
-- LLVM's @getelementptr@ takes a list of indices and walks a type with them,
-- so reading one means knowing what type each index lands in and what the
-- next one therefore means.  CLAUDE.md asks for a form that calculates one
-- offset at a time, and this is it: a type to stride over, a pointer, and how
-- many strides.  A chain of these says what one @getelementptr@ said, with
-- nothing left implicit between the steps.
--
-- The index is an operand, so it may be anything a value may be — this is the
-- form an array subscript takes, and the subscript is usually not known.
data Offset operand = Offset
  { offsetFlags :: [GepFlag]
  , -- | What one stride covers, not the type of the result.  A pointer has no
    -- pointee type here any more than it does in LLVM.
    offsetElementType :: Type
  , offsetPointer :: operand
  , offsetIndex :: operand
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | @p + offsetof(ty, index)@.
--
-- The other kind of step, and it is not an 'Offset' because it is not a
-- stride: a struct's fields need not be the same size, so where the @k@th
-- begins is what the data layout says and not @k@ times anything.
--
-- The index is a number rather than an operand because LLVM requires a
-- constant there, and because an offset nothing can compute until run time is
-- not an offset into a struct.  That the field exists is a verifier's
-- business; that the index is constant is this type's.
data Field operand = Field
  { fieldFlags :: [GepFlag]
  , -- | The struct being stepped into, which is what names the field.  Held
    -- as it was written, so a named type stays named.
    fieldStructType :: Type
  , fieldPointer :: operand
  , fieldIndex :: Natural
  }
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | The operation ending a block.  A terminator assigns to nothing, so unlike
-- 'Instruction' it carries no result name.
data Terminator = Terminator
  { terminatorTransfer :: Transfer (TypedValue Local)
  , terminatorMetadata :: [MetadataAttachment]
  }
  deriving (Eq, Show)

-- | How a block passes control on.
data Transfer operand
  = -- | @ret void@, or @ret \<ty\> \<value\>@.
    Ret (Maybe operand)
  | Br Label
  | CondBr operand Label Label
  | -- | The value switched on, where it goes when nothing matches, and the
    -- cases.  LLVM requires the case values to be constants;
    -- 'Olivine.Syntax.Value.isConstant' is what asks, rather than the shape of
    -- the data.
    Switch operand Label [(operand, Label)]
  | IndirectBr operand [Label]
  | Unreachable
  | -- | A call that ends its block: what it assigns, the call itself, where
    -- control goes when it returns, and where it goes when it throws.
    --
    -- The one transfer that names a result, which is why the name is here
    -- rather than beside the transfer: a @ret@ with a result name is then not
    -- a thing that can be written down.  It is not an operand and 'fmap' does
    -- not reach it, the same rule 'Label' keeps to.
    --
    -- What it holds is a 'Call' and not a copy of one, so a pass asking what
    -- a call does asks it in one way wherever the call stands.  The value it
    -- assigns arrives only along the normal edge; nothing in the unwind
    -- destination may read it, which the verifier checks because the
    -- dominance rule alone would allow it.
    Invoke (Maybe Local) (Call operand) Label Label
  | -- | Carry on unwinding with what the landing pad was handed.
    Resume operand
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | The blocks a terminator can branch to, in the order written.
--
-- This is the control flow graph.  Written out case by case with no catch-all,
-- so that a transfer added later fails to compile here rather than quietly
-- reporting that it goes nowhere.
targetsOf :: Terminator -> [Label]
targetsOf = go . terminatorTransfer
  where
    go (Ret _) = []
    go (Br target) = [target]
    go (CondBr _ true false) = [true, false]
    go (Switch _ target cases) = target : map snd cases
    go (IndirectBr _ targets) = targets
    go Unreachable = []
    go (Invoke _ _ normal unwind) = [normal, unwind]
    go (Resume _) = []

-- | Send every branch somewhere else.
--
-- The counterpart of 'fmap', and the reason 'Label' is not the type
-- parameter: this reaches the destinations and nothing else, where 'fmap'
-- reaches the operands and nothing else, so neither can be reached for by
-- mistake.  No catch-all here either.
retarget :: (Label -> Label) -> Terminator -> Terminator
retarget f t = t {terminatorTransfer = go (terminatorTransfer t)}
  where
    go (Ret value) = Ret value
    go (Br target) = Br (f target)
    go (CondBr condition true false) = CondBr condition (f true) (f false)
    go (Switch value target cases) =
      Switch value (f target) [(x, f label) | (x, label) <- cases]
    go (IndirectBr address targets) = IndirectBr address (map f targets)
    go Unreachable = Unreachable
    go (Invoke result call normal unwind) =
      Invoke result call (f normal) (f unwind)
    go (Resume value) = Resume value

-- | What a terminator assigns, which only an @invoke@ does.
--
-- The counterpart of 'Olivine.Core.Program.blockInstructions' answering
-- 'instructionResult': anything asking what a function defines has to ask it
-- of the terminators too, now that one of them defines something.  Written out
-- case by case for the reason 'targetsOf' is.
resultOf :: Terminator -> Maybe Local
resultOf = go . terminatorTransfer
  where
    go (Invoke result _ _ _) = result
    go (Ret _) = Nothing
    go (Br _) = Nothing
    go (CondBr _ _ _) = Nothing
    go (Switch _ _ _) = Nothing
    go (IndirectBr _ _) = Nothing
    go Unreachable = Nothing
    go (Resume _) = Nothing

-- | The locals something reads, however deeply they are written.
--
-- Two derived instances composed, under a name that says what they reach: the
-- outer one visits the operands, the inner one the locals inside each.  A
-- local written inside an aggregate is reached like any other, which matters
-- because nothing valid puts one there but a pass asking what it may remove
-- should not be the thing that decides so.
localsUsedBy :: (Foldable f, Foldable g) => f (g local) -> [local]
localsUsedBy = concatMap toList . toList

-- | The globals something names, including from inside its constants.
--
-- The callee of a call is an operand like any other, so a call names what it
-- calls here without this having to know what a call is — and without anything
-- here having to know what an operation is either, which is the point of the
-- operand being the type parameter.
globalsUsedBy :: Foldable f => f (TypedValue local) -> [Name]
globalsUsedBy = concatMap (globalsIn . typedValue) . toList

-- | What an operation leaves in the local it assigns to, 'TVoid' when it
-- leaves nothing.
--
-- The core writes down what an instruction reads and not what it produces, so
-- this is the rule that says what a result is worth.  Where an operation is
-- itself malformed the answer is a guess — the element type of something that
-- is not a vector is that thing — and the guess costs nothing, because the
-- only thing that cares whether an operation is well formed is the verifier,
-- which reports the malformation either way.
--
-- Two callers want it for different reasons: the verifier, to say what a
-- local was assigned at, and a pass rewriting one computation into a copy of
-- another, to say what the copy carries.  It lives here because it is a fact
-- about the grammar rather than about either of them.
resultType :: Map Name Type -> Operation (TypedValue local) -> Type
resultType types operation = case operation of
  OAssign value -> typedValueType value
  OBinary b -> typedValueType (binaryLeft b)
  OUnary u -> typedValueType (unaryOperand u)
  OICmp c -> boolean (typedValueType (compareLeft c))
  OFCmp c -> boolean (typedValueType (compareLeft c))
  OConvert c -> convertTarget c
  OSelect s -> typedValueType (selectTrue s)
  OExtractElement e -> elementOf types (typedValueType (extractElementVector e))
  OInsertElement i -> typedValueType (insertElementVector i)
  OExtractValue e ->
    insideOf types (typedValueType (extractValueAggregate e)) (extractValueIndices e)
  -- The whole aggregate comes back, whatever was written into it.
  OInsertValue i -> typedValueType (insertValueAggregate i)
  OShuffleVector s -> shuffled s
  -- The whole function type is written here for a variadic callee and the
  -- return type alone otherwise, so what a call produces is the return type of
  -- either.
  OCall c -> case callType c of
    TFunction returns _ _ -> returns
    t -> t
  OAlloca a -> TPointer (allocaAddrSpace a)
  OLoad l -> loadType l
  OStore _ -> TVoid
  OAtomicLoad l -> atomicLoadType l
  OAtomicStore _ -> TVoid
  -- What was there before, which is of the type of the value written against
  -- it.
  OAtomicRmw r -> typedValueType (atomicRmwValue r)
  -- What was there, and whether it was replaced.  That pair is why aggregate
  -- values and lock-free code arrive together.
  OCmpXchg c -> TStruct Unpacked [typedValueType (cmpXchgCompare c), TInteger 1]
  OFence _ -> TVoid
  -- A step along a pointer gives back a pointer into the same address space,
  -- which is what the operand already is.
  OOffset o -> typedValueType (offsetPointer o)
  OField field -> typedValueType (fieldPointer field)
  OLandingPad p -> landingPadType p
  where
    -- A comparison of vectors is a vector of answers.
    boolean t = case resolveNamed types t of
      TVector scale n _ -> TVector scale n (TInteger 1)
      _ -> TInteger 1

    -- A shuffle is as long as its mask and as wide as what it shuffles.
    shuffled s =
      case ( resolveNamed types (typedValueType (shuffleVectorLeft s))
           , resolveNamed types (typedValueType (shuffleVectorMask s))
           ) of
        (TVector _ _ element, TVector scale n _) -> TVector scale n element
        _ -> typedValueType (shuffleVectorLeft s)

-- | Whether an operation may be run where the program would not have run it.
--
-- Two questions at once, and an operation has to answer both: that it leaves
-- the same value behind whenever its operands are the same, and that running it
-- where the original would not have run it changes nothing else.  Written out
-- case by case with no catch-all, so that an operation added to the grammar
-- later fails to compile here rather than being quietly taken for one that can
-- be moved.
--
-- Two passes want it, and neither of them for a reason the other shares.
-- "Olivine.Core.Pass.LoopInvariants" computes a value before a loop that may
-- never be entered; "Olivine.Core.Pass.IfConversion" runs both sides of a
-- branch where control took one.  What they have in common is the whole of what
-- is asked here, which is why it is a fact about the grammar and lives with the
-- grammar rather than in either of them.
--
-- A load answers the first question in neither direction here, since what it
-- answers depends on what happens to memory in between and, for the second, on
-- whether the address can be read at all where it is being put.  Both are
-- questions about a place rather than about an operation, so this says only that
-- nothing about a load on its own settles them.
speculatable :: Operation operand -> Bool
speculatable operation = case operation of
  -- A copy saves nothing by being made earlier — reconstruction removes every
  -- assignment on the way out of the core, so there is no instruction here to
  -- pay for.  It is moved because it is what stands between a pass and the value
  -- it is looking at: promotion turns every load of a slot into a copy where the
  -- load was, so what an operand names is rarely the value it stands for.
  OAssign _ -> True
  -- May do anything, and may answer differently each time it is asked.
  OCall _ -> False
  -- Fresh storage each time, so one allocation is not the allocations that were
  -- asked for.
  OAlloca _ -> False
  -- What an unwinder left, which is a fact about how control arrived here and
  -- not a computation at all.  There is nowhere else it could stand.
  OLandingPad _ -> False
  -- The answer is whatever memory holds, and a store or a call in between may
  -- change that.  Nor is the pointer necessarily one that can be read at all
  -- where the load is being put.
  OLoad _ -> False
  -- Writes memory, so moving it changes when the write happens.
  OStore _ -> False
  -- Every atomic operation orders the accesses around it, and where an
  -- ordering takes effect is the whole of what it is for.  Running one early
  -- is running it somewhere else, which is a different program however
  -- harmless the value it leaves behind.
  OAtomicLoad _ -> False
  OAtomicStore _ -> False
  OAtomicRmw _ -> False
  OCmpXchg _ -> False
  OFence _ -> False
  OBinary b -> not (undefinedByZero (binaryOp b))
  OUnary _ -> True
  OICmp _ -> True
  OFCmp _ -> True
  OConvert _ -> True
  OSelect _ -> True
  OExtractElement _ -> True
  OInsertElement _ -> True
  OShuffleVector _ -> True
  -- An index that does not fit the aggregate is a program the verifier
  -- rejects rather than one that faults, so reading one early is safe.
  OExtractValue _ -> True
  OInsertValue _ -> True
  -- Pointer arithmetic says where something is rather than what is there, and
  -- one that runs off the end of its object is poison rather than a fault.
  OOffset _ -> True
  OField _ -> True

-- | Whether an opcode undefines the program on operands it can be given.
--
-- The integer divisions, and only those: dividing by zero is undefined
-- behaviour in LLVM rather than poison, so one of these run where the program
-- would not have run it is behaviour invented rather than behaviour preserved.
-- Everything else here answers poison at worst — a shift past the width, an
-- @nsw@ addition that overflows — which is a value nothing goes on to read.
--
-- Floating point division is not one of them: dividing by zero is an infinity,
-- and the default environment traps on nothing.
undefinedByZero :: BinaryOp -> Bool
undefinedByZero op = case op of
  OpUDiv -> True
  OpSDiv -> True
  OpURem -> True
  OpSRem -> True
  OpAdd -> False
  OpSub -> False
  OpMul -> False
  OpShl -> False
  OpLShr -> False
  OpAShr -> False
  OpAnd -> False
  OpOr -> False
  OpXor -> False
  OpFAdd -> False
  OpFSub -> False
  OpFMul -> False
  OpFDiv -> False
  OpFRem -> False

