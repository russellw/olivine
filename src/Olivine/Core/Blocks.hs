-- | Simplifying the control flow graph.
--
-- Two simplifications, both of the same kind: an edge that control has no
-- choice about is not really an edge.  A block holding nothing but a branch
-- is a detour, and its predecessors can go where it went; a block reached
-- from one place, by a block that goes nowhere else, is the rest of that
-- block written separately.
--
-- Both run on the core, where there are no phis — that being the point of the
-- core — so a block that stops existing leaves nothing behind naming it.  The
-- same detours have to be removed on the way out as well, where phis exist
-- again and name the block a value arrives from; that is
-- 'Olivine.Core.Phi.removeForwarding', and it is a separate function because
-- correcting those names is the whole of what it does differently.
module Olivine.Core.Blocks
  ( removeForwarding
  , mergeBlocks
  ) where

import Olivine.Core.Program
import Olivine.Syntax.Instruction (Operation (..))

-- | Remove blocks that do nothing but branch elsewhere.
--
-- One at a time, to a fixed point: removing a detour can leave the block
-- before it a detour in turn.
--
-- The entry block is never one of them, however little it does.  A function
-- starts where its first block is, so removing that block would start it
-- somewhere else, and the block it forwards to may well have predecessors —
-- which LLVM forbids an entry block, whatever the rest of the graph says.
removeForwarding :: Function -> Function
removeForwarding f = f {functionBlocks = settle (functionBlocks f)}
  where
    entry = entryLabel f

    settle blocks = case candidates blocks of
      [] -> blocks
      (block, target) : _ -> settle (remove blocks block target)

    candidates blocks =
      [ (b, target)
      | b <- blocks
      , Just (blockLabel b) /= entry
      , null (blockInstructions b)
      , OBr target <- [terminatorOperation (blockTerminator b)]
      , -- A block branching to itself is a loop, not a detour.
        target /= blockLabel b
      ]

    remove blocks block target =
      [ retarget b
      | b <- blocks
      , blockLabel b /= blockLabel block
      ]
      where
        gone = blockLabel block
        retarget b =
          b
            { blockTerminator =
                (blockTerminator b)
                  { terminatorOperation =
                      fmap (\l -> if l == gone then target else l) $
                        terminatorOperation (blockTerminator b)
                  }
            }

-- | Merge a block into the one block that reaches it.
--
-- The condition is on both ends of the edge: the block below is reached from
-- nowhere else, and the block above goes nowhere else.  Then the branch
-- between them is not a decision, and the two are one block written as two.
--
-- One at a time, to a fixed point, as merging can leave the merged block the
-- only successor of the one above it in turn.  The block above keeps its name
-- and its place, so what a merge removes is always the lower of the two,
-- which is what makes the entry block safe: it is never the lower one, having
-- no predecessor to be reached from.
--
-- Appending one block's instructions to another is the whole of it, because
-- this runs on the core.  In LLVM the lower block could begin with phis that
-- the merge invalidates; here it cannot begin with one, so there is nothing
-- to check for and nothing to fix up.
mergeBlocks :: Function -> Function
mergeBlocks f = f {functionBlocks = settle (functionBlocks f)}
  where
    entry = entryLabel f

    settle blocks = case candidates blocks of
      [] -> blocks
      (above, below) : _ -> settle (merge blocks above below)

    candidates blocks =
      [ (b, below)
      | b <- blocks
      , -- Nowhere else to go: an unconditional branch is the whole
        -- terminator, so this block has the one successor.
        OBr target <- [terminatorOperation (blockTerminator b)]
      , -- A block branching to itself goes somewhere else as well as here.
        target /= blockLabel b
      , -- Nowhere else it is reached from.  The entry block is reached
        -- without being branched to, which no count of predecessors can see.
        Just target /= entry
      , [_] <- [predecessorsOf blocks target]
      , below <- [c | c <- blocks, blockLabel c == target]
      ]

    merge blocks above below =
      [absorb b | b <- blocks, blockLabel b /= blockLabel below]
      where
        into = blockLabel above
        absorb b
          | blockLabel b == into =
              b
                { blockInstructions = blockInstructions b <> blockInstructions below
                , blockTerminator = blockTerminator below
                }
          | otherwise = b

-- | The blocks that branch to a given one, once each however many edges they
-- carry there.
predecessorsOf :: [Block] -> Label -> [Label]
predecessorsOf blocks target =
  [blockLabel b | b <- blocks, target `elem` targetsOf (blockTerminator b)]
