-- | The shape of a program the optimizer works on.
--
-- What an instruction does is "Olivine.Core.Instruction"; this is what holds
-- them.  Types, values, signatures and attributes are the ones the syntax
-- layer already defines rather than copies of them, since CLAUDE.md asks that
-- unnecessary differences be minimized and there is no difference to have: a
-- type is a type and a global's name is a global's name at either end.
--
-- __A block structurally has one terminator.__  The syntax layer had to
-- represent a block that ends in the wrong thing, or in nothing, because it
-- has to read back whatever was written.  Nothing constructs a core program
-- but Olivine, so here the invariant is part of the shape.
module Olivine.Core.Program
  ( Program (..)
  , Entry (..)
  , Function (..)
  , Block (..)
  , functionsIn
  , entryLabel
  , nextLocal
  , nextLabel
  ) where

import Olivine.Core.Instruction

import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function (Signature)

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

data Block = Block
  { blockLabel :: Label
  , blockInstructions :: [Instruction]
  , -- | Exactly one, and last, by construction.
    blockTerminator :: Terminator
  }
  deriving (Eq, Show)

functionsIn :: Program -> [Function]
functionsIn program = [f | EFunction f <- programEntries program]

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
           , local <-
              maybe [] pure (instructionResult i)
                <> localsUsedBy (instructionOperation i)
           ]
        <> [ local
           | b <- functionBlocks f
           , local <- localsUsedBy (terminatorTransfer (blockTerminator b))
           ]

-- | A block number nothing in the function already uses.
--
-- The counterpart of 'nextLocal', wanted by anything that has to invent a
-- block — which is inlining, splitting the block a call sits in.  Branch
-- targets are looked at as well as the blocks themselves, for the reason
-- operands are looked at there: a destination naming a block that is not
-- present still names it, and issuing that number would silently connect the
-- two.
nextLabel :: Function -> Label
nextLabel f = Label (1 + maximum (-1 : [n | Label n <- used]))
  where
    used =
      map blockLabel (functionBlocks f)
        <> concatMap (targetsOf . blockTerminator) (functionBlocks f)

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
