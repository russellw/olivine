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

import Olivine.Core.Instruction
import Olivine.Core.Phi (Joined (..), PhiNode (..), eliminate)
import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction (isTerminator)
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name
import Olivine.Syntax.Value (TypedValue (..))

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
    isPhi (Syntax.IOperation _ (Syntax.OPhi _) _) = True
    isPhi _ = False
    phi (Syntax.IOperation (Just name) (Syntax.OPhi p) _) =
      PhiNode
        <$> Map.lookup name locals
        <*> pure (Syntax.phiType p)
        <*> traverse
          (bitraverse (traverse (`Map.lookup` locals) . typedValue) (`Map.lookup` labels))
          (Syntax.phiIncoming p)
    phi _ = Nothing
    instruction (Syntax.IOperation result operation metadata) =
      Instruction
        <$> traverse (`Map.lookup` locals) result
        <*> lowerOperation locals operation
        <*> pure metadata
    instruction _ = Nothing
    bitraverse f g (x, y) = (,) <$> f x <*> g y

-- | One operation, on the other side of the boundary.
--
-- Renaming the locals comes first and is the derived traversal, so every
-- operand is reached whatever it is written inside; what is left is the arm
-- for each operation, which is where the two grammars actually differ.  A
-- terminator is not an operation here and fails, as does a phi, which by this
-- point 'readBlock' has taken out.
--
-- Failing fails the whole definition, which is what makes a use of a local
-- nothing defines something the core cannot be made to hold.
lowerOperation ::
  Map Name Local ->
  Syntax.Operation (TypedValue Name) ->
  Maybe (Operation (TypedValue Local))
lowerOperation locals written = do
  operation <- traverse (traverse (`Map.lookup` locals)) written
  case operation of
    Syntax.OBinary b -> Just (OBinary b)
    Syntax.OUnary u -> Just (OUnary u)
    Syntax.OICmp c -> Just (OICmp c)
    Syntax.OFCmp c -> Just (OFCmp c)
    Syntax.OConvert c -> Just (OConvert c)
    Syntax.OSelect s -> Just (OSelect s)
    Syntax.OExtractElement e -> Just (OExtractElement e)
    Syntax.OInsertElement i -> Just (OInsertElement i)
    Syntax.OShuffleVector s -> Just (OShuffleVector s)
    Syntax.OCall c -> Just (OCall c)
    Syntax.OAlloca a -> Just (OAlloca a)
    Syntax.OLoad l -> Just (OLoad l)
    Syntax.OStore s -> Just (OStore s)
    Syntax.OGetElementPtr g -> Just (OGetElementPtr g)
    Syntax.OPhi _ -> Nothing
    Syntax.ORet _ -> Nothing
    Syntax.OBr _ -> Nothing
    Syntax.OCondBr _ _ _ -> Nothing
    Syntax.OSwitch _ _ _ -> Nothing
    Syntax.OIndirectBr _ _ -> Nothing
    Syntax.OUnreachable -> Nothing

-- | One terminator, on the other side of the boundary.
--
-- Every destination becomes a 'Label' by looking it up, so a branch to a
-- block nothing defines has nothing to become and the definition is retained
-- as written rather than lowered into a graph with an edge to nowhere.
lowerTransfer ::
  Map Name Label ->
  Map Name Local ->
  Syntax.Operation (TypedValue Name) ->
  Maybe (Transfer (TypedValue Local))
lowerTransfer labels locals written = do
  operation <- traverse (traverse (`Map.lookup` locals)) written
  let target = (`Map.lookup` labels)
  case operation of
    Syntax.ORet value -> Just (Ret value)
    Syntax.OBr d -> Br <$> target d
    Syntax.OCondBr c a b -> CondBr c <$> target a <*> target b
    Syntax.OSwitch value d cases ->
      Switch value
        <$> target d
        <*> traverse (\(x, l) -> (x,) <$> target l) cases
    Syntax.OIndirectBr address ds -> IndirectBr address <$> traverse target ds
    Syntax.OUnreachable -> Just Unreachable
    _ -> Nothing

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
        (\t -> (reverse rest, Terminator t metadata))
          <$> lowerTransfer labels locals operation
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
