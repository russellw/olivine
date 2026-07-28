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
import Data.Maybe (fromMaybe)
import Data.Text qualified as T

import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction (Operation (..), Phi (..), isTerminator)
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name
import Olivine.Syntax.Operands (traverseOperands)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value

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
      , functionBlocks = eliminatePhis (length written) (Map.size locals) blocks
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

-- | A block as read, before its phis have been dealt with.
data Read' = Read'
  { readLabel :: Label
  , readPhis :: [(Local, Type, [(Value Local, Label)])]
  , readBody :: [Instruction]
  , readTerminator :: Terminator
  }

readBlock ::
  Map Name Label -> Map Name Local -> (Label, Syntax.BasicBlock) -> Maybe Read'
readBlock labels locals (label, block) = do
  (body, terminator) <- split labels locals (Syntax.blockBody block)
  let (phis, rest) = partition isPhi body
  Read' label <$> traverse phi phis <*> traverse instruction rest <*> pure terminator
  where
    isPhi (Syntax.IOperation _ (OPhi _) _) = True
    isPhi _ = False
    phi (Syntax.IOperation (Just name) (OPhi p) _) =
      (,,)
        <$> Map.lookup name locals
        <*> pure (phiType p)
        <*> traverse (bitraverse (traverse (`Map.lookup` locals)) (`Map.lookup` labels)) (phiIncoming p)
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

-- * Phi elimination

-- | Replace every phi with assignments on the edges that reach it.
--
-- Two things make this more than moving instructions about.
--
-- An edge leaving a block with more than one successor cannot carry the
-- assignments, since appending them to that block would also run them on the
-- way to its other successors.  Such an edge is split: a new block holding
-- the assignments is put on it.
--
-- The phis at the head of a block all happen at once, on arrival.  Writing
-- them out in the order they appear is wrong when one reads a local another
-- writes — @a, b = b, a@ being the plainest case — so the assignments on each
-- edge are ordered so that every local is read before it is written, and a
-- cycle is broken with a temporary.
eliminatePhis :: Int -> Int -> [Read'] -> [Block]
eliminatePhis firstLabel firstLocal blocks = concatMap build issued
  where
    phiBlocks = [b | b <- blocks, not (null (readPhis b))]

    -- The assignments edge P -> B has to make.
    copiesOn source target =
      [ (name, TypedValue t value)
      | b <- phiBlocks
      , readLabel b == target
      , (name, t, incoming) <- readPhis b
      , value <- take 1 [v | (v, p) <- incoming, p == source]
      ]

    successorsOf b = targetsOf (readTerminator b)
    splits b = length (successorsOf b) > 1

    -- The edges this block must split, each becoming a block of its own.
    splitting b =
      [ (target, copies)
      | splits b
      , target <- distinct (successorsOf b)
      , let copies = copiesOn (readLabel b) target
      , not (null copies)
      ]

    -- Blocks put on edges, and the temporaries that breaking a cycle needs,
    -- are numbered after everything already there, issued across the whole
    -- function so that no two share.  Building a name out of the two blocks
    -- an edge joins was the old way, and it could collide with a name the
    -- source had chosen; a number cannot.
    issued = snd (foldl' issue ((firstLabel, firstLocal), []) blocks)
    issue ((nextLabel, nextLocal), done) b =
      let (afterInline, inline) = sequenceCopies nextLocal (inlineOn b)
          (afterEdges, edges) = spread afterInline (splitting b)
       in ( (nextLabel + length edges, afterEdges)
          , done <> [(b, inline, zip (map Label [nextLabel ..]) edges)]
          )
    -- Each edge's copies in turn, each picking up where the last left off.
    spread next [] = (next, [])
    spread next ((target, copies) : rest) =
      let (after, sequenced) = sequenceCopies next copies
          (afterRest, others) = spread after rest
       in (afterRest, (target, sequenced) : others)

    -- Assignments that can simply go at the end of the block itself.
    inlineOn b =
      [ copy
      | not (splits b)
      , target <- distinct (successorsOf b)
      , copy <- copiesOn (readLabel b) target
      ]

    build (b, inline, edges) =
      Block (readLabel b) (readBody b <> map assignment inline) terminator
        : [ Block label (map assignment copies) (Terminator (OBr target) [])
          | (label, (target, copies)) <- edges
          ]
      where
        terminator =
          retarget [(target, label) | (label, (target, _)) <- edges] (readTerminator b)

    assignment (name, value) = Instruction (Just name) (Assign value) []

-- | Send a terminator's branches to the blocks that were put on its edges.
retarget :: [(Label, Label)] -> Terminator -> Terminator
retarget renames t = t {terminatorOperation = fmap to (terminatorOperation t)}
  where
    to label = fromMaybe label (lookup label renames)

-- | Order a set of simultaneous assignments so that running them one after
-- another has the same effect.
--
-- An assignment may be emitted once nothing left to do still reads what it
-- writes.  When every remaining assignment is read by another they form a
-- cycle, which is broken by saving one local in a temporary and reading the
-- temporary instead.
sequenceCopies ::
  Int -> [(Local, TypedValue Local)] -> (Int, [(Local, TypedValue Local)])
sequenceCopies = go
  where
    go n [] = (n, [])
    go n pending =
      case partition (not . isReadBy pending . fst) pending of
        (ready@(_ : _), rest) -> (ready <>) <$> go n rest
        ([], (name, value) : rest) ->
          let temporary = Local n
              saved = (temporary, TypedValue (typedValueType value) (VLocal name))
           in (saved :) <$> go (n + 1) ((name, value) : map (substitute name temporary) rest)
        ([], []) -> (n, [])

    isReadBy pending name =
      or [reads' name v | (_, v) <- pending]
    reads' name (TypedValue _ (VLocal other)) = name == other
    reads' _ _ = False
    substitute name temporary (dst, TypedValue t (VLocal other))
      | other == name = (dst, TypedValue t (VLocal temporary))
    substitute _ _ copy = copy

distinct :: Eq a => [a] -> [a]
distinct = foldr (\x xs -> x : filter (/= x) xs) []

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
