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
  , Terminator (..)
  , Transfer (..)
  , targetsOf
  , retarget
  , localsUsedBy
  , globalsUsedBy
  ) where

import Data.Foldable (toList)

import Olivine.Syntax.Instruction
  ( Alloca (..)
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
import Olivine.Syntax.Value (TypedValue (..), globalsIn)

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
  | OCall (Call operand)
  | OAlloca (Alloca operand)
  | OLoad (Load operand)
  | OStore (Store operand)
  | OGetElementPtr (GetElementPtr operand)
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
