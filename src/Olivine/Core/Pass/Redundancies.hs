-- | Reading a value off whatever already has it: the computation that worked it
-- out, or the memory that holds it.
--
-- Two kinds of redundancy under one name, because they are one question here.
-- An instruction computing what an earlier one computed is redundant, and so is
-- a load of an address an earlier access already settled; either becomes an
-- assignment of the value already in hand.  That is the same device folding
-- uses, and for the same reason: the core has assignment, so a pass that finds
-- out what an instruction comes to never has to move or delete anything to say
-- so.  Reconstruction carries the value to the uses and the dead code pass
-- takes away whatever was only computed to feed the instruction that is now a
-- copy.
--
-- What makes them one question is availability.  Neither kind can be settled by
-- looking at the instruction: what is in hand where it stands depends on every
-- path that reaches it, so both are read off the same walk, both are killed by
-- an assignment to a local, and both name their operands through the same
-- copies.  Splitting them into two passes would be that walk written twice.
--
-- __This is where the core's bargain comes due.__  In single assignment form
-- "computed already" is a lookup and nothing more: a name is a value, so two
-- instructions with the same operands compute the same thing wherever they
-- stand.  Here a local can be reassigned, so the question is availability —
-- whether on /every/ path that reaches this instruction the expression was
-- computed, and neither what it reads nor the local holding it has been
-- assigned since.  That is a forward dataflow analysis rather than a lookup,
-- which is exactly the cost CLAUDE.md called an acceptable trade, and this is
-- the first pass to pay it.
--
-- __Operands are read through the copies the core is full of.__  Two
-- expressions written identically in LLVM rarely arrive here identical.  A
-- @getelementptr@ is lowered to a chain of steps and folding replaces the
-- steps that move nowhere with assignments, so what LLVM wrote twice becomes
-- two chains reading two different locals that hold the same pointer.  So the
-- operands are resolved through what each local is known to be a copy of
-- before two expressions are compared.  Naming the same value the same way is
-- the whole of what makes them comparable, and it is why this is value
-- numbering rather than a text match on instructions.
--
-- Resolving them is for comparing, not for rewriting: the operands written in
-- the program are left as they are.  What a copy comes to is settled on the
-- way out of the core, where reconstruction removes every assignment by
-- carrying its value to the uses, and doing it again here would be a second
-- place to keep that right.
--
-- __A load is not shared; it is answered.__  Nothing shareable reads memory,
-- so two runs of any expression here give the same value whatever happened in
-- between, and for those availability is about assignment alone.  A load is
-- the other kind: what it answers is not a function of its operands but of
-- what memory holds at the address they name, so two loads written identically
-- are one value only if nothing wrote that address in between.
--
-- So what is carried along beside the expressions is what memory is known to
-- hold — an address, the type it was accessed at, and the value the access left
-- there.  A load records what it read and a store records what it wrote, which
-- makes one fact of two transformations: a load finding the address in hand
-- becomes a copy of the earlier load's result, or of the stored value where a
-- store is what put it there.  Nothing about the two cases differs, because
-- what memory holds does not remember how it came to hold it.
--
-- __What invalidates it is a question about pointers, and lives elsewhere.__
-- A store writes the address it names and, for all this can tell, every
-- address that might be the same one; a call writes anything it can reach.
-- Which addresses those are is "Olivine.Core.Alias", worked out once per
-- function and asked here.  The precision that matters most is the one about
-- calls: a slot whose address never left this function's own accesses is
-- storage no callee can name, so what is known about it survives a call, and
-- without that a load in any loop containing a call would be recomputed.
--
-- The type is part of the fact rather than checked against it, so a store of
-- one type followed by a load of another is two facts about one address and
-- neither answers the other.  Writing four bytes of an eight byte slot leaves
-- something no load of the slot can be told, and the way to decline that is to
-- have no fact to find.
--
-- __A volatile access is neither answered nor recorded.__  The point of one is
-- that it happens, so it is never replaced by a copy; and what it leaves behind
-- is not something to reason about, a volatile store being written precisely
-- where reading the value back is not the same as remembering it.  A volatile
-- store still invalidates, since it does write.  The atomic forms are not
-- modelled at all — a line carrying one keeps its function out of the core —
-- so there is nothing here to say about them.
--
-- __Nothing moves.__  Availability says the earlier computation already ran on
-- every path that arrives here, so no operation is hoisted anywhere and none
-- runs that would not have run.  A pass that shared a computation into a place
-- it might not have reached would be inventing work, and inventing poison
-- along with it where the operands only make sense on the path that guards
-- them.
--
-- __Equal, flags and all.__  @add nsw@ and @add@ are not the same expression
-- here, though they compute the same number whenever neither overflows.  Where
-- the @nsw@ one overflows it is poison and the plain one is a number, so
-- sharing in one direction — giving the later @nsw@ instruction the plain
-- result — replaces poison with a value and is sound, and sharing in the other
-- spreads poison to where there was none.  Requiring the operations to be
-- equal declines both.  Taking the sound half is a refinement for later, as is
-- reading @add %a, %b@ and @add %b, %a@ as one expression.
--
-- __Availability is iterated, so a loop keeps what it carries in.__  The
-- blocks are walked over and over, in the order a value can be carried
-- forwards in, until what is known on the way into each of them stops
-- changing.  Every block begins by saying that everything the function
-- computes anywhere is available in it, and each round takes away whatever
-- some path into the block turns out not to carry.
--
-- Beginning from everything is what a must-analysis of a graph with cycles
-- takes.  An expression worked out before a loop is available inside it only
-- if the back edge agrees, and the back edge cannot agree until the body has
-- been walked, which cannot happen until the block the loop begins at has.
-- Beginning from nothing and growing gives the least solution instead, and the
-- least solution is precisely the one where nothing crosses a back edge: the
-- loop would recompute everything it was handed.
--
-- __Everything is never written down.__  Meeting with the set of every fact is
-- the identity, so a block no round has reached yet is left saying nothing at
-- all and the meet passes over it.  That is also the only way to say it, the
-- copies half of an answer being a map: a map holds one value per local, so
-- "anything at all" is not a thing it can hold.
--
-- __And the rounds are made to stop.__  Walking a block is not monotone.  What
-- an instruction is left saying depends on what arrived and not only on how
-- much of it: one that finds its expression already in hand becomes a copy and
-- leaves the answer where it was, while one that does not leaves the answer in
-- itself, and every operand is resolved through whichever copies arrived, so
-- the same expression recorded under two different arrivals is not the same
-- fact — it is the same computation written two ways.  Less arriving can
-- therefore mean something different leaving rather than less, and two rounds
-- that read each other could alternate forever.
--
-- So the rounds are bounded.  One round per block and two more take what
-- arrives at each block as they find it, which is as many as a fact can need —
-- a round carries it at least one block on, and the last round is the one that
-- finds nothing left to change.  After that a round holds what arrives to what
-- arrived last time, which can only shrink and so must stop.  No function in
-- the corpus asks for a fourth round, let alone for the bound.
--
-- Stopping that way is sound whenever it happens, because what makes an answer
-- sound is that nothing arriving at a block is more than every path into it
-- agrees on, and an intersection of what arrives with anything is still that.
-- What it costs is precision, and only past the bound: a computation the
-- intersection drops because an earlier round wrote it another way is a
-- computation not shared, which is the direction this pass is allowed to be
-- wrong in.
module Olivine.Core.Pass.Redundancies
  ( eliminateRedundancies
  , shareable
  ) where

