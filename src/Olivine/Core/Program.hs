-- | The representation the optimizer works on.
--
-- It resembles LLVM's, deliberately: CLAUDE.md asks that unnecessary
-- differences be minimized, so types, names, values and operations are the
-- ones the syntax layer already defines rather than copies of them.  What
-- differs is what the optimizer needs to differ.
--
-- __A block structurally has one terminator.__  The syntax layer had to
-- represent a block that ends in the wrong thing, or in nothing, because it
-- has to read back whatever was written.  Nothing constructs a core program
-- but Olivine, so here the invariant can be part of the shape.  This is the
-- other side of the rule in CLAUDE.md: a predicate is right where invalid
-- input must survive, and structure is right where it cannot arise.
--
-- __Locals are numbered too, and for the same reason.__  A local's name is
-- its identity and nothing else — unlike a global's, which is how the rest of
-- the world refers to it — so it is a 'Local' here and a number on the way
-- out.  What this buys beyond tidiness is that a pass needing a new local
-- asks for one, where a pass inventing a name had to hope the source had not
-- chosen it already.
--
-- __A block is identified by a number, not a name.__  Nothing in the core
-- reads a block's spelling, and passes move code between blocks freely, so
-- what a block was called in the source is not information the optimizer can
-- keep true.  Labels are issued by the lowering and reissued by the raising,
-- which numbers everything unnamed the way LLVM does; between the two, a
-- label is an integer that means nothing except which block it is.
--
-- __There is no phi.__  A value that depends on which edge was taken is an
-- assignment on each edge, which is possible because locals can be
-- reassigned.  That is the one operation the core has and LLVM does not:
-- LLVM has no copy instruction, because in single assignment form it would
-- have nothing to do.
module Olivine.Core.Program
  ( Program (..)
  , Entry (..)
  , Label (..)
  , Local (..)
  , Operation (..)
  , Function (..)
  , Block (..)
  , Instruction (..)
  , Terminator (..)
  , functionsIn
  , targetsOf
  , entryLabel
  , nextLocal
  ) where

import Data.Foldable (toList)

import Olivine.Syntax.Operands (localsUsedBy)

import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function (Signature)
import Olivine.Syntax.Instruction (MetadataAttachment)
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Value qualified as Syntax

-- | A whole program.  Olivine optimizes across all of it at once, so this is
-- the unit a pass is a function of.
newtype Program = Program
  { programEntries :: [Entry]
  }
  deriving (Eq, Show)

-- | Entries keep the order they were written in, so that what comes back out
-- can be compared with what went in.
data Entry
  = EFunction Function
  | -- | Anything not lowered, carried through untouched.
    --
    -- This is the same device that let the syntax layer grow one construct at
    -- a time: what is not yet understood survives intact rather than being
    -- dropped or half-read.  It holds the globals, metadata and attribute
    -- groups, which have no core form yet, and any function definition the
    -- lowering cannot take.
    ERetained Syntax.Entry
  deriving (Eq, Show)

data Function = Function
  { -- | The signature as written, except that its parameters are nameless
    -- here.  What the body calls them is 'functionParameters', and the names
    -- LLVM will see are issued on the way out with everything else; leaving
    -- the written ones in place would be leaving something for a pass to read
    -- and be misled by.
    functionSignature :: Signature
  , -- | The parameters, as the body refers to them, in the order written.
    functionParameters :: [Local]
  , functionBlocks :: [Block]
  }
  deriving (Eq, Show)

-- | What a branch names when it names a block.
--
-- An integer rather than a 'Olivine.Syntax.Name.Name' because that is all the
-- identity a block has here: two blocks are the same block when their labels
-- are equal, and nothing else about a label means anything.  It also puts
-- minting one out of reach of collision — a pass needing a new block asks for
-- the next number, where a pass inventing a name has to hope nothing else
-- chose it.
newtype Label = Label Int
  deriving (Eq, Ord, Show)

-- | What an instruction assigns to, and what an operand names when it names
-- something the function computed.
--
-- Parameters are locals as much as results are: they are what the body reads
-- them by, and the signature's own names are written afresh on the way out
-- like everything else.
newtype Local = Local Int
  deriving (Eq, Ord, Show)

data Block = Block
  { blockLabel :: Label
  , blockInstructions :: [Instruction]
  , -- | Exactly one, and last, by construction.
    blockTerminator :: Terminator
  }
  deriving (Eq, Show)

-- | An operation and the name it assigns to its result, if any.
--
-- That the operation is not a terminator is left to
-- 'Olivine.Syntax.Instruction.isTerminator' rather than to a second type:
-- the position already says where a terminator goes.
data Instruction = Instruction
  { instructionResult :: Maybe Local
  , instructionOperation :: Operation
  , instructionMetadata :: [MetadataAttachment]
  }
  deriving (Eq, Show)

-- | What an instruction does.
--
-- Everything LLVM's instruction set has, and one thing it does not.
data Operation
  = -- | @r := value@.
    --
    -- A local may be assigned more than once, so this needs no counterpart in
    -- LLVM and has none.  It is what a phi becomes: an assignment on each
    -- edge that reaches the block the phi was at the head of.
    Assign (Syntax.TypedValue Local)
  | -- | An operation of LLVM's own, which is most of them.
    Perform (Syntax.Operation Local Label)
  deriving (Eq, Show)

-- | The operation ending a block.  A terminator assigns to nothing, so unlike
-- 'Instruction' it carries no result name.
data Terminator = Terminator
  { terminatorOperation :: Syntax.Operation Local Label
  , terminatorMetadata :: [MetadataAttachment]
  }
  deriving (Eq, Show)

functionsIn :: Program -> [Function]
functionsIn program = [f | EFunction f <- programEntries program]

-- | The blocks a terminator can branch to, in the order written.
--
-- The label positions of an operation are the only thing its 'Foldable'
-- instance visits, and in a terminator those are its destinations, so this is
-- the control flow graph.  Deriving it rather than writing out the cases
-- means a terminator added later cannot be left out of the graph.
targetsOf :: Terminator -> [Label]
targetsOf = toList . terminatorOperation

-- | A local number nothing in the function already uses.
--
-- Wanted by anything that has to invent a local after lowering — which is
-- reconstruction, placing a phi — and answered by looking, since the core
-- holds no counter.  Everything a function mentions is a result, a parameter,
-- or an operand, so those are the three places to look.
nextLocal :: Function -> Local
nextLocal f = Local (1 + maximum (-1 : [n | Local n <- used]))
  where
    used =
      functionParameters f
        <> [ local
           | b <- functionBlocks f
           , i <- blockInstructions b
           , local <- maybe [] pure (instructionResult i) <> readBy (instructionOperation i)
           ]
        <> [ local
           | b <- functionBlocks f
           , local <- localsUsedBy (terminatorOperation (blockTerminator b))
           ]
    readBy (Perform operation) = localsUsedBy operation
    readBy (Assign value) = toList value

-- | The block a function starts at, which is the first one written.
--
-- Absent only for a function with no blocks at all.  There is no rule to
-- apply beyond the order, now that the entry block has a label like any
-- other: what made this delicate before was the entry block being the one
-- block allowed to go unnamed.
entryLabel :: Function -> Maybe Label
entryLabel f = case functionBlocks f of
  block : _ -> Just (blockLabel block)
  [] -> Nothing
