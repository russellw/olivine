-- | Simplifying the control flow graph.
--
-- Only one simplification so far: a block holding nothing but a branch is a
-- detour, and its predecessors can go where it went.
--
-- These blocks are the ones phi elimination puts on split edges.  In the core
-- they are not empty — they hold the assignments the split exists to carry —
-- so this does not do much when run over a core program.  It does most of its
-- work after single assignment has been reconstructed, which is what empties
-- them, and the rest wherever a pass leaves a block holding nothing but a
-- branch.
module Olivine.Core.Blocks
  ( removeForwarding
  ) where

import Data.Maybe (fromMaybe)

import Olivine.Core.Program
import Olivine.Syntax.Instruction (Operation (..), Phi (..))

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
    -- Only the entry block can go unlabelled, so this is the name of that
    -- block rather than of blocks in general.  Which is not to say it is the
    -- name the function starts at: that is 'entryLabel', and differs whenever
    -- the entry block was written with a label.
    nameOf b = fromMaybe (entryName (functionSignature f)) (blockLabel b)

    settle blocks = case candidates blocks of
      [] -> blocks
      (block, target) : _ -> settle (remove blocks block target)

    predecessorsIn blocks target =
      [nameOf b | b <- blocks, target `elem` targetsOf (blockTerminator b)]

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

phisIn :: Block -> [Phi]
phisIn b = [p | i <- blockInstructions b, Perform (OPhi p) <- [instructionOperation i]]

mapPhis :: (Phi -> Phi) -> Instruction -> Instruction
mapPhis f i = case instructionOperation i of
  Perform (OPhi p) -> i {instructionOperation = Perform (OPhi (f p))}
  _ -> i