import Control.Applicative ((<|>))
import Control.Monad (guard)
import Data.Foldable (toList)
import Data.List (find, mapAccumL)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.Set qualified as Set

import Olivine.Core.Alias (Access (..), mayAlias, objectsIn, reachableByCall)
import Olivine.Core.Layout (Layout, layoutOf)
import Olivine.Core.Blocks (predecessorsOf, reversePostorder)
import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Load (..), Store (..))
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)
import Olivine.Syntax.Value (TypedValue (..), Value (..))

eliminateRedundancies :: Program -> Program
eliminateRedundancies program =
  program {programEntries = map entry (programEntries program)}
  where
    types = namedTypes program
    -- What the module says about sizes and offsets, read once: it is what
    -- tells one field of a struct from another when a store to one is asked
    -- whether it wrote what a load of the other reads.
    layout = layoutOf program
    entry (EFunction f) = EFunction (eliminateIn types layout f)
    entry retained = retained

-- | What is known at a point in a function.
--
-- The first two are killed by the same event — an assignment to a local —
-- which is why they travel together rather than being two analyses.  The third
-- is killed by that as well, an address and the value found there both being
-- written with locals, and by writes to memory besides.
data Known = Known
  { -- | The expressions worked out already, each with the local holding the
    -- answer and the type of what that local holds, indexed by the locals the
    -- expression reads.
    --
    -- The index is those locals rather than the expression itself for two
    -- reasons.  Keying on the expression would mean an ordering on
    -- operations, which would have to be invented for the calls, attributes
    -- and calling conventions that are never keyed on at all and where an
    -- order would mean nothing.  And the locals an expression reads are
    -- exactly what a reassignment has to invalidate, so the same index that
    -- finds an expression finds everything one assignment takes away.
    --
    -- Expressions reading no locals share the one empty bucket.  Those are
    -- the ones whose operands are all constants, which folding has already
    -- replaced with the value they come to, so the bucket stays as small as
    -- folding leaves it.
    expressions :: Map [Local] [(Operation (TypedValue Local), Local, Type)]
  , -- | What a local is a copy of, where it is a copy of something.  This is
    -- what lets two expressions written the same way be recognized as the
    -- same expression when the operands they read are different locals
    -- holding one value.
    copies :: Map Local (Value Local)
  , -- | What memory is known to hold, one fact per access that settled it.
    --
    -- A list rather than a map keyed by the address, because the event that
    -- invalidates these is a write to /some/ address that may be the one, which
    -- is a question asked of each fact in turn and not a lookup.  There are as
    -- many of them as the block has accesses whose value still stands, which is
    -- few.
    contents :: [Content]
  }
  deriving (Eq)

