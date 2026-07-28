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
-- instances reach is the locals and only the locals, so renaming operands is
-- 'fmap' and cannot touch control flow, and moving control flow is
-- 'retarget' and cannot touch operands.
module Olivine.Core.Instruction
  ( Local (..)
  , Label (..)
  , Instruction (..)
  , Operation (..)
  , Terminator (..)
  , Transfer (..)
  , targetsOf
  , retarget
  , Operands (..)
  , mapValues
  , valuesIn
  , localsUsedBy
  , globalsUsedBy
  ) where

import Data.Foldable (toList)
import Data.Functor.Const (Const (..))
import Data.Functor.Identity (Identity (..))

import Olivine.Syntax.Instruction
  ( Alloca (..)
  , Argument (..)
  , Binary (..)
  , Call (..)
  , Compare (..)
  , Convert (..)
  , ExtractElement (..)
  , FloatPredicate
  , GetElementPtr (..)
  , InsertElement (..)
  , IntPredicate
  , Load (..)
  , MetadataAttachment
  , Select (..)
  , ShuffleVector (..)
  , Store (..)
  , Unary (..)
  )
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Value (TypedValue (..), Value, globalsIn)

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
  , instructionOperation :: Operation Local
  , instructionMetadata :: [MetadataAttachment]
  }
  deriving (Eq, Show)

-- | What an instruction does.
--
-- LLVM's instruction set without the terminators, without @phi@, and with
-- assignment.
data Operation local
  = -- | @r := value@.
    --
    -- A local may be assigned more than once, so this needs no counterpart in
    -- LLVM and has none.  It is what a phi becomes: an assignment on each
    -- edge that reaches the block the phi was at the head of.
    OAssign (TypedValue local)
  | OBinary (Binary local)
  | OUnary (Unary local)
  | OICmp (Compare IntPredicate local)
  | OFCmp (Compare FloatPredicate local)
  | OConvert (Convert local)
  | OSelect (Select local)
  | OExtractElement (ExtractElement local)
  | OInsertElement (InsertElement local)
  | OShuffleVector (ShuffleVector local)
  | OCall (Call local)
  | OAlloca (Alloca local)
  | OLoad (Load local)
  | OStore (Store local)
  | OGetElementPtr (GetElementPtr local)
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | The operation ending a block.  A terminator assigns to nothing, so unlike
-- 'Instruction' it carries no result name.
data Terminator = Terminator
  { terminatorTransfer :: Transfer Local
  , terminatorMetadata :: [MetadataAttachment]
  }
  deriving (Eq, Show)

-- | How a block passes control on.
data Transfer local
  = -- | @ret void@, or @ret \<ty\> \<value\>@.
    Ret (Maybe (TypedValue local))
  | Br Label
  | CondBr (TypedValue local) Label Label
  | -- | The value switched on, where it goes when nothing matches, and the
    -- cases.  LLVM requires the case values to be constants;
    -- 'Olivine.Syntax.Value.isConstant' is what asks, rather than the shape of
    -- the data.
    Switch (TypedValue local) Label [(TypedValue local, Label)]
  | IndirectBr (TypedValue local) [Label]
  | Unreachable
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

