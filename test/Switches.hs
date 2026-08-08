-- | Switch folding: which switches become arithmetic, which are left alone,
-- and what the block they collapse into holds afterwards.
--
-- The pass reads a run of cases as a formula, so the questions are which runs
-- it reads and what it writes for each.  A switch it must not touch is checked
-- by the program coming back equal to itself, which is what a pure pass makes
-- available.
--
-- What the arithmetic /means/ is checked by running it: 'answers' evaluates
-- the folded function at every value either side of the range, so a formula
-- off by one in the base, the step or the range test fails here rather than in
-- the corpus.
module Switches (switchTests) where

import Data.Char (toLower)
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.ControlFlow (simplifyControlFlow)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Pass.Switches (caseFloor, foldSwitches)
import Olivine.Core.Program
import Olivine.Core.Raise (raise)
import Olivine.Core.Verify qualified as Core
import Olivine.Syntax.Instruction (Binary (..), BinaryOp (..), Compare (..), Select (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))
import Olivine.Syntax.Verify qualified as Syntax

switchTests :: TestTree
switchTests =
  testGroup
    "switch folding"
    [ testGroup
        "what becomes arithmetic"
        [ -- The cases run in step with their values, so the answer is a
          -- multiply, an add and one select against the default.  The copies
          -- either side of it are promotion's, not this pass's: a slot opens
          -- holding poison and the load at the join is a copy of it, and
          -- reconstruction takes every one of them away.
          testCase "results in step with the case values" $ do
            shapes <- shapesIn (run 0 [3, 5, 7, 9, 11] 0)
            assertEqual
              "the index is the value, so no subtraction"
              [["copy", "icmp", "mul", "add", "select", "copy", "copy"]]
              shapes
        , testCase "and nothing branches any more" $ do
            edges <- edgesIn (run 0 [3, 5, 7, 9, 11] 0)
            assertEqual "one block, going nowhere" [(Label 0, [])] edges
        , -- Cases that do not start at zero: the index is counted from the
          -- lowest of them, which is the one subtraction.
          testCase "cases that start somewhere else" $ do
            shapes <- shapesIn (run 3 [1, 1, 1, 1] 0)
            assertEqual
              "a subtraction, the range test, and no arithmetic on the answer"
              [["copy", "sub", "icmp", "select", "copy", "copy"]]
              shapes
        , testCase "one answer for the whole range" $ do
            shapes <- shapesIn (run 0 [8, 8, 8] 0)
            assertEqual "the range test and a select" [["copy", "icmp", "select", "copy", "copy"]] shapes
        , -- A descending run is a step like any other.
          testCase "results running downwards" $
            answers (run 10 [40, 30, 20, 10] (-1)) [8 .. 15]
              >>= (@?= [-1, -1, 40, 30, 20, 10, -1, -1])
        , testCase "the range test decides at both ends" $
            answers (run 0 [3, 5, 7, 9, 11] 0) [-2 .. 6]
              >>= (@?= [0, 0, 3, 5, 7, 9, 11, 0, 0])
        , testCase "and where the cases start elsewhere" $
            answers (run 3 [1, 1, 1, 1] 0) [0 .. 8]
              >>= (@?= [0, 0, 0, 1, 1, 1, 1, 0, 0])
        ]
    , testGroup
        "what is left alone"
        [ -- Results in no order are what a lookup table in memory answers,
          -- and no pass here writes a global.
          testCase "results in no order" $ leftAlone (run 0 [4, 9, 2, 7] (-1))
        , -- A hole in the case values means the index is not the case.
          testCase "case values with a hole in them" $
            leftAlone (switchOn [(1, 2), (2, 4), (4, 8)] 0)
        , testCase "fewer cases than the floor" $
            leftAlone (run 0 (replicate (caseFloor - 1) 5) 0)
        , testCase "a case that computes" $ leftAlone computing
        , testCase "a case that goes somewhere else" $ leftAlone escaping
        , testCase "two locals decided at once" $ leftAlone pairwise
        ]
    , testGroup
        "what comes back"
        [ testCase "the core verifier is satisfied" $
            mapM_ sound cases
        , testCase "and so is the syntax verifier" $
            mapM_ acceptable cases
        ]
    ]
  where
    cases =
      [ run 0 [3, 5, 7, 9, 11] 0
      , run 3 [1, 1, 1, 1] 0
      , run 10 [40, 30, 20, 10] (-1)
      , run 0 [4, 9, 2, 7] (-1)
      , computing
      , escaping
      , pairwise
      ]

