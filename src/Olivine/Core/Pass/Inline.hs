-- | Replacing a call with the body of the function it calls.
--
-- The first pass that rewrites one function using another's contents, and so
-- the first that could not be written at all without the whole program in
-- hand: dead symbol removal reads every function to decide what to delete,
-- but this reads one to decide what another should say.  Everything after it
-- benefits — a constant handed to a parameter is a constant inside the body
-- once the parameter is an assignment, and folding, control flow and dead code
-- all work on what that opens up.
--
-- __This is the second pass the core representation was shaped for.__  In
-- single assignment form the hard part of inlining is the return value: a
-- callee with three @ret@s hands three values to one use, so the call site
-- becomes a join and the join needs a phi, which means splitting the block,
-- finding every reaching return and building the node.  Here a @ret@ becomes
-- an assignment to the local the call assigned to, once per return, and
-- nothing joins anything — the same trick that let promotion skip dominance
-- frontiers.  "Olivine.Core.Ssa" builds whatever phi that implies on the way
-- out, for every local at once, which it was going to do anyway.  Binding the
-- arguments is the same trick again: a parameter is a local, and passing an
-- argument is assigning to it.
--
-- __What comes back is a graph, not a straight line.__  The block holding the
-- call is cut in two, the callee's blocks go between the halves, and every
-- return branches to the lower half.  A callee that was a single block leaves
-- three blocks where there was one, which looks like a step backwards until
-- the control flow pass runs: two of the three edges are unconditional and
-- lead to blocks with one predecessor, which is exactly what block merging
-- takes away.  That is why this runs before it and not after.
--
-- __A @setjmp@ stays in the function that wrote it.__  This is the one rule
-- here that is about what the rest of the optimizer is allowed to do rather
-- than about what this pass can express.  A call that returns twice comes back
-- a second time with the frame as @longjmp@ left it, and the licence every
-- language gives for that is scoped to the function holding the call: C says
-- the local variables of /that/ function have indeterminate values afterwards
-- unless they are @volatile@, and says nothing about anybody else's.  That
-- licence is what lets "Olivine.Core.Pass.Promote" put such a function's slots
-- in locals at all — LLVM promotes them too, which was checked by asking
-- @opt -passes=mem2reg@ rather than by reading the LangRef.  Copying the body
-- into a caller would carry the @setjmp@ into a function whose locals were
-- never covered, and every promotion, reordering and reuse the caller has
-- already been given becomes a guess about storage a @longjmp@ can rewind.  So
-- a body holding such a call is not copyable, which is what LLVM's inliner
-- does and what @opt -passes=inline@ confirms on a body it would otherwise
-- take whole.
--
-- __@noinline@ is obeyed and @optnone@ is not.__  They arrive together — the
-- verifier rejects @optnone@ without @noinline@, which @llvm-as@ confirms — so
-- nothing in the input distinguishes a function somebody marked from every
-- function in a module clang compiled at @-O0@, where the pair is a level
-- marker stamped on a group every function points at.  What separates them is
-- what they ask for.  @noinline@ asks that this body not be copied elsewhere,
-- which is a request about the one thing this pass does, and a body that reads
-- its own return address or is patched at run time means it: the class is
-- @returns_twice@ and @naked@, refused just below on their own merits.
-- @optnone@ asks that the function stay debuggable, and that is a promise
-- Olivine cannot keep — debug info is carried across passes but not
-- maintained, and no other pass asks about the attribute, so an @optnone@
-- function is promoted, rotated and folded like any other.  Obeying it in the
-- inliner alone would buy the appearance of the promise and not the promise.
--
-- __Debug information is carried, not corrected.__  An instruction copied out
-- of the callee keeps the attachments it was written with, which after
-- inlining describe a position in a function the instruction is no longer in.
-- LLVM answers that by rewriting each location with the scope it was inlined
-- at; Olivine does not maintain debug info across passes, so what it does here
-- is carry what was there and invent nothing — the branches this creates get
-- no attachment at all, since no line of source says to jump there.
module Olivine.Core.Pass.Inline
  ( inlineCalls
  , bodySize
  , sizeThreshold
  ) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust, isNothing, mapMaybe)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)

import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Core.Promises
import Olivine.Syntax.Attribute (FunctionAttribute (..))
import Olivine.Syntax.Function (Parameter (..), Signature (..))
import Olivine.Syntax.Instruction
  ( Alloca (..)
  , Argument (..)
  , Call (..)
  , TailKind (..)
  )
