-- | Removing a store whose value nothing can ever read.
--
-- The dead code pass asks whether anything reads an instruction's result, and
-- a store has none, so it declines every one of them — @OStore _ -> False@ is
-- the first line of 'Olivine.Core.Pass.DeadCode.removableWhenUnused'.  The
-- question a store wants asked is a different one: not whether anything reads
-- the local it assigns, but whether anything reads the /bytes/ it writes.
-- Nothing was asking it, so until now no store was ever removed.
--
-- __It is the redundancies pass read backwards.__  That one walks forwards
-- carrying what memory is known to hold, so that a load can be answered by an
-- earlier access.  This walks backwards carrying which of the function's
-- stores are dead, so that a store can be answered by a later one.  The two
-- are the same analysis about the same facts in the two directions, and the
-- pieces they ask it with — "Olivine.Core.Alias" for what a pointer may be,
-- "Olivine.Core.Effects" for what a call may do — are the same pieces.
--
-- __Two things make a store dead, and the second is why this is worth doing.__
--
-- * A later store writes the same bytes with nothing reading them in between.
-- * The storage it writes stops existing with nothing reading them in
--   between: an @alloca@ belongs to a frame that goes when the function
--   returns or unwinds, and a slot between a lifetime marker and the store
--   above it is storage the program has said is not live there.
--
-- The first is the one a reader expects and the rarer of the two in practice,
-- because a front end does not write the same address twice for nothing.  The
-- second is what a function's own frame is full of: a slot written on the way
-- out, an aggregate built to be passed by value, a field set and never read
-- again.  Both are the same fact — the value is not read before it stops
-- mattering — which is why one walk answers them.
--
-- __A fact is a store, not an address.__  What travels is a set of the
-- function's own stores, each meaning \"the value this one wrote is not read\".
-- Naming the stores rather than the addresses is what makes the set finite —
-- there are as many facts as the function has stores — and a walk over a
-- finite lattice is a walk that stops.  It is also all that is wanted: the
-- only thing a fact is ever used for is to remove the store it names.
--
-- __What kills a fact is a read, and only a read.__  A write in between does
-- not: if something else overwrote the bytes first, the value is even less
-- readable, not more.  So a load kills the facts its bytes may meet
-- ('mayAlias'), a call that may read kills every fact a stranger can reach,
-- and an atomic or a fence kills those too — that is where another thread's
-- reads become ordered against this one's writes, and storage a stranger can
-- reach is exactly storage another thread can reach.
--
-- __A call that may not come back, or that may leave by throwing, kills them
-- as well.__  The later store that was going to overwrite the bytes is reached
-- only if the call returns normally, and the frame that was going to take them
-- away is only taken away by a return this may never make.  Storage no
-- stranger can name survives all of that, since nothing that happens after
-- such a call has a way to read it.  @opt -passes=dse@ draws the same two
-- lines: it keeps a store to a parameter's storage across a @noreturn@ call
-- and across one that may unwind, and removes a store to an @alloca@ whose
-- address was handed to a call before it.
--
-- __No fact crosses a back edge.__  What one would say is that a store is
-- overwritten by the next turn of the loop, which is the same store writing
-- the same address again — and LLVM declines that: @opt -passes=dse@ leaves
-- @loop: store 1, ptr %p; br label %loop@ exactly as written.  A store whose
-- only overwrite is itself has left the value standing for a whole iteration,
-- and what could observe it is not a question the aliasing here can answer.
-- Declining costs a set intersection with the empty set and nothing else, and
-- it is what lets the walk start from nothing rather than from everything: the
-- graph it flows over has no cycles left in it, so growing to the least fixed
-- point loses nothing that the optimistic start of the redundancies pass had
-- to be written for.
--
-- __What it does not do.__  A store covered by a /wider/ later store, or by two
-- narrower ones together, is not removed: 'mustAlias' asks for one address and
-- one extent, so a write that covers another and more besides is a write this
-- declines to read as covering it.  A slot a @memcpy@ names is storage a call
-- was handed, so what is written to it before the call stays.  Both want a
-- store to be the bytes it writes rather than the access it is written as,
-- which is the same thing promotion wants for a slot held as bits, and neither
-- has anything in the corpus asking for it yet.
module Olivine.Core.Pass.DeadStores
  ( eliminateDeadStores
  ) where

import Data.Foldable (toList)
import Data.List (mapAccumL, mapAccumR)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (catMaybes)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Alias
  ( Access (..)
  , Object (..)
  , mayAlias
  , mustAlias
  , objectOf
  , objectsIn
  , reachableByCall
  )
