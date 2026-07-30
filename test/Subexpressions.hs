-- | The common subexpression pass, redundant loads and all, and the aliasing
-- it stands on for those.
--
-- Two things are checked separately: which computations and loads are answered
-- from earlier ones, and which must not be.  The second is where the bugs are —
-- sharing a call, answering a load across something that wrote the address, or
-- reusing an expression whose operand was reassigned in between gives a module
-- LLVM accepts and a program that computes something else.
module Subexpressions (subexpressionTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Alias
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.CommonSubexpressions (eliminateCommonSubexpressions, shareable)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Program
import Olivine.Syntax.Instruction hiding (Operation (..))
import Olivine.Syntax.Name
import Olivine.Syntax.Type
import Olivine.Syntax.Value

subexpressionTests :: TestTree
subexpressionTests =
  testGroup
    "common subexpressions"
    [ testGroup
        "what is shared"
        [ -- Locals are numbered as they are defined: the two parameters, then
          -- %x %y %z as 2 to 4.
          testCase "the same sum twice in one block" $ do
            copies <- copiesIn twice
            assertEqual "the second reads the first" [(Local 3, Local 2)] copies
        , -- The point of walking the blocks rather than each block alone: the
          -- entry block is the only way to reach %again, so what it worked out
          -- is worked out wherever control is in there.
          testCase "across a branch, from the block above it" $ do
            copies <- copiesIn dominating
            assertEqual "the second reads the first" [(Local 4, Local 3)] copies
        , -- Two pointer steps written identically arrive here reading two
          -- different locals, because the lowering splits a getelementptr and
          -- what LLVM wrote once becomes a chain.  Resolving the operands
          -- through the copies is what makes them one expression again.
          testCase "a pointer step whose operands are copies" $ do
            copies <- copiesIn stepped
            assertBool
              ("expected a shared step in " <> show copies)
              (not (null copies))
        , -- Both computations in the body are the one the block before the
          -- loop already made, so neither is left to make.  The locals here
          -- are the three parameters, then %e %i %c %x %y %j as 3 to 8.
          testCase "twice in a loop body" $ do
            copies <- copiesIn looping
            assertEqual
              "both read what the block before the loop worked out"
              [(Local 6, Local 3), (Local 7, Local 3)]
              copies
        ]
    , testGroup
        "what iterating buys"
        [ -- The whole of what the rounds are for.  The block the loop begins
          -- at has a predecessor below it, so one walk over the blocks has
          -- nothing to say about what arrives along that edge and can only
          -- assume the worst; the rounds start by assuming the best instead
          -- and take away what some path does not carry, and no path into the
          -- loop fails to carry this.
          testCase "an expression carried into a loop is available" $ do
            copies <- copiesIn carried
            assertEqual "%x reads what came in" [(Local 6, Local 3)] copies
        , -- Two edges deep, which takes a round to reach the outer loop and
          -- another to reach the inner one.  The locals are the three
          -- parameters, then %e %i %c %j %x %m %d %k as 3 to 10.
          testCase "carried into a loop inside a loop" $ do
            copies <- copiesIn nested
            assertEqual "%x reads what came in" [(Local 7, Local 3)] copies
        ]
    , testGroup
        "what is not"
        [ -- @add nsw@ is poison where it overflows and @add@ is a number, so
          -- the two are not one expression.  Sharing the plain result for the
          -- flagged instruction would be sound and is not done; sharing the
          -- flagged result for the plain one would spread poison.
          testCase "the same sum with different flags" $ do
            copies <- copiesIn flagged
            assertEqual "nothing is shared" [] copies
        , -- The reason availability is a question at all.  Promotion turns
          -- the slot into a local assigned twice, and the second addition
          -- reads what the second assignment left there.
          testCase "an operand reassigned in between" $ do
            copies <- promotedCopiesIn reassigned
            assertEqual "nothing is shared" [] copies
        , -- The other half of the same rule: %a was a copy of the slot, and
          -- the store means it is no longer, so the additions that read %a and
          -- the slot are not the same expression however alike they look.
          testCase "an operand that has stopped being a copy" $ do
            copies <- promotedCopiesIn stale
            assertEqual "nothing is shared" [] copies
        , -- Available means computed on every path that arrives, and one arm
          -- of a branch is not every path.
          testCase "computed on only one path to here" $ do
            copies <- copiesIn oneArm
            assertEqual "nothing is shared" [] copies
        , -- Both arms compute it, but into different locals, so there is no
          -- one local a block below can read it from.  The core could hold
          -- the answer — two arms assigning to one local is exactly what
          -- reconstruction turns into a phi — which makes this a refinement
          -- this pass does not make rather than something it cannot say.
          testCase "computed on both paths into different locals" $ do
            copies <- copiesIn bothArms
            assertEqual "nothing is shared" [] copies
        , testCase "two calls to the same function" $ do
            copies <- copiesIn calling
            assertEqual "nothing is shared" [] copies
        , testCase "two allocations of the same size" $ do
            copies <- copiesIn allocating
            assertEqual "nothing is shared" [] copies
        ]
    , testGroup
        "what memory answers"
        [ -- Locals are numbered as they are defined: the parameter, then %a %b
          -- %s as 1 to 3.
          testCase "a second load of one address" $ do
            answered <- assignmentsIn twiceLoaded
            assertEqual
              "the second load reads what the first left"
              [(Local 2, VLocal (Local 1))]
              answered
        , -- The other half of the same fact.  What memory holds does not
          -- remember whether a load or a store put it there, so a store answers
          -- a load below it for the same reason one load answers another.
          testCase "a load of what was just stored" $ do
            answered <- assignmentsIn storedThenLoaded
            assertEqual
              "the load reads the stored value"
              [(Local 2, VLocal (Local 1))]
              answered
        , -- And it need not be a local: a store of a constant leaves the
          -- constant there.
          testCase "a load of a constant that was stored" $ do
            answered <- assignmentsIn loading
            assertEqual
              "the second load is the stored constant"
              [(Local 2, VInteger 99)]
              answered
        , -- Two allocations are two objects, so a write to one is not a write to
          -- the other however alike the accesses look.  The locals are the
          -- parameter, then %x %y %a %b %s as 1 to 5.
          testCase "across a store to a different allocation" $ do
            answered <- assignmentsIn otherSlot
            assertEqual
              "the second load reads the first"
              [(Local 4, VLocal (Local 3))]
              answered
        , -- The precision the whole thing turns on.  A callee reaches what it
          -- was handed and what has a symbol, and this slot is neither, so a
          -- call in between writes nothing that can be read here.  The locals
          -- are %x %a %b %s as 0 to 3.
          testCase "across a call, of a slot whose address never left" $ do
            answered <- assignmentsIn pastACall
            assertEqual
              "the second load reads the first"
              [(Local 2, VLocal (Local 1))]
              answered
        , -- A symbol names its storage as plainly as an allocation does, so a
          -- load through one is answered the same way.  The locals here are
          -- %a %b %s as 0 to 2, there being no parameters.
          testCase "a second load of a symbol" $ do
            answered <- assignmentsIn symbolTwice
            assertEqual
              "the second load reads the first"
              [(Local 1, VLocal (Local 0))]
              answered
        , -- What iterating buys for memory, as 'carried' is what it buys for
          -- arithmetic.  The block the loop begins at is reached from below as
          -- well as above, and nothing round the loop writes memory.  The
          -- locals are the two parameters, then %a %i %t %c %b %u %j as 2 to 8.
          testCase "a load carried into a loop" $ do
            answered <- assignmentsIn carriedLoad
            assertEqual
              "the body reads what the block above the loop read"
              [(Local 6, VLocal (Local 2))]
              answered
        , -- Both arms wrote the address, and both wrote the same thing, which is
          -- what makes it something a block below them can be told.  The locals
          -- are the three parameters, then %a as 3.
          testCase "stored to the same value on both paths here" $ do
            answered <- assignmentsIn storedAlike
            assertEqual
              "the load reads what both arms wrote"
              [(Local 3, VLocal (Local 2))]
              answered
        ]
    , testGroup
        "what memory does not"
        [ -- The address was handed to the callee, so the callee could write it.
          testCase "across a call that was given the address" $ do
            answered <- assignmentsIn escapedSlot
            assertEqual "nothing is answered" [] answered
        , -- Two pointers this cannot tell apart, so the store between the loads
          -- has to be taken for a store to the one being read.
          testCase "across a store through another pointer" $ do
            answered <- assignmentsIn throughAnother
            assertEqual "nothing is answered" [] answered
        , -- Two symbols, and nothing here tells them apart: an alias is a second
          -- name for storage that already had one.  Reading the module to find
          -- which names are aliases of what is what this case is waiting for,
          -- and until then it is a load answered less often than it could be.
          testCase "across a store to another symbol" $ do
            answered <- assignmentsIn symbolAndAnother
            assertEqual "nothing is answered" [] answered
        , -- Eight bytes were written and four are being read.  The load is of
          -- part of what the store wrote, and a part is not something the store
          -- said anything about.
          testCase "a load narrower than the store above it" $ do
            answered <- assignmentsIn otherWidth
            assertEqual "nothing is answered" [] answered
        , -- The point of a volatile access is that it happens, so neither is
          -- replaced by a copy of the other.
          testCase "a second volatile load" $ do
            answered <- assignmentsIn volatileTwice
            assertEqual "nothing is answered" [] answered
        , -- And what one leaves behind is not a fact to keep: reading a volatile
          -- address is not the same as remembering what it read.
          testCase "a plain load below a volatile one" $ do
            answered <- assignmentsIn volatileThenPlain
            assertEqual "nothing is answered" [] answered
        , -- Both arms wrote the address and they wrote different things, so
          -- there is nothing the block below them can be told it holds.
          testCase "stored to different values on the two paths here" $ do
            answered <- assignmentsIn storedEitherWay
            assertEqual "nothing is answered" [] answered
        , -- Storage allocated in a loop is a new object each time round, holding
          -- whatever it holds, so what the last iteration left at that address
          -- is not what this one finds there.  Two things say so — the
          -- allocation assigns to the local naming the address, and no path from
          -- above the loop carries a fact about a local only the loop assigns —
          -- and this asks for the answer rather than for either of them.
          testCase "a slot allocated again each time round the loop" $ do
            answered <- assignmentsIn reallocated
            assertEqual "nothing is answered" [] answered
        ]
    , testGroup
        "which pointers may be one"
        [ testCase "an allocation is the storage it made" $ do
            (objects, [x, _]) <- aliasingIn twoSlots
            assertEqual "named by its own local" (Just (OnStack x)) (objectOf objects (VLocal x))
        , testCase "two allocations are two objects" $ do
            (objects, [x, y]) <- aliasingIn twoSlots
            assertEqual "which cannot overlap" False (mayAlias objects (VLocal x) (VLocal y))
        , testCase "an allocation and a symbol" $ do
            (objects, [x, _]) <- aliasingIn twoSlots
            assertEqual
              "no symbol names stack storage"
              False
              (mayAlias objects (VLocal x) (VGlobal (Name Bare "g")))
        , -- Two names, possibly one object: an alias is a second name for
          -- storage that already had one, and two declarations can be one
          -- symbol once the linker has been over them.
          testCase "two symbols are not told apart" $ do
            (objects, _) <- aliasingIn twoSlots
            assertEqual
              "which is the cautious answer"
              True
              (mayAlias objects (VGlobal (Name Bare "g")) (VGlobal (Name Bare "h")))
        , -- A pointer that says nothing about where it points may point
          -- anywhere a pointer got to, and this slot's address never got
          -- anywhere.
          testCase "a slot whose address stayed put, and a stranger" $ do
            (objects, [x]) <- aliasingIn confinedSlot
            assertEqual
              "cannot be the same storage"
              False
              (mayAlias objects (VLocal x) (VLocal (Local 0)))
        , testCase "and no call can reach it either" $ do
            (objects, [x]) <- aliasingIn confinedSlot
            assertEqual "having no way to name it" False (reachableByCall objects (VLocal x))
        , -- One step is all it takes: the address was written somewhere a
          -- callee could read it back.
          testCase "a slot whose address was stored somewhere" $ do
            (objects, [x]) <- aliasingIn handedOver
            assertEqual
              "may be any pointer at all"
              True
              (mayAlias objects (VLocal x) (VLocal (Local 0)))
        , testCase "and a call may reach it" $ do
            (objects, [x]) <- aliasingIn handedOver
            assertEqual "the address being out there" True (reachableByCall objects (VLocal x))
        ]
    , testGroup
        "what may be shared at all"
        [ testCase "arithmetic" $ shareable (binary OpAdd) @?= True
        , testCase "a comparison" $ shareable comparison @?= True
        , testCase "a conversion" $ shareable conversion @?= True
        , testCase "a pointer step" $ shareable step @?= True
        , testCase "a field selection" $ shareable field @?= True
        , -- Dividing by zero is poison rather than a fault, so a division is
          -- as shareable as an addition: two of them with the same operands
          -- are poison together or a number together.
          testCase "division" $ shareable (binary OpSDiv) @?= True
        , -- Fresh storage each time, so two allocations are two objects.
          testCase "an allocation" $ shareable allocation @?= False
        , testCase "a load" $ shareable load' @?= False
        , testCase "a store" $ shareable store' @?= False
        , -- Nothing here can tell whether a call answers the same thing
          -- twice, or what it does on the way to answering.
          testCase "a call" $ shareable call' @?= False
        , -- Already the value it holds; there is no computation to repeat.
          testCase "an assignment" $ shareable assignment @?= False
        ]
    ]

-- | The instructions the pass turned into a copy of an earlier local, as the
-- local assigned and the local read.
--
-- An assignment of anything but a local is not one of these: the lowering
-- writes those itself, for a phi and for a pointer step that moves nowhere,
-- and they are not what this pass leaves behind.
copiesIn :: Text -> IO [(Local, Local)]
copiesIn source = locals <$> assignmentsAfter id source
  where
    locals xs = [(name, read') | (name, VLocal read') <- xs]

-- | The same, of a function promotion has already been over.
--
-- Promotion is what puts a local assigned more than once in front of this
-- pass, which no LLVM function can be written to produce directly: single
-- assignment is what the input is in.  The pipeline runs them in this order
-- for its own reasons, and these cases are why the order is not the only
-- thing keeping the answer right.
promotedCopiesIn :: Text -> IO [(Local, Local)]
promotedCopiesIn source = locals <$> assignmentsAfter promoteMemory source
  where
    locals xs = [(name, read') | (name, VLocal read') <- xs]

-- | Everything the pass turned into an assignment, as the local assigned and
-- the value it now holds.
--
-- Wider than 'copiesIn' because a load can be answered by something that is not
-- a local: a store of a constant leaves the constant at the address, and a load
-- reading it becomes an assignment with no local in it at all.
assignmentsIn :: Text -> IO [(Local, Value Local)]
assignmentsIn = assignmentsAfter id

assignmentsAfter :: (Program -> Program) -> Text -> IO [(Local, Value Local)]
assignmentsAfter before source = do
  parsed <- expectParse "<inline>" source
  let shared = eliminateCommonSubexpressions (before (lower parsed))
      original = before (lower parsed)
      assignments program =
        [ (name, value)
        | f <- functionsIn program
        , b <- functionBlocks f
        , Instruction (Just name) (OAssign (TypedValue _ value)) _ <-
            blockInstructions b
        ]
  -- What the pass added, rather than every assignment in the result: lowering
  -- and promotion write their own, and those are not this pass's doing.
  pure [a | a <- assignments shared, a `notElem` assignments original]

-- | The first function of a module, lowered, for the questions that are asked
-- of the analysis rather than of the rewrite.
functionOf :: Text -> IO Function
functionOf source = do
  parsed <- expectParse "<inline>" source
  case functionsIn (lower parsed) of
    f : _ -> pure f
    [] -> assertFailure "no function lowered"

-- | What a function says about its pointers, and the locals its allocations
-- assign to, in the order written.
--
-- The slots are looked for rather than counted to, because an @alloca@ is not
-- the only instruction the lowering issues a local for and counting would
-- break on the next test that added one.
aliasingIn :: Text -> IO (Objects, [Local])
aliasingIn source = do
  f <- functionOf source
  pure
    ( objectsIn f
    , [ slot
      | b <- functionBlocks f
      , Instruction (Just slot) (OAlloca _) _ <- blockInstructions b
      ]
    )

twice :: Text
twice =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b) {"
    , "entry:"
    , "  %x = add i32 %a, %b"
    , "  %y = add i32 %a, %b"
    , "  %z = add i32 %x, %y"
    , "  ret i32 %z"
    , "}"
    ]

