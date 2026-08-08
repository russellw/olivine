-- | Turning a loop that tests on the way in into one that tests on the way
-- out.
--
-- A @while@ loop arrives as a header that decides whether to go round and a
-- body that branches back to it, so the block the loop is certain to run is the
-- test and the block it may never run is everything the loop was written for.
-- Rotation copies the test into the block above the loop, which then decides
-- whether the loop is entered at all, and leaves the loop entered at its body:
-- a @do@ loop under an @if@.  The instructions are the same instructions run in
-- the same order — what changes is which block control arrives at first.
--
-- __What it is for.__  The header is the one block a loop runs whenever it is
-- entered, and that is the fact "Olivine.Core.Pass.LoopInvariants" spends: a
-- load can come out of a loop that may never run only if reading the address
-- cannot fault, and the way to know it can is for the load to stand where the
-- loop is certain to reach it.  Before rotation the header holds the test, so
-- the loads a front end writes — through a pointer the function was handed, in
-- the body — are exactly the ones that cannot come out.  After it the body is
-- the header and they can.  That is the whole of why this pass exists: nothing
-- it does is worth anything on its own.
--
-- __Copying the header is the whole of the edit.__  The copy goes in the
-- preheader and takes the header's branch with it; the header stays where it
-- is, now reached only from the blocks that branch back to it.  Control that
-- ran the preheader, then the header, then went on, now runs the preheader,
-- then the copy, then goes on — and the header itself runs once for every turn
-- back into the loop, which is once for every time it ran before less the one
-- on the way in.  The instructions therefore execute in the same order as often
-- as they did, and this needs no argument about which of them may be repeated
-- or run early: a call in the header is copied like anything else and is still
-- made exactly as many times.
--
-- __The core is what makes the copy cheap, and it asks for one thing back.__
-- In single assignment form the copy wants new names and the header wants a phi
-- for each of them.  Here a local can be assigned twice, so a value the header
-- computes and the body reads can be written under the name the body already
-- reads — whichever assignment ran is the one a read sees, which on the way in
-- is the copy and on every turn after is the header.
--
-- What the core asks in return is that only an assignment may write a local
-- twice.  That is the rule "Olivine.Core.Ssa" reconstructs against: a local
-- written by two ordinary instructions has two definitions and no phi can name
-- them both, where a local written by two assignments is exactly what a phi is
-- for.  Everything that reassigns a local today reassigns it that way —
-- promotion's variables, the lowering's phis — and a copied header would be the
-- first thing that did not.  So each instruction copied here, and the one it was
-- copied from, is given a name of its own and an assignment from it to the name
-- it had: @%c = icmp@ standing in two blocks becomes @%n = icmp@ with @%c := %n@
-- in one and @%m = icmp@ with @%c := %m@ in the other.  The assignments cost
-- nothing — reconstruction is where they go — and what is left in each block is
-- one instruction defining one local, as LLVM will want it back.
--
-- The terminator is the exception, being copied whole and having nowhere to put
-- an assignment after it.  So a header ending in a call — an @invoke@ or a
-- @callbr@, which assign where they stand — is left alone rather than rotated.
--
-- __What it costs.__  A second copy of the test in the function, which is what
-- every compiler pays for this and the reason LLVM caps the size of a header it
-- will rotate.  Nothing here caps it: the copy is one per loop rather than one
-- per turn, and a number to compare a header against is a number there is
-- nothing here to measure.  What it does not cost is the test's own invariants —
-- the instructions still assign once each, so hoisting can still take one out of
-- the loop, and only the assignment naming its result stays behind.
--
-- __A loop is rotated when the test is on the way in and not on the way out.__
-- Three conditions, of which the first two are that description.  The header
-- leaves the loop, or there is no test in it to copy anywhere.  And it has one
-- way on into the body, so that the copy decides exactly what the header
-- decided and there is a single block for the loop to be entered at instead.
--
-- The third is that the loop does not leave from the bottom already, which is
-- the shape this produces and which a @do@ loop arrives in.  What decides
-- whether such a loop goes round again is the block that branches back to the
-- header — except that a block testing at the bottom and branching back to
-- itself has nowhere to put the assignments a phi on the edge back becomes, so
-- the lowering splits that edge, and what closes the loop is a block holding
-- nothing but those.  'deciding' therefore reads through a block that does
-- nothing but assign to whatever branches to it, and the loop is left alone if
-- any of them leaves.  Without that, every @do@ loop in optimized input would
-- be rotated: the copies would be the latch, the latch would leave nothing, and
-- what came out is the loop with one turn of it peeled off in front — correct,
-- larger, and no better.
--
-- __Which is why a loop is rotated at most once.__  After the edit the header
-- is reached only from its latches, and every one of those is reached through
-- the body block the copy branches to; that block therefore dominates the
-- header, and the edge from the header to it is a back edge.  So the loop is
-- the same blocks with the body block as its header — and the old header is now
-- one of its latches, a latch that leaves the loop, which is the condition
-- declined just above.  A rotated loop cannot be rotated again, and the rounds
-- below are bounded by how many loops there are rather than by anything about
-- how they nest.
--
-- __The block the header leaves behind.__  Rotation leaves the loop a block
-- longer than it needs to be: the body branches to the header and the header is
-- reached from nowhere else, which is one block written as two.  Putting them
-- back together is what 'Olivine.Core.Blocks.mergeBlocks' is for, and it is why
-- this pass runs before control flow simplification rather than after it.  What
-- comes out the other side is a single block holding the body and then the
-- test, which is the loop as it would have been written by hand, and which
-- hoisting sees as a header holding everything.
module Olivine.Core.Pass.LoopRotation
  ( rotateLoops
  ) where

