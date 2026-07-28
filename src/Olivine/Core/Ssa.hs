-- | Putting a core function back into single assignment form.
--
-- The core lets a local be assigned as often as it likes; LLVM lets it be
-- assigned once.  Bridging that is what this does, and it is the inverse of
-- the phi elimination the lowering performs: a local assigned on several
-- edges becomes a phi where those edges meet.
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

import Olivine.Core.Program
import Olivine.Syntax.Instruction
import Olivine.Syntax.Operands (localsUsedBy, mapOperands)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value

-- | What a local holds at a point in the program.
type Values = Map Local (Value Local)

reconstruct :: Function -> Function
reconstruct f = f {functionBlocks = rebuild}
  where
    blocks = functionBlocks f
    order = map blockLabel blocks -- already reverse postorder as written
    byLabel = Map.fromList [(blockLabel b, b) | b <- blocks]

    predecessors target =
      [blockLabel b | b <- blocks, target `elem` targetsOf (blockTerminator b)]

    -- Every local the core assigns, and the type it was assigned at.
    mutable :: [(Local, Type)]
    mutable =
      nub
        [ (name, typedValueType value)
        | b <- blocks
        , Instruction (Just name) (Assign value) _ <- blockInstructions b
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
          let block = byLabel Map.! name
              incoming
                | not (null (phisAt name)) =
                    Map.fromList [(v, VLocal p) | (p, v, _) <- phisAt name]
                | otherwise = case predecessors name of
                    [only] -> Map.findWithDefault Map.empty only acc
                    _ -> Map.empty
           in Map.insert name (runBlock incoming (blockInstructions block)) acc

    runBlock = foldl apply
      where
        apply values (Instruction (Just name) (Assign value) _) =
          Map.insert name (resolve values (typedValue value)) values
        apply values (Instruction (Just name) (Perform _) _) =
          Map.insert name (VLocal name) values
        apply values _ = values

    exitOf name = Map.findWithDefault Map.empty name exits

    -- The operands each placed phi ends up with.
    operands :: Map Local [(Value Local, Label)]
    operands =
      Map.fromList
        [ (p, [(arriving q v, q) | q <- predecessors name])
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
    surviving name =
      [phi' | phi' <- phisAt name, live (nameOfPhi phi')]
      where
        nameOfPhi (p, _, _) = p

    live p = p `elem` liveSet

    liveSet = fixpoint grow (concatMap readByRewritten blocks)
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
      concat
        [ localsUsedBy operation
        | i <- mapMaybe (rewrite (blockLabel b)) (blockInstructions b)
        , Perform operation <- [instructionOperation i]
        ]
        <> localsUsedBy (terminatorOperation (rewriteTerminator (blockLabel b) (blockTerminator b)))

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

    renameIn = mapOperands (\(TypedValue t x) -> TypedValue t (renameValue x))
    renameValue (VLocal n) = VLocal (finalName n)
    renameValue x = x

    rebuild = map applyNames built

    applyNames b =
      b
        { blockInstructions =
            [ i
              { instructionResult = finalName <$> instructionResult i
              , instructionOperation = case instructionOperation i of
                  Perform op -> Perform (renameIn op)
                  other -> other
              }
            | i <- blockInstructions b
            ]
        , blockTerminator =
            (blockTerminator b)
              { terminatorOperation = renameIn (terminatorOperation (blockTerminator b))
              }
        }

    built =
      [ b
        { blockInstructions =
            [ Instruction (Just p) (Perform (OPhi (phi t p))) []
            | (p, _, t) <- surviving (blockLabel b)
            ]
              <> mapMaybe (rewrite (blockLabel b)) (blockInstructions b)
        , blockTerminator = rewriteTerminator (blockLabel b) (blockTerminator b)
        }
      | b <- blocks
      ]

    phi t p =
      Phi
        { phiFlags = []
        , phiType = t
        , phiIncoming =
            [ (substitute collapsed value, from)
            | (value, from) <- Map.findWithDefault [] p operands
            ]
        }

    -- An assignment has no LLVM spelling and needs none: its value has been
    -- carried to wherever the local is read.
    rewrite name instruction = case instructionOperation instruction of
      Assign _ -> Nothing
      Perform operation ->
        Just
          instruction
            { instructionOperation =
                Perform (mapOperands (fmap' (resolveAt name instruction)) operation)
            }

    -- A terminator stands after everything in its block, so the values it
    -- sees are the ones on the way out.
    rewriteTerminator name t =
      t
        { terminatorOperation =
            mapOperands
              (fmap' (substitute collapsed . resolve (exitOf name)))
              (terminatorOperation t)
        }

    fmap' g (TypedValue t x) = TypedValue t (g x)

    -- What a local holds where an instruction stands: the values on the way
    -- into its block, updated by everything before it.
    resolveAt name instruction value =
      substitute collapsed (resolve (before name instruction) value)

    before name instruction =
      let block = byLabel Map.! name
          incoming
            | not (null (phisAt name)) =
                Map.fromList [(v, VLocal p) | (p, v, _) <- phisAt name]
            | otherwise = case predecessors name of
                [only] -> exitOf only
                _ -> Map.empty
       in runBlock incoming (takeWhile (/= instruction) (blockInstructions block))

    resolve values value = case value of
      VLocal n -> Map.findWithDefault value n values
      _ -> value


