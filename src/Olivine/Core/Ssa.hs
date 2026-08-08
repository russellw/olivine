-- | Putting a core function back into single assignment form.
--
-- The core lets a local be assigned as often as it likes; LLVM lets it be
-- assigned once.  Bridging that is what this does, and it is the inverse of
-- the phi elimination the lowering performs: a local assigned on several
-- edges becomes a phi where those edges meet.
--
-- What comes out is therefore not a core function.  It is
-- 'Olivine.Core.Phi.Joined', the shape with phis listed at the head of a
-- block, which is what LLVM's block is and what the raising writes down.  A
-- core 'Olivine.Core.Program.Block' has nowhere to put a phi, and the point of
-- this pass is producing them, so it produces the form that holds them.
--
-- Phis are placed at every join, rather than at the iterated dominance
-- frontier of each local's definitions.  Placing more than are needed is
-- harmless as long as the useless ones are removed again, and a phi whose
-- operands all agree is exactly a useless one, so removing them to a fixed
-- point leaves the same result as computing where they belonged — without a
-- dominator tree.  What that costs is the assumption that the control flow
-- graph is reducible, since values are propagated in reverse postorder;
-- everything a compiler emits is.
module Olivine.Core.Ssa
  ( reconstruct
  ) where

import Data.List (nub)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Blocks (reversePostorder)
import Olivine.Core.Instruction
import Olivine.Core.Phi (Joined (..), PhiNode (..))
import Olivine.Core.Program
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value

-- | What a local holds at a point in the program.
type Values = Map Local (Value Local)

