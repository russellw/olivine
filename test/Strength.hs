-- | Counters, and the work in a loop that is counted beside them.
--
-- What a counter is gets asked of the shapes a front end writes, which is a
-- slot promotion has turned into a local read through one copy and written
-- through another — so these run the passes above this one rather than writing
-- the core out by hand.  What is reduced is then asked in pairs: the same loop
-- with and without the one thing that makes the rewrite sound.
module Strength (strengthTests) where

import Data.List (sort)
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Induction (Counter (..), countersOf)
import Olivine.Core.Instruction
import Olivine.Core.Loops (Loop (..), loopsOf)
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.ControlFlow (simplifyControlFlow)
import Olivine.Core.Pass.DeadCode (eliminateDeadCode)
import Olivine.Core.Pass.LoopRotation (rotateLoops)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Pass.StrengthReduce (reduceStrength)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Convert (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

strengthTests :: TestTree
strengthTests =
  testGroup
    "strength reduction"
    [ testGroup
        "what a counter is"
        [ -- The counter reads itself through one of promotion's copies and is
          -- written through another, so neither end of its own increment names
          -- it.  Finding it at all is finding that out.
          testCase "a local the loop adds one to" $
            steps (walking "1") >>= (@?= [1])
        , testCase "and one it adds three to" $
            steps (walking "3") >>= (@?= [3])
        , testCase "and one it takes one from" $
            steps (walking "-1") >>= (@?= [-1])
        , -- Two of them, which is what a loop with an accumulator in it has:
          -- the accumulator is counted too when what it adds is a constant.
          testCase "two counters in one loop" $
            steps twoCounters >>= (@?= [1, 5])
        , -- What it adds is not a constant, so there is no one step.
          testCase "a local the loop adds a parameter to" $
            steps addingParameter >>= (@?= [])
        , -- Assigned in two places in the loop, so it is not a fixed amount
          -- larger a turn however each of them looks.
          testCase "a local the loop assigns twice" $
            steps assignedTwice >>= (@?= [])
        ]
    , testGroup
        "what is counted beside it"
        [ -- The point of the whole pass: the address is stepped along rather
          -- than computed, so the widening of the counter goes with the
          -- multiply the stride implied.  What is left of the widening is an
          -- instruction nothing reads, which is the next pass's to remove and
          -- is removed here so that what is asked is what the loop runs.
          testCase "an address computed from the counter" $ do
            shapes <- shapesAfter (walking "1")
            assertEqual "no widening left in the loop" 0 (count "convert" shapes)
            assertEqual "one step along the pointer" 1 (count "offset" shapes)
        , testCase "and it steps by the counter's own step" $
            stepIndices (walking "3") >>= (@?= [VInteger 3])
        , -- A multiply by a constant, which becomes an addition of the product.
          testCase "a multiply by a constant" $ do
            shapes <- shapesAfter multiplying
            assertEqual "the multiply is gone" 0 (count "mul" shapes)
        ]
    , testGroup
        "what is left alone"
        [ -- Without the promise, a widening of the count is not the widened
          -- count one step on, and the address may not be stepped along.  This
          -- is the same loop as the first case above with the flag taken off.
          testCase "a counter the loop does not promise about" $
            leftAlone (walkingFlagged "")
        , -- The base is computed in the loop, so the block above it cannot name
          -- what to start from.
          testCase "an address off a base the loop computes" $
            leftAlone basedInside
        , -- Two blocks, so there is no one place the step belongs.
          testCase "a loop of more than one block" $
            leftAlone twoBlocked
        ]
    ]

-- | The steps of the loop's counters, sorted: which order they are found in
-- is not something anything promises.
steps :: Text -> IO [Integer]
steps source = do
  program <- prepared source
  pure $ case functionsIn program of
    f : _ -> case loopsOf f of
      loop : _ -> sort (map counterStep (countersOf f loop))
      [] -> []
    [] -> []

-- | The program as this pass is handed it: one block, the test at the bottom.
prepared :: Text -> IO Program
prepared source =
  simplifyControlFlow . rotateLoops . promoteMemory . lower <$> expectParse "<inline>" source

-- | Reduced, and then swept — the widening the reduction leaves behind is read
-- by nothing, and taking it away is the dead code pass's job rather than this
-- one's.  Asking about the loop without sweeping would be asking about a state
-- the pipeline never leaves anything in.
reduced :: Text -> IO Program
reduced source = eliminateDeadCode . reduceStrength <$> prepared source

leftAlone :: Text -> Assertion
leftAlone source = do
  program <- prepared source
  assertBool "expected a function" (not (null (functionsIn program)))
  assertEqual "unchanged" program (reduceStrength program)

-- | What the loop block computes after the pass.
shapesAfter :: Text -> IO [String]
shapesAfter source = do
  program <- reduced source
  case functionsIn program of
    f : _ ->
      pure
        [ shape (instructionOperation i)
        | b <- functionBlocks f
        , blockLabel b `elem` [loopHeader loop | loop <- loopsOf f]
        , i <- blockInstructions b
        ]
    [] -> assertFailure "expected a function"

-- | The index every pointer step in the loop advances by.
stepIndices :: Text -> IO [Value Local]
stepIndices source = do
  program <- reduced source
  case functionsIn program of
    f : _ ->
      pure
        [ typedValue (offsetIndex o)
        | b <- functionBlocks f
        , blockLabel b `elem` [loopHeader loop | loop <- loopsOf f]
        , i <- blockInstructions b
        , OOffset o <- [instructionOperation i]
        ]
    [] -> assertFailure "expected a function"

count :: String -> [String] -> Int
count what = length . filter (== what)

shape :: Operation (TypedValue Local) -> String
shape operation = case operation of
  OAssign _ -> "copy"
  OBinary _ -> "binary"
  OConvert _ -> "convert"
  OOffset _ -> "offset"
  OICmp _ -> "icmp"
  OLoad _ -> "load"
  _ -> "other"

-- | A loop walking an array, the counter stepping by the given amount.  The
-- increment carries @nsw@, which is what a front end writes for a signed index
-- and what the widening of the counter is rewritten on the strength of.
walking :: Text -> Text
walking step = walkingFlagged' step "nsw "

-- | The same loop with whatever flags are given on the increment.
walkingFlagged :: Text -> Text
walkingFlagged flags = walkingFlagged' "1" (if T.null flags then "" else flags <> " ")

walkingFlagged' :: Text -> Text -> Text
walkingFlagged' step flags =
  T.unlines
    [ "define i32 @f(ptr %p, i32 %n) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  %s = alloca i32"
    , "  store i32 0, ptr %i"
    , "  store i32 0, ptr %s"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp slt i32 %i1, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %i2 = load i32, ptr %i"
    , "  %w = sext i32 %i2 to i64"
    , "  %a = getelementptr inbounds i32, ptr %p, i64 %w"
    , "  %v = load i32, ptr %a"
    , "  %s1 = load i32, ptr %s"
    , "  %sum = add i32 %s1, %v"
    , "  store i32 %sum, ptr %s"
    , "  %i3 = load i32, ptr %i"
    , "  %next = add " <> flags <> "i32 %i3, " <> step
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %s2 = load i32, ptr %s"
    , "  ret i32 %s2"
    , "}"
    ]

-- | A loop whose counter is multiplied by a constant.
multiplying :: Text
multiplying =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  %s = alloca i32"
    , "  store i32 0, ptr %i"
    , "  store i32 0, ptr %s"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp slt i32 %i1, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %i2 = load i32, ptr %i"
    , "  %m = mul i32 %i2, 7"
    , "  %s1 = load i32, ptr %s"
    , "  %sum = add i32 %s1, %m"
    , "  store i32 %sum, ptr %s"
    , "  %i3 = load i32, ptr %i"
    , "  %next = add nsw i32 %i3, 1"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %s2 = load i32, ptr %s"
    , "  ret i32 %s2"
    , "}"
    ]