import Olivine.Syntax.Name (Name (..))
import Olivine.Syntax.Type (Arity (..), Type (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

-- | How big a body may be and still be worth copying to every call site.
--
-- Instructions and blocks, counted by 'bodySize'.  This is a first number, not
-- a measured one: it is set where a wrapper, an accessor or a line of
-- arithmetic goes and anything with a loop in it stays, on the grounds that
-- copying a body smaller than the call sequence it replaces cannot lose and
-- copying a large one is a judgement no counting rule makes well.  A callee
-- marked @alwaysinline@ ignores it, which is what that attribute means.
--
-- Nothing here bounds the total growth.  A chain of small functions each
-- calling the next is copied into every caller along the chain, and the
-- threshold — being a fact about one callee — does not see that happening.
-- LLVM answers this with a cost model that grows stricter as a caller does;
-- until there is a benchmark to tune such a thing against, guessing at one
-- would be worse than the plain rule.
sizeThreshold :: Int
sizeThreshold = 12

-- | Inline what is worth inlining, everywhere in the program at once.
inlineCalls :: Program -> Program
inlineCalls program =
  program {programEntries = map entry (programEntries program)}
  where
    world = worldOf program

    entry (EFunction f) = EFunction (settle world f)
    entry e = e

-- | Inline one call, then look again.
--
-- One at a time, because each rewrite decides the numbers the next one has to
-- avoid: a body is copied in at whatever locals and blocks the caller has left
-- free, and it has left different ones afterwards.
--
-- Looking again reaches what was inside what was just inlined, so a call to a
-- function that calls a function arrives in one sweep and needs no second one.
-- What it cannot do is loop forever, for the reason 'recursive' gives.
settle :: World -> Function -> Function
settle world f = case sites world f of
  [] -> f
  site : _ -> settle world (splice f site)

-- | What the whole program tells one function's rewriting.
data World = World
  { -- | The functions the program defines, by symbol.  Names as text, since
    -- @\@f@ and @\@"f"@ are one symbol and the quoting is a fact about the
    -- writing rather than about what is called.
    worldBodies :: Map Text Function
  , -- | Which functions each one can reach by calling, transitively.  This is
    -- what refuses recursion, and it has to be the closure rather than the
    -- direct calls: @f@ calling @g@ calling @f@ is a cycle no single edge
    -- looks like.
    worldReaches :: Map Text (Set Text)
  , -- | What each symbol the module names promises about itself.
    --
    -- 'worldBodies' cannot answer this.  It holds what was lowered, and the
    -- callees whose promises decide anything here are mostly declarations —
    -- @setjmp@ above all.  Reading them is "Olivine.Core.Promises", which is
    -- where it lives now that tail recursion elimination asks the same
    -- questions of the same attributes.
    worldPromises :: Promises
  }

worldOf :: Program -> World
worldOf program =
  World
    { worldBodies = bodies
    , worldReaches = closure (Map.map (Set.fromList . directCalls) bodies)
    , worldPromises = promisesOf program
    }
  where
    bodies =
      Map.fromList
        [ (nameText (signatureName (functionSignature f)), f)
        | EFunction f <- programEntries program
        ]

-- | The symbols a function calls directly.
--
-- Direct calls and nothing else, which is the right graph for this and would
-- be the wrong one for reachability: a call through a pointer is not an edge
-- inlining can travel, so it is not one that can make inlining recur.  Dead
-- symbol removal has to follow every mention there is, and does.
directCalls :: Function -> [Text]
directCalls f =
  [ nameText name
  | b <- functionBlocks f
  , i <- blockInstructions b
  , OCall call <- [instructionOperation i]
  , VGlobal name <- [typedValue (callCallee call)]
  ]

-- | Transitive closure of a graph, by growing each node's set until none grows.
closure :: Ord a => Map a (Set a) -> Map a (Set a)
closure graph
  | grown == graph = graph
  | otherwise = closure grown
  where
    grown = Map.map step graph
    step reached =
      foldl' Set.union reached (mapMaybe (`Map.lookup` graph) (Set.toList reached))

-- | Every call in a function that should be replaced by the body it names.
sites :: World -> Function -> [Site]
sites world caller =
  [ Site
      { siteLabel = blockLabel b
      , siteBefore = before
      , siteAfter = after
      , siteResult = instructionResult i
      , siteArguments = callArguments call
      , siteReturn = blockTerminator b
      , siteCallee = callee
      , siteHoisted = hoisted
      }
  | b <- functionBlocks caller
  , (before, i, after) <- splits (blockInstructions b)
  , OCall call <- [instructionOperation i]
  , VGlobal name <- [typedValue (callCallee call)]
  , Just callee <- [Map.lookup (nameText name) (worldBodies world)]
  , callable world call
  , agrees call (instructionResult i) callee
  , copyable world callee
  , not (recursive world name)
  , Just hoisted <- [hoistable callee]
  , worthCopying world callee
  ]

-- | Every way of picking one element out of a list, with what is either side.
splits :: [a] -> [([a], a, [a])]
splits xs = [(take n xs, x, drop (n + 1) xs) | (n, x) <- zip [0 ..] xs]

-- | One call about to be replaced, and everything replacing it needs to know.
data Site = Site
  { siteLabel :: Label
  -- ^ The block the call is in, which keeps its number: whatever branches
  -- there still branches there, and the half of it after the call is what
  -- moves.
  , siteBefore :: [Instruction]
  , siteAfter :: [Instruction]
  , siteResult :: Maybe Local
  -- ^ What the call assigned to, if anything.  A call to a function returning
  -- a value may still discard it, so this being absent says nothing about the
  -- callee's return type.
  , siteArguments :: [Argument (TypedValue Local)]
  , siteReturn :: Terminator
  -- ^ How the block ended, which now ends the lower half.
  , siteCallee :: Function
  , siteHoisted :: [Instruction]
  -- ^ The callee's allocations, to be moved to the caller's entry block.
  }

-- | Whether the call site itself is an ordinary one.
--
-- @musttail@ is a promise about the machine code — the call must be the last
-- thing the function does and must reuse its frame — and inlining it away
-- breaks that promise rather than keeping it.  An address space on the call is
-- rare enough that reproducing it is not worth guessing at.
--
-- @noinline@ can be written here as well as on the callee, and means the same
-- thing about this one call: a body worth copying everywhere else may still be
-- one this caller was told to leave alone.
--
-- @tail@ is not among these.  It says the callee does not see the caller's
-- stack, which is a fact about the callee that stays true wherever its body is
-- written, and the marker simply has nowhere to go afterwards.
callable :: World -> Call (TypedValue Local) -> Bool
callable world call =
  callTail call /= Just MustTail
    && isNothing (callAddrSpace call)
    && FANoInline `notElem` resolve (worldPromises world) (callAttributes call)
    && not (any (any copied . argumentAttributes) (callArguments call))

-- | Whether the call site and the callee fit together closely enough that
-- binding each argument to each parameter says what the call said.
--
-- A variadic callee is refused because the arguments past the parameters have
-- no local to be bound to: what reads them is @va_arg@ walking a list this
-- would have to build. A count that does not match is refused for the same
-- reason from the other end, and it is invalid input rather than a shape to
-- handle. A calling convention that differs between the two is a disagreement
-- about how the call happens, and inlining would resolve it by silently
-- picking neither.
--
-- The return type is checked only where the call keeps the result: a @void@
-- function reaches its @ret@ with no value to assign, so a site expecting one
-- would be left reading a local nothing writes.
agrees :: Call (TypedValue Local) -> Maybe Local -> Function -> Bool
agrees call result callee =
  signatureArity signature == FixedArity
    && length (callArguments call) == length (functionParameters callee)
    && callCallingConvention call == signatureCallingConvention signature
    && not (any (any copied . parameterAttributes) (signatureParameters signature))
    && (isNothing result || signatureReturnType signature /= TVoid)
  where
    signature = functionSignature callee

-- | Whether the body may be copied out of the function it is written in.
--
-- @optnone@ is not among the attributes refused here; the module header says
-- why.
copyable :: World -> Function -> Bool
copyable world callee =
  isJust (entryLabel callee)
    && not (interposable (signatureLinkage signature))
    && not (any (`elem` attributes) [FANoInline, FAReturnsTwice, FANaked])
    && not (any indirect (functionBlocks callee))
    && not (any unwinding (functionBlocks callee))
    && not (returnsTwiceIn (worldPromises world) callee)
  where
    signature = functionSignature callee
    attributes = attributesOf (worldPromises world) signature
    indirect b = case terminatorTransfer (blockTerminator b) of
      IndirectBr _ _ -> True
      _ -> False

    -- A body that handles or propagates an exception stays where it is.  What
    -- its landing pads mean is decided by the personality on the function they
    -- are written in, and the caller's is another function's promise or none
    -- at all; a resume copied into a caller unwinds a frame that was never
    -- asked to unwind.  Nothing here would notice either.
    unwinding b =
      any pad (blockInstructions b) || case terminatorTransfer (blockTerminator b) of
        Invoke{} -> True
        Resume _ -> True
        _ -> False
    pad i = case instructionOperation i of
      OLandingPad _ -> True
      _ -> False

-- | Whether a function can call its way back to itself.
--
-- Asked of the callee alone, and not of whether the callee can reach the
-- caller, which is the weaker condition it is tempting to write. @even@
-- calling @odd@ calling @even@ reaches neither of them from a third function
-- that calls @even@, so a check against the caller admits it: @even@'s body is
-- copied in, bringing a call to @odd@, whose body is copied in, bringing a
-- call to @even@, and the two take turns forever.
--
-- Refusing every function on a cycle is what stops that, and it is enough to
-- stop it everywhere. A function that cannot reach itself cannot be on a
-- cycle, so what is left to copy from forms a graph with no cycles in it;
-- every body brought in names functions strictly further down it, and there is
-- a bottom. Direct recursion needs no separate case, a function that calls
-- itself reaching itself in one step.
recursive :: World -> Name -> Bool
recursive world callee =
  nameText callee `Set.member` Map.findWithDefault Set.empty (nameText callee) (worldReaches world)

-- | Whether a body small enough to copy, or one asked for regardless.
worthCopying :: World -> Function -> Bool
worthCopying world callee =
  FAAlwaysInline `elem` attributesOf (worldPromises world) (functionSignature callee)
    || bodySize callee <= sizeThreshold

-- | How much code a function is, in instructions.
--
-- Each block counts one more than it holds, for its terminator: a body cut
-- into many blocks is more code than the same instructions in one, and the
-- branches between them are what inlining will leave behind.
bodySize :: Function -> Int
bodySize f = sum [1 + length (blockInstructions b) | b <- functionBlocks f]

-- | The callee's allocations, if every one of them can be moved to the
-- caller's entry block, and nothing otherwise.
--
-- They have to move. An @alloca@ is freed when the function holding it
-- returns, and after inlining that function is the caller: leaving the
-- allocation where the body puts it would let a call in a loop allocate once
-- per iteration and free none of it until the caller returned, turning a
-- constant stack requirement into an unbounded one.
--
-- Hoisting is sound because the storage is dead as soon as the inlined body
-- reaches its return, so the executions of the body cannot want it at the same
-- time and may share one slot. It costs the allocation happening even when
-- control never enters the body, which is stack space and nothing else.
--
-- What cannot move is an allocation whose size is computed. Its operand is a
-- local, and the caller's entry block is above everything that defines one —
-- including the assignments binding the arguments, which is where a size
-- depending on a parameter would come from. Rather than work out which of them
-- happen to be constant enough, a body holding any such allocation is left
-- alone entire. The same goes for one written outside the entry block, which
-- is a body deliberately allocating more than once, and for @inalloca@, which
-- is an allocation the call sequence itself writes into.
hoistable :: Function -> Maybe [Instruction]
hoistable f
  | all fixed here && not (any allocation elsewhere) = Just here
  | otherwise = Nothing
  where
    here = filter allocation (concatMap blockInstructions (take 1 (functionBlocks f)))
    elsewhere = concatMap blockInstructions (drop 1 (functionBlocks f))

    fixed i = case instructionOperation i of
      OAlloca alloca ->
        not (allocaInalloca alloca) && null (localsUsedBy (OAlloca alloca))
      _ -> False

-- | Whether an instruction allocates storage for the duration of a call.
allocation :: Instruction -> Bool
allocation i = case instructionOperation i of
  OAlloca _ -> True
  _ -> False

-- | Replace one call with the body of what it calls.
--
-- The block holding the call is cut at it. The upper half keeps the block's
-- number, so nothing branching there has to be told anything, and gains the
-- assignments binding the arguments and a branch into the copied body. The
-- lower half is a new block holding whatever followed the call and the
-- terminator that was already there. Between them go the callee's blocks, with
-- every number in them moved past everything the caller uses, and every @ret@
-- turned into an assignment to what the call assigned to and a branch to the
-- lower half.
splice :: Function -> Site -> Function
splice caller site = caller {functionBlocks = hoist (concatMap place (functionBlocks caller))}
  where
    callee = siteCallee site

    -- One shift for locals and one for blocks, each past everything the caller
    -- already uses. The callee's numbering survives intact underneath, which
    -- is what makes this a copy rather than a renaming: nothing has to be
    -- looked up, since a number's new value is a function of its old one.
    localBase = case nextLocal caller of Local n -> n
    labelBase = case nextLabel caller of Label n -> n

    shiftLocal (Local n) = Local (localBase + n)
    shiftLabel (Label n) = Label (labelBase + n)

    -- Past every block the callee has, so it collides with none of them.
    continuation = shiftLabel (nextLabel callee)

    place b
      | blockLabel b == siteLabel site = upper : map copy (functionBlocks callee) <> [lower]
      | otherwise = [b]

    upper =
      Block
        { blockLabel = siteLabel site
        , blockInstructions = siteBefore site <> bindings
        , -- No attachment: nothing in the source said to jump here, and
          -- inventing a position for a branch Olivine made up would be
          -- claiming a line of code wrote it.
          blockTerminator = Terminator (Br entry) []
        }
      where
        entry = maybe continuation shiftLabel (entryLabel callee)

    lower =
      Block
        { blockLabel = continuation
        , blockInstructions = siteAfter site
        , blockTerminator = siteReturn site
        }

    -- Passing an argument is assigning to the parameter, the parameter being a
    -- local like any other. The attributes on either end are dropped: they say
    -- things about how a call happens that are no longer being promised to
    -- anyone, and an assignment has nowhere to write them down.
    bindings =
      [ Instruction (Just (shiftLocal parameter)) (OAssign (argumentValue argument)) []
      | (parameter, argument) <- zip (functionParameters callee) (siteArguments site)
      ]

    copy b =
      Block
        { blockLabel = shiftLabel (blockLabel b)
        , blockInstructions = map renumber (retained b) <> returned b
        , blockTerminator = ending b
        }
      where
        -- The allocations are gone from the entry block, having been hoisted.
        -- 'hoistable' has already established that the entry block is the only
        -- place they appear, so removing them is asking what they are.
        retained block
          | Just (blockLabel block) == entryLabel callee =
              filter (not . allocation) (blockInstructions block)
          | otherwise = blockInstructions block

    -- A return becomes an assignment of what it returned, where the call kept
    -- the result. This is the whole of what a phi would have been for, and the
    -- reason there is none to build: each return assigns on its own path, and
    -- reconstruction works out on the way back to LLVM what that implies where
    -- the paths meet.
    returned b = case terminatorTransfer (blockTerminator b) of
      Ret (Just value)
        | Just result <- siteResult site ->
            [Instruction (Just result) (OAssign (renumberOperand value)) []]
      _ -> []

    -- The metadata stays with the terminator it was written on: a return and
    -- the branch replacing it are the same transfer of control, so an
    -- attachment true of one is true of the other.
    ending b = case terminatorTransfer (blockTerminator b) of
      Ret _ -> Terminator (Br continuation) (terminatorMetadata (blockTerminator b))
      _ -> renumberTerminator (blockTerminator b)

    -- The allocations go to the front of the caller's first block. That is the
    -- entry block, and the upper half of a split entry block is still first,
    -- so this reaches the right place whether or not the call was in it.
    hoist (b : bs) = b {blockInstructions = map renumber (siteHoisted site) <> blockInstructions b} : bs
    hoist [] = []

    renumber i =
      i
        { instructionResult = fmap shiftLocal (instructionResult i)
        , instructionOperation = fmap renumberOperand (instructionOperation i)
        }

    renumberOperand = fmap shiftLocal

    -- All three walks over a terminator, because a body copied into a caller
    -- is renumbered whole: the operands, the destinations, and — where the
    -- terminator is one of the two calls — the local it assigns, which is not
    -- an operand and which 'fmap' therefore does not reach.
    renumberTerminator t =
      reassign shiftLocal $
        retarget shiftLabel t {terminatorTransfer = fmap renumberOperand (terminatorTransfer t)}
