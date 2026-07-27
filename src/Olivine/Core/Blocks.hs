-- | Simplifying the control flow graph.
--
-- Only one simplification so far: a block holding nothing but a branch is a
-- detour, and its predecessors can go where it went.
--
-- These blocks are the ones phi elimination puts on split edges.  In the core
-- they are not empty — they hold the assignments the split exists to carry —
-- so this cannot yet run as a pass over a program.  It runs after single
-- assignment has been reconstructed, which is what empties them.  When a pass
-- can leave a block empty by other means, the same function will serve there
-- unchanged.
module Olivine.Core.Blocks
  ( removeForwarding
  ) where

import Data.Maybe (fromMaybe)

import Olivine.Core.Program
import Olivine.Syntax.Instruction (Operation (..), Phi (..))
import Olivine.Syntax.Name

-- | Remove blocks that do nothing but branch elsewhere.
--
-- One at a time, to a fixed point: removing a detour can leave the block
-- before it a detour in turn.
removeForwarding :: Name -> [Block] -> [Block]
removeForwarding entry blocks = case candidates of
  [] -> blocks
  (block, target) : _ -> removeForwarding entry (remove block target)
  where
    nameOf b = fromMaybe entry (blockLabel b)
    predecessorsOf target =
      [nameOf b | b <- blocks, target `elem` targetsOf b]

    candidates =
      [ (b, target)
      | b <- blocks
      , nameOf b /= entry
      , null (blockInstructions b)
      , OBr target <- [terminatorOperation (blockTerminator b)]
      , -- A block branching to itself is a loop, not a detour.
        target /= nameOf b
      , relabellable (nameOf b) target
      ]

    -- A phi in the target names the block a value arrives from.  Removing the
    -- detour means naming what came before it instead, which only works when
    -- there is one such block, and when it is not already named by that phi:
    -- two entries for one predecessor would have to agree, and nothing here
    -- knows that they would.
    relabellable name target =
      all fits [p | b <- blocks, nameOf b == target, p <- phisIn b]
      where
        fits p = case (name `elem` map snd (phiIncoming p), predecessorsOf name) of
          (False, _) -> True
          (True, [before]) -> before `notElem` map snd (phiIncoming p)
          (True, _) -> False

    remove block target =
      [ redirect b
      | b <- blocks
      , nameOf b /= nameOf block
      ]
      where
        gone = nameOf block
        before = case predecessorsOf gone of
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

targetsOf :: Block -> [Name]
targetsOf b = case terminatorOperation (blockTerminator b) of
  OBr t -> [t]
  OCondBr _ a c -> [a, c]
  OSwitch _ d cases -> d : map snd cases
  OIndirectBr _ ds -> ds
  _ -> []