-- | What memory holds at one address, as one access left it.
--
-- The address and the value are resolved through 'copies', as an expression's
-- operands are, so that two accesses through two locals holding one pointer are
-- accesses to one address.  The type is what the access was at, and is part of
-- what the fact says rather than something to check against it: a load at
-- another type reads other bytes, and finds no fact here to answer it.
data Content = Content
  { contentAddress :: Value Local
  , contentType :: Type
  , contentValue :: Value Local
  }
  deriving (Eq)

-- | The fact as the aliasing reads it: an address and how far the access that
-- settled it reached.
contentAccess :: Content -> Access
contentAccess content = Access (contentAddress content) (contentType content)

nothingKnown :: Known
nothingKnown = Known Map.empty Map.empty []

eliminateIn :: Map Name Type -> Maybe Layout -> Function -> Function
eliminateIn types layout f = f {functionBlocks = map rewrite (functionBlocks f)}
  where
    blocks = functionBlocks f
    order = reversePostorder f
    -- What the function's own pointers point into, which every question about
    -- memory below is asked of.  Read from the function as it arrives: the
    -- rewrite replaces computations with copies of the same value, so what a
    -- pointer points into is the same in what leaves.
    objects = objectsIn layout f
    reachable = Set.fromList order
    byLabel = Map.fromList [(blockLabel b, b) | b <- blocks]

    rewrite b = case Map.lookup (blockLabel b) settled of
      Just (incoming, _) -> b {blockInstructions = snd (walk incoming b)}
      -- A block nothing reaches.  No walk arrives at one, so nothing is known
      -- in it to answer anything with, and nothing it computes or reads reaches
      -- anywhere else to answer anything there.
      Nothing -> b

    -- A block's instructions rewritten against what is known on the way in,
    -- with what is known on the way out.
    walk :: Known -> Block -> (Known, [Instruction])
    walk incoming block = mapAccumL instruction incoming (blockInstructions block)

    -- What is known on the way into each reachable block and on the way out of
    -- it, once the rounds have stopped changing them.
    --
    -- A round takes the blocks in turn, each reading what the blocks before it
    -- in this same round were left saying, so a fact travels as far as the
    -- order allows rather than one block per round.  Rounds up to the bound
    -- take what arrives as it is; after that they hold it to what arrived last
    -- time, which is what stops them.  What leaves is always this round's own
    -- answer about what arrived: holding /that/ to the previous round's would
    -- intersect two spellings of one computation, since the operands were
    -- resolved through the copies each round believed in, and keep neither.
    settled :: Map Label (Known, Known)
    settled = settle (length order + 2) Map.empty
      where
        settle plain before
          | after == before = before
          | otherwise = settle (plain - 1) after
          where
            after = foldl' (visit (plain > 0)) before order

        visit plain seen label = case entering seen label of
          -- Every way in is a block no round has reached yet.  A block reached
          -- from the entry has a predecessor that was reached before it, so
          -- this is a block in a cycle the rounds are still working inwards
          -- to; the next round has more to go on.
          Nothing -> seen
          Just arriving ->
            let incoming = case Map.lookup label seen of
                  Just (previously, _) | not plain -> agreeing previously arriving
                  _ -> arriving
             in Map.insert
                  label
                  (incoming, fst (walk incoming (byLabel Map.! label)))
                  seen

    -- What arrives at a block: what every block control can arrive from was
    -- left knowing, and only where they agree.
    --
    -- A predecessor no round has reached yet is still saying everything, and
    -- meeting with everything is meeting with nothing, so it is passed over
    -- rather than answered for.  The entry block is the one place where an
    -- answer is known outright: a function starts there knowing nothing, and
    -- an edge back to it — which LLVM forbids, whatever else the graph does —
    -- could only agree with less.
    entering :: Map Label (Known, Known) -> Label -> Maybe Known
    entering known label
      | entryLabel f == Just label = Just nothingKnown
      | otherwise = case mapMaybe (fmap snd . (`Map.lookup` known)) (predecessors label) of
          [] -> Nothing
          arriving : rest -> Just (foldl' agreeing arriving rest)

    -- Blocks nothing reaches are not predecessors.  The edge one carries is
    -- an edge control never takes, and counting it would leave a block that
    -- is reached with nothing known on the way in.
    predecessors label = filter (`Set.member` reachable) (predecessorsOf blocks label)

    instruction :: Known -> Instruction -> (Known, Instruction)
    instruction known i = (after, maybe i copy held)
      where
        -- The expression this instruction computes, with every operand read
        -- through what it is a copy of.
        operation = resolve known (instructionOperation i)

        -- The value this instruction can be read off something that already has
        -- it, if there is one.
        held = do
          result <- instructionResult i
          value <- computed <|> loaded
          -- The value can already be in the very local this assigns to, which
          -- is nothing to rewrite: it is a copy of itself.
          guard (typedValue value /= VLocal result)
          pure value

        -- A local holding what this computes.
        computed = do
          guard (shareable operation)
          (_, holder, t) <- lookupExpression operation known
          pure (TypedValue t (VLocal holder))

        -- What memory is known to hold where this reads it.
        loaded = do
          OLoad l <- Just operation
          guard (not (loadVolatile l))
          value <- lookupContent (typedValue (loadPointer l)) (loadType l) known
          pure (TypedValue (loadType l) value)

        copy value = i {instructionOperation = OAssign value}

        -- What the instruction leaves known: what assigning to its result does,
        -- and then what it does to memory.  Two questions rather than one, a
        -- store answering only the second and a load both.
        after = written assigned

        assigned = case instructionResult i of
          -- Assigns to nothing, so there is nothing it can invalidate.
          Nothing -> known
          Just result
            -- Now a copy of the local that holds the answer, and known to be.
            | Just value <- held -> noted result (typedValue value) remaining
            -- Was written as a copy.  A copy of a copy is a copy of what that
            -- one was a copy of, which resolving the operand has already made
            -- it say.
            | OAssign value <- operation -> noted result (typedValue value) remaining
            | shareable operation
            , -- An expression that reads the local it assigns to is not
              -- available after it.  @%a := add %a, 1@ leaves %a holding what
              -- the expression meant before it ran, and the expression now
              -- means something else.
              result `notElem` localsUsedBy operation ->
                record operation result (resultType types operation) remaining
            -- A call, a load, an allocation: nothing to say about what it left
            -- behind beyond what its assignment took away.  What a load leaves
            -- known about memory is 'written' below, which is a different fact.
            | otherwise -> remaining
            where
              remaining = kill result known

        -- What the instruction leaves known about memory.
        written known' = case operation of
          OStore s
            | not (storeVolatile s) -> recording wrote (clobbering target known')
            -- It writes, so what stood at the address it names no longer
            -- stands; that it is volatile only means the value it wrote is not
            -- a fact to keep.
            | otherwise -> clobbering target known'
            where
              -- The bytes it writes, which is where it writes and how wide what
              -- it writes is: a store to one field of a struct leaves what is
              -- known about the others standing.
              target = Access (typedValue (storePointer s)) (typedValueType (storeValue s))
              wrote =
                Content
                  (typedValue (storePointer s))
                  (typedValueType (storeValue s))
                  (typedValue (storeValue s))
          -- Whatever it does to memory, it does it to memory it can name.
          OCall _ ->
            known' {contents = filter (not . reachableByCall objects . contentAddress) (contents known')}
          OLoad l
            | not (loadVolatile l)
            , Just result <- instructionResult i
            , -- A load into the local its own address is read from leaves that
              -- address naming something else, so there is no fact to record
              -- about it.
              result `notElem` localsUsedBy operation ->
                recording
                  ( Content
                      (typedValue (loadPointer l))
                      (loadType l)
                      -- What it was answered with where it was answered, so
                      -- that the fact a later load finds is the one already
                      -- there rather than a second spelling of it.
                      (maybe (VLocal result) typedValue held)
                  )
                  known'
          -- Reads nothing and writes nothing, or is a load with nowhere to put
          -- what it read.
          _ -> known'

        -- Every fact about an address a write to this one could have been a
        -- write to.
        clobbering target known' =
          known'
            { contents =
                filter (not . mayAlias objects target . contentAccess) (contents known')
            }

        -- One more fact, unless it is one already: a load answered by what was
        -- known records what was known, and recording it twice would leave two
        -- facts for one access for the meet to choose between.
        recording content known'
          | content `elem` contents known' = known'
          | otherwise = known' {contents = content : contents known'}

