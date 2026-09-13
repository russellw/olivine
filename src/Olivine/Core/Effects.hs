-- | What calling a function does besides handing back a result.
--
-- Every pass here treats a call as a wall.  Nothing known about memory
-- survives one, no computation may be moved across one, and no call may be
-- taken away however plainly its result is unread — because a call may write
-- anything, may never come back, and may leave by throwing.  That is the right
-- answer for a call to something this module knows nothing about, and it is
-- the wrong answer for most calls a program makes.
--
-- __Two sources say otherwise, and both are read here.__  The first is what
-- the module already wrote down: @memory(none)@, @nounwind@ and @willreturn@ on
-- a signature or on a call site are promises, and clang writes them on
-- declarations of the library it expects to link against and on everything its
-- own inference reached at @-O1@ and above.  The second is the bodies in this
-- very module, which is the thing this optimizer is designed to be able to
-- read and had not been reading: a function whose body writes nothing outside
-- itself writes nothing outside itself, whatever its signature happens to say.
--
-- __The whole program is one fixed point.__  What a call does is what the
-- callee's body does, and a body is made of calls, so the two are settled
-- together: every function starts out promising everything and each round
-- takes back what its body cannot do.  Starting optimistic is what lets two
-- functions that call each other be pure — a least fixed point from the
-- pessimistic end would keep every cycle at \"may do anything\" forever — and
-- it is sound for the three questions asked that way, since an effect a
-- program has is an effect some instruction has, and no instruction of a cycle
-- ever loses it.
--
-- __Termination is the exception, and it is forced rather than iterated.__  A
-- function that can reach itself may recur without end, and that is not
-- something any instruction of its body says; an optimistic round would
-- conclude that it always returns because each call in it does.  So a function
-- in a call cycle is held to \"may not return\" from the start, exactly as a
-- function holding a loop is.  @opt -passes=function-attrs@ was asked and
-- agrees on both: it gives a self-recursive @memory(none)@ function its
-- @memory(none)@ and withholds @willreturn@.
--
-- __Where it touches is read as well as whether.__  LLVM's @memory@ says which
-- locations are touched — the arguments, storage nothing in the module can
-- address, everything else — and 'behaviourReach' keeps that.  It is what
-- separates a call that may disturb anything from one that may disturb only
-- what it was handed: @memcpy@ promises @memory(argmem: readwrite)@, so a load
-- from storage neither of its two pointers names survives it.  'mayReach' is
-- the question a pass actually asks, and it is asked instead of
-- 'reachableByCall' rather than as well.
--
-- Whether and where are kept apart on purpose.  'writesMemory' goes on meaning
-- \"writes something\", including storage this module cannot address, because
-- that is what the dead code pass has to ask: a call writing inaccessible
-- memory has an effect even though no load here can see it, and dropping it
-- because nothing here aliases it would be dropping the effect.
module Olivine.Core.Effects
  ( Behaviour (..)
  , Reach (..)
  , anything
  , nothing
  , mayReach
  , Effects
  , effectsOf
  , behaviourOf
  ) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Core.Alias (Objects, objectsIn, reachableByArguments, reachableByCall)
import Olivine.Core.Blocks (predecessorsOf)
import Olivine.Core.Instruction
import Olivine.Core.Layout (Layout, layoutOf)
import Olivine.Core.Loops (Loop (..), loopsOf)
import Olivine.Core.Metadata (Metadata, attachmentSays, metadataOf)
import Olivine.Core.Program
import Olivine.Core.Promises
  ( Promises
  , interposable
  , promisedNames
  , promisesOf
  , resolve
  )
import Olivine.Syntax.Attribute (FunctionAttribute (..))
import Olivine.Syntax.Function (Signature (..))
import Olivine.Syntax.Instruction (Argument (..), Call (..), Load (..), Store (..))
import Olivine.Syntax.Name (nameText)
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..), holdsAsm)

