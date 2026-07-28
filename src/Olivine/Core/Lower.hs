-- | Syntax to core.
--
-- Total, by the same device the syntax layer used: a definition the lowering
-- cannot take is retained as syntax rather than rejected, so a program always
-- lowers and what is not yet handled still comes back out intact.
module Olivine.Core.Lower
  ( lower
  ) where

import Data.Char (isDigit)
import Data.List (partition)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Olivine.Core.Phi (Joined (..), PhiNode (..), eliminate)
import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction (Operation (..), isTerminator)
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name
import Olivine.Syntax.Operands (traverseOperands)

lower :: Syntax.Module -> Program
lower = Program . map lowerEntry . Syntax.moduleEntries

lowerEntry :: Syntax.Entry -> Entry
lowerEntry entry = case entry of
  Syntax.EDefine definition -> maybe (ERetained entry) EFunction (lowerDefinition definition)
  _ -> ERetained entry

-- | Lower a definition, or refuse it whole.
--
-- Refusing covers a branch to a block that is not there as well as an
-- instruction that is not modelled: every label becomes a 'Label' by looking
-- it up, so a destination nothing defines has nothing to become, and the
-- definition is retained as written rather than lowered into a graph with an
-- edge to nowhere.
lowerDefinition :: Syntax.Definition -> Maybe Function
lowerDefinition definition = do
  blocks <- traverse (readBlock labels locals) (zip (map Label [0 ..]) written)
  pure
    Function
      { functionSignature = signature {Syntax.signatureParameters = nameless}
      , functionParameters = take (length parameters) (map Local [0 ..])
      , functionBlocks = eliminate (length written) (Map.size locals) blocks
      }
  where
    signature = Syntax.definitionSignature definition
    parameters = Syntax.signatureParameters signature
    written = Syntax.definitionBlocks definition

    -- Blocks are labelled by where they were written, which is the one thing
    -- about a block that cannot be ambiguous.
    labels =
      Map.fromList
        [ (nameOf block, Label i)
        | (i, block) <- zip [0 ..] written
        ]
    nameOf block =
      maybe (entryName signature) Syntax.blockLabelName (Syntax.blockLabel block)

    -- Every local the function defines, in the order written: the parameters
    -- first, then each result.  A local is defined once in LLVM, so this
    -- names every local there is, and an operand naming anything else is a
    -- use of something undefined — which fails the definition rather than
    -- lowering into a reference to nothing.
    locals =
      Map.fromList
        (zip ([name | p <- parameters, Just name <- [Syntax.parameterName p]] <> results) (map Local [0 ..]))
    results =
      [ name
      | b <- written
      , Syntax.IOperation (Just name) _ _ <- Syntax.blockBody b
      ]
    -- The names in the signature are not what the body calls the parameters
    -- any more, so they are not kept: 'functionParameters' says what is, and
    -- the raising writes the names LLVM will see.
    nameless = [p {Syntax.parameterName = Nothing} | p <- parameters]

readBlock ::
  Map Name Label -> Map Name Local -> (Label, Syntax.BasicBlock) -> Maybe Joined
readBlock labels locals (label, block) = do
  (body, terminator) <- split labels locals (Syntax.blockBody block)
  let (phis, rest) = partition isPhi body
  Joined label <$> traverse phi phis <*> traverse instruction rest <*> pure terminator
  where
    isPhi (Syntax.IOperation _ (OPhi _) _) = True
    isPhi _ = False
    phi (Syntax.IOperation (Just name) (OPhi p) _) =
      PhiNode
        <$> Map.lookup name locals
        <*> pure (Syntax.phiType p)
        <*> traverse
          (bitraverse (traverse (`Map.lookup` locals)) (`Map.lookup` labels))
          (Syntax.phiIncoming p)
    phi _ = Nothing
    instruction (Syntax.IOperation result operation metadata) =
      Instruction
        <$> traverse (`Map.lookup` locals) result
        <*> (Perform <$> rename labels locals operation)
        <*> pure metadata
    instruction _ = Nothing
    bitraverse f g (x, y) = (,) <$> f x <*> g y

-- | An operation as the core refers to what it mentions.
--
-- Two traversals that cannot be confused: the destinations are what the
-- operation is parameterized by, and the locals are inside its operands.
-- Either failing fails the whole definition, which is what makes a branch to
-- a block that is not there, or a use of a local nothing defines, something
-- the core cannot be made to hold.
rename ::
  Map Name Label ->
  Map Name Local ->
  Syntax.Operation Name Name ->
  Maybe (Syntax.Operation Local Label)
rename labels locals operation =
  traverse (`Map.lookup` labels)
    =<< traverseOperands (traverse (`Map.lookup` locals)) operation

-- | Take the terminator off the end and the rest as the body.
--
-- Anything unmodelled fails the whole definition rather than part of it: a
-- half-lowered function would have to be printed from a mixture of parsed
-- structure and remembered text, and retaining the definition whole is
-- already correct.
split ::
  Map Name Label ->
  Map Name Local ->
  [Syntax.Instruction] ->
  Maybe ([Syntax.Instruction], Terminator)
split labels locals body = case reverse body of
  Syntax.IOperation Nothing operation metadata : rest
    | isTerminator operation
    , all modelled rest ->
        (\o -> (reverse rest, Terminator o metadata)) <$> rename labels locals operation
  _ -> Nothing
  where
    modelled (Syntax.IOperation _ operation _) = not (isTerminator operation)
    modelled _ = False

-- | The number LLVM gives an unlabelled entry block.
--
-- Only the lowering needs this, and only to find what the blocks branching to
-- an unlabelled entry block call it.  Once every block has a 'Label' the
-- question does not come up again: the rule that reads a number off the
-- parameter list belongs at the edge where LLVM's names are still in force.
--
-- LLVM numbers unnamed values in order, and a block takes a number like
-- anything else, so the entry block gets the one after the parameters.  A
-- parameter written @%0@ is an unnamed value whose number has been written
-- down rather than a parameter named zero, so it counts; one written @%x@ is
-- named and does not.
entryName :: Syntax.Signature -> Name
entryName signature = Name Bare (T.pack (show (length numbered)))
  where
    numbered =
      [ ()
      | p <- Syntax.signatureParameters signature
      , maybe True (T.all isDigit . nameText) (Syntax.parameterName p)
      ]
