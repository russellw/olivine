-- | The control flow graph: simplifying it, and walking it.
--
-- Three simplifications, all of the same kind: an edge that control has no
-- choice about is not really an edge.  A block holding nothing but a branch
-- is a detour, and its predecessors can go where it went; a block holding
-- nothing but assignments is a detour too, once they stand where control came
-- from; and a block reached from one place, by a block that goes nowhere else,
-- is the rest of that block written separately.
--
-- All three run on the core, where there are no phis — that being the point of
-- the core — so a block that stops existing leaves nothing behind naming it.
-- That is what makes the second of them possible at all: a phi belongs to the
-- block it stands at and cannot be moved, where the assignments it becomes here
-- belong to the edges and can stand at either end of one.  The
-- same detours have to be removed on the way out as well, where phis exist
-- again and name the block a value arrives from; that is
-- 'Olivine.Core.Phi.removeForwarding', and it is a separate function because
-- correcting those names is the whole of what it does differently.
--
-- And one walk, 'reversePostorder', which is the order anything propagating a
-- value forwards has to go in.
module Olivine.Core.Blocks
  ( removeForwarding
  , liftAssignments
  , mergeBlocks
  , reversePostorder
  , predecessorsOf
  ) where

import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Instruction
import Olivine.Core.Program

-- | Remove blocks that do nothing but branch elsewhere.
--
-- One at a time, to a fixed point: removing a detour can leave the block
-- before it a detour in turn.
--
-- The entry block is never one of them, however little it does.  A function
-- starts where its first block is, so removing that block would start it
-- somewhere else, and the block it forwards to may well have predecessors —
-- which LLVM forbids an entry block, whatever the rest of the graph says.
--
-- A block whose address is taken is never one either.  Control can arrive at
-- it without any branch here saying so, so removing it and sending the
-- branches past it would leave that arrival with nowhere to land.
removeForwarding :: Function -> Function
removeForwarding f = f {functionBlocks = settle (functionBlocks f)}
  where
    entry = entryLabel f
    pinned = pinnedIn f

    settle blocks = case candidates blocks of
      [] -> blocks
      (block, target) : _ -> settle (remove blocks block target)

    candidates blocks =
      [ (b, target)
      | b <- blocks
      , Just (blockLabel b) /= entry
      , not (Set.member (blockLabel b) pinned)
      , null (blockInstructions b)
      , Br target <- [terminatorTransfer (blockTerminator b)]
      , -- A block branching to itself is a loop, not a detour.
        target /= blockLabel b
      ]

    remove blocks block target =
      [ b {blockTerminator = redirect (blockTerminator b)}
      | b <- blocks
      , blockLabel b /= blockLabel block
      ]
      where
        gone = blockLabel block
        redirect = retarget (\l -> if l == gone then target else l)

