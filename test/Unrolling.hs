-- | Counting a loop's turns, and writing them out.
--
-- The count is what the loop's own arithmetic says, so these ask it of loops
-- whose arithmetic says different things: a counter that steps by one, by more
-- than one, downwards, and one that says nothing at all.  What is written out
-- is then asked of the shapes the pass is for and refused of the shapes it is
-- not.
module Unrolling (unrollingTests) where

import Data.Char (toLower)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Induction (Turn (..), turnsOf)
import Olivine.Core.Instruction
import Olivine.Core.Loops (loopsOf)
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.ControlFlow (simplifyControlFlow)
import Olivine.Core.Pass.LoopRotation (rotateLoops)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Pass.Unroll (turnLimit, unrollLoops)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Binary (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

unrollingTests :: TestTree
unrollingTests =
  testGroup
    "unrolling"
    [ testGroup
        "how many turns"
        [ testCase "a counter that steps by one" $
            turns (counting "0" "1" "4") >>= (@?= Just [0, 1, 2, 3])
        , -- Nothing here knows what a closed form would be for this; it is
          -- counted the same way the last one was, by running it.
          testCase "a counter that steps by three" $
            turns (counting "0" "3" "10") >>= (@?= Just [0, 3, 6, 9])
        , -- Counting down to nothing, which is the same interpreter reading
          -- the other comparison.
          testCase "a counter that steps downwards" $
            turns countingDown >>= (@?= Just [4, 3, 2, 1])
        , -- And a loop that never leaves is one the interpreter runs out of
          -- turns on rather than one it concludes anything about: counting away
          -- from a bound it is already inside is the plainest way to write one.
          testCase "a counter that steps away from its bound" $
            turns (counting "0" "-1" "4") >>= (@?= Nothing)
        , -- A start the block above the loop does not settle is a loop this
          -- says nothing about, however plain the arithmetic in it.
          testCase "a counter whose start is a parameter" $
            turns fromParameter >>= (@?= Nothing)
        , -- More turns than the caller asked to look at is no answer.  The
          -- interpreter cannot skip ahead: running the loop is the whole of how
          -- it knows.
          testCase "a loop of more turns than the limit" $
            turns (counting "0" "1" "1000") >>= (@?= Nothing)
        , -- A test that reads memory is a test the interpreter cannot settle,
          -- and it stops there rather than guessing.
          testCase "a loop that tests what it loaded" $
            turns loadTested >>= (@?= Nothing)
        ]
    , testGroup
        "what is written out"
        [ -- Two additions a turn, four turns, and no edge back: the whole loop
          -- is in a row.  Each copy still holds a copy of the test the loop
          -- closed on, which now decides nothing and which the dead code pass
          -- is what takes away.
          testCase "the loop is gone and its turns are in a row" $ do
            shapes <- shapesAfter (counting "0" "1" "4")
            assertEqual "two additions a turn, four turns" 8 (length (filter (== "add") (concat shapes)))
        , testCase "and nothing branches back to it" $ do
            edges <- edgesAfter (counting "0" "1" "4")
            assertBool
              ("expected no block branching to itself, got " <> show edges)
              (not (or [label `elem` targets | (label, targets) <- edges]))
        , -- The whole reason the copies are worth making: each one opens by
          -- saying what the counter holds, so the arithmetic in it is
          -- arithmetic on a constant.  The turn's other locals are written down
          -- too and the accumulator is one of them, so what is asked is that
          -- every one of the counter's values is there, not that nothing else
          -- is.
          testCase "each copy says what the counter holds" $ do
            program <- unrolled (counting "0" "1" "4")
            let written = countersIn program
            assertBool
              ("expected every turn's counter written down, got " <> show written)
              (all (`elem` written) [VInteger 0, VInteger 1, VInteger 2, VInteger 3])
        ]
    , testGroup
        "what is left alone"
        [ -- The bound is a parameter, so there is no count and nothing to write.
          testCase "a loop counted to a parameter" $ leftAlone open
        , -- Two blocks in the loop: the turns cannot be put in a row without
          -- copying the paths through them, which is a different pass.
          testCase "a loop of more than one block" $ leftAlone twoBlocked
        , -- A body big enough that writing every turn out costs more than the
          -- branch it saves.
          testCase "a loop whose turns come to more than the budget" $ leftAlone fat
        ]
    ]

-- | What the loop's counter holds on each turn, where the loop has one counter
-- and the loop is counted at all.
--
-- The counter is read as the smallest local the turns say anything about,
-- which in these loops is the one the phi elimination named first; a turn
-- mentions the accumulator too, and which of the two is which is not what these
-- are asking about.
turns :: Text -> IO (Maybe [Integer])
turns source = do
  program <- prepared source
  pure $ case functionsIn program of
    f : _ -> case loopsOf f of
      loop : _ -> map counter <$> turnsOf turnLimit f loop
      [] -> Nothing
    [] -> Nothing
  where
    counter (Turn known) =
      head ([n | (_, VInteger n) <- Map.toAscList known] <> [0])

-- | The program as this pass is handed it.
--
-- A loop is one block by the time unrolling runs and not before: a front end
-- writes the counter in memory, promotion makes it a local, rotation puts the
-- test at the bottom and merging makes the body and the test one block.  So
-- these run the passes above this one rather than writing the shape out by
-- hand — which cannot be done anyway, since a one block loop written in LLVM
-- wants a phi and the edge a phi becomes is a block of its own.
prepared :: Text -> IO Program
prepared source =
  simplifyControlFlow . rotateLoops . promoteMemory . lower <$> expectParse "<inline>" source

unrolled :: Text -> IO Program
unrolled source = unrollLoops <$> prepared source

leftAlone :: Text -> Assertion
leftAlone source = do
  program <- prepared source
  assertBool "expected a function" (not (null (functionsIn program)))
  assertEqual "unchanged" program (unrollLoops program)

-- | Every block after the pass with where it branches, in the order written.
edgesAfter :: Text -> IO [(Label, [Label])]
edgesAfter source = do
  program <- unrolled source
  case functionsIn program of
    f : _ -> pure [(blockLabel b, targetsOf (blockTerminator b)) | b <- functionBlocks f]
    [] -> assertFailure "expected a function"

shapesAfter :: Text -> IO [[String]]
shapesAfter source = do
  program <- unrolled source
  case functionsIn program of
    f : _ -> pure (map (map (shape . instructionOperation) . blockInstructions) (functionBlocks f))
    [] -> assertFailure "expected a function"

-- | Every constant a copy opens with, in the order the copies stand.
countersIn :: Program -> [Value Local]
countersIn program =
  [ value
  | f <- functionsIn program
  , b <- functionBlocks f
  , Instruction _ (OAssign (TypedValue _ value)) _ <- blockInstructions b
  , isNumber value
  ]
  where
    isNumber (VInteger _) = True
    isNumber _ = False

shape :: Operation (TypedValue Local) -> String
shape operation = case operation of
  OAssign _ -> "copy"
  OBinary b -> map toLower (drop 2 (show (binaryOp b)))
  OICmp _ -> "icmp"
  OLoad _ -> "load"
  OStore _ -> "store"
  _ -> "other"

-- | A loop counted down to nothing rather than up to a bound.
countingDown :: Text
countingDown =
  T.unlines
    [ "define i32 @f(i32 %x) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  store i32 4, ptr %i"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp sgt i32 %i1, 0"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %i2 = load i32, ptr %i"
    , "  %next = add i32 %i2, -1"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %i3 = load i32, ptr %i"
    , "  ret i32 %i3"
    , "}"
    ]

-- | A loop counted from a start, by a step, while below a bound, written the
-- way a front end writes one: the counter in memory.
counting :: Text -> Text -> Text -> Text
counting start step bound =
  T.unlines
    [ "define i32 @f(i32 %x) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  %s = alloca i32"
    , "  store i32 " <> start <> ", ptr %i"
    , "  store i32 0, ptr %s"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp slt i32 %i1, " <> bound
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %i2 = load i32, ptr %i"
    , "  %s1 = load i32, ptr %s"
    , "  %sum = add i32 %s1, %i2"
    , "  store i32 %sum, ptr %s"
    , "  %next = add i32 %i2, " <> step
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %s2 = load i32, ptr %s"
    , "  ret i32 %s2"
    , "}"
    ]

-- | The same loop started at something the block above it does not settle.
fromParameter :: Text
fromParameter =
  T.unlines
    [ "define i32 @f(i32 %x) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  store i32 %x, ptr %i"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp slt i32 %i1, 4"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %i2 = load i32, ptr %i"
    , "  %next = add i32 %i2, 1"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %i3 = load i32, ptr %i"
    , "  ret i32 %i3"
    , "}"
    ]

-- | A loop that goes round again on what it read out of memory it does not own.
loadTested :: Text
loadTested =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  store i32 0, ptr %i"
    , "  br label %head"
    , "head:"
    , "  %v = load i32, ptr %p"
    , "  %c = icmp slt i32 %v, 4"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %i2 = load i32, ptr %i"
    , "  %next = add i32 %i2, 1"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %i3 = load i32, ptr %i"
    , "  ret i32 %i3"
    , "}"
    ]

