-- | Taking out of a loop the work that does not depend on going round it.
--
-- An instruction whose operands are the same on every iteration computes the
-- same value on every iteration, so it can be computed once before the loop is
-- entered instead of once per turn.  This is the first pass that moves an
-- instruction rather than rewriting one in place, and everything delicate about
-- it follows from that: what a computation is worth is a question the other
-- passes ask where it stands, and this one has to ask it somewhere else.
--
-- __Invariant means not assigned in the loop.__  A local the loop never
-- assigns holds, at every point inside it, what it held when control arrived —
-- so reading it before the loop reads the same value the instruction would have
-- read inside.  That is the whole of the analysis, and it is cheap for the
-- reason "Olivine.Core.Pass.Redundancies" is not: availability asks what /has
-- been/ computed on the way here, which every path has to agree on, while
-- invariance asks what is /never/ assigned in a set of blocks, which is one
-- sweep over them.
--
-- __The value goes in a preheader.__  Which block that is and how it is made
-- are "Olivine.Core.Loops"' business, since rotation wants the same block for
-- its own reasons: it is the block every edge into the header passes through,
-- so what it computes is computed exactly when the loop is entered.  Where the
-- loop is already entered from a single block that branches nowhere else, that
-- block /is/ the preheader and the instructions are appended to it, which is
-- the usual case in what a front end emits and why this pass adds no block to
-- most functions.
--
-- __The result must be a local the function assigns in one place.__  Here is
-- the bill the non-SSA core presents this time.  Moving @%x := add %a, %b@
-- earlier moves /when @%x@ is written/, so any read of @%x@ between the loop
-- being entered and the instruction being reached sees the new value where it
-- saw the old one.  In single assignment form the question cannot arise.  The
-- condition that settles it is that nothing else in the function assigns @%x@
-- and that it is not a parameter: then a read that could have seen the old
-- value is a read of a local nothing has assigned, which is undefined
-- behaviour already, and refining that is allowed.  A local assigned twice —
-- what promotion makes of a variable, and what a phi is lowered to — is
-- declined, which is a refinement left for a liveness analysis rather than
-- something this pass cannot say.
--
-- __It may run where the original would not have.__  A loop whose test fails
-- the first time never runs its body, and an instruction in a block the body
-- only sometimes reaches may not have run either; hoisted, it runs whenever the
-- loop is reached.  For an operation that only computes a value that costs
-- nothing: an overflowing @add nsw@ hoisted out of a loop that never ran leaves
-- poison in a local nothing goes on to read.  For an operation that can
-- undefine the program it costs everything, so integer division is not hoisted
-- — dividing by zero is undefined behaviour rather than poison, and running it
-- where the program would not have is inventing that behaviour rather than
-- collecting on it.  A division standing where the loop is certain to run it
-- could come out on exactly the terms a load does below, 'alwaysReached' being
-- the whole of what it would need; it is left declined outright until a program
-- turns up that wants it.
--
-- __A load comes out when the loop cannot change what it reads.__  What a load
-- answers is not a function of its operands but of what memory holds at the
-- address they name, so a pointer the loop never assigns is not enough: a store
-- or a call anywhere in the loop may leave something else there.  Which ones
-- could is "Olivine.Core.Alias", asked here of every store in the body, and for
-- a call asked as whether the address is one a callee has any way to name.  It
-- is the question "Olivine.Core.Pass.Redundancies" asks of the instructions
-- between two accesses, asked of a whole loop body instead.
--
-- __And when running it early cannot fault.__  A load is the first thing this
-- pass moves that can undefine a program by being run where the program would
-- not have run it.  Two answers rather than one, because they are different
-- facts:
--
-- * /The loop runs it anyway./  An instruction in the header runs whenever the
--   loop is entered at all, and every edge into the header goes through the
--   preheader, so moving it there moves it past nothing — nothing except a call
--   above it in the header, which may not come back.  The loads and divisions
--   above it may fault, and those are passed over: a program that faults there
--   is undefined already, and refining one that is undefined is allowed.
--
-- * /Or the storage is there whatever the program does./  A load of a whole
--   symbol reads storage the program has for as long as it is running, so it
--   cannot fault wherever it is run.  Whole is the word: the type loaded has to
--   be the type the symbol was defined with, since without a data layout
--   nothing here knows whether any other type fits inside it, and the alignment
--   asked for has to be one the symbol was given, an access at an alignment the
--   storage does not have being undefined like any other.  An @extern_weak@
--   symbol may be absent and is declined; an alias is not answered for at all,
--   being a second name for storage this does not follow to.
--
-- What that would otherwise leave out is the shape a front end writes most
-- often: a load through a pointer the function was handed, in a body the loop
-- may never reach.  Knowing that one is safe by looking at it means knowing the
-- pointer is good for as many bytes as the load reads, which is
-- dereferenceability and wants sizes.  The way to it that does not want them is
-- to rotate the loop first, which makes the body the header and so makes the
-- must-execute answer above the one that fires; that is
-- "Olivine.Core.Pass.LoopRotation", and it runs earlier in the pipeline for
-- this reason.
--
-- __The copies come out first.__  An operand is rarely the value it stands
-- for.  Promotion replaces a load of a slot with a copy of the local the slot
-- became, standing where the load stood, so a loop reading a variable it never
-- writes reads a copy that the loop /does/ write, and the arithmetic on it is
-- invariant in nothing.  The redundancy pass answers this by resolving operands
-- through the copies for the purpose of comparing them, which it can do because
-- it rewrites nothing and moves nothing.  Moving an instruction is not that: an
-- operand written in the program has to mean, where the instruction is moved to,
-- what it meant where it stood.  So the copy is moved as well — it is invariant
-- exactly when what it copies is not assigned in the loop — and the round after
-- it finds the arithmetic reading a local the loop no longer assigns.  Hoisting a copy saves nothing by itself, since
-- reconstruction removes every assignment on the way out; what it buys is the
-- hoist after it.
--
-- __Innermost first, and iterated.__  An instruction is hoisted out of the
-- smallest loop it is invariant in, because a value that reaches the preheader
-- of an inner loop is then computed outside that loop, which can make it
-- invariant in the loop containing it.  So the loops are taken smallest first
-- and the whole thing runs again after each move: a chain of computations comes
-- out one instruction per round — the first has to leave the loop before the
-- second stops reading something the loop assigns — and a value in a nest of
-- loops comes out one loop per round.
--
-- The rounds are bounded by what a round achieves.  A hoist takes an
-- instruction out of one loop's body and puts it in a block outside it, so the
-- number of pairs of an instruction and a loop holding it goes down by at least
-- one; that number, counted once at the start, is therefore as many rounds as
-- there can be.  It is a bound rather than the argument itself because a loop
-- containing another contains its preheader only where the graph is reducible,
-- and everything a compiler emits is, but nothing here checks.
module Olivine.Core.Pass.LoopInvariants
  ( hoistLoopInvariants
  , hoistable
  ) where