-- | What running something may do besides computing with its operands.
--
-- Four questions, each of which some pass is refusing to do something over.
-- Every field says /may/, so 'nothing' is the strongest thing that can be
-- known and every combination of behaviours is a pointwise @||@.
data Behaviour = Behaviour
  { -- | May read memory that anything outside it can also reach.
    --
    -- Reading its own storage is not reading: an @alloca@ whose address never
    -- leaves the function is memory no caller had before the call and none has
    -- after it, so what the body does there is no more visible than what it
    -- does with its locals.  That is 'reachableByCall' answering, and it is
    -- what makes a function that spills to the stack still a function that
    -- reads nothing — confirmed against @opt -passes=function-attrs@, which
    -- calls such a function @memory(none)@.
    readsMemory :: Bool
  , -- | May write memory that anything outside it can also reach, on the same
    -- reading of \"outside\".
    writesMemory :: Bool
  , -- | May leave by throwing rather than by returning.
    mayUnwind :: Bool
  , -- | May fail to come back at all: it loops, it recurs, or it exits.
    mayNotReturn :: Bool
  , -- | Where the reading and the writing can land.
    behaviourReach :: Reach
  }
  deriving (Eq, Show)

-- | Where a call's memory accesses can be, as far as its caller can see.
data Reach
  = -- | Anywhere a stranger can name, which is the answer for anything not
    -- promising otherwise.
    Anywhere
  | -- | Only the storage its own arguments point into, which is what
    -- @memory(argmem: ...)@ promises.
    OnlyArguments
  | -- | Only storage nothing in this module can address, which is
    -- @memory(inaccessiblemem: ...)@.  No access written here can alias it, so
    -- for aliasing this is nothing at all — but it is not nothing for the
    -- passes that ask whether a call does anything, and 'writesMemory' still
    -- says it writes.
    Unaddressable
  deriving (Eq, Show)

-- | Whether a call may touch the storage a pointer points into.
--
-- The question every pass that has to give something up at a call is really
-- asking.  What it gives up depends on what the callee promised about where it
-- goes, so this is 'reachableByCall' for a callee that promised nothing and
-- something narrower for one that did.
--
-- __A callee promising nothing may still touch what it was handed.__  Being
-- handed a pointer is a second way to reach storage, beside naming it as a
-- stranger, and the two are unioned rather than either standing for both.
-- While every argument is a pointer let out of sight the union is the first
-- alone — an argument's storage has escaped by the act of being an argument —
-- which is why this said 'reachableByCall' and was right.  It stops being
-- right the moment a callee can promise to be handed a pointer without keeping
-- it: the storage is then unescaped and an argument at once, and reading
-- 'reachableByCall' alone would have this answer that a call cannot touch what
-- it was just given.
mayReach :: Objects -> Behaviour -> Call (TypedValue Local) -> Value Local -> Bool
mayReach objects behaviour call address = case behaviourReach behaviour of
  Anywhere -> reachableByCall objects address || handedOver
  OnlyArguments -> handedOver
  Unaddressable -> False
  where
    -- Only the pointer arguments: @argmem@ is what the arguments /point/ into,
    -- and an argument that is not a pointer is not a way to reach storage.  The
    -- size and the volatile flag of a @memcpy@ are two of them, and counting
    -- them would make every such call reach everywhere — which is what it did
    -- before this said so.
    handedOver =
      reachableByArguments
        objects
        [ typedValue (argumentValue argument)
        | argument <- callArguments call
        , TPointer _ <- [typedValueType (argumentValue argument)]
        ]
        address

-- | The answer for something nothing is known about.
anything :: Behaviour
anything = Behaviour True True True True Anywhere

-- | The answer for something that does none of it.
-- Its reach is the smallest there is, which is what makes it the identity of
-- 'also': something that touches no memory widens nothing when it is added to
-- something that does.
nothing :: Behaviour
nothing = Behaviour False False False False Unaddressable

-- | Both of them, which is what a body does when it does two things.
also :: Behaviour -> Behaviour -> Behaviour
also a b =
  Behaviour
    { readsMemory = readsMemory a || readsMemory b
    , writesMemory = writesMemory a || writesMemory b
    , mayUnwind = mayUnwind a || mayUnwind b
    , mayNotReturn = mayNotReturn a || mayNotReturn b
    , behaviourReach = wider (behaviourReach a) (behaviourReach b)
    }

-- | What two accounts of one thing agree it may do.
--
-- Every field is a \"may\", so the sharper of two answers is the smaller one.
-- Two accounts arise wherever a promise is written twice: a call site and the
-- callee it names each carry attributes, and either alone is enough to say
-- that this call does not write — which is how LLVM reads them too, a site's
-- attributes being a promise about that call rather than a description of the
-- callee.
sharper :: Behaviour -> Behaviour -> Behaviour
sharper a b =
  Behaviour
    { readsMemory = readsMemory a && readsMemory b
    , writesMemory = writesMemory a && writesMemory b
    , mayUnwind = mayUnwind a && mayUnwind b
    , mayNotReturn = mayNotReturn a && mayNotReturn b
    , behaviourReach = narrower (behaviourReach a) (behaviourReach b)
    }