flagged :: Text
flagged =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b) {"
    , "entry:"
    , "  %x = add nsw i32 %a, %b"
    , "  %y = add i32 %a, %b"
    , "  %z = add i32 %x, %y"
    , "  ret i32 %z"
    , "}"
    ]

dominating :: Text
dominating =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
    , "entry:"
    , "  %x = mul i32 %a, %b"
    , "  br i1 %c, label %again, label %done"
    , "again:"
    , "  %y = mul i32 %a, %b"
    , "  %z = add i32 %x, %y"
    , "  ret i32 %z"
    , "done:"
    , "  ret i32 %x"
    , "}"
    ]

oneArm :: Text
oneArm =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %join"
    , "yes:"
    , "  %x = mul i32 %a, %b"
    , "  br label %join"
    , "join:"
    , "  %y = mul i32 %a, %b"
    , "  ret i32 %y"
    , "}"
    ]

bothArms :: Text
bothArms =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  %x = mul i32 %a, %b"
    , "  br label %join"
    , "no:"
    , "  %y = mul i32 %a, %b"
    , "  br label %join"
    , "join:"
    , "  %z = mul i32 %a, %b"
    , "  ret i32 %z"
    , "}"
    ]

-- | A subscript written twice, which is what the corpus contains: clang emits
-- the same @getelementptr@ for the same expression rather than reusing one.
stepped :: Text
stepped =
  T.unlines
    [ "define i32 @f(ptr %p, i64 %i) {"
    , "entry:"
    , "  %q = getelementptr inbounds [8 x i32], ptr %p, i64 %i, i64 3"
    , "  %a = load i32, ptr %q, align 4"
    , "  %r = getelementptr inbounds [8 x i32], ptr %p, i64 %i, i64 3"
    , "  store i32 %a, ptr %r, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | A loop whose body computes one thing twice, and one thing the block
-- before the loop already computed.
looping :: Text
looping =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i32 %n) {"
    , "entry:"
    , "  %e = mul i32 %a, %b"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %j, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %x = mul i32 %a, %b"
    , "  %y = mul i32 %a, %b"
    , "  %j = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %e"
    , "}"
    ]

