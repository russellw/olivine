-- | Syntax to core.
--
-- Total, by the same device the syntax layer used: a definition the lowering
-- cannot take is retained as syntax rather than rejected, so a program always
-- lowers and what is not yet handled still comes back out intact.
module Olivine.Core.Lower
  ( lower
  ) where

import Data.List (partition)
import Data.Maybe (fromMaybe, mapMaybe)
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

lowerDefinition :: Syntax.Definition -> Maybe Function
lowerDefinition definition = do
  blocks <- traverse readBlock (Syntax.definitionBlocks definition)
  let entry = entryName (Syntax.definitionSignature definition)
  pure
    Function
      { functionSignature = Syntax.definitionSignature definition
      , functionBlocks = eliminatePhis entry blocks
      }

-- | A block as read, before its phis have been dealt with.
data Read' = Read'
  { readLabel :: Maybe Name
  , readPhis :: [(Name, Type, [(Value, Name)])]
  , readBody :: [Instruction]
  , readTerminator :: Terminator
  }

readBlock :: Syntax.BasicBlock -> Maybe Read'
readBlock block = do
  (body, terminator) <- split (Syntax.blockBody block)
  let (phis, rest) = partition isPhi body
  pure
    Read'
      { readLabel = Syntax.blockLabelName <$> Syntax.blockLabel block
      , readPhis = mapMaybe phi phis
      , readBody = mapMaybe instruction rest
      , readTerminator = terminator
      }
  where
    isPhi (Syntax.IOperation _ (OPhi _) _) = True
    isPhi _ = False
    phi (Syntax.IOperation (Just name) (OPhi p) _) =
      Just (name, phiType p, phiIncoming p)
    phi _ = Nothing
    instruction (Syntax.IOperation result operation metadata) =
      Just (Instruction result (Perform operation) metadata)
    instruction _ = Nothing

-- | Take the terminator off the end and the rest as the body.
--
-- Anything unmodelled fails the whole definition rather than part of it: a
-- half-lowered function would have to be printed from a mixture of parsed
-- structure and remembered text, and retaining the definition whole is
-- already correct.
split :: [Syntax.Instruction] -> Maybe ([Syntax.Instruction], Terminator)
split body = case reverse body of
  Syntax.IOperation Nothing operation metadata : rest
    | isTerminator operation
    , all modelled rest ->
        Just (reverse rest, Terminator operation metadata)
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
eliminatePhis :: Name -> [Read'] -> [Block]
eliminatePhis entry blocks = concatMap rewrite blocks
  where
    named b = fromMaybe entry (readLabel b)
    phiBlocks = [b | b <- blocks, not (null (readPhis b))]

    -- The assignments edge P -> B has to make.
    copiesOn source target =
      [ (name, TypedValue t value)
      | b <- phiBlocks
      , named b == target
      , (name, t, incoming) <- readPhis b
      , value <- take 1 [v | (v, p) <- incoming, p == source]
      ]

    successorsOf b = targetsOf (readTerminator b)
    splits b = length (successorsOf b) > 1

    rewrite b =
      let source = named b
          targets = successorsOf b
          -- Edges this block must split, each becoming a block of its own.
          toSplit =
            [ (target, copies)
            | splits b
            , target <- distinct targets
            , let copies = copiesOn source target
            , not (null copies)
            ]
          renames = [(target, splitName source target) | (target, _) <- toSplit]
          -- Assignments that can simply go at the end of this block.
          inline =
            [ copy
            | not (splits b)
            , target <- distinct targets
            , copy <- copiesOn source target
            ]
          body =
            readBody b
              <> map assignment (sequenceCopies source inline)
          terminator = retarget renames (readTerminator b)
       in Block (readLabel b) body terminator
            : [ Block
                (Just (splitName source target))
                (map assignment (sequenceCopies source copies))
                (Terminator (OBr target) [])
              | (target, copies) <- toSplit
              ]

    assignment (name, value) = Instruction (Just name) (Assign value) []

-- | A name for the block put on the edge from one block to another.
splitName :: Name -> Name -> Name
splitName source target =
  Name Bare ("olivine.edge." <> nameText source <> "." <> nameText target)

-- | Send a terminator's branches to the blocks that were put on its edges.
retarget :: [(Name, Name)] -> Terminator -> Terminator
retarget renames t = t {terminatorOperation = go (terminatorOperation t)}
  where
    to name = fromMaybe name (lookup name renames)
    go (OBr d) = OBr (to d)
    go (OCondBr c a b) = OCondBr c (to a) (to b)
    go (OSwitch v d cases) = OSwitch v (to d) [(x, to l) | (x, l) <- cases]
    go (OIndirectBr v ds) = OIndirectBr v (map to ds)
    go other = other

-- | Order a set of simultaneous assignments so that running them one after
-- another has the same effect.
--
-- An assignment may be emitted once nothing left to do still reads what it
-- writes.  When every remaining assignment is read by another they form a
-- cycle, which is broken by saving one local in a temporary and reading the
-- temporary instead.
sequenceCopies :: Name -> [(Name, TypedValue)] -> [(Name, TypedValue)]
sequenceCopies here = go (0 :: Int)
  where
    go _ [] = []
    go n pending =
      case partition (not . isReadBy pending . fst) pending of
        (ready@(_ : _), rest) -> ready <> go n rest
        ([], (name, value) : rest) ->
          let temporary = Name Bare ("olivine.swap." <> nameText here <> "." <> T.pack (show n))
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

-- | The blocks a terminator can branch to, in the order written.
targetsOf :: Terminator -> [Name]
targetsOf t = case terminatorOperation t of
  OBr target -> [target]
  OCondBr _ a b -> [a, b]
  OSwitch _ d cases -> d : map snd cases
  OIndirectBr _ ds -> ds
  _ -> []

distinct :: Eq a => [a] -> [a]
distinct = foldr (\x xs -> x : filter (/= x) xs) []

-- | The number LLVM gives an unlabelled entry block: the one after the
-- parameters, counting those whose names are numbers written down.
entryName :: Syntax.Signature -> Name
entryName signature = Name Bare (T.pack (show (length numbered)))
  where
    numbered =
      [ ()
      | p <- Syntax.signatureParameters signature
      , maybe True (T.all (`elem` ("0123456789" :: String)) . nameText) (Syntax.parameterName p)
      ]