-- | Where two things between them may go, which is wherever either may.
wider :: Reach -> Reach -> Reach
wider a b
  | a == Anywhere || b == Anywhere = Anywhere
  | a == OnlyArguments || b == OnlyArguments = OnlyArguments
  | otherwise = Unaddressable

-- | Where two promises about one call agree it may go, which is where both
-- allow.  Two that allow nothing in common allow nothing the caller can see.
narrower :: Reach -> Reach -> Reach
narrower a b
  | a == Unaddressable || b == Unaddressable = Unaddressable
  | a == OnlyArguments || b == OnlyArguments = OnlyArguments
  | otherwise = Anywhere

-- | What each symbol the module names may do, and the promises to read a call
-- site's own attributes with.
data Effects = Effects
  { effectPromises :: Promises
  , -- | Names as text, for the reason "Olivine.Core.Promises" holds them so:
    -- @\@f@ and @\@"f"@ are one symbol.
    effectSymbols :: Map Text Behaviour
  }

-- | Read the whole program: what it promises, and what its bodies do.
effectsOf :: Program -> Effects
effectsOf program = Effects promises (settle initial)
  where
    promises = promisesOf program
    layout = layoutOf program
    metadata = metadataOf program

    -- The bodies whose contents may be believed.  A weak definition is one
    -- candidate among several and the linker picks, so what /this/ body does is
    -- no promise about what the program will call; 'interposable' is the same
    -- question inlining asks before copying one, and the answer has to be the
    -- same.
    bodies =
      Map.fromList
        [ (nameText (signatureName (functionSignature f)), f)
        | EFunction f <- programEntries program
        , not (interposable (signatureLinkage (functionSignature f)))
        ]

    -- What every symbol's own attributes say, bodies and declarations alike.
    -- A symbol with a body still has these: they are what the front end
    -- promised, and a body cannot take back a promise, only add to it.
    declared =
      Map.fromList
        [ (name, fromAttributes attributes)
        | (name, attributes) <- promisedNames promises
        ]

    -- A function that can reach itself may recur forever, which is not
    -- something any one instruction of it says.  The closure rather than the
    -- direct calls, since @f@ calling @g@ calling @f@ is a cycle no single edge
    -- looks like — the same graph inlining refuses to copy along.
    cyclic =
      Set.fromList
        [ name
        | (name, reached) <- Map.toList (closure (Map.map callees bodies))
        , Set.member name reached
        ]

    -- What each body says for itself, read once rather than once a round: the
    -- accesses it makes, the loops it holds and the calls it makes are the
    -- same in every round, and only what the callees do changes.
    read' = Map.map (bodyOf layout promises metadata) bodies

    initial = Map.map (const nothing) bodies

    -- Each round reads the last one's answers about the callees.  It stops
    -- because a round only ever adds — an effect once concluded is concluded
    -- from an instruction that is still there next round — and there are
    -- finitely many effects to add.
    settle guess
      | next == guess = Map.union next declared
      | otherwise = settle next
      where
        next = Map.mapWithKey round' read'
        round' name body =
          held name (sharper (promised name) (doing promises (asked guess) body))

    -- What a callee may do, part way through settling.  A symbol with no body
    -- here is answered by its promises alone, and one the module never names
    -- at all may do anything.
    asked guess name = case Map.lookup name guess of
      Just behaviour -> behaviour
      Nothing -> Map.findWithDefault anything name declared

    promised name = Map.findWithDefault anything name declared

    held name behaviour
      | Set.member name cyclic = behaviour {mayNotReturn = True}
      | otherwise = behaviour

-- | The symbols a function calls directly, the calls that end a block
-- included.
callees :: Function -> Set Text
callees f =
  Set.fromList
    [ nameText name
    | call <- callsIn f
    , VGlobal name <- [typedValue (callCallee call)]
    ]

-- | Every call a body makes, wherever it stands.
callsIn :: Function -> [Call (TypedValue Local)]
callsIn f =
  [ call
  | b <- functionBlocks f
  , call <-
      [c | i <- blockInstructions b, OCall c <- [instructionOperation i]]
        <> [c | Just c <- [callIn (terminatorTransfer (blockTerminator b))]]
  ]