-- | Remove a block that does nothing but assign and then branch elsewhere, by
-- leaving its assignments where control came from.
--
-- The third detour, and it is 'removeForwarding' one step further on.  A block
-- holding nothing but assignments is a phi and no more — in single assignment
-- form that is exactly what it is written as, a block whose only content is
-- @phi@ nodes — and reconstruction will put those back at the block it branches
-- to just as well as at this one, once the assignments stand at the end of every
-- block that reaches here.  What goes is a whole block, so a phi at it goes with
-- it: what was two phis, one deciding a value here and one deciding it again
-- below, becomes the one phi below.
--
-- __Every way in must be unconditional.__  The assignments are put at the end of
-- each block that reaches this one, and a block that could go somewhere else
-- instead would then make them on that path too.  Splitting such an edge would
-- answer it, and that is a block put back for a block taken away.
--
-- The block is removed here rather than left empty for 'removeForwarding' to
-- take, and that is what makes this terminate: every step is one block fewer,
-- where lifting alone can put assignments back into a block it emptied a moment
-- ago and go round a cycle of them for ever.
liftAssignments :: Function -> Function
liftAssignments f = f {functionBlocks = settle (functionBlocks f)}
  where
    entry = entryLabel f
    pinned = pinnedIn f

    settle blocks = case candidates blocks of
      [] -> blocks
      (block, target, feeding) : _ -> settle (lift blocks block target feeding)

    candidates blocks =
      [ (b, target, feeding)
      | b <- blocks
      , Just (blockLabel b) /= entry
      , -- Control can arrive at a block whose address is taken without any
        -- branch here saying so, and such an arrival would find the assignments
        -- gone.
        not (Set.member (blockLabel b) pinned)
      , not (null (blockInstructions b))
      , all (isAssignment . instructionOperation) (blockInstructions b)
      , Br target <- [terminatorTransfer (blockTerminator b)]
      , target /= blockLabel b
      , let feeding = predecessorsOf blocks (blockLabel b)
      , -- A block nothing reaches is for the reachability walk to remove, and
        -- one that reaches itself is a loop rather than a detour.
        not (null feeding)
      , blockLabel b `notElem` feeding
      , all (onlyHere blocks (blockLabel b)) feeding
      ]

    -- Whether a block that reaches this one can go nowhere else.
    onlyHere blocks here label =
      or
        [ True
        | b <- blocks
        , blockLabel b == label
        , Br target <- [terminatorTransfer (blockTerminator b)]
        , target == here
        ]

    lift blocks block target feeding =
      [ carry b {blockTerminator = redirect (blockTerminator b)}
      | b <- blocks
      , blockLabel b /= gone
      ]
      where
        gone = blockLabel block
        redirect = retarget (\l -> if l == gone then target else l)
        carry b
          | blockLabel b `elem` feeding =
              b {blockInstructions = blockInstructions b <> blockInstructions block}
          | otherwise = b

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
    pinned = pinnedIn f

    settle blocks = case candidates blocks of
      [] -> blocks
      (above, below) : _ -> settle (merge blocks above below)

    candidates blocks =
      [ (b, below)
      | b <- blocks
      , -- Nowhere else to go: an unconditional branch is the whole
        -- terminator, so this block has the one successor.
        Br target <- [terminatorTransfer (blockTerminator b)]
      , -- A block branching to itself goes somewhere else as well as here.
        target /= blockLabel b
      , -- Nowhere else it is reached from.  The entry block is reached
        -- without being branched to, which no count of predecessors can see.
        Just target /= entry
      , -- And it is not a block something can hold the address of, which is
        -- reached by more than the one predecessor a merge can see.
        not (Set.member target pinned)
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

-- | The reachable blocks, each before every block it reaches except across a
-- back edge.
--
-- This is the order a value can be carried forwards in by one walk: a block
-- comes after the blocks control arrives from, so what arrives has been worked
-- out by the time it is wanted.  Only a back edge breaks that, and a back edge
-- is a loop, which no single walk can settle anyway.
--
-- The order blocks are written in is not this, which is worth stating because
-- it looks like it: LLVM puts no requirement on that order at all, and clang
-- does write a block before the only block that branches to it.  Reading the
-- written order as a walk order was a bug — a value propagated to a block
-- before the block it came from, and arrived as nothing.
--
-- Blocks nothing reaches are not here.  An order defined by walking forwards
-- from the entry has nowhere to put them, and no value arrives at one; a
-- caller that must still visit them has to say where itself.
reversePostorder :: Function -> [Label]
reversePostorder f = snd (maybe (Set.empty, []) (visit (Set.empty, [])) (entryLabel f))
  where
    successors =
      Map.fromList [(blockLabel b, targetsOf (blockTerminator b)) | b <- functionBlocks f]

    -- Depth first, each block going in front of everything that finished
    -- before it.  A block finishes after everything it reaches, so going in
    -- front of them all puts it before them: that is the reversal, done as the
    -- walk goes rather than to a finished list afterwards.
    visit :: (Set Label, [Label]) -> Label -> (Set Label, [Label])
    visit (seen, ordered) label
      | Set.member label seen = (seen, ordered)
      | otherwise =
          let (seen', ordered') =
                foldl'
                  visit
                  (Set.insert label seen, ordered)
                  (Map.findWithDefault [] label successors)
           in (seen', label : ordered')

-- | The blocks that branch to a given one, once each however many edges they
-- carry there.
predecessorsOf :: [Block] -> Label -> [Label]
predecessorsOf blocks target =
  [blockLabel b | b <- blocks, target `elem` targetsOf (blockTerminator b)]