import Data.List (nub)
import Data.Map.Strict (Map)
import Data.Maybe (isNothing, mapMaybe)
import Data.Set qualified as Set

import Olivine.Core.Blocks (predecessorsOf)
import Olivine.Core.Instruction
import Olivine.Core.Loops (Loop (..), Preheader, enterThrough, loopsOf, preheaderFor)
import Olivine.Core.Metadata (named)
import Olivine.Core.Program
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)

rotateLoops :: Program -> Program
rotateLoops program =
  program {programEntries = map entry (programEntries program)}
  where
    -- What the module's named types stand for, which is what says the type of
    -- a result an assignment is written for.  Read once for the program: no
    -- pass makes or unmakes a type definition.
    types = namedTypes program

    entry (EFunction f) = EFunction (settle types (rounds f) f)
    entry retained = retained

-- | As many rotations as there can be: one to a loop, and this is how many
-- loops there are to begin with.
--
-- A bound rather than the argument itself, which is in the header above.  What
-- it does not stand on is the loops staying the same loops: a rotated loop is
-- the same blocks under a different header, and counting them before anything
-- moves is what makes that not matter.
rounds :: Function -> Int
rounds = length . loopsOf

-- | Rotate one loop, then look again.
--
-- One at a time because the edit changes the graph the next question is asked
-- of: a loop containing the one just rotated is the same loop with a block
-- added to it, and the loops are found again rather than carried.
settle :: Map Name Type -> Int -> Function -> Function
settle types remaining f
  | remaining <= 0 = f
  | otherwise = case rotatable f of
      [] -> f
      (loop, preheader, header) : _ ->
        settle types (remaining - 1) (rotate types f loop preheader header)

-- | Put a copy of the header where the loop is entered, and let it decide
-- whether the loop is entered at all.
--
-- Both copies go through assignments, the one left behind as much as the one
-- made: the names the rest of the function reads have to be written by an
-- assignment wherever they are written twice, and after this they are written
-- in both places.
rotate :: Map Name Type -> Function -> Loop -> Preheader -> Block -> Function
rotate types f loop preheader header =
  enterThrough left loop preheader made (Just (blockTerminator header))
  where
    Local next = nextLocal f
    written = length (mapMaybe instructionResult (blockInstructions header))

    left = f {functionBlocks = map apart (functionBlocks f)}
    apart b
      | blockLabel b == blockLabel header =
          b
            { blockInstructions = namedApart types (Local next) (blockInstructions b)
            , blockTerminator = closing (blockTerminator b)
            }
      | Set.member (blockLabel b) (loopBody loop)
      , loopHeader loop `elem` targetsOf (blockTerminator b) =
          b {blockTerminator = strip (blockTerminator b)}
      | otherwise = b

    made = namedApart types (Local (next + written)) (blockInstructions header)

    -- What a loop says about itself is written on the branch that closes it,
    -- and this moves that branch.  Before the rotation the loop is closed by
    -- the blocks branching to the header; after it the header is the last
    -- block of the loop, since everything that reached it still does and the
    -- way in now goes past it.  So @!llvm.loop@ comes off the old back edges
    -- and goes on the header's own branch, which is where the next reader of
    -- it will look.  LLVM's own rotation does the same, and for the same
    -- reason: a node left on a branch that no longer closes anything is a
    -- promise about a loop nobody can find.
    --
    -- The copy of the header made in front of the loop does not get it.  That
    -- copy decides whether the loop is entered and is not part of it, and it
    -- is built from the terminator as it was rather than from this one.
    --
    -- A header already carrying one is a header that closes a loop outside
    -- this one, and an instruction may not carry two nodes of a name.  The
    -- outer loop's is the one already where it belongs, so the inner loop's is
    -- dropped rather than moved: a loop whose promise is lost is a loop
    -- nothing may be concluded about, which is the safe way for this to be
    -- wrong.
    closing t
      | any loopNode (terminatorMetadata t) = t
      | otherwise = t {terminatorMetadata = terminatorMetadata t <> nub carried}

    -- What the branches that close the loop now say, which is what the header
    -- is about to say instead.  Two of them saying the same thing is one node
    -- named twice, not two nodes.
    carried =
      [ a
      | b <- functionBlocks f
      , Set.member (blockLabel b) (loopBody loop)
      , loopHeader loop `elem` targetsOf (blockTerminator b)
      , a <- terminatorMetadata (blockTerminator b)
      , loopNode a
      ]

    strip t = t {terminatorMetadata = filter (not . loopNode) (terminatorMetadata t)}

    loopNode = named "llvm.loop"

