-- | Loop rotation: which loops it turns round, which it leaves alone, and what
-- a turned loop is afterwards.
--
-- The pass moves no computation and removes none, so what these ask is where
-- the blocks go and what each one now holds.  A loop it must not touch is
-- checked by the program coming back equal to itself, which is what a pure pass
-- makes available: no change at all is a stronger statement than nothing
-- particular having moved.
module Rotation (rotationTests) where

import Data.Char (toLower)
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.ControlFlow (simplifyControlFlow)
import Olivine.Core.Pass.LoopInvariants (hoistLoopInvariants)
import Olivine.Core.Pass.LoopRotation (rotateLoops)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Binary (..))
import Olivine.Syntax.Value (TypedValue (..))

rotationTests :: TestTree
rotationTests =
  testGroup
    "loop rotation"
    [ testGroup
        "what a turned loop is"
        [ -- The test is copied into the block above the loop, which then
          -- decides whether the loop is entered; the header keeps its own copy
          -- and is reached only from the block that branches back to it.
          testCase "a loop that tests on the way in" $ do
            shapes <- shapesIn counted
            assertEqual
              "the test stands in the block above the loop as well as in it"
              [["copy", "icmp", "copy"], ["icmp", "copy"], ["add", "copy"], []]
              shapes
        , testCase "and the block above it is where the loop is entered from" $ do
            edges <- edgesIn counted
            assertEqual
              "the entry decides, and the header is reached from the body alone"
              [ (Label 0, [Label 2, Label 3])
              , (Label 1, [Label 2, Label 3])
              , (Label 2, [Label 1])
              , (Label 3, [])
              ]
              edges
        , -- The bill the copy pays: a local written in two places has to be
          -- written by an assignment in both of them, since that is the only
          -- reassignment "Olivine.Core.Ssa" can put a phi back for.
          testCase "each instruction still assigns a local of its own" $ do
            f <- rotatedFunction counted
            assertEqual "nothing an instruction assigns is assigned twice" [] (assignedTwice f)
        , -- The header of a loop entered from a branch is not a block anything
          -- can be appended to, so the copy goes in a block made for it, and
          -- every way into the loop goes through that block.
          testCase "a block is made where there is no preheader" $ do
            edges <- edgesIn guarded
            assertEqual
              "the made block holds the copy and decides for both ways in"
              [ (Label 0, [Label 4, Label 3])
              , (Label 4, [Label 2, Label 3])
              , (Label 1, [Label 2, Label 3])
              , (Label 2, [Label 1])
              , (Label 3, [])
              ]
              edges
        , -- One way on into the body is all the copy needs to decide the same
          -- thing the header did; how many ways out there are does not matter.
          testCase "a header that switches its way out" $ do
            edges <- edgesIn switched
            assertEqual
              "the entry switches as the header did"
              [ (Label 0, [Label 2, Label 3, Label 4])
              , (Label 1, [Label 2, Label 3, Label 4])
              , (Label 2, [Label 1])
              , (Label 3, [])
              , (Label 4, [])
              ]
              edges
        , -- A loop that has been turned round tests at the bottom, which is the
          -- shape this declines, so running it again finds nothing.
          testCase "turning one round twice does nothing the second time" $ do
            once <- rotated counted
            assertEqual "the second round changes nothing" once (rotateLoops once)
        ]
    , testGroup
        "what is left alone"
        [ -- Already a do loop: the test is at the latch, where rotation would
          -- have put it.
          testCase "a loop that tests on the way out" $ leftAlone doWhile
        , -- Nothing in the header decides whether to leave, so there is no test
          -- to copy anywhere.
          testCase "a loop with no way out of its header" $ leftAlone endless
        , -- The latch decides whether to go round again as well as the header,
          -- and a loop that already leaves at the bottom is one this would copy
          -- a test into the entry of for nothing.
          testCase "a loop that leaves at its latch" $ leftAlone breaking
        , -- Two ways on into the body and no single block for the loop to be
          -- entered at instead.
          testCase "a header with two ways on into the loop" $ leftAlone forking
        , -- The terminator is copied as it stands, and a call standing where a
          -- branch stands may not be: the assembly would run in two places and
          -- what it assigns would be written by two things that are not
          -- assignments.
          testCase "a header ending in assembly that branches" $ leftAlone jumping
        , -- The block in front of the header would be in front of where the
          -- function starts.
          testCase "a loop the function starts at" $ leftAlone leading
        , testCase "a function with no loop in it" $ leftAlone straight
        ]
    , testGroup
        "what it is for"
        [ -- A load in a block the loop may never reach cannot be taken out of
          -- it: nothing says the address can be read where the loop is entered
          -- and the body is not.  This is that load, and hoisting leaves it.
          testCase "a load in the body stays where the body may not run" $ do
            shapes <- shapesAfter hoistLoopInvariants reading
            assertBool
              ("expected the load still in the loop, got " <> show shapes)
              ("load" `elem` (shapes !! 2))
        , -- Rotated, the body is the block the loop is certain to run, and the
          -- same load comes out into the block that decides whether the loop
          -- runs at all.
          testCase "and comes out of the body once the body is the header" $ do
            shapes <- shapesAfter (hoistLoopInvariants . simplifyControlFlow . rotateLoops) reading
            assertEqual
              "the load stands where the loop is entered and nowhere else"
              [["copy", "icmp", "copy"], ["load"], ["add", "copy", "icmp", "copy"], []]
              shapes
        ]
    ]