-- | Transitive closure of a graph, by growing each node's set until none
-- grows.
closure :: Ord a => Map a (Set a) -> Map a (Set a)
closure graph
  | grown == graph = graph
  | otherwise = closure grown
  where
    grown = Map.map step graph
    step reached =
      foldl' Set.union reached [Map.findWithDefault Set.empty r graph | r <- Set.toList reached]

-- | What a body says for itself: everything but what its callees do.
--
-- The calls are kept rather than answered, because answering them is what
-- changes from round to round of the settling and none of the rest of this
-- does.
data Body = Body
  { bodyOwn :: Behaviour
  , bodyCalls :: [Call (TypedValue Local)]
  , -- | Whether it holds a loop, and whether every loop of it that writes
    -- nothing has to end.  Together they say whether the body has a way of not
    -- coming back that is not a call — see 'spinning'.
    bodyLoops :: Bool
  , bodyProgress :: Bool
  }

-- | Read a body once.
--
-- Written as a fold over everything the function holds rather than as a search
-- for the first thing that does something, because all four questions are
-- asked at once and an early answer to one is no answer to the others.
bodyOf :: Maybe Layout -> Promises -> Metadata -> Function -> Body
bodyOf layout promises metadata f =
  Body
    { bodyOwn =
        foldl' also nothing (map operation (operationsIn f) <> map transfer (transfersIn f))
    , bodyCalls = callsIn f
    , bodyLoops = not (null loops)
    , bodyProgress = stamped || all ending loops
    }
  where
    loops = loopsOf f
    blocks = functionBlocks f

    -- What the whole function promises, which covers every loop in it at once.
    -- That is the C++ spelling: clang writes @mustprogress@ on the function
    -- because the language guarantees progress for every loop it has.
    stamped = FAMustProgress `elem` resolve promises (signatureAttributes (functionSignature f))

    -- What one loop promises for itself.  C guarantees progress only for a
    -- loop whose controlling expression is not a constant, so clang has to say
    -- it a loop at a time, and it says it by hanging
    -- @!llvm.loop.mustprogress@ off the @!llvm.loop@ node the branch closing
    -- the loop names.  Every edge that closes the loop has to say it: they are
    -- the several ways round one loop, and a way round that promises nothing
    -- is a way round that may be taken for ever.  A loop with no back edge is
    -- not one this could be asked of, and answering 'False' for it is the
    -- answer that costs nothing.
    ending loop = case latches loop of
      [] -> False
      closing -> all (deciding loop Set.empty) closing

    latches loop =
      [ b
      | b <- blocks
      , Set.member (blockLabel b) (loopBody loop)
      , loopHeader loop `elem` targetsOf (blockTerminator b)
      ]

    -- Where a loop says it for itself is the branch that decides to go round
    -- again.  For LLVM that is the latch's own terminator and nothing else.
    -- Here it may be one block further back: a phi becomes copies on the edges
    -- reaching it, an edge that cannot take them gets a block of its own, and
    -- a loop whose header carries a phi therefore ends in a block that holds
    -- copies and goes nowhere but back.  The branch that chose to come that
    -- way is the one that was written down, so the walk steps back through
    -- such a block and stops at anything else.
    deciding loop seen b
      | not (own loop (blockLabel b)) = False
      | progressing b = True
      | Set.member (blockLabel b) seen = False
      | Br _ <- terminatorTransfer (blockTerminator b)
      , all copied (blockInstructions b)
      , [above] <- predecessorsOf blocks (blockLabel b)
      , [chose] <- [c | c <- blocks, blockLabel c == above] =
          deciding loop (Set.insert (blockLabel b) seen) chose
      | otherwise = False

    -- A block this loop holds and no smaller loop does.  Every branch of a
    -- loop inside this one is a branch of this one too, and what an inner loop
    -- promises about itself says nothing about the loop around it — reading it
    -- as if it did would be reading a bounded inner loop as a promise that the
    -- outer one ends.
    own loop label =
      Set.member label (loopBody loop)
        && not
          ( any
              (\inner -> Set.isProperSubsetOf (loopBody inner) (loopBody loop) && Set.member label (loopBody inner))
              loops
          )

    copied i = case instructionOperation i of
      OAssign _ -> True
      _ -> False

    progressing b =
      attachmentSays
        metadata
        "llvm.loop"
        "llvm.loop.mustprogress"
        (terminatorMetadata (blockTerminator b))

    -- What the function's own pointers point into, which is what tells a write
    -- to its own frame from a write anything else can see.
    objects = objectsIn promises layout f

    -- A call is not answered here: what it does is what its callee does, and
    -- that is not settled yet.  They are collected in 'bodyCalls' instead.
    operation o = case o of
      OCall _ -> nothing
      -- A volatile access is a side effect whatever else it is: the program
      -- says the access itself is to be preserved and that what it reads may
      -- change under it, so it is both a read and a write of storage nothing
      -- here can account for.
      OLoad l
        | loadVolatile l -> reading `also` writing
        | otherwise -> touching (typedValue (loadPointer l)) reading
      OStore s
        | storeVolatile s -> reading `also` writing
        | otherwise -> touching (typedValue (storePointer s)) writing
      -- An atomic is where another thread's writes become visible here and
      -- this thread's become visible there, so it reads and writes memory
      -- everybody can see however narrow the address it names.  A fence names
      -- no address at all and is no exception: ordering is what makes somebody
      -- else's earlier write the answer to a later read.
      OAtomicLoad _ -> reading `also` writing
      OAtomicStore _ -> reading `also` writing
      OAtomicRmw _ -> reading `also` writing
      OCmpXchg _ -> reading `also` writing
      OFence _ -> reading `also` writing
      -- Fresh storage that nothing outside has ever had a name for.  What the
      -- body then does with it is the accesses above, which is where it is
      -- decided whether the address got out.
      OAlloca _ -> nothing
      -- Where an unwinder resumes the function.  It says the function catches
      -- something rather than that it does anything: what may throw is the
      -- invoke, and it is read as the call it holds.
      OLandingPad _ -> nothing
      OAssign _ -> nothing
      OBinary _ -> nothing
      OUnary _ -> nothing
      OICmp _ -> nothing
      OFCmp _ -> nothing
      OConvert _ -> nothing
      OSelect _ -> nothing
      OExtractElement _ -> nothing
      OInsertElement _ -> nothing
      OShuffleVector _ -> nothing
      OExtractValue _ -> nothing
      OInsertValue _ -> nothing
      OOffset _ -> nothing
      OField _ -> nothing

    -- The two transfers that are calls are collected with the rest of the
    -- calls and not answered here.  A resume carries on unwinding, which is
    -- the one way out of a function that is not a return and not a call.
    transfer t = case t of
      Invoke _ _ _ _ -> nothing
      CallBr _ _ _ _ -> nothing
      Resume _ -> nothing {mayUnwind = True}
      Ret _ -> nothing
      Br _ -> nothing
      CondBr _ _ _ -> nothing
      Switch _ _ _ -> nothing
      IndirectBr _ _ -> nothing
      -- Control never gets here, so nothing it stands for happens.
      Unreachable -> nothing

    -- A body's own access may be anywhere: proving that what it reaches through
    -- a parameter is only what the caller handed it is the analysis this does
    -- not have, and the promise a callee makes is read rather than worked out.
    reading = nothing {readsMemory = True, behaviourReach = Anywhere}
    writing = nothing {writesMemory = True, behaviourReach = Anywhere}

    -- An access to storage no caller can name is no effect of the call at all.
    touching address behaviour
      | reachableByCall objects address = behaviour
      | otherwise = nothing

