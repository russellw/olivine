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
  blocks <- traverse (readBlock labels) (zip (map Label [0 ..]) written)
  pure
    Function
      { functionSignature = signature
      , functionBlocks = eliminatePhis (length written) blocks
      }
  where
    signature = Syntax.definitionSignature definition
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

-- | A block as read, before its phis have been dealt with.
data Read' = Read'
  { readLabel :: Label
  , readPhis :: [(Name, Type, [(Value, Label)])]
  , readBody :: [Instruction]
  , readTerminator :: Terminator
  }

readBlock :: Map Name Label -> (Label, Syntax.BasicBlock) -> Maybe Read'
readBlock labels (label, block) = do
  (body, terminator) <- split labels (Syntax.blockBody block)
  let (phis, rest) = partition isPhi body
  Read' label <$> traverse phi phis <*> traverse instruction rest <*> pure terminator
  where
    isPhi (Syntax.IOperation _ (OPhi _) _) = True
    isPhi _ = False
    phi (Syntax.IOperation (Just name) (OPhi p) _) =
      (name,phiType p,) <$> traverse (traverse (`Map.lookup` labels)) (phiIncoming p)
    phi _ = Nothing
    instruction (Syntax.IOperation result operation metadata) =
      (\o -> Instruction result (Perform o) metadata) <$> relabel labels operation
    instruction _ = Nothing

-- | Every destination an operation names, as the block it names.
--
-- The label is what the operation is parameterized by, so this is its
-- traversal and nothing has to know which operations have destinations.
relabel :: Map Name Label -> Syntax.Operation Name -> Maybe (Syntax.Operation Label)
relabel labels = traverse (`Map.lookup` labels)

-- | Take the terminator off the end and the rest as the body.
--
-- Anything unmodelled fails the whole definition rather than part of it: a
-- half-lowered function would have to be printed from a mixture of parsed
-- structure and remembered text, and retaining the definition whole is
-- already correct.
split ::
  Map Name Label -> [Syntax.Instruction] -> Maybe ([Syntax.Instruction], Terminator)
split labels body = case reverse body of
  Syntax.IOperation Nothing operation metadata : rest
    | isTerminator operation
    , all modelled rest ->
        (\o -> (reverse rest, Terminator o metadata)) <$> relabel labels operation
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
eliminatePhis :: Int -> [Read'] -> [Block]
eliminatePhis firstFresh blocks = concatMap build numbered
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

    -- New blocks take the numbers after the ones already written, issued
    -- across the whole function so that no two share.  Inventing a name from
    -- the two blocks the edge joins was the old way, and it could collide
    -- with a name the source had chosen; a number cannot.
    numbered = snd (foldl' issue (firstFresh, []) blocks)
    issue (next, done) b =
      let edges = zip (map Label [next ..]) (splitting b)
       in (next + length edges, done <> [(b, edges)])

    build (b, edges) =
      Block source body terminator
        : [ Block
            label
            (map assignment (sequenceCopies source copies))
            (Terminator (OBr target) [])
          | (label, (target, copies)) <- edges
          ]
      where
        source = readLabel b
        -- Assignments that can simply go at the end of this block.
        inline =
          [ copy
          | not (splits b)
          , target <- distinct (successorsOf b)
          , copy <- copiesOn source target
          ]
        body = readBody b <> map assignment (sequenceCopies source inline)
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
sequenceCopies :: Label -> [(Name, TypedValue)] -> [(Name, TypedValue)]
sequenceCopies (Label here) = go (0 :: Int)
  where
    go _ [] = []
    go n pending =
      case partition (not . isReadBy pending . fst) pending of
        (ready@(_ : _), rest) -> ready <> go n rest
        ([], (name, value) : rest) ->
          let temporary = Name Bare ("olivine.swap." <> T.pack (show here) <> "." <> T.pack (show n))
              saved = (temporary, TypedValue (typedValueType value) (VLocal name))
           in saved : go (n + 1) ((name, value) : map (substitute name temporary) rest)
        ([], []) -> []

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
