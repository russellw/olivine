-- | Core to syntax.
--
-- The core lets a local be assigned as often as it likes and LLVM does not,
-- so "Olivine.Core.Ssa" puts the function back into single assignment form
-- first.  After that every instruction has an LLVM spelling and this is a
-- translation rather than a transformation.
module Olivine.Core.Raise
  ( raise
  ) where

import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Core.Blocks (removeForwarding)
import Olivine.Core.Program
import Olivine.Core.Ssa (reconstruct)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderName)

raise :: Program -> Syntax.Module
raise = Syntax.Module . map raiseEntry . programEntries

raiseEntry :: Entry -> Syntax.Entry
raiseEntry (ERetained entry) = entry
raiseEntry (EFunction f) =
  Syntax.EDefine
    Syntax.Definition
      { Syntax.definitionSignature = functionSignature single
      , Syntax.definitionBlocks = map (raiseBlock single) (functionBlocks single)
      }
  where
    -- Reconstruction is what empties the blocks put on split edges: the
    -- assignments in them become phi operands, leaving a branch and nothing
    -- else.  Taking them out again is what makes the trip through the core
    -- leave the control flow graph as it found it.
    single = removeForwarding (reconstruct (entryName (functionSignature f)) f)

raiseBlock :: Function -> Block -> Syntax.BasicBlock
raiseBlock f block =
  Syntax.BasicBlock
    { Syntax.blockLabel = raiseLabel <$> blockLabel block
    , Syntax.blockBody = map raiseInstruction (blockInstructions block) <> [terminator]
    }
  where
    terminator =
      Syntax.IOperation
        Nothing
        (terminatorOperation (blockTerminator block))
        (terminatorMetadata (blockTerminator block))
    raiseLabel label =
      Syntax.BlockLabel
        { Syntax.blockLabelName = label
        , Syntax.blockLabelComment = predecessorComment f label
        }

-- | One core instruction.
--
-- No assignment survives reconstruction: each assigned value was carried to
-- where it is read, and a phi put wherever several of them meet.
raiseInstruction :: Instruction -> Syntax.Instruction
raiseInstruction i = case instructionOperation i of
  Perform operation ->
    Syntax.IOperation (instructionResult i) operation (instructionMetadata i)
  Assign _ ->
    error "Olivine.Core.Raise: an assignment survived reconstruction"

-- | The @; preds = %a, %b@ comment LLVM writes after a label.
--
-- Derived from the control flow graph rather than carried, which is what
-- having structural terminators buys: the comment states which blocks reach
-- this one, so a pass that changes control flow cannot leave it stale.
--
-- LLVM lists predecessors in reverse order of where the blocks appear, once
-- per edge rather than once per block, and writes @; No predecessors!@ for a
-- block nothing reaches.  An entry block gets no comment at all.
predecessorComment :: Function -> Name -> Maybe Text
predecessorComment f name
  | isEntry = Nothing
  | null predecessors = Just "; No predecessors!"
  | otherwise = Just ("; preds = " <> T.intercalate ", " (map reference predecessors))
  where
    isEntry = Just name == (blockLabel =<< listToMaybe (functionBlocks f))
    listToMaybe = foldr (\x _ -> Just x) Nothing
    predecessors =
      concat
        [ [blockName f b | target <- targetsOf (blockTerminator b), target == name]
        | b <- reverse (functionBlocks f)
        ]
    reference n = "%" <> renderName n

blockName :: Function -> Block -> Name
blockName f block = fromMaybe (entryName (functionSignature f)) (blockLabel block)