-- | What a body does, given what its callees do.
--
-- Everything it does for itself, everything its calls do, and then the
-- question of whether it comes back at all.
doing :: Promises -> (Text -> Behaviour) -> Body -> Behaviour
doing promises callee body =
  spinning (foldl' also (bodyOwn body) (map made (bodyCalls body)))
  where
    made = made' promises callee

    -- A loop is the way of not coming back that a body wears on its face.
    -- Recursion is the other, and is settled by the caller of this.
    --
    -- __Unless progress is promised__, which says a loop that has no effect
    -- anybody can observe must end — that being what a language guaranteeing
    -- forward progress gives the compiler.  So a body that writes nothing and
    -- whose every loop is promised to end comes back from them.  Which loops
    -- are promised is 'bodyProgress', and the promise is written in either of
    -- two places depending on the language.  Asking whether the /loop/ writes
    -- rather than whether the body does would be sharper still and wants the
    -- write attributed to a block; asking it of the whole body is the cautious
    -- side of the same question.  @opt -passes=function-attrs@ was asked and
    -- draws the line in the same place: it gives a @mustprogress@ counting
    -- loop @willreturn@, and gives a @mustprogress@ loop that stores for ever
    -- @noreturn@ instead.
    --
    -- A volatile access is why the write is the thing asked about and reads
    -- are not: a loop that spins reading a volatile address makes progress
    -- every time round, and it is 'operation' that turns such a read into a
    -- write so that this question comes out the cautious way.
    spinning behaviour
      | not (bodyLoops body) = behaviour
      | bodyProgress body && not (writesMemory behaviour) = behaviour
      | otherwise = behaviour {mayNotReturn = True}

operationsIn :: Function -> [Operation (TypedValue Local)]
operationsIn f =
  [instructionOperation i | b <- functionBlocks f, i <- blockInstructions b]

transfersIn :: Function -> [Transfer (TypedValue Local)]
transfersIn f = [terminatorTransfer (blockTerminator b) | b <- functionBlocks f]

-- | What one call may do.
--
-- The call site's own attributes and the callee's, each able to rule something
-- out on its own.  Two things are answered before either is read: a call
-- carrying an operand bundle means whatever the bundle's tag means, which is
-- nothing anything here understands, and inline assembly is a body no
-- attribute of the module describes — its template is text this optimizer does
-- not read, so what it does is everything.
made' :: Promises -> (Text -> Behaviour) -> Call (TypedValue local) -> Behaviour
made' promises callee call
  | bundled call = anything
  | holdsAsm (typedValue (callCallee call)) = anything
  | otherwise = sharper atSite named
  where
    atSite = fromAttributes (resolve promises (callAttributes call))
    named = case typedValue (callCallee call) of
      VGlobal name -> callee (nameText name)
      -- Through a pointer, so the site's promises are all there is.
      _ -> anything

-- | What a call may do, once the whole program has been read.
behaviourOf :: Effects -> Call (TypedValue local) -> Behaviour
behaviourOf effects =
  made'
    (effectPromises effects)
    (\name -> Map.findWithDefault anything name (effectSymbols effects))

-- | What a list of attributes rules out.
--
-- Everything not ruled out stays: an attribute list is a set of promises and
-- says nothing about what it leaves out.
fromAttributes :: [FunctionAttribute] -> Behaviour
fromAttributes attributes =
  Behaviour
    { readsMemory = maybe True reads' locations
    , writesMemory = maybe True writes' locations
    , mayUnwind = FANoUnwind `notElem` attributes
    , mayNotReturn = FAWillReturn `notElem` attributes
    , behaviourReach = maybe Anywhere goes locations
    }
  where
    locations = case [text | FAMemory text <- attributes] of
      [] -> Nothing
      texts -> Just (foldr1 both (map accesses texts))
    both (r, w, x) (r', w', x') = (r || r', w || w', wider x x')
    reads' (r, _, _) = r
    writes' (_, w, _) = w
    goes (_, _, x) = x

-- | What a @memory(...)@ clause says, as \"may read\" and \"may write\".
--
-- The clause is a list of accesses, each either a location and what is done to
-- it (@argmem: read@) or an access for every location not otherwise named
-- (@read@, or the whole of @none@).  Which location a promise is about does not
-- matter here — see the module header — so this reads the accesses and forgets
-- the locations, and an unnamed location's access is @none@, which contributes
-- nothing.  That makes @memory(read, argmem: none)@ a read and no write, which
-- is what it says.
accesses :: Text -> (Bool, Bool, Reach)
accesses text = (any (`elem` ["read", "readwrite"]) said, any (`elem` ["write", "readwrite"]) said, goes)
  where
    items = map T.strip (T.splitOn "," text)
    said = map after items

    after item = case T.breakOn ":" item of
      (_, rest) | not (T.null rest) -> T.strip (T.drop 1 rest)
      (whole, _) -> whole

    location item = case T.breakOn ":" item of
      (name, rest) | not (T.null rest) -> T.strip name
      _ -> ""

    -- The locations something is actually done to.  A bare access is the one
    -- for every location not named, so it counts as a location of its own and
    -- one that is not on the short list below.
    touched = [location item | item <- items, after item `elem` ["read", "write", "readwrite"]]

    -- @errnomem@ is deliberately not here: errno is storage this module can
    -- address like any other, so a promise about it is no promise to a caller
    -- holding a pointer.
    goes
      | null touched = Unaddressable
      | not (all (`elem` ["argmem", "inaccessiblemem"]) touched) = Anywhere
      | "argmem" `elem` touched = OnlyArguments
      | otherwise = Unaddressable