import Data.List (inits)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Alias (Objects, mayAlias, objectsIn, reachableByCall)
import Olivine.Core.Instruction
import Olivine.Core.Loops (Loop (..), Preheader, enterThrough, loopsOf, preheaderFor)
import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Global (Global (..))
import Olivine.Syntax.Instruction (Binary (..), BinaryOp (..), Load (..), Store (..))
import Olivine.Syntax.Linkage (GlobalAttribute (..), Linkage (..))
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Value (TypedValue (..), Value (..))

hoistLoopInvariants :: Program -> Program
hoistLoopInvariants program =
  program {programEntries = map entry (programEntries program)}
  where
    -- What the module's symbols name, which is what says whether a load of one
    -- can be run where the program would not have run it.  Read once for the
    -- program: no pass makes or unmakes a global, and this one moves
    -- instructions between blocks of one function.
    globals = globalVariables program

    entry (EFunction f) = EFunction (settle globals (rounds f) f)
    entry retained = retained

-- | The module's global variables by name.
--
-- Variables and nothing else.  A function is not storage to read from, and an
-- alias names storage this does not follow to — the type written on an alias is
-- the type it is given rather than the type of what is behind it — so neither
-- answers what 'alwaysReadable' asks.
globalVariables :: Program -> Map Name Global
globalVariables program =
  Map.fromList
    [ (globalName g, g)
    | ERetained (Syntax.EGlobal g) <- programEntries program
    ]

