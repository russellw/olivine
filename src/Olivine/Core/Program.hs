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
-- __There is no phi.__  A value that depends on which edge was taken is an
-- assignment on each edge, which is possible because locals can be
-- reassigned.  That is the one operation the core has and LLVM does not:
-- LLVM has no copy instruction, because in single assignment form it would
-- have nothing to do.
module Olivine.Core.Program
  ( Program (..)
  , Entry (..)
  , Operation (..)
  , Function (..)
  , Block (..)
  , Instruction (..)
  , Terminator (..)
  , functionsIn
  ) where

import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function (Signature)
import Olivine.Syntax.Instruction (MetadataAttachment)
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Value qualified as Syntax
import Olivine.Syntax.Name (Name)

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
  { functionSignature :: Signature
  , functionBlocks :: [Block]
  }
  deriving (Eq, Show)

data Block = Block
  { -- | Absent for an entry block written without one.
    blockLabel :: Maybe Name
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
  { instructionResult :: Maybe Name
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
    Assign Syntax.TypedValue
  | -- | An operation of LLVM's own, which is most of them.
    Perform Syntax.Operation
  deriving (Eq, Show)

-- | The operation ending a block.  A terminator assigns to nothing, so unlike
-- 'Instruction' it carries no result name.
data Terminator = Terminator
  { terminatorOperation :: Syntax.Operation
  , terminatorMetadata :: [MetadataAttachment]
  }
  deriving (Eq, Show)

functionsIn :: Program -> [Function]
functionsIn program = [f | EFunction f <- programEntries program]
