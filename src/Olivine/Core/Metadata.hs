-- | The metadata nodes a module defines, read once for everyone who asks.
--
-- An attachment on an instruction is a name and a number — @!llvm.loop !6@ —
-- and the number is an index into a table standing at the end of the module.
-- A pass that wants to know what an attachment /says/ therefore has to have
-- the whole module in hand, which is why this is here and not in
-- "Olivine.Core.Instruction": an instruction cannot answer a question about
-- itself that is written somewhere else.
--
-- __Only the presence of a string is asked.__  The nodes that matter to an
-- optimizer are lists of markers — @!{!\"llvm.loop.mustprogress\"}@,
-- @!{!\"llvm.loop.unroll.disable\"}@ — hung off a node the loop names, and the
-- question is always whether one of them is there.  Nothing here reads a
-- node's shape, so nothing here has to know which markers take operands.
--
-- __A loop's node refers to itself.__  LLVM writes
-- @!6 = distinct !{!6, !7}@, the self reference being what keeps the node
-- distinct from the identical node of another loop, so a walk over the
-- references has to remember where it has been or it does not come back.
module Olivine.Core.Metadata
  ( Metadata
  , metadataOf
  , named
  , attachmentSays
  ) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Instruction (MetadataAttachment (..))
import Olivine.Syntax.Metadata (MetadataOperand (..))
import Olivine.Syntax.Name (nameText)

-- | @!0 = !{...}@ for every node the module defines.
newtype Metadata = Metadata (Map Natural [MetadataOperand])

-- | Read the module's table.  The nodes are retained syntax — nothing lowers
-- them, and nothing needs to — so they are found among the entries the
-- lowering carried through whole.
metadataOf :: Program -> Metadata
metadataOf program =
  Metadata
    (Map.fromList [(n, operands) | ERetained (Syntax.EMetadata n _ operands) <- programEntries program])

-- | Whether an attachment is the one named — @!llvm.loop@ and the like.
--
-- Here rather than in the caller because the name is the one part of an
-- attachment that is not the module's table, and a pass that has to reach for
-- the field to ask is a pass reading the syntax of an instruction it is
-- otherwise done reading.
named :: Text -> MetadataAttachment -> Bool
named attachment a = nameText (attachmentName a) == attachment

-- | Whether an attachment of this name holds this string anywhere within it.
--
-- Anywhere, because a marker stands one node further down than the node the
-- instruction names: a latch says @!llvm.loop !6@, @!6@ lists @!7@ among its
-- operands, and @!7@ is the string.  Following that is the whole of what a
-- reader of these needs, and stopping at the first level would find nothing at
-- all.
attachmentSays :: Metadata -> Text -> Text -> [MetadataAttachment] -> Bool
attachmentSays metadata attachment marker attachments =
  or
    [ holds metadata marker (MDRef (attachmentNode a))
    | a <- attachments
    , named attachment a
    ]

-- | Whether an operand is the string, or leads to it.
holds :: Metadata -> Text -> MetadataOperand -> Bool
holds (Metadata nodes) marker = go Set.empty
  where
    go :: Set Natural -> MetadataOperand -> Bool
    go seen operand = case operand of
      MDString text -> text == marker
      MDTuple inner -> any (go seen) inner
      MDRef n
        | Set.member n seen -> False
        | otherwise -> any (go (Set.insert n seen)) (Map.findWithDefault [] n nodes)
      MDValue _ -> False
      MDNull -> False