-- | The lowered program with the pass run over it.
rotated :: Text -> IO Program
rotated source = rotateLoops . lower <$> expectParse "<inline>" source

rotatedFunction :: Text -> IO Function
rotatedFunction source = do
  program <- rotated source
  case functionsIn program of
    f : _ -> pure f
    [] -> assertFailure "expected a function"

-- | That the pass leaves a program exactly as it found it.
leftAlone :: Text -> Assertion
leftAlone source = do
  parsed <- expectParse "<inline>" source
  let program = lower parsed
  -- A definition the lowering could not take is retained syntax, and retained
  -- syntax comes back equal whatever this pass does; saying so here is what
  -- keeps these cases from passing for the wrong reason.
  assertBool "expected a function" (not (null (functionsIn program)))
  assertEqual "unchanged" program (rotateLoops program)

-- | What each block computes after the pass, block by block in the order
-- written.
shapesIn :: Text -> IO [[String]]
shapesIn = shapesAfter rotateLoops

shapesAfter :: (Program -> Program) -> Text -> IO [[String]]
shapesAfter pass source = do
  parsed <- expectParse "<inline>" source
  case functionsIn (pass (lower parsed)) of
    f : _ -> pure (map (map (shape . instructionOperation) . blockInstructions) (functionBlocks f))
    [] -> assertFailure "expected a function"

shape :: Operation (TypedValue Local) -> String
shape operation = case operation of
  OAssign _ -> "copy"
  OBinary b -> map toLower (drop 2 (show (binaryOp b)))
  OICmp _ -> "icmp"
  OLoad _ -> "load"
  OStore _ -> "store"
  OCall _ -> "call"
  _ -> "other"

-- | Every block after the pass with where it branches, in the order written.
edgesIn :: Text -> IO [(Label, [Label])]
edgesIn source = do
  f <- rotatedFunction source
  pure [(blockLabel b, targetsOf (blockTerminator b)) | b <- functionBlocks f]

-- | The locals assigned by more than one instruction that is not an
-- assignment, which is what reconstruction has no phi to put back for.
assignedTwice :: Function -> [Local]
assignedTwice f =
  [ local
  | local <- results
  , length (filter (== local) results) > 1
  ]
  where
    results =
      [ local
      | b <- functionBlocks f
      , i <- blockInstructions b
      , Just local <- [instructionResult i]
      , not (isCopy (instructionOperation i))
      ]
    isCopy (OAssign _) = True
    isCopy _ = False

