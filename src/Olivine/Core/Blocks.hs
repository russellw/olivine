-- | Simplifying the control flow graph.
--
-- Two simplifications, both of the same kind: an edge that control has no
-- choice about is not really an edge.  A block holding nothing but a branch
-- is a detour, and its predecessors can go where it went; a block reached
-- from one place, by a block that goes nowhere else, is the rest of that
-- block written separately.
--
-- Detours are what phi elimination puts on split edges.  In the core they are
-- not empty — they hold the assignments the split exists to carry — so
-- removing them does most of its work after single assignment has been
-- reconstructed, which is what empties them, and the rest wherever a pass
-- leaves a block holding nothing but a branch.
--
-- Both are careful about phis, which the core does not have: these run either
-- side of reconstruction, and after it a phi names the block a value arrives
-- from, so a block that stops existing is a name that has to be corrected.
module Olivine.Core.Blocks
  ( removeForwarding
  , mergeBlocks
  ) where

import Olivine.Core.Program
import Olivine.Syntax.Instruction (Operation (..), Phi (..))
import Olivine.Syntax.Name (Name)

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
    nameOf = blockName f
    predecessorsIn = predecessorsOf f

    settle blocks = case candidates blocks of
      [] -> blocks
      (block, target) : _ -> settle (remove blocks block target)

    candidates blocks =
      [ (b, target)
      | b <- blocks
      , nameOf b /= entry
      , null (blockInstructions b)
      , OBr target <- [terminatorOperation (blockTerminator b)]
      , -- A block branching to itself is a loop, not a detour.
        target /= nameOf b
      , relabellable blocks (nameOf b) target
      ]

    -- A phi in the target names the block a value arrives from.  Removing the
    -- detour means naming what came before it instead, which only works when
    -- there is one such block, and when it is not already named by that phi:
    -- two entries for one predecessor would have to agree, and nothing here
    -- knows that they would.
    relabellable blocks name target =
      all fits [p | b <- blocks, nameOf b == target, p <- phisIn b]
      where
        fits p = case (name `elem` map snd (phiIncoming p), predecessorsIn blocks name) of
          (False, _) -> True
          (True, [before]) -> before `notElem` map snd (phiIncoming p)
          (True, _) -> False

    remove blocks block target =
      [ redirect b
      | b <- blocks
      , nameOf b /= nameOf block
      ]
      where
        gone = nameOf block
        before = case predecessorsIn blocks gone of
          [only] -> only
          _ -> gone
        redirect b =
          b
            { blockInstructions = map (mapPhis relabel) (blockInstructions b)
            , blockTerminator = retarget (blockTerminator b)
            }
        relabel p =
          p {phiIncoming = [(v, if l == gone then before else l) | (v, l) <- phiIncoming p]}
        retarget t = t {terminatorOperation = go (terminatorOperation t)}
          where
            to l = if l == gone then target else l
            go (OBr d) = OBr (to d)
            go (OCondBr c a b) = OCondBr c (to a) (to b)
            go (OSwitch v d cases) = OSwitch v (to d) [(x, to l) | (x, l) <- cases]
            go (OIndirectBr v ds) = OIndirectBr v (map to ds)
            go other = other

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
mergeBlocks :: Function -> Function
mergeBlocks f = f {functionBlocks = settle (functionBlocks f)}
  where
    entry = entryLabel f
    nameOf = blockName f

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
        target /= nameOf b
      , -- Nowhere else it is reached from.  The entry block is reached
        -- without being branched to, which no count of predecessors can see.
        target /= entry
      , [_] <- [predecessorsOf f blocks target]
      , below <- [c | c <- blocks, nameOf c == target]
      , -- A phi at the head of the lower block is a value that depended on
        -- which edge arrived, and one edge arrives.  Folding it to that value
        -- is a simplification of its own rather than part of this one.
        null (phisIn below)
      ]

    merge blocks above below =
      [absorb (rename b) | b <- blocks, nameOf b /= gone]
      where
        gone = nameOf below
        into = nameOf above
        -- The blocks below branched to name it in their phis, and it is about
        -- to stop existing.  What arrives at them now comes from the block it
        -- was merged into.
        rename b = b {blockInstructions = map (mapPhis relabel) (blockInstructions b)}
        relabel p =
          p {phiIncoming = [(v, if l == gone then into else l) | (v, l) <- phiIncoming p]}
        absorb b
          | nameOf b == into =
              b
                { blockInstructions = blockInstructions b <> blockInstructions below
                , blockTerminator = blockTerminator below
                }
          | otherwise = b

-- | The blocks that branch to a given one, once each however many edges they
-- carry there.
predecessorsOf :: Function -> [Block] -> Name -> [Name]
predecessorsOf f blocks target =
  [blockName f b | b <- blocks, target `elem` targetsOf (blockTerminator b)]

phisIn :: Block -> [Phi]
phisIn b = [p | i <- blockInstructions b, Perform (OPhi p) <- [instructionOperation i]]

mapPhis :: (Phi -> Phi) -> Instruction -> Instruction
mapPhis f i = case instructionOperation i of
  Perform (OPhi p) -> i {instructionOperation = Perform (OPhi (f p))}
  _ -> i
