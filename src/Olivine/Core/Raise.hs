-- | Core to syntax.
--
-- The core lets a local be assigned as often as it likes and LLVM does not,
-- so "Olivine.Core.Ssa" puts the function back into single assignment form
-- first.  After that every instruction has an LLVM spelling and this is a
-- translation rather than a transformation.
module Olivine.Core.Raise
  ( raise
  ) where

import Data.Char (isDigit)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Core.Program
import Olivine.Core.Ssa (reconstruct)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction (Operation (..))
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
    single = reconstruct (entryName f) f

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
blockName f block = fromMaybe (entryName f) (blockLabel block)

-- | The number LLVM gives an unlabelled entry block.
--
-- LLVM numbers unnamed values in order, and a block takes a number like
-- anything else, so the entry block gets the one after the parameters.  A
-- parameter written @%0@ is an unnamed value whose number has been written
-- down rather than a parameter named zero, so it counts; one written @%x@ is
-- named and does not.
entryName :: Function -> Name
entryName f = Name Bare (T.pack (show (length numbered)))
  where
    numbered =
      [ ()
      | p <- Syntax.signatureParameters (functionSignature f)
      , maybe True (T.all isDigit . nameText) (Syntax.parameterName p)
      ]

targetsOf :: Terminator -> [Name]
targetsOf t = case terminatorOperation t of
  OBr target -> [target]
  OCondBr _ a b -> [a, b]
  OSwitch _ d cases -> d : map snd cases
  OIndirectBr _ ds -> ds
  _ -> []