-- | A loop whose body recomputes what the block before it worked out, and
-- nothing else.
carried :: Text
carried =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i32 %n) {"
    , "entry:"
    , "  %e = mul i32 %a, %b"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %j, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %x = mul i32 %a, %b"
    , "  %j = add i32 %i, %x"
    , "  br label %head"
    , "done:"
    , "  ret i32 %e"
    , "}"
    ]

-- | The same, one loop further in.
nested :: Text
nested =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i32 %n) {"
    , "entry:"
    , "  %e = mul i32 %a, %b"
    , "  br label %outer"
    , "outer:"
    , "  %i = phi i32 [ 0, %entry ], [ %k, %latch ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %inner, label %done"
    , "inner:"
    , "  %j = phi i32 [ 0, %outer ], [ %m, %inner ]"
    , "  %x = mul i32 %a, %b"
    , "  %m = add i32 %j, %x"
    , "  %d = icmp slt i32 %m, %n"
    , "  br i1 %d, label %inner, label %latch"
    , "latch:"
    , "  %k = add i32 %i, 1"
    , "  br label %outer"
    , "done:"
    , "  ret i32 %e"
    , "}"
    ]

reassigned :: Text
reassigned =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %n, ptr %s, align 4"
    , "  %v = load i32, ptr %s, align 4"
    , "  %x = add i32 %v, 1"
    , "  store i32 7, ptr %s, align 4"
    , "  %w = load i32, ptr %s, align 4"
    , "  %y = add i32 %w, 1"
    , "  %t = add i32 %x, %y"
    , "  ret i32 %t"
    , "}"
    ]