-- | A loop with a second local that also grows by a constant each turn.
twoCounters :: Text
twoCounters =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  %s = alloca i32"
    , "  store i32 0, ptr %i"
    , "  store i32 0, ptr %s"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp slt i32 %i1, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %s1 = load i32, ptr %s"
    , "  %sum = add i32 %s1, 5"
    , "  store i32 %sum, ptr %s"
    , "  %i3 = load i32, ptr %i"
    , "  %next = add nsw i32 %i3, 1"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %s2 = load i32, ptr %s"
    , "  ret i32 %s2"
    , "}"
    ]

-- | A loop whose counter grows by something only the caller knows.
addingParameter :: Text
addingParameter =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %k) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  store i32 0, ptr %i"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp slt i32 %i1, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %i2 = load i32, ptr %i"
    , "  %next = add nsw i32 %i2, %k"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %i3 = load i32, ptr %i"
    , "  ret i32 %i3"
    , "}"
    ]

-- | A loop that writes its counter twice a turn.
assignedTwice :: Text
assignedTwice =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  store i32 0, ptr %i"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp slt i32 %i1, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %i2 = load i32, ptr %i"
    , "  %bumped = add nsw i32 %i2, 1"
    , "  store i32 %bumped, ptr %i"
    , "  %i3 = load i32, ptr %i"
    , "  %next = add nsw i32 %i3, 1"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %i4 = load i32, ptr %i"
    , "  ret i32 %i4"
    , "}"
    ]

-- | A loop stepping off a base it computes itself, which the block above it
-- cannot name.
basedInside :: Text
basedInside =
  T.unlines
    [ "define i32 @f(ptr %p, i32 %n) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  store i32 0, ptr %i"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp slt i32 %i1, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %base = load ptr, ptr %p"
    , "  %i2 = load i32, ptr %i"
    , "  %w = sext i32 %i2 to i64"
    , "  %a = getelementptr inbounds i32, ptr %base, i64 %w"
    , "  %v = load i32, ptr %a"
    , "  %i3 = load i32, ptr %i"
    , "  %next = add nsw i32 %i3, 1"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %i4 = load i32, ptr %i"
    , "  ret i32 %i4"
    , "}"
    ]

-- | A counted loop whose body keeps a block of its own.
twoBlocked :: Text
twoBlocked =
  T.unlines
    [ "define i32 @f(ptr %p, i32 %n) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  store i32 0, ptr %i"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp slt i32 %i1, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %i2 = load i32, ptr %i"
    , "  %w = sext i32 %i2 to i64"
    , "  %a = getelementptr inbounds i32, ptr %p, i64 %w"
    , "  %v = load i32, ptr %a"
    , "  %odd = icmp sgt i32 %v, 0"
    , "  br i1 %odd, label %work, label %skip"
    , "work:"
    , "  %doubled = mul i32 %v, 2"
    , "  br label %skip"
    , "skip:"
    , "  %i3 = load i32, ptr %i"
    , "  %next = add nsw i32 %i3, 1"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %i4 = load i32, ptr %i"
    , "  ret i32 %i4"
    , "}"
    ]