-- | The lowered program, straightened, with the pass run over it.
--
-- Control flow simplification first because the pass wants the graph it
-- leaves: a case whose block only branches onward is a detour, and a side that
-- does not go to the join is not read as one.  That is the order the pipeline
-- has them in.
folded :: Text -> IO Program
folded source =
  foldSwitches . simplifyControlFlow . promoteMemory . lower
    <$> expectParse "<inline>" source

-- | That the pass leaves a program exactly as it found it.
leftAlone :: Text -> Assertion
leftAlone source = do
  program <- simplifyControlFlow . promoteMemory . lower <$> expectParse "<inline>" source
  assertBool "expected a function" (not (null (functionsIn program)))
  assertEqual "unchanged" program (foldSwitches program)

acceptable :: Text -> Assertion
acceptable source = do
  program <- folded source
  let problems = Syntax.verify (raise program)
  assertEqual (T.unpack (T.unlines (map Syntax.renderProblem problems))) [] problems

sound :: Text -> Assertion
sound source = do
  program <- folded source
  let problems = Core.verify program
  assertEqual (T.unpack (T.unlines (map Core.renderProblem problems))) [] problems

-- | What each block computes after the pass, block by block in the order
-- written.
shapesIn :: Text -> IO [[String]]
shapesIn source = do
  program <- folded source
  case functionsIn program of
    f : _ ->
      pure (map (map (shape . instructionOperation) . blockInstructions) (functionBlocks f))
    [] -> assertFailure "expected a function"

shape :: Operation (TypedValue Local) -> String
shape operation = case operation of
  OAssign _ -> "copy"
  OBinary b -> map toLower (drop 2 (show (binaryOp b)))
  OICmp _ -> "icmp"
  OSelect _ -> "select"
  _ -> "other"

edgesIn :: Text -> IO [(Label, [Label])]
edgesIn source = do
  program <- folded source
  case functionsIn program of
    f : _ -> pure [(blockLabel b, targetsOf (blockTerminator b)) | b <- functionBlocks f]
    [] -> assertFailure "expected a function"

-- | What the folded function answers at each of the given values.
--
-- The arithmetic is run rather than read: what a formula is worth is what it
-- computes, and a base, a step or a range test one out is a thing to be caught
-- by asking it.  The evaluator here is a few lines because what the pass
-- writes is a few operations: an add, a subtraction, a multiply, one unsigned
-- comparison and one select.  It handles nothing else and says so loudly, so
-- a pass that starts writing something else fails here rather than being
-- quietly waved through.
answers :: Text -> [Integer] -> IO [Integer]
answers source values = do
  program <- folded source
  case functionsIn program of
    f : _ -> pure [evaluate f v | v <- values]
    [] -> assertFailure "expected a function"