stale :: Text
stale =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %n, ptr %s, align 4"
    , "  %a = load i32, ptr %s, align 4"
    , "  store i32 7, ptr %s, align 4"
    , "  %b = load i32, ptr %s, align 4"
    , "  %x = add i32 %a, 1"
    , "  %y = add i32 %b, 1"
    , "  %t = mul i32 %x, %y"
    , "  ret i32 %t"
    , "}"
    ]

calling :: Text
calling =
  T.unlines
    [ "declare i32 @tick(i32)"
    , "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %a = call i32 @tick(i32 %n)"
    , "  %b = call i32 @tick(i32 %n)"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- | A load either side of a store to the same address.  The first load's answer
-- is gone and the store's is there instead.
loading :: Text
loading =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %a = load i32, ptr %p, align 4"
    , "  store i32 99, ptr %p, align 4"
    , "  %b = load i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

twiceLoaded :: Text
twiceLoaded =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %a = load i32, ptr %p, align 4"
    , "  %b = load i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

storedThenLoaded :: Text
storedThenLoaded =
  T.unlines
    [ "define i32 @f(ptr %p, i32 %n) {"
    , "entry:"
    , "  store i32 %n, ptr %p, align 4"
    , "  %a = load i32, ptr %p, align 4"
    , "  ret i32 %a"
    , "}"
    ]

otherSlot :: Text
otherSlot =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %y = alloca i32, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  store i32 %n, ptr %y, align 4"
    , "  %b = load i32, ptr %x, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

pastACall :: Text
pastACall =
  T.unlines
    [ "declare void @sink()"
    , "define i32 @f() {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  call void @sink()"
    , "  %b = load i32, ptr %x, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

escapedSlot :: Text
escapedSlot =
  T.unlines
    [ "declare void @sink(ptr)"
    , "define i32 @f() {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  call void @sink(ptr %x)"
    , "  %b = load i32, ptr %x, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

throughAnother :: Text
throughAnother =
  T.unlines
    [ "define i32 @f(ptr %p, ptr %q, i32 %n) {"
    , "entry:"
    , "  %a = load i32, ptr %p, align 4"
    , "  store i32 %n, ptr %q, align 4"
    , "  %b = load i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

otherWidth :: Text
otherWidth =
  T.unlines
    [ "define i32 @f(ptr %p, i64 %n) {"
    , "entry:"
    , "  store i64 %n, ptr %p, align 8"
    , "  %a = load i32, ptr %p, align 4"
    , "  ret i32 %a"
    , "}"
    ]

volatileTwice :: Text
volatileTwice =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %a = load volatile i32, ptr %p, align 4"
    , "  %b = load volatile i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

volatileThenPlain :: Text
volatileThenPlain =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %a = load volatile i32, ptr %p, align 4"
    , "  %b = load i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- | A loop whose body reads what the block above the loop read, and writes no
-- memory at all.
carriedLoad :: Text
carriedLoad =
  T.unlines
    [ "define i32 @f(ptr %p, i32 %n) {"
    , "entry:"
    , "  %a = load i32, ptr %p, align 4"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %j, %body ]"
    , "  %t = phi i32 [ %a, %entry ], [ %u, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %b = load i32, ptr %p, align 4"
    , "  %u = add i32 %t, %b"
    , "  %j = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %t"
    , "}"
    ]

-- | Storage allocated inside the loop, read before it is written.
reallocated :: Text
reallocated =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %k = phi i32 [ 0, %entry ], [ %k1, %body ]"
    , "  %t = phi i32 [ 0, %entry ], [ %t1, %body ]"
    , "  %c = icmp slt i32 %k, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %x = alloca i32, align 4"
    , "  %v = load i32, ptr %x, align 4"
    , "  store i32 %k, ptr %x, align 4"
    , "  %t1 = add i32 %t, %v"
    , "  %k1 = add i32 %k, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %t"
    , "}"
    ]

storedAlike :: Text
storedAlike =
  T.unlines
    [ "define i32 @f(ptr %p, i1 %c, i32 %n) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  store i32 %n, ptr %p, align 4"
    , "  br label %join"
    , "no:"
    , "  store i32 %n, ptr %p, align 4"
    , "  br label %join"
    , "join:"
    , "  %a = load i32, ptr %p, align 4"
    , "  ret i32 %a"
    , "}"
    ]

storedEitherWay :: Text
storedEitherWay =
  T.unlines
    [ "define i32 @f(ptr %p, i1 %c, i32 %n) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  store i32 1, ptr %p, align 4"
    , "  br label %join"
    , "no:"
    , "  store i32 %n, ptr %p, align 4"
    , "  br label %join"
    , "join:"
    , "  %a = load i32, ptr %p, align 4"
    , "  ret i32 %a"
    , "}"
    ]

symbolTwice :: Text
symbolTwice =
  T.unlines
    [ "@count = internal global i32 0"
    , "define i32 @f() {"
    , "entry:"
    , "  %a = load i32, ptr @count, align 4"
    , "  %b = load i32, ptr @count, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

symbolAndAnother :: Text
symbolAndAnother =
  T.unlines
    [ "@count = internal global i32 0"
    , "@other = internal global i32 7"
    , "define i32 @f() {"
    , "entry:"
    , "  %a = load i32, ptr @count, align 4"
    , "  store i32 3, ptr @other, align 4"
    , "  %b = load i32, ptr @count, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- Functions the aliasing is asked about rather than run over.

twoSlots :: Text
twoSlots =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %y = alloca i32, align 4"
    , "  store i32 %n, ptr %x, align 4"
    , "  store i32 %n, ptr %y, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | A slot read and written and nothing else, beside a pointer that arrived
-- from somewhere this function cannot see.
confinedSlot :: Text
confinedSlot =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  store i32 1, ptr %x, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  %b = load i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- | The same slot, with its address written where anything could read it back.
handedOver :: Text
handedOver =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  store ptr %x, ptr %p, align 8"
    , "  %a = load i32, ptr %x, align 4"
    , "  ret i32 %a"
    , "}"
    ]

allocating :: Text
allocating =
  T.unlines
    [ "declare void @keep(ptr, ptr)"
    , "define void @f() {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %y = alloca i32, align 4"
    , "  call void @keep(ptr %x, ptr %y)"
    , "  ret void"
    , "}"
    ]

-- Operations at the core's own operand type, for 'shareable', which reads
-- nothing but which operation it is.

binary :: BinaryOp -> Operation (TypedValue Local)
binary op = OBinary (Binary op [] (word 1) (word 2))

comparison :: Operation (TypedValue Local)
comparison = OICmp (Compare [] IEq (word 1) (word 2))

conversion :: Operation (TypedValue Local)
conversion = OConvert (Convert CastZExt [] (word 1) (TInteger 64))

step :: Operation (TypedValue Local)
step = OOffset (Offset [] (TInteger 32) pointer (word 1))

field :: Operation (TypedValue Local)
field = OField (Field [] (TStruct Unpacked [TInteger 32]) pointer 0)

allocation :: Operation (TypedValue Local)
allocation = OAlloca (Alloca False (TInteger 32) Nothing Nothing Nothing)

load' :: Operation (TypedValue Local)
load' = OLoad (Load False (TInteger 32) pointer Nothing)

store' :: Operation (TypedValue Local)
store' = OStore (Store False (word 1) pointer Nothing)

call' :: Operation (TypedValue Local)
call' =
  OCall
    ( Call
        Nothing
        []
        Nothing
        []
        Nothing
        (TInteger 32)
        (TypedValue (TPointer Nothing) (VGlobal (Name Bare "tick")))
        []
        []
    )

assignment :: Operation (TypedValue Local)
assignment = OAssign (word 1)

word :: Integer -> TypedValue Local
word n = TypedValue (TInteger 32) (VInteger n)

pointer :: TypedValue Local
pointer = TypedValue (TPointer Nothing) (VLocal (Local 0))