-- | Whether two runs of an operation with the same operands leave the same
-- value behind.
--
-- Written out case by case with no catch-all, so that an operation added to
-- the grammar later fails to compile here rather than being quietly taken for
-- one whose answer can be reused.
shareable :: Operation operand -> Bool
shareable operation = case operation of
  -- Already an assignment of the value it holds; there is no computation to
  -- do twice.  What it is a copy of is noted rather than shared.
  OAssign _ -> False
  -- May do anything, and may answer differently each time it is asked.
  OCall _ -> False
  -- Fresh storage each time, so two allocations are two objects however alike
  -- the instructions asking for them.
  OAlloca _ -> False
  -- The answer is not a function of the operands but of what memory holds at
  -- the address they name, which is what 'contents' is for.
  OLoad _ -> False
  -- Leaves nothing behind to share.
  OStore _ -> False
  OBinary _ -> True
  OUnary _ -> True
  OICmp _ -> True
  OFCmp _ -> True
  OConvert _ -> True
  OSelect _ -> True
  OExtractElement _ -> True
  OInsertElement _ -> True
  OShuffleVector _ -> True
  -- Pointer arithmetic reads no memory: it says where something is, not what
  -- is there.
  OOffset _ -> True
  OField _ -> True

-- | An operation with every operand naming the value it stands for, rather
-- than a local that is a copy of it.
--
-- Only an operand that is a local outright is resolved.  One naming a local
-- from inside a constant aggregate is left alone, which shares less and never
-- shares wrongly — and 'localsUsedBy' reaches it anyway, so an assignment to
-- it still invalidates the expression that holds it.
resolve :: Known -> Operation (TypedValue Local) -> Operation (TypedValue Local)
resolve known = fmap (\(TypedValue t value) -> TypedValue t (through value))
  where
    through (VLocal n) = Map.findWithDefault (VLocal n) n (copies known)
    through value = value