-- | As many hoists as there can be: one instruction leaves one loop each time,
-- and this is how many of those there are to begin with.
rounds :: Function -> Int
rounds f =
  sum
    [ length (blockInstructions b)
    | loop <- loopsOf f
    , b <- functionBlocks f
    , Set.member (blockLabel b) (loopBody loop)
    ]

settle :: Map Name Global -> Int -> Function -> Function
settle globals remaining f
  | remaining <= 0 = f
  | otherwise = case candidates globals f of
      [] -> f
      (loop, preheader, moving) : _ ->
        settle globals (remaining - 1) (hoistFrom f loop preheader moving)

-- | The loops with something to take out of them, innermost first, each with
-- where what comes out of it goes.
candidates :: Map Name Global -> Function -> [(Loop, Preheader, [Instruction])]
candidates globals f =
  [ (loop, preheader, moving)
  | loop <- loopsOf f
  , Just preheader <- [preheaderFor f loop]
  , let moving = invariantIn globals objects f loop
  , not (null moving)
  ]
  where
    -- What the function's own pointers point into, which every question about
    -- memory below is asked of.  Read once for the function rather than once
    -- per loop: hoisting moves instructions between blocks, and what a pointer
    -- points into is not a fact about where the instruction computing it
    -- stands.
    objects = objectsIn f

-- | The instructions in a loop that can be computed before it instead.
--
-- Everything collected in one round is independent of everything else in it: an
-- instruction reading what another one in the loop assigns is not invariant
-- yet, so nothing here reads anything else here, and the order they are
-- appended in cannot matter.  Two loads are independent of each other in the
-- stronger sense as well, neither writing anything the other could read.
invariantIn :: Map Name Global -> Objects -> Function -> Loop -> [Instruction]
invariantIn globals objects f loop =
  [ i
  | b <- functionBlocks f
  , Set.member (blockLabel b) (loopBody loop)
  , (above, i) <- zip (inits (blockInstructions b)) (blockInstructions b)
  , movable (blockLabel b) above (instructionOperation i)
  , Just result <- [instructionResult i]
  , Set.member result once
  , not (any (`Set.member` assigned) (localsUsedBy (instructionOperation i)))
  ]
  where
    once = writtenOnce f
    assigned = assignedIn f loop

    -- Every instruction the loop runs, which is what a load has to be safe
    -- against all of.
    inside =
      [ instructionOperation i
      | b <- functionBlocks f
      , Set.member (blockLabel b) (loopBody loop)
      , i <- blockInstructions b
      ]

    -- Whether an instruction may be moved out, given where in the loop it
    -- stands.  Only a load reads the position: for everything else the answer
    -- is a fact about the operation alone, which is 'hoistable'.
    movable label above operation = case operation of
      OLoad l ->
        not (loadVolatile l)
          && not (changed (typedValue (loadPointer l)))
          && (alwaysReached loop label above || alwaysReadable globals l)
      _ -> hoistable operation

    -- Whether anything the loop runs can write what a load of this address
    -- reads.  A volatile store is a store: what makes it volatile is that the
    -- write must happen, which is the opposite of a reason to pass over it.
    changed pointer =
      any (mayAlias objects pointer) stored
        || (calling && reachableByCall objects pointer)

    stored = [typedValue (storePointer s) | OStore s <- inside]
    calling = not (null [() | OCall _ <- inside])

-- | Every local the loop assigns, which is exactly what is not invariant in
-- it.
assignedIn :: Function -> Loop -> Set Local
assignedIn f loop =
  Set.fromList
    [ result
    | b <- functionBlocks f
    , Set.member (blockLabel b) (loopBody loop)
    , i <- blockInstructions b
    , Just result <- [instructionResult i]
    ]

