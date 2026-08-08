-- | The one construct the core does not have, and the two conversions that
-- get rid of it and put it back.
--
-- LLVM writes a value that depends on which edge was taken as a phi at the
-- head of the block those edges meet at.  The core writes it as an assignment
-- on each edge, which is possible because a local there can be reassigned.
-- Neither form is a translation of the other block by block: the phi is one
-- instruction and the assignments are several, in blocks the phi does not name
-- and that sometimes have to be created.
--
-- So there is a shape between the two, and it is this one — a core block with
-- its phis still listed separately, which is what LLVM's block is.  The
-- lowering reads one of these per block and 'eliminate' turns them into core
-- blocks; on the way out "Olivine.Core.Ssa" produces them again and the
-- raising writes them down.  Both boundaries meet here, which is what keeps
-- phis out of "Olivine.Core.Program" entirely: a core 'Block' has no place to
-- put one, and this is where the place is.
module Olivine.Core.Phi
  ( PhiNode (..)
  , Joined (..)
  , eliminate
  , removeForwarding
  , inWrittenOrder
  ) where

import Data.List (elemIndex, partition, sortOn)
import Data.Maybe (fromMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value (TypedValue (..), Value (..))

-- | A phi: the local it assigns, the type it assigns at, and the value
-- arriving along each edge together with the block that edge comes from.
--
-- Not 'Olivine.Syntax.Instruction.Phi', which is the same thing spelled the
-- way LLVM writes it, with names for the predecessors and a place for the
-- fast-math flags a phi may carry.  Here the predecessors are labels like
-- every other destination in the core, and the flags have nowhere to go
-- because nothing between the two boundaries reads them.
data PhiNode = PhiNode
  { phiLocal :: Local
  , phiType :: Type
  , -- | The value arriving along each edge, and the block it comes from.
    phiIncoming :: [(Value Local, Label)]
  }
  deriving (Eq, Show)

-- | A core block with the phis at its head still explicit.
--
-- Everything else about it is already the core's: the instructions are core
-- instructions, the terminator is structural, and a destination is a 'Label'.
-- Only the phis are left, and only because they are what the two conversions
-- either side of this exist to remove and restore.
data Joined = Joined
  { joinedLabel :: Label
  , joinedPhis :: [PhiNode]
  , joinedInstructions :: [Instruction]
  , joinedTerminator :: Terminator
  }
  deriving (Eq, Show)

-- * Into the core

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
--
-- The two numbers are where to start issuing labels and locals: everything
-- this invents is numbered past what the function already has.
eliminate :: Int -> Int -> [Joined] -> [Block]
eliminate firstLabel firstLocal blocks = concatMap build issued
  where
    phiBlocks = [b | b <- blocks, not (null (joinedPhis b))]

    -- The assignments edge P -> B has to make.
    copiesOn source target =
      [ (phiLocal p, TypedValue (phiType p) value)
      | b <- phiBlocks
      , joinedLabel b == target
      , p <- joinedPhis b
      , value <- take 1 [v | (v, q) <- phiIncoming p, q == source]
      ]

    successorsOf b = targetsOf (joinedTerminator b)
    splits b = length (successorsOf b) > 1

    -- The edges this block must split, each becoming a block of its own.
    splitting b =
      [ (target, copies)
      | splits b
      , target <- distinct (successorsOf b)
      , let copies = copiesOn (joinedLabel b) target
      , not (null copies)
      ]

    -- Blocks put on edges, and the temporaries that breaking a cycle needs,
    -- are numbered after everything already there, issued across the whole
    -- function so that no two share.  Building a name out of the two blocks
    -- an edge joins was the old way, and it could collide with a name the
    -- source had chosen; a number cannot.
    issued = snd (foldl' issue ((firstLabel, firstLocal), []) blocks)
    issue ((freeLabel, nextTemporary), done) b =
      let (afterInline, inline) = sequenceCopies nextTemporary (inlineOn b)
          (afterEdges, edges) = spread afterInline (splitting b)
       in ( (freeLabel + length edges, afterEdges)
          , done <> [(b, inline, zip (map Label [freeLabel ..]) edges)]
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
      , copy <- copiesOn (joinedLabel b) target
      ]

    build (b, inline, edges) =
      Block (joinedLabel b) (joinedInstructions b <> map assignment inline) terminator
        : [ Block label (map assignment copies) (Terminator (Br target) [])
          | (label, (target, copies)) <- edges
          ]
      where
        renames = [(target, label) | (label, (target, _)) <- edges]
        terminator =
          retarget (\l -> fromMaybe l (lookup l renames)) (joinedTerminator b)

    assignment (name, value) = Instruction (Just name) (OAssign value) []

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

-- * Out of the core

-- | Remove blocks that do nothing but branch elsewhere.
--
-- This is what empties the blocks 'eliminate' put on split edges: their
-- assignments have become phi operands again, leaving a branch and nothing
-- else, and taking them out is what makes the trip through the core leave the
-- control flow graph as it found it.
--
-- The counterpart in "Olivine.Core.Blocks" removes the same thing and is not
-- this function, because on that side of reconstruction there are no phis.
-- Here there are, and a phi names the block a value arrives from, so a block
-- that stops existing is a name to be corrected — which is the whole
-- difference between the two and the reason they are apart.
--
-- One at a time, to a fixed point: removing a detour can leave the block
-- before it a detour in turn.  The entry block is never one of them, however
-- little it does.  A function starts where its first block is, so removing
-- that block would start it somewhere else, and the block it forwards to may
-- well have predecessors — which LLVM forbids an entry block, whatever the
-- rest of the graph says.
--
-- The pinned blocks are never detours either, however little they do: a block
-- something can hold the address of is reached by ways no branch here names,
-- so branching past it would leave a jump arriving at a block that is gone.
removeForwarding :: Set Label -> [Joined] -> [Joined]
removeForwarding pinned = settle
  where
    settle blocks = case candidates blocks of
      [] -> blocks
      (block, target) : _ -> settle (remove blocks block target)

    -- The entry block is the first one, which is the one rule there is now
    -- that every block has a label like any other.
    entryOf blocks = case blocks of
      b : _ -> Just (joinedLabel b)
      [] -> Nothing

    candidates blocks =
      [ (b, target)
      | b <- blocks
      , Just (joinedLabel b) /= entryOf blocks
      , not (Set.member (joinedLabel b) pinned)
      , null (joinedInstructions b)
      , null (joinedPhis b)
      , Br target <- [terminatorTransfer (joinedTerminator b)]
      , -- A block branching to itself is a loop, not a detour.
        target /= joinedLabel b
      , relabellable blocks (joinedLabel b) target
      ]

    -- A phi in the target names the block a value arrives from.  Removing the
    -- detour means naming what came before it instead, which only works when
    -- there is one such block, and when it is not already named by that phi:
    -- two entries for one predecessor would have to agree, and nothing here
    -- knows that they would.
    relabellable blocks name target =
      all fits [p | b <- blocks, joinedLabel b == target, p <- joinedPhis b]
      where
        fits p = case (name `elem` map snd (phiIncoming p), predecessorsOf blocks name) of
          (False, _) -> True
          (True, [before]) -> before `notElem` map snd (phiIncoming p)
          (True, _) -> False

    remove blocks block target =
      [ redirect b
      | b <- blocks
      , joinedLabel b /= joinedLabel block
      ]
      where
        gone = joinedLabel block
        before = case predecessorsOf blocks gone of
          [only] -> only
          _ -> gone
        redirect b =
          b
            { joinedPhis = map relabel (joinedPhis b)
            , joinedTerminator =
                retarget (\l -> if l == gone then target else l) (joinedTerminator b)
            }
        -- The entry naming the detour comes to name the block above it, and
        -- comes to name it once for each way that block reached the detour.
        -- A @switch@ with four cases to one detour is four edges arriving
        -- where there was one, and LLVM asks a phi for an operand per edge —
        -- one for four is what its verifier calls a phi without an entry for
        -- each predecessor.
        ways =
          length
            [ ()
            | b <- blocks
            , joinedLabel b == before
            , going <- targetsOf (joinedTerminator b)
            , going == gone
            ]
        relabel p =
          p
            { phiIncoming =
                concat
                  [ if l == gone then replicate ways (v, before) else [(v, l)]
                  | (v, l) <- phiIncoming p
                  ]
            }

-- | Put each phi's operands in the order the blocks they arrive from are
-- written.
--
-- A phi says nothing by the order of its operands, and 'Olivine.Core.Ssa' writes
-- them in the order the predecessors stand in already, so there is usually
-- nothing here to do.  What there is to do is 'removeForwarding' just above:
-- taking a detour out means naming the block before it instead, and that block
-- stands somewhere else, so the operand it now names is left out of place.
--
-- Which would still not matter, except that the trip through the core has to be
-- a fixed point — @test\/Core.hs@ asks that lowering and raising a second time
-- changes nothing — and the next trip cannot always take the same block out.
-- Where the source had a forwarding block for the copies to go in, Olivine's own
-- output has none, so 'eliminate' has to make one, and it puts a made block
-- where it puts every made block rather than where that source's block happened
-- to be.  The two trips then disagree about the order of two operands and about
-- nothing else at all.  Ordering both by where the blocks stand is what makes
-- them agree, and it is available here because by this point the blocks are the
-- ones that will be written.
--
-- The order chosen is the order of the blocks rather than LLVM's own habit,
-- which for the @; preds@ comment is the reverse of it.  What matters is that
-- there be one; this is the one reconstruction already produces everywhere it
-- was not interfered with, so it is the one that changes least.
inWrittenOrder :: [Joined] -> [Joined]
inWrittenOrder blocks = map order blocks
  where
    labels = map joinedLabel blocks
    order b =
      b {joinedPhis = [p {phiIncoming = sortOn standing (phiIncoming p)} | p <- joinedPhis b]}
    -- A value arriving from a block that is not there is a phi naming a
    -- predecessor the function does not have, which is a program to report
    -- rather than to sort; it goes last and the verifier says so.
    standing (_, from) = fromMaybe (length labels) (elemIndex from labels)

-- | The blocks that branch to a given one, once each however many edges they
-- carry there.
predecessorsOf :: [Joined] -> Label -> [Label]
predecessorsOf blocks target =
  [joinedLabel b | b <- blocks, target `elem` targetsOf (joinedTerminator b)]
