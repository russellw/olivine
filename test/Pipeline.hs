-- | The pipeline as a whole: that it runs until a round changes nothing, and
-- what the rounds after the first are for.
--
-- The order the passes stand in settles what each of them gets to see the
-- first time through, and it cannot settle everything: a pass above another
-- cannot act on what the one below it makes.  What these ask is that the
-- program come back at a fixed point rather than at whatever the single
-- ordering happened to reach.
module Pipeline (pipelineTests) where

import Data.List (isInfixOf)
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Program
import Olivine.Pipeline (Pass (..), passes, rounds, stages)

pipelineTests :: TestTree
pipelineTests =
  testGroup
    "pipeline"
    [ testGroup
        "what a second round is for"
        [ -- Rotation copies the header's test into the block above the loop,
          -- where the counter is the value it starts at — so a loop counted to
          -- a constant leaves a comparison of two constants behind.  Folding
          -- settles that in a line, and folding stands above rotation in the
          -- order, so nothing asks it until the pipeline comes round again.
          testCase "the guard rotation leaves is two constants" $ do
            shapes <- shapesAfter oneRound bounded
            assertBool
              ("expected the copied test in the block above the loop, got " <> show shapes)
              ("icmp" `elem` concat (take 1 shapes))
        , -- What is left is the loop's own test, on the branch that closes it:
          -- that one is a counter against a bound and settles nothing.
          testCase "and the round after settles it" $ do
            shapes <- shapesAfter optimized bounded
            assertBool
              ("expected the guard gone and the latch test kept, got " <> show shapes)
              ("icmp" `notElem` concat (take 1 shapes) && any ("icmp" `elem`) shapes)
        ]
    , testGroup
        "when it stops"
        [ -- The whole claim the iteration makes: what comes out is what the
          -- passes have nothing left to do to, not what one ordering reached.
          testCase "the program that comes out is a fixed point" $ do
            program <- optimized bounded
            assertEqual "another round changes nothing" program (oneRound' program)
        , -- And the same of a program the first round already finished with,
          -- which is the case that costs a round to find out about.
          testCase "a program the first round finishes with" $ do
            program <- optimized straight
            assertEqual "another round changes nothing" program (oneRound' program)
        ]
    , testGroup
        "what the stages say"
        [ -- A pass that breaks a program is named by the stage it broke it at,
          -- and "after folding" stops naming one point once there are two.
          testCase "a round after the first says which it is" $ do
            labels <- labelsFor bounded
            assertBool
              ("expected a second round in " <> show labels)
              (any ("(round 2)" `isInfixOf`) labels)
        , testCase "the first round says nothing about rounds" $ do
            labels <- labelsFor bounded
            assertEqual
              "the passes of the first round are named as they were"
              ["after " <> passName p | p <- passes]
              (take (length passes) (drop 1 labels))
        , -- Every round is there to be looked at, so the count of stages says
          -- how many rounds ran, and the bound is what it cannot pass.
          testCase "no more rounds run than the bound allows" $ do
            labels <- labelsFor bounded
            assertBool
              ("expected at most " <> show rounds <> " rounds, got " <> show labels)
              (length labels <= 1 + rounds * length passes)
        ]
    ]

-- | The passes once through, in order.
oneRound' :: Program -> Program
oneRound' program = foldl (\p pass -> runPass pass p) program passes

oneRound :: Text -> IO Program
oneRound source = oneRound' . lower <$> expectParse "<inline>" source

-- | The pipeline as it actually runs, rounds and all.
optimized :: Text -> IO Program
optimized source = snd . last . stages <$> expectParse "<inline>" source

labelsFor :: Text -> IO [String]
labelsFor source = map fst . stages <$> expectParse "<inline>" source

-- | What each block computes afterwards, block by block in the order written.
shapesAfter :: (Text -> IO Program) -> Text -> IO [[String]]
shapesAfter run source = do
  program <- run source
  case functionsIn program of
    f : _ -> pure (map (map (shape . instructionOperation) . blockInstructions) (functionBlocks f))
    [] -> assertFailure "expected a function"

shape :: Operation a -> String
shape operation = case operation of
  OAssign _ -> "copy"
  OICmp _ -> "icmp"
  OLoad _ -> "load"
  OStore _ -> "store"
  _ -> "other"

-- | A loop counted to a constant: the shape whose entry guard is settled by
-- the round after the one that made it.
--
-- Counted to a hundred rather than to four so that unrolling declines it.  A
-- loop written out turn by turn has no guard left to settle and no latch test
-- to keep, which would make this pass for having removed the whole loop rather
-- than for the round that folds two constants.
bounded :: Text
bounded =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %s = phi i32 [ 0, %entry ], [ %sum, %body ]"
    , "  %c = icmp slt i32 %i, 100"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %a = getelementptr inbounds i32, ptr %p, i32 %i"
    , "  %v = load i32, ptr %a"
    , "  %sum = add i32 %s, %v"
    , "  %next = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %s"
    , "}"
    ]

-- | A function with nothing in it for a second round to find.
straight :: Text
straight =
  T.unlines
    [ "define i32 @f(i32 %x) {"
    , "entry:"
    , "  %y = add i32 %x, 1"
    , "  ret i32 %y"
    , "}"
    ]
