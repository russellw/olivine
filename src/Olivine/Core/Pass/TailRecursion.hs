-- | Turning a function whose last act is to call itself into one that loops.
--
-- @gcd(a, b)@ returning @gcd(b, a % b)@ does nothing after the call comes back
-- but hand its answer on, so the frame it is waiting in holds nothing anybody
-- will read again.  The next turn can have it: assign the arguments to the
-- parameters, branch to the top, and the call, the frame and the return are all
-- gone.  What is left is the loop the function would have been written as by
-- somebody who did not have recursion.
--
-- __This is the third pass the core representation was shaped for.__  In
-- single assignment form a parameter cannot be assigned, so the loop wants a
-- phi at the head for each one, and building them is most of the work — which
-- is why LLVM's @tailcallelim@ carries a list of the values going round and
-- inserts the nodes itself.  Here a parameter is a local like any other and can
-- be written twice, so the whole of the edit is an assignment per argument and
-- a branch.  "Olivine.Core.Ssa" puts the phis back on the way out, for every
-- local at once, which it was going to do anyway.
--
-- __What a tail call is here.__  A call whose value the function goes on to
-- return, with nothing but assignments in between.  That is not the same as the
-- call standing last in its block: a front end writes the result into the slot
-- it returns from and jumps to a common exit, and promotion turns that into a
-- copy in one block and a @ret@ of it in another.  So the walk from the call
-- follows unconditional branches through as many blocks as it takes, carrying
-- which locals hold what the call left, and asks at the @ret@ whether the value
-- given back is one of them.  Anything else standing on the way — an
-- instruction that computes, a branch that decides — is work the function does
-- after the call, and there is nowhere to do it once the frame is gone.
--
-- __The function starts one block earlier than it did.__  The loop is entered
-- at the block the function used to start at, and LLVM forbids a branch to the
-- entry block, so a block is made in front of it that does nothing but fall in.
-- That block is also where the parameters get their initial values: the body
-- goes on reading the locals it always read, and those are now assigned from
-- fresh parameters at the top and from the arguments at the bottom, which is
-- exactly the phi 'Olivine.Core.Ssa' will write.  Renaming is what makes that
-- possible — a phi standing for a local takes the local's name, and the name it
-- reads on the way in has to be somebody else's.
--
-- __The arguments are handed over through temporaries.__  @gcd(b, a % b)@
-- assigns @b@ to the first parameter, which is @a@'s next value, and would then
-- read the parameter it has just overwritten if the second assignment read it
-- directly.  So every argument is computed into a local of its own first and the
-- parameters are written from those, which is a parallel assignment done the
-- one way that always works.  The copies cost nothing: reconstruction is where
-- assignments go, and none of them reaches LLVM.
--
-- __Every turn shares the frame's storage.__  An @alloca@ makes room in the
-- frame, and
-- the whole point here is that the next turn gets the frame back — so the
-- allocations move up into the block made in front of the loop, where they run
-- once and every turn shares what they made.  That is only sound if no turn can
-- see another's: the address must not escape, which "Olivine.Core.Alias"
-- answers, and the size must be a constant, since a size worked out from this
-- turn's parameters would be the wrong size for the next one.  A function with
-- any allocation this does not hold of is left alone entire rather than being
-- turned into a loop that allocates once around, which is a frame that grows
-- exactly as fast as the recursion it replaced.
--
-- __A tail call to another function is not this.__  Reusing the frame for a call
-- to somebody else is a thing only the code generator can do, and LLVM already
-- has the word for asking: @tail@ on the call site.  What this pass eliminates
-- is the recursion, and a self call is the one case where the callee's code is
-- here to branch to.
module Olivine.Core.Pass.TailRecursion
  ( eliminateTailRecursion
  ) where

import Data.Maybe (isNothing, mapMaybe)
import Data.Set qualified as Set