reconstruct :: Function -> [Joined]
reconstruct f = rebuild
  where
    blocks = functionBlocks f
    byLabel = Map.fromList [(blockLabel b, b) | b <- blocks]

    -- A value is carried forwards by one walk, so a block has to be visited
    -- after the blocks it arrives from.  That is reverse postorder, and it has
    -- to be computed: the order the blocks are written in looks like it and is
    -- not, since LLVM puts no requirement on that order and clang does write a
    -- block before the only block that branches to it.
    --
    -- Blocks nothing reaches come after, in the order written.  Nothing
    -- arrives at one, so where among themselves they go cannot matter; that
    -- they are walked at all does, because a join that is reached can have a
    -- predecessor that is not, and the phi there reads what that block was left
    -- holding like it reads any other edge.
    walked :: [Label]
    walked = reversePostorder f

    reachable :: Set Label
    reachable = Set.fromList walked

    order = walked <> filter (not . (`Set.member` reachable)) (map blockLabel blocks)

    -- The blocks control can arrive from, each named once however many ways
    -- it goes here.  This is what the dataflow wants: two edges from one block
    -- carry the same values, that block having run once either way.
    predecessors target =
      [blockLabel b | b <- blocks, target `elem` targetsOf (blockTerminator b)]

    -- The edges, which is not the same list.  A @switch@ with two cases naming
    -- one block reaches it twice, and LLVM asks a phi for one operand per
    -- edge — @llvm-as@ parses a phi with one and its verifier then says
    -- @PHINode should have one entry for each predecessor@.  So this is what
    -- the operands are built from, and 'predecessors' is what everything else
    -- here is.
    edges target =
      [ blockLabel b
      | b <- blocks
      , going <- targetsOf (blockTerminator b)
      , going == target
      ]

    -- Every local the core assigns, and the type it was assigned at.
    mutable :: [(Local, Type)]
    mutable =
      nub
        [ (name, typedValueType value)
        | b <- blocks
        , Instruction (Just name) (OAssign value) _ <- blockInstructions b
        ]

    -- A phi for every such local at every join, to be thinned out after.
    --
    -- Each takes a local of its own, issued after everything the function
    -- already uses.  Which number a phi gets does not matter — the raising
    -- reissues them all — only that no two share one and none treads on a
    -- local already there.
    joins = [blockLabel b | b <- blocks, length (predecessors (blockLabel b)) > 1]

    placed :: Map Label [(Local, Local, Type)]
    placed =
      Map.fromList
        [ (label, [(Local (base + at * length mutable + k), v, t) | (k, (v, t)) <- zip [0 ..] mutable])
        | (at, label) <- zip [0 ..] joins
        ]
      where
        Local base = nextLocal f

    phisAt name = Map.findWithDefault [] name placed

    -- Walking the blocks in order, what each local holds on the way out.
    exits :: Map Label Values
    exits = foldl step Map.empty order
      where
        step acc name =
          Map.insert
            name
            (runBlock (entering acc name) (blockInstructions (byLabel Map.! name)))
            acc

    -- What the locals hold on the way into a block, given what the blocks
    -- walked so far were left holding.
    --
    -- At a join, the phis placed there: standing for what arrives on each edge
    -- is what a phi is.  At a block with one predecessor, whatever that block
    -- was left holding, which the walk order is what guarantees is worked out
    -- already.  The entry block holds nothing yet, having nothing before it.
    --
    -- And at a block nothing reaches, poison for every local the core assigns.
    -- Nothing was assigned on the way to a block there is no way to, and a
    -- local this pass takes the name of has no name left to be read by, so
    -- poison is the only answer that is not a reference to nothing.  Naming it
    -- here rather than as a fallback wherever a local comes up short is what
    -- lets 'Olivine.Core.Raise' go on insisting that every local it writes has
    -- a name.  Unreachable code is the one place with no value to carry, and
    -- saying so here leaves a value missing anywhere else the error that it is —
    -- which matters, because answering poison wherever one came up short would
    -- have turned this very bug from a stop into a wrong answer.
    entering :: Map Label Values -> Label -> Values
    entering known name
      | not (null (phisAt name)) =
          Map.fromList [(v, VLocal p) | (p, v, _) <- phisAt name]
      | not (Set.member name reachable) =
          Map.fromList [(v, VPoison) | (v, _) <- mutable]
      | otherwise = case predecessors name of
          [only] -> Map.findWithDefault Map.empty only known
          _ -> Map.empty

    runBlock = foldl apply
      where
        apply values (Instruction (Just name) (OAssign value) _) =
          Map.insert name (resolve values (typedValue value)) values
        apply values (Instruction (Just name) _ _) =
          Map.insert name (VLocal name) values
        apply values _ = values

    exitOf name = Map.findWithDefault Map.empty name exits

    -- The operands each placed phi ends up with.
    operands :: Map Local [(Value Local, Label)]
    operands =
      Map.fromList
        [ (p, [(arriving q v, q) | q <- edges name])
        | (name, phis) <- Map.toList placed
        , (p, v, _) <- phis
        ]
      where
        -- A local that holds nothing along an edge holds poison there.  It
        -- cannot hold itself: that would be a use of a value never defined.
        arriving q v = Map.findWithDefault VPoison v (exitOf q)

    -- A phi all of whose operands agree, ignoring references to itself, says
    -- nothing; it is replaced by the value they agree on.  Removing them to a
    -- fixed point is what makes placing phis everywhere safe.
    collapsed :: Map Local (Value Local)
    collapsed = fixpoint step Map.empty
      where
        step known =
          Map.fromList
            [ (p, value)
            | (p, incoming) <- Map.toList operands
            , Just value <- [agreement p (map (substitute known . fst) incoming)]
            ]
        agreement p values = case nub [x | x <- values, x /= VLocal p] of
          [x] -> Just x
          [] -> Just VPoison
          _ -> Nothing
        fixpoint g x = let y = g x in if y == x then x else fixpoint g y

    substitute known value = case value of
      VLocal n -> maybe value (substitute (Map.delete n known)) (Map.lookup n known)
      _ -> value

    -- A phi that survives collapsing but that nothing reads is junk left over
    -- from placing them at every join.  Placing more than are needed is only
    -- harmless if the extras go again, and this is the second half of that.
    --
    -- What counts as read has to be judged on the rewritten instructions, not
    -- the ones lowering produced: a use written as the local %i becomes a use
    -- of the phi standing for it, and looking at the original would find
    -- neither.  A phi read only by another live phi is live too, so the set
    -- grows to a fixed point.
    --
    -- The reads are counted once each before the first round, because a round
    -- is judged to have found nothing by the count coming out the same and a
    -- round is what removes the repetitions.  Two blocks reading one local and
    -- one phi found in the same round is a round that adds one and takes one
    -- away — which stopped the walk with the phi it had just found left out,
    -- and wrote a reference to a phi nothing went on to place.
    surviving name =
      [phi' | phi' <- phisAt name, live (nameOfPhi phi')]
      where
        nameOfPhi (p, _, _) = p

    live p = p `elem` liveSet

    liveSet = fixpoint grow (nub (concatMap readByRewritten blocks))
      where
        grow known =
          nub
            ( known
                <> [ q
                   | (p, incoming) <- Map.toList operands
                   , p `elem` known
                   , VLocal q <- map (substitute collapsed . fst) incoming
                   ]
            )
        fixpoint g x = let y = g x in if length y == length x then x else fixpoint g y

    readByRewritten b =
      concatMap
        (localsUsedBy . instructionOperation)
        (mapMaybe (uncurry (rewrite (blockLabel b))) (numbered (blockInstructions b)))
        <> localsUsedBy
          (terminatorTransfer (rewriteTerminator (blockLabel b) (blockTerminator b)))

    -- A phi standing for a local, where it is the only one that local needs,
    -- takes that local over rather than being a local of its own.  The phi is
    -- what that local now is, so giving it a second identity would put the
    -- value one place further down the sequence written out, for no reason a
    -- reader of the output could see.
    finalNames :: Map Local Local
    finalNames =
      Map.fromList
        [ (p, v)
        | (v, _) <- mutable
        , [(p, _, _)] <- [[ph | b <- blocks, ph@(_, u, _) <- surviving (blockLabel b), u == v]]
        ]

    finalName n = Map.findWithDefault n n finalNames

    renameIn :: Functor f => f (TypedValue Local) -> f (TypedValue Local)
    renameIn = fmap (onValue renameValue)
    renameValue (VLocal n) = VLocal (finalName n)
    renameValue x = x

    rebuild = map applyNames built

    applyNames j =
      j
        { joinedPhis =
            [ p
              { phiLocal = finalName (phiLocal p)
              , phiIncoming = [(renameValue v, from) | (v, from) <- phiIncoming p]
              }
            | p <- joinedPhis j
            ]
        , joinedInstructions =
            [ i
              { instructionResult = finalName <$> instructionResult i
              , instructionOperation = renameIn (instructionOperation i)
              }
            | i <- joinedInstructions j
            ]
        , joinedTerminator =
            (joinedTerminator j)
              { terminatorTransfer = renameIn (terminatorTransfer (joinedTerminator j))
              }
        }

    built =
      [ Joined
          { joinedLabel = blockLabel b
          , joinedPhis =
              [ PhiNode {phiLocal = p, phiType = t, phiIncoming = incomingOf p}
              | (p, _, t) <- surviving (blockLabel b)
              ]
          , joinedInstructions =
              mapMaybe (uncurry (rewrite (blockLabel b))) (numbered (blockInstructions b))
          , joinedTerminator = rewriteTerminator (blockLabel b) (blockTerminator b)
          }
      | b <- blocks
      ]

    incomingOf p =
      [ (substitute collapsed value, from)
      | (value, from) <- Map.findWithDefault [] p operands
      ]

    -- An assignment has no LLVM spelling and needs none: its value has been
    -- carried to wherever the local is read.
    rewrite name at instruction = case instructionOperation instruction of
      OAssign _ -> Nothing
      operation ->
        Just
          instruction
            { instructionOperation =
                onValue (resolveAt name at) <$> operation
            }

    numbered = zip [0 ..]

    -- A terminator stands after everything in its block, so the values it
    -- sees are the ones on the way out.
    rewriteTerminator name t =
      t
        { terminatorTransfer =
            onValue (substituteIn (exitOf name)) <$> terminatorTransfer t
        }

    substituteIn values = substitute collapsed . resolve values

    -- An operand is a type and a value; every rewrite here is of the value.
    onValue g (TypedValue t x) = TypedValue t (g x)

    -- What a local holds where an instruction stands: the values on the way
    -- into its block, updated by everything before it.
    --
    -- __Where it stands is a position, not the instruction itself.__  Two
    -- instructions in one block can be equal — an instruction naming a result
    -- is told apart by the local it names, but a store, a fence or a call
    -- naming nothing is only its operands, and one block can hold two that are
    -- written identically.  Looking for the instruction by value then finds the
    -- first of them and reads every later one against what held there, which is
    -- a wrong answer rather than a missing one wherever an operand was assigned
    -- again in between.  Unrolling writes exactly that: n copies of a body in
    -- one block, each opening by saying what the counter holds this turn.
    resolveAt name at = substituteIn (before name at)

    before name at =
      runBlock
        (entering exits name)
        (take at (blockInstructions (byLabel Map.! name)))

    -- What a local holds, given what the locals hold here.
    --
    -- A local with no entry keeps its name, which is right for the locals that
    -- have one: an ordinary result is named by the instruction that produced it
    -- wherever that instruction stands.  The locals the core assigns have no
    -- name to keep, and 'entering' is what makes sure one of those is never
    -- looked up here without an entry to find.
    resolve values value = case value of
      VLocal n -> Map.findWithDefault value n values
      _ -> value