lookupExpression ::
  Operation (TypedValue Local) ->
  Known ->
  Maybe (Operation (TypedValue Local), Local, Type)
lookupExpression operation known =
  find
    (\(candidate, _, _) -> candidate == operation)
    (Map.findWithDefault [] (localsUsedBy operation) (expressions known))

-- | What memory is known to hold at an address, accessed at a type.
lookupContent :: Value Local -> Type -> Known -> Maybe (Value Local)
lookupContent address t known =
  contentValue
    <$> find
      (\c -> contentAddress c == address && contentType c == t)
      (contents known)

record ::
  Operation (TypedValue Local) -> Local -> Type -> Known -> Known
record operation result t known =
  known
    { expressions =
        Map.insertWith
          (<>)
          (localsUsedBy operation)
          [(operation, result, t)]
          (expressions known)
    }

-- | Note that a local holds what a value holds.
--
-- A local said to be a copy of itself is no copy, and saying so would be a
-- name that resolves to itself.
noted :: Local -> Value Local -> Known -> Known
noted result value known
  | value == VLocal result = known
  | otherwise = known {copies = Map.insert result value (copies known)}

-- | What is left known by an assignment to a local.
--
-- Four things go: every expression that reads it, which now means something
-- else; every expression held in it, since it now holds something else; every
-- copy either of it or of something it was a copy of, for both reasons at once;
-- and every fact about memory whose address or whose value was written with it,
-- for those same two reasons — an address is somewhere else now, and a value
-- found there is no longer where the fact says it is.
--
-- That last one is also what an @alloca@ reached twice needs.  Storage
-- allocated in a loop is a new object each time round and holds whatever it
-- holds, and the allocation assigns to the local naming it, so the facts the
-- last iteration left about that address go before the body reads it again.  It
-- is the second of two reasons rather than the only one: the address of such a
-- slot is written with a local nothing above the loop assigns, so no path into
-- the loop carries a fact about it and the meet would have dropped it anyway.
-- Which of the two is doing the work is not something to depend on.
kill :: Local -> Known -> Known
kill assigned known =
  Known
    { expressions =
        Map.filter (not . null) $
          Map.map (filter (\(_, holder, _) -> holder /= assigned)) $
            Map.filterWithKey (\localsRead _ -> assigned `notElem` localsRead) $
              expressions known
    , copies =
        Map.filterWithKey
          (\target value -> target /= assigned && value /= VLocal assigned)
          (copies known)
    , contents = filter (notElem assigned . mentions) (contents known)
    }
  where
    mentions c = toList (contentAddress c) <> toList (contentValue c)

-- | What two paths agree on: the same expression, held in the same local, on
-- both; the same copies on both; and the same value at the same address on
-- both.
--
-- Two blocks that worked the same expression out into different locals leave
-- nothing a block below them can name — there is no one local that holds it
-- however control arrived — so requiring the holders to agree is not caution
-- but the whole of what makes the answer nameable.  The same goes for memory,
-- where the fact is what the address holds: two paths that stored different
-- values to one address leave a block below them nothing it can say the address
-- holds.
agreeing :: Known -> Known -> Known
agreeing a b =
  Known
    { expressions =
        Map.filter (not . null) $
          Map.intersectionWith
            (\xs ys -> filter (`elem` ys) xs)
            (expressions a)
            (expressions b)
    , copies =
        Map.mapMaybe id $
          Map.intersectionWith
            (\x y -> if x == y then Just x else Nothing)
            (copies a)
            (copies b)
    , contents = filter (`elem` contents b) (contents a)
    }