counted :: Text
counted =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %next = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

-- | The same loop, entered from a branch, so no block above it is one the copy
-- can be appended to.
guarded :: Text
guarded =
  T.unlines
    [ "define i32 @f(i32 %n, i1 %g) {"
    , "entry:"
    , "  br i1 %g, label %head, label %done"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %next = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 0"
    , "}"
    ]

-- | A header that leaves the loop two ways and goes on one way.
switched :: Text
switched =
  T.unlines
    [ "define i32 @f(i32 %x) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  switch i32 %x, label %body [ i32 0, label %done i32 1, label %other ]"
    , "body:"
    , "  %y = add i32 %x, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 0"
    , "other:"
    , "  ret i32 1"
    , "}"
    ]

-- | The shape rotation produces, arrived at already.
doWhile :: Text
doWhile =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br label %body"
    , "body:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %next = add i32 %i, 1"
    , "  %c = icmp slt i32 %next, %n"
    , "  br i1 %c, label %body, label %done"
    , "done:"
    , "  ret i32 %next"
    , "}"
    ]

endless :: Text
endless =
  T.unlines
    [ "define void @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  br label %body"
    , "body:"
    , "  br label %head"
    , "}"
    ]

-- | A loop whose body decides whether to go round again, as well as its
-- header.
breaking :: Text
breaking =
  T.unlines
    [ "define i32 @f(i32 %n, i1 %g) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %next = add i32 %i, 1"
    , "  br i1 %g, label %head, label %done"
    , "done:"
    , "  ret i32 0"
    , "}"
    ]

-- | A loop whose header ends in assembly that branches.
--
-- Everything else about it asks to be rotated: the header decides whether to
-- leave, there is one way on into the body, and the latch decides nothing.
-- What stops it is that the terminator would be copied — the assembly written
-- twice, and what it assigns written by two things that are not assignments.
jumping :: Text
jumping =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %next = add i32 %i, 1"
    , "  callbr void asm sideeffect \"testl $0, $0; jne ${1:l}\", \"r,!i,~{cc}\"(i32 %next)"
    , "          to label %body [label %done]"
    , "body:"
    , "  %z = mul i32 %next, %n"
    , "  br label %head"
    , "done:"
    , "  ret i32 %next"
    , "}"
    ]

-- | A header that leaves the loop and goes on two ways, so there is no single
-- block for the loop to be entered at instead.
forking :: Text
forking =
  T.unlines
    [ "define i32 @f(i32 %x) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  switch i32 %x, label %done [ i32 0, label %yes i32 1, label %no ]"
    , "yes:"
    , "  br label %latch"
    , "no:"
    , "  br label %latch"
    , "latch:"
    , "  br label %head"
    , "done:"
    , "  ret i32 0"
    , "}"
    ]

-- | A loop the function starts at, which LLVM does not allow and nothing
-- Olivine does produces.
leading :: Text
leading =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %k) {"
    , "head:"
    , "  %p = mul i32 %k, %k"
    , "  %c = icmp slt i32 %p, %n"
    , "  br i1 %c, label %head, label %done"
    , "done:"
    , "  ret i32 0"
    , "}"
    ]

straight :: Text
straight =
  T.unlines
    [ "define i32 @f(i1 %c) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  br label %join"
    , "no:"
    , "  br label %join"
    , "join:"
    , "  ret i32 0"
    , "}"
    ]

-- | A load through a pointer the function was handed, in a body the loop may
-- never reach.  Which is the shape a front end writes most often, and the one
-- hoisting cannot take anything out of until the body is the header.
reading :: Text
reading =
  T.unlines
    [ "define i32 @f(ptr %p, i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %v = load i32, ptr %p, align 4"
    , "  %next = add i32 %i, %v"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]
