-- | Core to syntax.
--
-- The inverse of "Olivine.Core.Lower", and what keeps it honest: lowering a
-- module and raising it again must give back a program that does the same
-- thing.  While the two representations still agree on everything but shape,
-- it gives back the same text.
module Olivine.Core.Raise
  ( raise
  ) where

import Data.Char (isDigit)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Core.Program
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
      { Syntax.definitionSignature = functionSignature f
      , Syntax.definitionBlocks = map (raiseBlock f) (functionBlocks f)
      }

raiseBlock :: Function -> Block -> Syntax.BasicBlock
raiseBlock f block =
  Syntax.BasicBlock
    { Syntax.blockLabel = raiseLabel <$> blockLabel block
    , Syntax.blockBody =
        map raiseInstruction (blockInstructions block)
          <> [raiseTerminator (blockTerminator block)]
    }
  where
    raiseLabel name =
      Syntax.BlockLabel
        { Syntax.blockLabelName = name
        , Syntax.blockLabelComment = predecessorComment f name
        }

raiseInstruction :: Instruction -> Syntax.Instruction
raiseInstruction i =
  Syntax.IOperation (instructionResult i) (instructionOperation i) (instructionMetadata i)

raiseTerminator :: Terminator -> Syntax.Instruction
raiseTerminator t = Syntax.IOperation Nothing (terminatorOperation t) (terminatorMetadata t)

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
    isEntry = (Just name ==) (blockLabel =<< listToMaybe (functionBlocks f))
    listToMaybe = foldr (\x _ -> Just x) Nothing
    predecessors =
      concat
        [ [blockName f b | target <- targetsOf b, target == name]
        | b <- reverse (functionBlocks f)
        ]
    reference n = "%" <> renderName n

-- | What a block is called, giving an unlabelled entry block the number LLVM
-- would have given it.
blockName :: Function -> Block -> Name
blockName f block = fromMaybe (entryName f) (blockLabel block)

-- | The number LLVM gives an unlabelled entry block.
--
-- LLVM numbers unnamed values in order, and a block takes a number like
-- anything else, so the entry block gets the one after the parameters.  A
-- parameter written @%0@ is an unnamed value whose number has been written
-- down rather than a parameter named zero, so it counts; one written @%x@ is
-- named and does not.  This is the only piece of LLVM's value numbering the
-- predecessor comment needs.
entryName :: Function -> Name
entryName f = Name Bare (T.pack (show (length numbered)))
  where
    numbered =
      [ ()
      | p <- Syntax.signatureParameters (functionSignature f)
      , maybe True (T.all isDigit . nameText) (Syntax.parameterName p)
      ]

-- | The blocks a block's terminator can branch to, in the order written.
targetsOf :: Block -> [Name]
targetsOf block = case terminatorOperation (blockTerminator block) of
  OBr target -> [target]
  OCondBr _ ifTrue ifFalse -> [ifTrue, ifFalse]
  OSwitch _ defaultTarget cases -> defaultTarget : map snd cases
  OIndirectBr _ targets -> targets
  _ -> []