-- | The loops whose test is on the way in, each with where the copy of it goes
-- and the block to copy.
rotatable :: Function -> [(Loop, Preheader, Block)]
rotatable f =
  [ (loop, preheader, header)
  | loop <- loopsOf f
  , header <- [b | b <- functionBlocks f, blockLabel b == loopHeader loop]
  , -- The header's terminator is copied as it stands, and a call standing
    -- where a branch stands may not be.  What it assigns would be written in
    -- two places by something that is not an assignment, which is exactly what
    -- the rule above forbids and what 'namedApart' exists to avoid for the
    -- instructions; and a @callbr@ copied is the assembly written twice, which
    -- nothing may do however many times it runs.
    isNothing (callIn (terminatorTransfer (blockTerminator header)))
  , -- There is a test in it, and one way on if the test says to go on.
    leaves loop header
  , [_] <- [staying loop header]
  , -- And the loop is not already testing where this would leave it testing.
    not (any (leaves loop) (deciding f loop))
  , Just preheader <- [preheaderFor f loop]
  ]

-- | The blocks that decide whether the loop goes round again.
--
-- The ones branching back to the header, and — where such a block does nothing
-- but assign — whatever in the loop branches to those, since a block of nothing
-- but assignments decides nothing itself.  That is the split edge the lowering
-- makes of a phi on the way back into a block that tests at the bottom, and
-- reading through it is what tells a loop already in that shape from one this
-- would put in it.
--
-- The walk stops at the first block that does something, and cannot go round
-- for ever: a block already looked at is not looked at twice.
deciding :: Function -> Loop -> [Block]
deciding f loop = walk [] (latchesOf f loop)
  where
    walk seen [] = seen
    walk seen (b : rest)
      | blockLabel b `elem` map blockLabel seen = walk seen rest
      | all (assigning . instructionOperation) (blockInstructions b) =
          walk (b : seen) (inLoop (predecessorsOf (functionBlocks f) (blockLabel b)) <> rest)
      | otherwise = walk (b : seen) rest

    inLoop labels =
      [ b
      | b <- functionBlocks f
      , blockLabel b `elem` labels
      , Set.member (blockLabel b) (loopBody loop)
      ]

    assigning (OAssign _) = True
    assigning _ = False

-- | The blocks in the loop that branch back to its header, which are the edges
-- that make it a loop.
latchesOf :: Function -> Loop -> [Block]
latchesOf f loop =
  [ b
  | b <- functionBlocks f
  , Set.member (blockLabel b) (loopBody loop)
  , loopHeader loop `elem` targetsOf (blockTerminator b)
  ]

-- | Whether control can leave the loop from this block.
leaves :: Loop -> Block -> Bool
leaves loop b = any (`Set.notMember` loopBody loop) (targetsOf (blockTerminator b))

-- | Where a block goes that is still in the loop, once each however many edges
-- go there.
staying :: Loop -> Block -> [Label]
staying loop b =
  Set.toList (Set.intersection (loopBody loop) (Set.fromList (targetsOf (blockTerminator b))))