-- | The locals the function assigns in one place and that are not parameters.
--
-- A parameter is assigned where the function is entered, which is before
-- anything this pass can move something to, so an instruction assigning to one
-- is assigning to it a second time whatever the blocks say.
writtenOnce :: Function -> Set Local
writtenOnce f =
  Set.difference
    (Set.fromList [local | (local, 1 :: Int) <- Map.toList counted])
    (Set.fromList (functionParameters f))
  where
    counted =
      Map.fromListWith
        (+)
        [ (result, 1)
        | b <- functionBlocks f
        , i <- blockInstructions b
        , Just result <- [instructionResult i]
        ]

-- | Move the given instructions out of the loop and into its preheader.
--
-- They are identified by the local they assign rather than by what they are:
-- each is the only assignment to it in the function, which is what made it
-- hoistable, so no other instruction can be taken for one of these.
hoistFrom :: Function -> Loop -> Preheader -> [Instruction] -> Function
hoistFrom f loop preheader moving =
  enterThrough (f {functionBlocks = map strip (functionBlocks f)}) loop preheader moving Nothing
  where
    moved = Set.fromList (mapMaybe instructionResult moving)

    strip b
      | Set.member (blockLabel b) (loopBody loop) =
          b {blockInstructions = filter (not . hoisted) (blockInstructions b)}
      | otherwise = b
    hoisted i = maybe False (`Set.member` moved) (instructionResult i)

-- | Whether an operation may be computed before a loop that would have
-- computed it inside, judged by what the operation is and nothing else.
--
-- Two questions at once, and an operation has to answer both: that it leaves
-- the same value behind whenever its operands are the same, and that running
-- it where the original would not have run it changes nothing else.  Written
-- out case by case with no catch-all, so that an operation added to the grammar
-- later fails to compile here rather than being quietly taken for one that can
-- be moved.
--
-- A load answers the first question in neither direction here, since what it
-- answers depends on what the loop does to memory and on where in the loop it
-- stands; 'invariantIn' asks it there, and this says only that nothing about a
-- load on its own settles it.
hoistable :: Operation operand -> Bool
hoistable operation = case operation of
  -- A copy saves nothing by being made earlier — reconstruction removes every
  -- assignment on the way out of the core, so there is no instruction here to
  -- pay for.  It is hoisted because it is what stands between the loop and the
  -- value it is invariant in.  Promotion turns every load of a slot into a copy
  -- where the load was, so a computation on a variable the loop never writes
  -- reads two copies made inside the loop and is invariant in nothing until
  -- they come out; taking them out is what makes the round after it see what
  -- the arithmetic really reads.
  OAssign _ -> True
  -- May do anything, and may answer differently each time it is asked.
  OCall _ -> False
  -- Fresh storage each time, so one allocation before the loop is not the
  -- allocations the loop asked for.
  OAlloca _ -> False
  -- The answer is whatever memory holds, and a store or a call in the loop may
  -- change that.  Nor is the pointer necessarily one that can be read at all
  -- when the loop is not entered.  Both are asked in 'invariantIn', which is
  -- where the loop is to ask them of.
  OLoad _ -> False
  -- Writes memory, so moving it changes when the write happens.
  OStore _ -> False
  OBinary b -> not (undefinedByZero (binaryOp b))
  OUnary _ -> True
  OICmp _ -> True
  OFCmp _ -> True
  OConvert _ -> True
  OSelect _ -> True
  OExtractElement _ -> True
  OInsertElement _ -> True
  OShuffleVector _ -> True
  -- Pointer arithmetic says where something is rather than what is there, and
  -- one that runs off the end of its object is poison rather than a fault.
  OOffset _ -> True
  OField _ -> True

-- | Whether the loop runs an instruction whenever it is entered at all.
--
-- In the header, since every block of the body is reached through it and no
-- other block of the body is reached at all on a turn that goes straight back
-- out.  And with nothing above it in the header that control may not come back
-- from, which is a call: the preheader runs and then the header runs from the
-- top, so an instruction with a call above it is one the loop may be entered
-- without ever reaching.
--
-- What is above it may fault instead of returning — a load through a bad
-- pointer, a division by zero — and that is passed over rather than answered
-- for.  Faulting there is undefined behaviour, so the program had none to
-- preserve from that point on, and a refinement of a program that is undefined
-- is any program at all.
alwaysReached :: Loop -> Label -> [Instruction] -> Bool
alwaysReached loop label above =
  label == loopHeader loop && all (returns . instructionOperation) above

