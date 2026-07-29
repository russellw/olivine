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

import Data.Foldable (toList)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust, isNothing, mapMaybe)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Attribute
  ( AttributeItem (..)
  , FunctionAttribute (..)
  , ParamAttribute (..)
  )
import Olivine.Syntax.Function (Parameter (..), Signature (..))
import Olivine.Syntax.Instruction
  ( Alloca (..)
  , Argument (..)
  , Call (..)
  , TailKind (..)
  )
import Olivine.Syntax.Linkage (Linkage (..))
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

    entry (EFunction f)
      | receptive world f = EFunction (settle world f)
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
  , -- | @attributes #0 = { ... }@, so that a signature referring to a group
    -- can be asked what it actually says.  Most of what decides inlining is
    -- written this way: clang puts @noinline@ and @optnone@ in a group and
    -- every function at @-O0@ points at it.
    worldGroups :: Map Natural [FunctionAttribute]
  , -- | Which functions each one can reach by calling, transitively.  This is
    -- what refuses recursion, and it has to be the closure rather than the
    -- direct calls: @f@ calling @g@ calling @f@ is a cycle no single edge
    -- looks like.
    worldReaches :: Map Text (Set Text)
  }

worldOf :: Program -> World
worldOf program =
  World
    { worldBodies = bodies
    , worldGroups =
        Map.fromList
          [ (n, toList attributes)
          | ERetained (Syntax.EAttributeGroup n attributes) <- programEntries program
          ]
    , worldReaches = closure (Map.map (Set.fromList . directCalls) bodies)
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

-- | Whether a function may be inlined into at all.
--
-- @optnone@ says not to optimize this function, and inlining into it is
-- optimizing it.  @noinline@ on a caller is not this question — it says not to
-- copy this function elsewhere, which is 'copyable'.
receptive :: World -> Function -> Bool
receptive world f = FAOptNone `notElem` attributesOf world (functionSignature f)

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
    && FANoInline `notElem` resolve world (callAttributes call)
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

-- | Whether an attribute says the argument is passed by making a copy of what
-- it points at.
--
-- These are the ones inlining cannot honour by binding a local to the value:
-- @byval@ means the callee gets its own copy of the pointee and may write to
-- it freely, so replacing the call without materializing that copy would let
-- the body write the caller's object. The others are the same promise made by
-- other ABI machinery.
copied :: ParamAttribute -> Bool
copied attribute = case attribute of
  PAByVal _ -> True
  PAByRef _ -> True
  PAPreallocated _ -> True
  PAInAlloca _ -> True
  _ -> False

-- | Whether the body may be copied out of the function it is written in.
copyable :: World -> Function -> Bool
copyable world callee =
  isJust (entryLabel callee)
    && not (interposable (signatureLinkage signature))
    && not (any (`elem` attributes) [FANoInline, FAOptNone, FAReturnsTwice, FANaked])
    && not (any indirect (functionBlocks callee))
  where
    signature = functionSignature callee
    attributes = attributesOf world signature
    indirect b = case terminatorTransfer (blockTerminator b) of
      IndirectBr _ _ -> True
      _ -> False

-- | Whether the definition here might not be the one that runs.
--
-- A @weak@ or @linkonce@ definition is one candidate among several and the
-- linker picks; copying its body inlines a function the program may never
-- call. The @_odr@ forms are exempt because that is what the suffix promises —
-- every candidate has the same body, so any of them is the right one.
--
-- Symbol interposition at load time is deliberately not treated as making a
-- definition uncertain. It would make almost every external function
-- uninlinable in a shared library, and it is the behaviour clang itself
-- assumes: @-fno-semantic-interposition@ is its default.
interposable :: Maybe Linkage -> Bool
interposable linkage = case linkage of
  Just LinkWeak -> True
  Just LinkLinkOnce -> True
  Just LinkCommon -> True
  Just LinkExternWeak -> True
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
  FAAlwaysInline `elem` attributesOf world (functionSignature callee)
    || bodySize callee <= sizeThreshold

-- | How much code a function is, in instructions.
--
-- Each block counts one more than it holds, for its terminator: a body cut
-- into many blocks is more code than the same instructions in one, and the
-- branches between them are what inlining will leave behind.
bodySize :: Function -> Int
bodySize f = sum [1 + length (blockInstructions b) | b <- functionBlocks f]

-- | What a function's attributes actually say, groups resolved.
attributesOf :: World -> Signature -> [FunctionAttribute]
attributesOf world = resolve world . signatureAttributes

-- | An attribute slot with its group references followed through.
--
-- A function and a call site have the same slot, and nearly everything that
-- decides inlining arrives through it rather than written out: clang puts
-- @noinline@ and @optnone@ in a group and points every function at @-O0@ at
-- it, so a pass reading only what is spelled on the function would see none of
-- them and inline the lot.
resolve :: World -> [AttributeItem] -> [FunctionAttribute]
resolve world = concatMap item
  where
    item (AIGroup n) = Map.findWithDefault [] n (worldGroups world)
    item (AIAttribute a) = [a]

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

    renumberTerminator t =
      retarget shiftLabel t {terminatorTransfer = fmap renumberOperand (terminatorTransfer t)}