-- | A function of one integer parameter, one block, and a @ret@, run on a
-- number.
evaluate :: Function -> Integer -> Integer
evaluate f value = case functionBlocks f of
  [b] -> case terminatorTransfer (blockTerminator b) of
    Ret (Just result) -> at (held b) result
    _ -> error "switch folding tests: expected one block ending in a return"
  _ -> error "switch folding tests: expected one block"
  where
    parameter = case functionParameters f of
      p : _ -> p
      [] -> error "switch folding tests: expected a parameter"

    held b = foldl step [(parameter, value)] (blockInstructions b)
    step env i = case instructionResult i of
      Just result -> (result, run' env (instructionOperation i)) : env
      Nothing -> env

    run' env operation = case operation of
      OAssign operand -> at env operand
      OBinary o -> case binaryOp o of
        OpAdd -> at env (binaryLeft o) + at env (binaryRight o)
        OpSub -> at env (binaryLeft o) - at env (binaryRight o)
        OpMul -> at env (binaryLeft o) * at env (binaryRight o)
        op -> error ("switch folding tests: unexpected " <> show op)
      OICmp c -> if inRange env c then 1 else 0
      OSelect s ->
        if at env (selectCondition s) /= 0
          then at env (selectTrue s)
          else at env (selectFalse s)
      _ -> error "switch folding tests: unexpected operation"

    -- The one comparison the pass writes, unsigned and at 32 bits, which is
    -- what makes a value below the lowest case fall outside the range.
    inRange env c =
      (at env (compareLeft c) `mod` (2 ^ (32 :: Int)))
        < (at env (compareRight c) `mod` (2 ^ (32 :: Int)))

    at env operand = case typedValue operand of
      VLocal local -> maybe (error "switch folding tests: unassigned") id (lookup local env)
      VInteger n -> n
      VBoolean True -> 1
      VBoolean False -> 0
      v -> error ("switch folding tests: unexpected operand " <> show v)

-- | @switch (c) { case lo+j: return r_j; default: return d; }@, as a front end
-- writes it: the answer travels through a slot, so promotion is what makes the
-- cases assignments.
run :: Integer -> [Integer] -> Integer -> Text
run lo results = switchOn (zip [lo ..] results)

switchOn :: [(Integer, Integer)] -> Integer -> Text
switchOn cases fallback =
  T.unlines $
    [ "define i32 @f(i32 %c) {"
    , "entry:"
    , "  %r = alloca i32, align 4"
    , "  switch i32 %c, label %other ["
    ]
      <> [ "    i32 " <> number value <> ", label %case" <> num value
         | (value, _) <- cases
         ]
      <> ["  ]"]
      <> concat
        [ [ "case" <> num value <> ":"
          , "  store i32 " <> number result <> ", ptr %r, align 4"
          , "  br label %join"
          ]
        | (value, result) <- cases
        ]
      <> [ "other:"
         , "  store i32 " <> number fallback <> ", ptr %r, align 4"
         , "  br label %join"
         , "join:"
         , "  %z = load i32, ptr %r, align 4"
         , "  ret i32 %z"
         , "}"
         ]
  where
    number = T.pack . show
    -- A block's name, where a minus sign is not an identifier character.
    num n
      | n < 0 = "m" <> T.pack (show (negate n))
      | otherwise = T.pack (show n)

-- | A case that does arithmetic rather than leaving a constant.
computing :: Text
computing =
  T.unlines
    [ "define i32 @f(i32 %c, i32 %x) {"
    , "entry:"
    , "  switch i32 %c, label %other ["
    , "    i32 0, label %a"
    , "    i32 1, label %b"
    , "    i32 2, label %d"
    , "  ]"
    , "a:"
    , "  %p = add i32 %x, 1"
    , "  br label %join"
    , "b:"
    , "  %q = add i32 %x, 2"
    , "  br label %join"
    , "d:"
    , "  %s = add i32 %x, 3"
    , "  br label %join"
    , "other:"
    , "  br label %join"
    , "join:"
    , "  %z = phi i32 [ %p, %a ], [ %q, %b ], [ %s, %d ], [ 0, %other ]"
    , "  ret i32 %z"
    , "}"
    ]

-- | A case that goes somewhere the others do not, so there is no one join.
escaping :: Text
escaping =
  T.unlines
    [ "define i32 @f(i32 %c) {"
    , "entry:"
    , "  switch i32 %c, label %other ["
    , "    i32 0, label %a"
    , "    i32 1, label %b"
    , "    i32 2, label %away"
    , "  ]"
    , "a:"
    , "  br label %join"
    , "b:"
    , "  br label %join"
    , "away:"
    , "  ret i32 7"
    , "other:"
    , "  br label %join"
    , "join:"
    , "  %z = phi i32 [ 1, %a ], [ 2, %b ], [ 0, %other ]"
    , "  ret i32 %z"
    , "}"
    ]

-- | Two values decided at once, which would be two formulas and two selects.
pairwise :: Text
pairwise =
  T.unlines
    [ "define i32 @f(i32 %c) {"
    , "entry:"
    , "  switch i32 %c, label %other ["
    , "    i32 0, label %a"
    , "    i32 1, label %b"
    , "    i32 2, label %d"
    , "  ]"
    , "a:"
    , "  br label %join"
    , "b:"
    , "  br label %join"
    , "d:"
    , "  br label %join"
    , "other:"
    , "  br label %join"
    , "join:"
    , "  %x = phi i32 [ 1, %a ], [ 2, %b ], [ 3, %d ], [ 0, %other ]"
    , "  %y = phi i32 [ 9, %a ], [ 8, %b ], [ 7, %d ], [ 6, %other ]"
    , "  %z = add i32 %x, %y"
    , "  ret i32 %z"
    , "}"
    ]