import Olivine.Core.Blocks (reversePostorder)
import Olivine.Core.Effects (Behaviour (..), Effects, behaviourOf, effectsOf)
import Olivine.Core.Instruction
import Olivine.Core.Layout (Layout, layoutOf)
import Olivine.Core.Loops (dominators)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Alloca (..), Load (..), Store (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

eliminateDeadStores :: Program -> Program
eliminateDeadStores program =
  program {programEntries = map entry (programEntries program)}
  where
    -- What the module says about sizes and offsets, which is what tells a
    -- store to one field of a struct from a load of another.
    layout = layoutOf program
    -- And what each call does, read once for the whole program: whether a call
    -- reads at all is the difference between a store surviving every call in
    -- the function and surviving none of them.
    effects = effectsOf program
    entry (EFunction f) = EFunction (eliminateIn layout effects f)
    entry retained = retained

-- | One store, as the walk needs it: what it writes, and the three questions
-- about that which are the same at every point and so are asked once.
data Written = Written
  { -- | The bytes it writes, for asking whether a read may meet them.
    writtenAccess :: Access
  , -- | What storage they are in, where the function says.  A frame slot is
    -- what dies at the return, and it is what a lifetime marker names.
    writtenObject :: Maybe Object
  , -- | Whether anything outside the function can reach the storage, which is
    -- what a call, an atomic or a fence takes away what is known about.
    writtenStrange :: Bool
  , -- | The locals the address is written with.  Assigning to one of them
    -- makes the address mean somewhere else, so a fact carried up past such an
    -- assignment is a fact about a different place and is dropped.
    writtenNames :: [Local]
  }

eliminateIn :: Maybe Layout -> Effects -> Function -> Function
eliminateIn layout effects f
  | Map.null stores = f
  | otherwise = f {functionBlocks = map rewrite (functionBlocks f)}
  where
    made = behaviourOf effects
    objects = objectsIn layout f
    blocks = functionBlocks f
    -- The order a value can be carried forwards in, walked backwards, which
    -- is the order this carries a fact in.  A block outside it is one nothing
    -- reaches: no walk arrives at it and nothing it writes reaches anywhere.
    order = reversePostorder f
    doms = dominators f

    -- Every store in the function, numbered.  A volatile one is not numbered
    -- at all: the point of writing one is that the write happens, so it is
    -- never removed, and it is no promise about what stands at the address
    -- afterwards either, so it settles nothing about the stores above it.
    tagged :: [(Label, [(Maybe Int, Instruction)])]
    tagged = snd (mapAccumL overBlock 0 blocks)
      where
        overBlock n b = (n', (blockLabel b, numbered))
          where
            (n', numbered) = mapAccumL overInstruction n (blockInstructions b)
        overInstruction n i = case instructionOperation i of
          OStore s | not (storeVolatile s) -> (n + 1, (Just n, i))
          _ -> (n, (Nothing, i))

    instructionsOf :: Map Label [(Maybe Int, Instruction)]
    instructionsOf = Map.fromList tagged

    byLabel = Map.fromList [(blockLabel b, b) | b <- blocks]

    stores :: Map Int Written
    stores =
      Map.fromList
        [ (n, written (Access (typedValue (storePointer s)) (typedValueType (storeValue s))))
        | (_, numbered) <- tagged
        , (Just n, i) <- numbered
        , OStore s <- [instructionOperation i]
        ]
      where
        written access =
          Written
            { writtenAccess = access
            , writtenObject = objectOf objects (accessPointer access)
            , writtenStrange = reachableByCall objects (accessPointer access)
            , writtenNames = toList (accessPointer access)
            }

    at n = stores Map.! n

    -- For each store, the stores it writes over entirely.  Worked out once
    -- rather than at each visit, an access having no ordering to be looked up
    -- by; there are few enough stores in a function for the square of them to
    -- be cheaper than the walk that reads it.
    covering :: Map Int (Set Int)
    covering =
      Map.map
        (\w -> Set.fromList [m | (m, c) <- Map.toList stores, covers w c])
        stores
      where
        covers w c = mustAlias objects (writtenAccess w) (writtenAccess c)

    -- The stores whose storage the frame takes away with it.  Every @alloca@
    -- but the one kind that is not the function's own: @inalloca@ is the
    -- memory the caller built the arguments in, which the caller still has
    -- after the call.
    --
    -- Whether the address escaped is not asked.  A slot's storage is gone once
    -- the frame is, however far its address travelled, and reading it
    -- afterwards is undefined rather than something to preserve — which is
    -- what @opt -passes=dse@ concludes too, removing a store to a slot whose
    -- address was handed to a call before it.  What the escape decides is
    -- something else: whether a call in between can read the value, and that is
    -- 'writtenStrange' being asked at each call.
    dying :: Set Int
    dying =
      Set.fromList
        [ n
        | (n, w) <- Map.toList stores
        , Just (OnStack slot) <- [writtenObject w]
        , not (Set.member slot argumentMemory)
        ]

    argumentMemory =
      Set.fromList
        [ result
        | b <- blocks
        , i <- blockInstructions b
        , Just result <- [instructionResult i]
        , OAlloca a <- [instructionOperation i]
        , allocaInalloca a
        ]

    -- Which stores are dead on the way into each block, grown from nothing
    -- until a round changes none of them.
    --
    -- Nothing is the right place to start because no fact crosses a back edge:
    -- what a block is told by its successors is settled without reference to
    -- itself, so the least fixed point is the only one there is.  Each round
    -- takes the blocks in the reverse of the order values travel in, so a fact
    -- gets as far up as the order allows rather than one block per round.
    settled :: Map Label (Set Int)
    settled = settle (Map.fromList [(label, Set.empty) | label <- order])
      where
        settle before
          | after == before = before
          | otherwise = settle after
          where
            after = foldl' visit before (reverse order)
        visit known label =
          Map.insert label (fst (through known (byLabel Map.! label))) known

    rewrite b
      | Map.member (blockLabel b) settled =
          b {blockInstructions = snd (through settled b)}
      -- A block nothing reaches.  Nothing arrives at it to say anything is
      -- dead, and what it writes is written on no path the program takes.
      | otherwise = b

    -- A block's instructions with the dead stores gone, and which stores are
    -- dead on the way into it.
    through :: Map Label (Set Int) -> Block -> (Set Int, [Instruction])
    through known b = (above, catMaybes kept)
      where
        (above, kept) =
          mapAccumR
            step
            (afterTerminator known b)
            (Map.findWithDefault [] (blockLabel b) instructionsOf)

    -- What is dead where the terminator stands, which is what its successors
    -- agree on and then what the terminator itself does.
    afterTerminator :: Map Label (Set Int) -> Block -> Set Int
    afterTerminator known b = assigned (called (leaving known b))
      where
        transfer = terminatorTransfer (blockTerminator b)
        -- An invoke and a callbr are calls standing where a branch stands, and
        -- what a call does to this has to be done here or a store above one
        -- would be removed on the strength of a later store the call may never
        -- let it reach.
        called dead = case callIn transfer of
          Just call | disturbing (made call) -> strangers dead
          _ -> dead
        assigned = killing (resultOf (blockTerminator b))

    -- What every way on from a block agrees is dead.
    --
    -- A block that goes nowhere is where the function ends: its frame goes
    -- with it, so every store into the frame is dead unless something below
    -- read it.  That covers the return and the resume alike — unwinding out of
    -- a function takes its frame away exactly as returning does — and the
    -- unreachable, where nothing runs at all.
    leaving :: Map Label (Set Int) -> Block -> Set Int
    leaving known b = case targetsOf (blockTerminator b) of
      [] -> dying
      targets -> foldr1 Set.intersection (map (across (blockLabel b)) targets)
      where
        across from to
          | Set.member to (Map.findWithDefault Set.empty from doms) = Set.empty
          | otherwise = Map.findWithDefault Set.empty to known

    -- One instruction, from below.  What is dead above it, and whether it
    -- stays.
    step :: Set Int -> (Maybe Int, Instruction) -> (Set Int, Maybe Instruction)
    step dead (index, i) = (killing (instructionResult i) (wrote (read' dead)), kept)
      where
        operation = instructionOperation i

        -- A store the walk has already found to be dead where it stands.
        kept
          | Just n <- index, Set.member n dead = Nothing
          | otherwise = Just i

        -- What reading takes away.  A store is not here: writing over a value
        -- nothing was going to read leaves it just as unread.
        read' = case operation of
          OLoad l -> without (Access (typedValue (loadPointer l)) (loadType l))
          OCall call | disturbing (made call) -> strangers
          -- An atomic is where another thread's reads and this one's writes
          -- are put in an order, so everything a stranger can reach may be
          -- read at it.  A fence names no address and is no exception: the
          -- ordering is the whole of what it is written for.
          OAtomicLoad _ -> strangers
          OAtomicStore _ -> strangers
          OAtomicRmw _ -> strangers
          OCmpXchg _ -> strangers
          OFence _ -> strangers
          _ -> id

        -- And what this instruction being here makes dead above it.
        wrote = case operation of
          OStore _ | Just n <- index -> Set.union (Map.findWithDefault Set.empty n covering)
          -- Storage the program has said is not live here.  Either marker says
          -- it: what @llvm.lifetime.end@ ends is not live afterwards, and what
          -- @llvm.lifetime.start@ begins holds nothing that was put there
          -- before it.  @opt -passes=dse@ removes the store above either one.
          _ | Just slot <- lifetimeMarked operation -> Set.union (within slot)
          _ -> id

    -- Every store into the storage a lifetime marker names, where that is a
    -- frame slot.  A marker naming anything else is malformed, and answering
    -- nothing for it is answering what it deserves.
    within slot = case objectOf objects (VLocal slot) of
      Just object@(OnStack _) ->
        Set.fromList [n | (n, w) <- Map.toList stores, writtenObject w == Just object]
      _ -> Set.empty

    without read'' = Set.filter (not . mayAlias objects read'' . writtenAccess . at)

    strangers = Set.filter (not . writtenStrange . at)

    killing Nothing = id
    killing (Just local) = Set.filter (notElem local . writtenNames . at)

-- | Whether what a call does can leave a store above it readable: it may read
-- the bytes itself, or it may not come back to the store that was going to
-- write over them.
disturbing :: Behaviour -> Bool
disturbing behaviour =
  readsMemory behaviour || mayUnwind behaviour || mayNotReturn behaviour