-- | A loop counted to something only the caller knows.
open :: Text
open =
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
    , "  %next = add i32 %i2, 1"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %i3 = load i32, ptr %i"
    , "  ret i32 %i3"
    , "}"
    ]

-- | A counted loop whose body keeps a block of its own, which nothing above
-- this pass merges away: the turns cannot be put in a row without copying the
-- paths through them.
twoBlocked :: Text
twoBlocked =
  T.unlines
    [ "define i32 @f(i32 %x) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  store i32 0, ptr %i"
    , "  br label %head"
    , "head:"
    , "  %i1 = load i32, ptr %i"
    , "  %c = icmp slt i32 %i1, 4"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %i2 = load i32, ptr %i"
    , "  %odd = icmp eq i32 %i2, 2"
    , "  br i1 %odd, label %skip, label %work"
    , "work:"
    , "  %z = mul i32 %x, 3"
    , "  br label %skip"
    , "skip:"
    , "  %i3 = load i32, ptr %i"
    , "  %next = add i32 %i3, 1"
    , "  store i32 %next, ptr %i"
    , "  br label %head"
    , "done:"
    , "  %i4 = load i32, ptr %i"
    , "  ret i32 %i4"
    , "}"
    ]

-- | A counted loop with more in it than writing every turn out is worth.
fat :: Text
fat =
  T.unlines
    ( [ "define i32 @f(i32 %x) {"
      , "entry:"
      , "  %i = alloca i32"
      , "  store i32 0, ptr %i"
      , "  br label %head"
      , "head:"
      , "  %i1 = load i32, ptr %i"
      , "  %c = icmp slt i32 %i1, 8"
      , "  br i1 %c, label %body, label %done"
      , "body:"
      ]
        <> ["  %w" <> T.pack (show n) <> " = mul i32 %x, " <> T.pack (show n) | n <- [1 :: Int .. 12]]
        <> [ "  %i2 = load i32, ptr %i"
           , "  %next = add i32 %i2, 1"
           , "  store i32 %next, ptr %i"
           , "  br label %head"
           , "done:"
           , "  %i3 = load i32, ptr %i"
           , "  ret i32 %i3"
           , "}"
           ]
    )