-- | Visiting the operands of an operation or of a transfer.
--
-- Renaming what a local is called is 'fmap' and reading the locals off is
-- 'Data.Foldable.toList', so neither comes through here.  What does is
-- everything those cannot express: putting a whole value where a local was,
-- which is what folding a constant and reconstructing single assignment both
-- do, and finding the globals, which are not the type parameter and never
-- will be.
--
-- Everything here comes from the one traversal, so reading the operands and
-- rewriting them cannot disagree: an operand missed by one is missed by both,
-- and a single test finds it.  Two grammars cost two of these, and this is the
-- whole of what the fork costs; the counterpart is
-- 'Olivine.Syntax.Operands.valuesIn'.
class Operands f where
  traverseValues ::
    Applicative m => (Value local -> m (Value local')) -> f local -> m (f local')

instance Operands Operation where
  traverseValues f operation = case operation of
    OAssign value -> OAssign <$> typed value
    OBinary b ->
      (\l r -> OBinary b {binaryLeft = l, binaryRight = r})
        <$> f (binaryLeft b)
        <*> f (binaryRight b)
    OUnary u -> (\x -> OUnary u {unaryOperand = x}) <$> f (unaryOperand u)
    OICmp c -> OICmp <$> comparison c
    OFCmp c -> OFCmp <$> comparison c
    OConvert c ->
      (\x -> OConvert c {convertOperand = x}) <$> typed (convertOperand c)
    OSelect s ->
      (\c t e -> OSelect s {selectCondition = c, selectTrue = t, selectFalse = e})
        <$> typed (selectCondition s)
        <*> typed (selectTrue s)
        <*> typed (selectFalse s)
    OExtractElement e ->
      (\v i -> OExtractElement e {extractElementVector = v, extractElementIndex = i})
        <$> typed (extractElementVector e)
        <*> typed (extractElementIndex e)
    OInsertElement i ->
      ( \v x n ->
          OInsertElement
            i {insertElementVector = v, insertElementValue = x, insertElementIndex = n}
      )
        <$> typed (insertElementVector i)
        <*> typed (insertElementValue i)
        <*> typed (insertElementIndex i)
    OShuffleVector s ->
      ( \l r m ->
          OShuffleVector
            s {shuffleVectorLeft = l, shuffleVectorRight = r, shuffleVectorMask = m}
      )
        <$> typed (shuffleVectorLeft s)
        <*> typed (shuffleVectorRight s)
        <*> typed (shuffleVectorMask s)
    OCall c ->
      (\callee arguments -> OCall c {callCallee = callee, callArguments = arguments})
        <$> f (callCallee c)
        <*> traverse argument (callArguments c)
    OAlloca a ->
      (\n -> OAlloca a {allocaElementCount = n})
        <$> traverse typed (allocaElementCount a)
    OLoad l -> (\p -> OLoad l {loadPointer = p}) <$> typed (loadPointer l)
    OStore s ->
      (\x p -> OStore s {storeValue = x, storePointer = p})
        <$> typed (storeValue s)
        <*> typed (storePointer s)
    OGetElementPtr g ->
      (\p i -> OGetElementPtr g {gepPointer = p, gepIndices = i})
        <$> typed (gepPointer g)
        <*> traverse typed (gepIndices g)
    where
      typed (TypedValue t x) = TypedValue t <$> f x
      comparison c =
        (\l r -> c {compareLeft = l, compareRight = r})
          <$> f (compareLeft c)
          <*> f (compareRight c)
      argument a = (\x -> a {argumentValue = x}) <$> f (argumentValue a)

instance Operands Transfer where
  traverseValues f transfer = case transfer of
    Ret value -> Ret <$> traverse typed value
    Br target -> pure (Br target)
    CondBr condition true false ->
      (\c -> CondBr c true false) <$> typed condition
    Switch value target cases ->
      Switch
        <$> typed value
        <*> pure target
        <*> traverse (\(x, l) -> (,l) <$> typed x) cases
    IndirectBr address targets -> (`IndirectBr` targets) <$> typed address
    Unreachable -> pure Unreachable
    where
      typed (TypedValue t x) = TypedValue t <$> f x

-- | Put a value where each operand was.
mapValues :: Operands f => (Value local -> Value local') -> f local -> f local'
mapValues f = runIdentity . traverseValues (Identity . f)

-- | Every operand, in the order written.
valuesIn :: forall f local. Operands f => f local -> [Value local]
valuesIn = getConst . traverseValues collect
  where
    collect :: Value local -> Const [Value local] (Value local)
    collect x = Const [x]

-- | The locals something reads, however deeply they are written.
--
-- The derived instance, under a name that says what it reaches: a local
-- written inside an aggregate is reached like any other, which matters
-- because nothing valid puts one there but a pass asking what it may remove
-- should not be the thing that decides so.
localsUsedBy :: Foldable f => f local -> [local]
localsUsedBy = toList

-- | The globals something names, including from inside its constants.
--
-- The callee of a call is an operand like any other, so a call names what it
-- calls here without this having to know what a call is.
globalsUsedBy :: Operands f => f local -> [Name]
globalsUsedBy = concatMap globalsIn . valuesIn
