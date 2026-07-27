-- | Syntax to core.
--
-- Total, by the same device the syntax layer used: a definition the lowering
-- cannot take is retained as syntax rather than rejected, so a program always
-- lowers and what is not yet handled still comes back out intact.
module Olivine.Core.Lower
  ( lower
  ) where

import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction (Operation (..), isTerminator)
import Olivine.Syntax.Instruction qualified as Syntax

lower :: Syntax.Module -> Program
lower = Program . map lowerEntry . Syntax.moduleEntries

lowerEntry :: Syntax.Entry -> Entry
lowerEntry entry = case entry of
  Syntax.EDefine definition -> maybe (ERetained entry) EFunction (lowerDefinition definition)
  _ -> ERetained entry

-- | A definition lowers when every one of its blocks ends in a terminator and
-- none of them contains a phi.
--
-- Phi is the whole of what is left: eliminating one means assigning to a
-- local on each incoming edge, and reconstructing it on the way out means
-- deciding where those assignments went.  Until that is written, a function
-- containing one stays as it was.
lowerDefinition :: Syntax.Definition -> Maybe Function
lowerDefinition definition = do
  blocks <- traverse lowerBlock (Syntax.definitionBlocks definition)
  pure
    Function
      { functionSignature = Syntax.definitionSignature definition
      , functionBlocks = blocks
      }

lowerBlock :: Syntax.BasicBlock -> Maybe Block
lowerBlock block = do
  (instructions, terminator) <- split (Syntax.blockBody block)
  pure
    Block
      { blockLabel = Syntax.blockLabelName <$> Syntax.blockLabel block
      , blockInstructions = instructions
      , blockTerminator = terminator
      }

-- | Take the terminator off the end, and the rest as instructions.
--
-- Anything unmodelled, and any phi, fails the whole definition rather than
-- part of it: a half-lowered function would have to be printed from a mixture
-- of parsed structure and remembered text, and there is no reason to build
-- that when retaining the definition whole is already correct.
split :: [Syntax.Instruction] -> Maybe ([Instruction], Terminator)
split body = case reverse body of
  Syntax.IOperation Nothing operation metadata : rest
    | isTerminator operation ->
        (,) <$> traverse instruction (reverse rest) <*> pure (Terminator operation metadata)
  _ -> Nothing
  where
    instruction (Syntax.IOperation result operation metadata)
      | not (isTerminator operation), not (isPhi operation) =
          Just (Instruction result operation metadata)
    instruction _ = Nothing
    isPhi (OPhi _) = True
    isPhi _ = False
