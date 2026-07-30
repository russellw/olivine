-- | Dominance, and the loops it defines.
--
-- A loop here is what a compiler means by one: a block control comes back to,
-- and the blocks it comes back through.  Finding them takes dominance, which
-- is why the two live together — nothing else in Olivine has wanted a
-- dominator yet, and nothing but loops wants one now.
--
-- __A loop is a back edge, not a shape in the source.__  The core knows
-- nothing about @for@ and @while@; what it has is a branch to a block that
-- dominates the block branching.  That is the definition every optimizer uses,
-- and it says the right thing about the loops a front end writes as goto and
-- about the ones that come out of inlining.
--
-- __Dominance is a must-analysis, so it begins from everything.__  A block is
-- dominated by whatever every path to it passes through, and the way to
-- compute that is to intersect what the predecessors say until it stops
-- changing.  As in "Olivine.Core.Pass.CommonSubexpressions", the set of every
-- fact is never written down: a block no round has reached yet is left out of
-- the map and passed over by the intersection, since meeting with everything
-- is the identity.
--
-- Unlike that pass, these rounds are plainly monotone — a round can only take
-- dominators away — so they need no bound to stop them.
--
-- __Only the reachable blocks are here.__  Dominance is about the paths from
-- the entry, and there are none to a block nothing reaches; a caller asking
-- which loops a function has does not want one made of blocks control never
-- gets to.  Control flow simplification removes them anyway, and this says the
-- same thing whether it has run or not.
module Olivine.Core.Loops
  ( dominators
  , Loop (..)
  , loopsOf
  ) where

import Data.List (sortOn)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Blocks (predecessorsOf, reversePostorder)
import Olivine.Core.Instruction
import Olivine.Core.Program

-- | For each reachable block, the blocks every path to it passes through,
-- itself among them.
--
-- The entry block is dominated by itself alone.  An edge back to it is
-- something LLVM forbids, and one would only be a path arriving from further
-- down that had already passed through here, so answering outright rather than
-- intersecting over its predecessors is not an assumption about the graph.
dominators :: Function -> Map Label (Set Label)
dominators f = settle Map.empty
  where
    blocks = functionBlocks f
    order = reversePostorder f
    reachable = Set.fromList order

    settle known
      | after == known = known
      | otherwise = settle after
      where
        after = foldl' visit known order

    visit known label = case above known label of
      -- Every way in is a block no round has reached yet, which is a block in
      -- a cycle the rounds are still working inwards to.  The next round has
      -- more to go on.
      Nothing -> known
      Just dominating -> Map.insert label (Set.insert label dominating) known

    above known label
      | entryLabel f == Just label = Just Set.empty
      | otherwise = case mapMaybe (`Map.lookup` known) (predecessors label) of
          [] -> Nothing
          first : rest -> Just (foldl' Set.intersection first rest)

    predecessors label = filter (`Set.member` reachable) (predecessorsOf blocks label)

-- | A block control returns to, and every block it returns through.
data Loop = Loop
  { -- | The one block the loop is entered at.  Everything in the body is
    -- dominated by it, which is what makes a natural loop natural and what
    -- lets a block be placed in front of it that the whole loop runs after.
    loopHeader :: Label
  , -- | The blocks control can be at between arriving at the header and
    -- branching back to it, the header among them.
    loopBody :: Set Label
  }
  deriving (Eq, Show)

-- | The natural loops of a function, each inner loop before the loop that
-- holds it.
--
-- One loop per header, however many edges come back to it.  Two back edges to
-- one header are two ways round the same loop — a body with an @if@ in it
-- writes exactly that — and treating them as two loops would mean two answers
-- about one thing and two places to put whatever is hoisted out of it.
--
-- The order is by size, which puts an inner loop first: its body is a subset
-- of the body of any loop containing it, and a proper one, since a loop
-- containing another has at least the header it is entered at.  What wants
-- that order is hoisting, which has to take a value out of the innermost loop
-- it is invariant in before the one outside can see it as invariant at all.
loopsOf :: Function -> [Loop]
loopsOf f =
  sortOn
    (Set.size . loopBody)
    [ Loop header (foldl' Set.union (Set.singleton header) (map (reaching header) latches))
    | (header, latches) <- Map.toList backEdges
    ]
  where
    blocks = functionBlocks f
    dominating = dominators f
    reachable = Map.keysSet dominating

    -- The edges that go back: a branch to a block that dominates the block
    -- branching.  A block branching to itself is one of them, its own
    -- dominator like every block.
    backEdges :: Map Label [Label]
    backEdges =
      Map.fromListWith
        (<>)
        [ (target, [blockLabel b])
        | b <- blocks
        , Just dominatorsOfBlock <- [Map.lookup (blockLabel b) dominating]
        , target <- targetsOf (blockTerminator b)
        , Set.member target dominatorsOfBlock
        ]

    -- The blocks that reach a latch without passing through the header: the
    -- body, walked backwards from the edge that closes the loop.  The header
    -- is in from the start, which is what stops the walk there.
    reaching header latch = walk (Set.singleton header) [latch]
      where
        walk seen [] = seen
        walk seen (label : rest)
          | Set.member label seen = walk seen rest
          | otherwise = walk (Set.insert label seen) (predecessors label <> rest)

    predecessors label = filter (`Set.member` reachable) (predecessorsOf blocks label)