import Olivine.Core.Alias (objectsIn, reachableByCall)
import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Core.Promises
import Olivine.Syntax.Attribute (FunctionAttribute (..))
import Olivine.Syntax.Function (Parameter (..), Signature (..))
import Olivine.Syntax.Instruction (Alloca (..), Argument (..), Call (..), TailKind (..))
import Olivine.Syntax.Name (Name (..))
import Olivine.Syntax.Type (Arity (..), Type (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

eliminateTailRecursion :: Program -> Program
eliminateTailRecursion program =
  program {programEntries = map entry (programEntries program)}
  where
    promises = promisesOf program

    entry (EFunction f) = EFunction (eliminate promises f)
    entry retained = retained

-- | Turn every self call the function makes last into a branch to the top.
--
-- All of them at once, and then never again: what the edit leaves behind holds
-- no self call at all, so a second run finds nothing and the pass is its own
-- fixed point.  Doing them one at a time would not be — the second round would
-- read the block made in front of the loop as the block to branch back to, and
-- branching there would assign the parameters their original values again.
eliminate :: Promises -> Function -> Function
eliminate promises f
  | not (transformable promises f) = f
  | otherwise = case (entryLabel f, sites f) of
      (Just header, found@(_ : _)) -> turn f header found
      _ -> f

-- | One self call about to become a branch.
data Site = Site
  { siteLabel :: Label
  -- ^ The block it is in, which keeps its number: whatever branches there
  -- still branches there, and what changes is where the block goes.
  , siteAt :: Int
  -- ^ Where in the block it stands.  Everything from here down goes, the call
  -- included, and there is nothing below it but the assignments carrying its
  -- result to the @ret@.
  , siteArguments :: [TypedValue Local]
  -- ^ What to hand the next turn, in the order the parameters take them.
  }

-- | Every call in the function that is a tail call to the function itself.
--
-- At most one to a block, although nothing here says so: the instructions
-- below a tail call are assignments and nothing else, so a second call cannot
-- stand under the first, and a call standing over one has that call below it
-- and is therefore not a tail call.
sites :: Function -> [Site]
sites f =
  [ Site
      { siteLabel = blockLabel b
      , siteAt = at
      , siteArguments = map argumentValue (callArguments call)
      }
  | b <- functionBlocks f
  , (at, i) <- zip [0 ..] (blockInstructions b)
  , OCall call <- [instructionOperation i]
  , itself (functionSignature f) call
  , handedOn f (instructionResult i) b (drop (at + 1) (blockInstructions b))
  , whole f (blockLabel b) at
  ]

-- | Whether a call is one the function makes to itself, and one that assigning
-- the arguments to the parameters says the same thing as.
--
-- The symbol is compared as text, @\@f@ and @\@"f"@ being one symbol written
-- two ways.  What follows it is the same question 'Olivine.Core.Pass.Inline'
-- asks of a call it is about to replace with a body, and for the same reason:
-- a call that disagrees with the definition about how it happens is one this
-- would settle by silently picking neither.  The types are compared because
-- LLVM does not require a direct call to agree with the callee it names — with
-- opaque pointers there is nothing left to make it — and an argument of one
-- type assigned to a parameter of another is a program the verifier is right to
-- complain about.
--
-- @notail@ is the one marker refused.  It asks that the call not become a tail
-- call, which is what @opt -passes=tailcallelim@ takes it for.  @musttail@ is
-- not refused: it promises the call will not grow the stack, and a call that is
-- not made at all keeps that promise the only way it can be kept absolutely.
--
-- An operand bundle is refused, as it is at an inlining site and for the same
-- reason: assigning the arguments to the parameters says what the arguments
-- said and nothing about what the call carried beside them, so the bundle
-- would go out with the call.  See 'bundled'.
itself :: Signature -> Call (TypedValue Local) -> Bool
itself signature call =
  named (typedValue (callCallee call))
    && callTail call /= Just NoTail
    && isNothing (callAddrSpace call)
    && not (bundled call)
    && callCallingConvention call == signatureCallingConvention signature
    && callType call == signatureReturnType signature
    && map (typedValueType . argumentValue) (callArguments call) == parameterTypes
    && not (any (any copied . argumentAttributes) (callArguments call))
  where
    named (VGlobal name) = nameText name == nameText (signatureName signature)
    named _ = False

    parameterTypes = map parameterType (signatureParameters signature)

-- | Whether what the call leaves behind is what the function goes on to return,
-- with nothing done in between.
--
-- The walk starts under the call and follows unconditional branches, carrying
-- the locals that hold the call's result: an assignment of one of them holds it
-- too, and an assignment of anything else takes the local that held it out of
-- the set.  Anything but an assignment stops the walk, being work the function
-- does after the call comes back.
--
-- A block is walked at most once.  A path that arrives somewhere it has been is
-- a loop with no @ret@ in it, and following it round is the one way this could
-- fail to answer.
handedOn :: Function -> Maybe Local -> Block -> [Instruction] -> Bool
handedOn f result from below =
  go
    (Set.singleton (blockLabel from))
    (maybe Set.empty Set.singleton result)
    below
    (blockTerminator from)
  where
    returns = signatureReturnType (functionSignature f)

    go seen holds (i : rest) t = case (instructionResult i, instructionOperation i) of
      (Just target, OAssign value) -> go seen (carrying holds target (typedValue value)) rest t
      _ -> False
    go seen holds [] t = case terminatorTransfer t of
      -- A function that gives nothing back has nothing to check: whatever the
      -- call left, if it left anything, is discarded here as it was there.
      Ret Nothing -> returns == TVoid
      Ret (Just value) -> case typedValue value of
        VLocal held -> Set.member held holds
        _ -> False
      Br target
        | not (Set.member target seen)
        , Just b <- blockAt target ->
            go (Set.insert target seen) holds (blockInstructions b) (blockTerminator b)
      _ -> False

    carrying holds target value = case value of
      VLocal held | Set.member held holds -> Set.insert target holds
      _ -> Set.delete target holds

    blockAt label = case [b | b <- functionBlocks f, blockLabel b == label] of
      b : _ -> Just b
      [] -> Nothing

-- | Whether the function still defines everything it still reads, once the
-- call and what stands below it have gone.
--
-- What goes is the call, the assignments carrying its result along, and the
-- branch under them.  A local one of those defined and nothing else does is
-- then defined nowhere — and the reads of it are all on the way to the @ret@,
-- which is the path being removed, unless something outside reaches one.  The
-- ordinary shape has nothing to say here: the result of a promoted @return@
-- slot is assigned on every path that reaches the exit, so the exit block goes
-- on reading a local the other paths still write.
whole :: Function -> Label -> Int -> Bool
whole f label at = all defined stillRead
  where
    kept = concatMap staying (functionBlocks f)
    staying b
      | blockLabel b == label = take at (blockInstructions b)
      | otherwise = blockInstructions b

    endings = [blockTerminator b | b <- functionBlocks f, blockLabel b /= label]

    stillRead =
      concatMap (localsUsedBy . instructionOperation) kept
        <> concatMap (localsUsedBy . terminatorTransfer) endings

    definitions =
      Set.fromList
        ( functionParameters f
            <> mapMaybe instructionResult kept
            <> mapMaybe resultOf endings
        )

    defined local = Set.member local definitions

-- | Whether the function as a whole is one whose frame the next turn may have.
--
-- Every parameter's value has to be something an assignment can hand over, so
-- a variadic function is refused — the arguments past the parameters have no
-- local to be assigned to — and so is one passed a copy of what a pointer
-- points at, since the copy is made by the call this is about to remove.
--
-- A @weak@ definition is refused because the call may not be a call to this
-- body at all; @naked@ because the body is not code this or any pass can
-- reason about; and a body holding a @setjmp@ because a second return arrives
-- in a frame the loop has since written over.
transformable :: Promises -> Function -> Bool
transformable promises f =
  signatureArity signature == FixedArity
    && not (interposable (signatureLinkage signature))
    && FANaked `notElem` attributesOf promises signature
    && not (any (any copied . parameterAttributes) (signatureParameters signature))
    && not (returnsTwiceIn promises f)
    && reusable f
  where
    signature = functionSignature f

-- | Whether the storage the function allocates can be shared by every turn of
-- the loop.
--
-- Three things have to hold of every allocation, and a function with one that
-- fails any of them is left alone.  It stands in the entry block, so that
-- moving it in front of the loop moves it nowhere control did not already run
-- it.  Its size is a constant, since a size read off this turn's parameters is
-- not the size the next turn asks for.  And its address does not escape, which
-- is what says no turn can be looking at what another turn is writing: nothing
-- reads it after the call, the call being last, and the call cannot reach it.
--
-- The layout is not consulted, and 'objectsIn' is given none.  What a layout
-- measures is how far one pointer stands from another, and the question here is
-- only whether an address got out at all.
reusable :: Function -> Bool
reusable f = all shareable here && not (any allocation elsewhere)
  where
    objects = objectsIn Nothing f

    here = filter allocation (concatMap blockInstructions (take 1 (functionBlocks f)))
    elsewhere = concatMap blockInstructions (drop 1 (functionBlocks f))

    shareable i = case (instructionResult i, instructionOperation i) of
      (Just slot, OAlloca a) ->
        not (allocaInalloca a)
          && null (localsUsedBy (OAlloca a))
          && not (reachableByCall objects (VLocal slot))
      _ -> False

-- | Whether an instruction makes room in the frame.
allocation :: Instruction -> Bool
allocation i = case instructionOperation i of
  OAlloca _ -> True
  _ -> False

-- | Put a block in front of the function and send every tail call back to what
-- used to be the first one.
turn :: Function -> Label -> [Site] -> Function
turn f header found =
  f
    { functionParameters = fresh
    , functionBlocks = made : map rewrite (functionBlocks f)
    }
  where
    signature = functionSignature f
    parameters = functionParameters f
    types = map parameterType (signatureParameters signature)
    width = length parameters

    -- One range of locals for the parameters the function now takes and one
    -- per site for the temporaries, each past everything the function already
    -- uses and past each other.
    Local base = nextLocal f
    fresh = [Local (base + k) | k <- [0 .. width - 1]]
    temporaries at = [Local (base + width * (at + 1) + k) | k <- [0 .. width - 1]]

    made =
      Block
        { blockLabel = nextLabel f
        , blockInstructions = hoisted <> zipWith3 copy parameters types (map VLocal fresh)
        , -- No attachment: nothing in the source says to jump here, and giving
          -- a branch Olivine made up a position would be claiming a line of
          -- code wrote it.
          blockTerminator = Terminator (Br header) []
        }

    -- The allocations run once, in front of the loop, and every turn shares
    -- what they made.  'reusable' has already said that the entry block is the
    -- only place they stand, so taking them out of it is asking what they are.
    hoisted = filter allocation (concatMap blockInstructions (take 1 (functionBlocks f)))

    rewrite b = case [(at, s) | (at, s) <- zip [0 ..] found, siteLabel s == blockLabel b] of
      (at, site) : _ ->
        b
          { blockInstructions =
              staying b (take (siteAt site) (blockInstructions b)) <> handing at site
          , blockTerminator = Terminator (Br header) []
          }
      [] -> b {blockInstructions = staying b (blockInstructions b)}

    -- The allocations are gone from the entry block, having been hoisted.
    -- Nothing else about a block moves: what stands above a call stands where
    -- it stood.
    staying b instructions
      | blockLabel b == header = filter (not . allocation) instructions
      | otherwise = instructions

    -- Every argument into a local of its own, and then the parameters from
    -- those: a parameter written before a later argument is read would
    -- otherwise be read as the value it is about to have rather than the one it
    -- has.
    handing at site =
      zipWith3 copy holding (map typedValueType arguments) (map typedValue arguments)
        <> zipWith3 copy parameters types (map VLocal holding)
      where
        arguments = siteArguments site
        holding = temporaries at

    copy target t value = Instruction (Just target) (OAssign (TypedValue t value)) []