-- | Whether control certainly reaches the instruction after this one.
--
-- A call may not come back — it may throw, it may exit, it may not finish —
-- and nothing else in the grammar has anywhere to go but on.  Written out case
-- by case with no catch-all for the reason 'hoistable' is: an operation added
-- later that can end the function has to be looked at here rather than be taken
-- for one that cannot.
returns :: Operation operand -> Bool
returns operation = case operation of
  OCall _ -> False
  OAssign _ -> True
  OBinary _ -> True
  OUnary _ -> True
  OICmp _ -> True
  OFCmp _ -> True
  OConvert _ -> True
  OSelect _ -> True
  OExtractElement _ -> True
  OInsertElement _ -> True
  OShuffleVector _ -> True
  OAlloca _ -> True
  -- These can fault, which is not the same as not returning: a program that
  -- faults is undefined from there on, and this is asked in order to say what a
  -- program that is defined does.
  OLoad _ -> True
  OStore _ -> True
  OOffset _ -> True
  OField _ -> True

-- | Whether a load can be run wherever it is put, for what it reads rather
-- than for where it stands.
--
-- The whole of a symbol, and only that.  Storage a symbol names is there for as
-- long as the program is running, so reading it cannot fault; what has to be
-- established is that the load reads that storage and no more of the address
-- space than that.
--
-- The type settles it, since the core has no data layout to compare sizes
-- with: a load at the type the symbol was defined with reads exactly the
-- symbol.  Any other type may be larger, and @i64@ read from a symbol defined
-- as @i32@ is two symbols' worth of address at best.  A step from the symbol is
-- declined for the same reason — the pointer here has to be the symbol itself,
-- since where an index lands within an object is what a layout would say.
--
-- The alignment likewise, and it is a real question rather than a formality:
-- an access at an alignment the storage does not have is undefined, so a load
-- written @align 8@ of a symbol given @align 4@ is undefined when it runs, and
-- running it where it would not have run is inventing that.  Both have to say
-- what they are for this to compare them; where either is silent the answer is
-- the type's natural alignment, which is a size again.
alwaysReadable :: Map Name Global -> Load (TypedValue Local) -> Bool
alwaysReadable globals l = case typedValue (loadPointer l) of
  VGlobal name
    | Just g <- Map.lookup name globals ->
        globalType g == loadType l
          -- The one linkage that says the symbol may not be there when the
          -- program runs: an @extern_weak@ name the linker does not resolve is
          -- null, and reading it is what this exists to avoid.
          && globalLinkage g /= Just LinkExternWeak
          && aligned g
  _ -> False
  where
    aligned g = case (loadAlignment l, [n | GAAlign n <- globalAttributes g]) of
      (Just wanted, [given]) -> wanted <= given
      _ -> False

-- | Whether an opcode undefines the program on operands it can be given.
--
-- The integer divisions, and only those: dividing by zero is undefined
-- behaviour in LLVM rather than poison, so one of these run where the program
-- would not have run it is behaviour invented rather than behaviour preserved.
-- Everything else here answers poison at worst — a shift past the width, an
-- @nsw@ addition that overflows — which is a value nothing reads when the loop
-- does not run.
--
-- Floating point division is not one of them: dividing by zero is an infinity,
-- and the default environment traps on nothing.
undefinedByZero :: BinaryOp -> Bool
undefinedByZero op = case op of
  OpUDiv -> True
  OpSDiv -> True
  OpURem -> True
  OpSRem -> True
  OpAdd -> False
  OpSub -> False
  OpMul -> False
  OpShl -> False
  OpLShr -> False
  OpAShr -> False
  OpAnd -> False
  OpOr -> False
  OpXor -> False
  OpFAdd -> False
  OpFSub -> False
  OpFMul -> False
  OpFDiv -> False
  OpFRem -> False
