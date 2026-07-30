-- | If-conversion: which branches become selects, which are left alone, and
-- what the block they collapse into holds afterwards.
--
-- The pass moves code that control did not have to run, so the questions are
-- what ends up standing unconditionally and what each side's values become.  A
-- branch it must not touch is checked by the program coming back equal to
-- itself, which is what a pure pass makes available.
--
-- Two invariants are checked on the way out rather than by reading the blocks:
-- that what comes back is a module LLVM would accept — a local written by a
-- select and by an assignment elsewhere is the mistake this pass could most
-- easily make, and it is exactly what the syntax verifier calls a local
-- assigned twice — and that the core verifier finds nothing between the two.
module IfConversion (ifConversionTests) where

import Data.Char (toLower)
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.IfConversion (armBudget, convertBranches)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Program
import Olivine.Core.Raise (raise)
import Olivine.Core.Verify qualified as Core
import Olivine.Pipeline (optimize)
import Olivine.Syntax.Instruction (Binary (..))
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Value (TypedValue (..))
import Olivine.Syntax.Verify qualified as Syntax

ifConversionTests :: TestTree
ifConversionTests =
  testGroup
    "if conversion"
    [ testGroup
        "what becomes a select"
        [ -- The plain diamond: a value computed on each side, and the local both
          -- sides assign is the one the join reads.
          testCase "a value computed on each side" $ do
            shapes <- shapesIn diamond
            assertEqual
              "both sides stand in the block that tested, and one select picks"
              [["add", "copy", "add", "copy", "select", "copy"]]
              shapes
        , testCase "and the branch is gone" $ do
            edges <- edgesIn diamond
            assertEqual "one block, going nowhere" [(Label 0, [])] edges
        , -- The side with nothing on it: what the join saw along that edge is
          -- what the local already held, so the select reads the local itself.
          --
          -- Promotion is what leaves this shape.  Written as a phi it is not one:
          -- the value arriving from the block that tested is a copy, and phi
          -- elimination has to put that copy on an edge of its own, which leaves
          -- two sides again.  Written as a variable, the side that assigns
          -- nothing holds nothing.
          testCase "a value on one side and nothing on the other" $ do
            shapes <- promotedShapesIn triangle
            assertEqual
              "the one side is speculated and the select picks against the local"
              [["copy", "copy", "add", "copy", "select", "copy", "copy"]]
              shapes
        , -- The inner diamond becomes a comparison and a select, which is a side
          -- like any other, so the outer one goes next without this looking for
          -- a nest.
          testCase "an else if collapses innermost first" $ do
            shapes <- shapesIn nested
            assertEqual
              "two comparisons and two selects, in one block"
              [ [ "icmp"
                , "copy"
                , "icmp"
                , "copy"
                , "copy"
                , "select"
                , "copy"
                , "copy"
                , "select"
                , "copy"
                ]
              ]
              shapes
        , -- Exactly what a side may hold, which is the other end of the case
          -- below that declines one instruction more.
          testCase "a side as long as the budget allows" $ do
            selects <- length . filter (== "select") . concat <$> shapesIn (sideComputing armBudget)
            assertEqual "converted" 1 selects
        , -- An instruction nothing reads is dead whether it is speculated or not,
          -- so it is not what the budget is for.  A @-O0@ front end leaves one on
          -- the side of a conditional whose value is a comparison, which is how
          -- this stopped being hypothetical.
          testCase "a side whose extra instruction nothing reads" $ do
            shapes <- shapesIn spare
            assertEqual
              "the dead conversion is speculated with the rest"
              [["icmp", "other", "copy", "copy", "select", "copy"]]
              shapes
        , -- A local nothing outside the side reads is a temporary of that side
          -- and stays one; only what something else reads had a value that
          -- depended on the branch.
          testCase "a temporary of one side is not decided" $ do
            selects <- length . filter (== "select") . concat <$> shapesIn diamond
            assertEqual "one select, for the one local the join reads" 1 selects
        , -- Every select stands for what arrives at the join, and what arrives
          -- there arrives at once.  Here one of the decided locals is the
          -- condition itself, so an assignment written between the two selects
          -- would leave the second reading the value the first had just chosen.
          testCase "the selects all stand before the assignments" $ do
            shapes <- shapesIn deciding
            assertEqual
              "nothing is written back until every side has been chosen between"
              [ ["copy", "copy"]
              , ["add", "copy", "copy", "copy", "copy", "select", "select", "copy", "copy"]
              ]
              shapes
        ]
    , testGroup
        "what is left alone"
        [ -- Running a call where control would not have is running it, and it
          -- may do anything.
          testCase "a call on one side" $ leftAlone (sideDoing "  %v = call i32 @g(i32 %a)")
        , -- The address may be one the other path never goes near.
          testCase "a load on one side" $ leftAlone (sideDoing "  %v = load i32, ptr %p, align 4")
        , testCase "a store on one side" $
            leftAlone (sideDoing "  store i32 1, ptr %p, align 4")
        , -- Undefined behaviour on operands it can be given, which is behaviour
          -- to invent rather than to collect on.
          testCase "a division on one side" $ leftAlone (sideDoing "  %v = sdiv i32 %a, %b")
        , -- Past 'armBudget': whichever way the branch went, this is what the
          -- other path would have to run for nothing.
          testCase "a side with more work than the budget allows" $
            leftAlone (sideComputing (armBudget + 1))
        , -- Reached from somewhere else as well, so it is not a side of this
          -- branch and merging it into the block above would lose the other way
          -- in.
          testCase "a side reached from elsewhere" $ leftAlone shared
        , -- The sides do not meet: each returns, and there is no value arriving
          -- anywhere to pick between.
          testCase "sides that return rather than join" $ leftAlone returning
        , -- Several sides, and a chain of selects against a jump table is not a
          -- trade this can judge.
          testCase "a switch" $ leftAlone switched
        ]
    , testGroup
        "what comes out"
        [ -- The select writes a local of its own and an assignment carries it
          -- into the one the rest of the function reads.  Written directly, it
          -- would be a second instruction assigning a local that the sides also
          -- assign, and reconstruction has no phi to put back for that: the
          -- module would come out with one local defined twice.
          testCase "a module LLVM would accept" $ mapM_ acceptable everything
        , testCase "a core program with nothing wrong with it" $ mapM_ sound everything
        , -- Nothing to pick between, and nothing left of the branch either: two
          -- empty sides make the same block whichever way control went.  Control
          -- flow simplification takes such a branch away before this pass runs,
          -- which is why this is stated here rather than counted on.
          testCase "a branch with nothing on either side" $ do
            shapes <- shapesIn empty
            assertEqual "one block, and no select in it" [[]] shapes
        , -- What the pass is for, on the shape a front end actually writes: a
          -- variable assigned differently on the two sides of an @if@, which
          -- arrives as a slot and reaches the output as one instruction.
          testCase "the shape a front end writes" $ do
            written <- optimized frontEnd
            assertBool
              ("expected a select and no branch, got:\n" <> T.unpack written)
              ("select" `T.isInfixOf` written && not ("br " `T.isInfixOf` written))
        ]
    ]

-- | Every source here, for the checks that are asked of all of them.
everything :: [Text]
everything =
  [ diamond
  , triangle
  , nested
  , deciding
  , shared
  , returning
  , switched
  , empty
  , frontEnd
  , sideDoing "  %v = sdiv i32 %a, %b"
  , sideComputing armBudget
  , sideComputing (armBudget + 1)
  , spare
  ]

-- | The lowered program with the pass run over it.
converted :: Text -> IO Program
converted source = convertBranches . lower <$> expectParse "<inline>" source

-- | That the pass leaves a program exactly as it found it.
leftAlone :: Text -> Assertion
leftAlone source = do
  program <- lower <$> expectParse "<inline>" source
  -- A definition the lowering could not take is retained syntax, which comes
  -- back equal whatever this pass does; saying so here is what keeps these
  -- cases from passing for the wrong reason.
  assertBool "expected a function" (not (null (functionsIn program)))
  assertEqual "unchanged" program (convertBranches program)

-- | That what the pass leaves can be written back out as LLVM would have it.
acceptable :: Text -> Assertion
acceptable source = do
  program <- converted source
  let problems = Syntax.verify (raise program)
  assertEqual
    (T.unpack (T.unlines (map Syntax.renderProblem problems)))
    []
    problems

-- | That what the pass leaves is a core program the verifier is happy with.
sound :: Text -> Assertion
sound source = do
  program <- converted source
  let problems = Core.verify program
  assertEqual
    (T.unpack (T.unlines (map Core.renderProblem problems)))
    []
    problems

-- | What each block computes after the pass, block by block in the order
-- written.
shapesIn :: Text -> IO [[String]]
shapesIn source = do
  program <- converted source
  case functionsIn program of
    f : _ -> pure (map (map (shape . instructionOperation) . blockInstructions) (functionBlocks f))
    [] -> assertFailure "expected a function"

-- | As 'shapesIn', with promotion run first: the shape of what a front end
-- writes, once the slots are locals.
promotedShapesIn :: Text -> IO [[String]]
promotedShapesIn source = do
  program <- convertBranches . promoteMemory . lower <$> expectParse "<inline>" source
  case functionsIn program of
    f : _ -> pure (map (map (shape . instructionOperation) . blockInstructions) (functionBlocks f))
    [] -> assertFailure "expected a function"

shape :: Operation (TypedValue Local) -> String
shape operation = case operation of
  OAssign _ -> "copy"
  OBinary b -> map toLower (drop 2 (show (binaryOp b)))
  OICmp _ -> "icmp"
  OSelect _ -> "select"
  OLoad _ -> "load"
  OStore _ -> "store"
  OCall _ -> "call"
  _ -> "other"

-- | Every block after the pass with where it branches, in the order written.
edgesIn :: Text -> IO [(Label, [Label])]
edgesIn source = do
  program <- converted source
  case functionsIn program of
    f : _ -> pure [(blockLabel b, targetsOf (blockTerminator b)) | b <- functionBlocks f]
    [] -> assertFailure "expected a function"

-- | The whole pipeline, as LLVM will see it.
optimized :: Text -> IO Text
optimized source = renderModule . optimize <$> expectParse "<inline>" source

diamond :: Text
diamond =
  T.unlines
    [ "define i32 @f(i1 %c, i32 %a, i32 %b) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  %x = add i32 %a, 1"
    , "  br label %join"
    , "no:"
    , "  %y = add i32 %b, 2"
    , "  br label %join"
    , "join:"
    , "  %z = phi i32 [ %x, %yes ], [ %y, %no ]"
    , "  ret i32 %z"
    , "}"
    ]

-- | @if (c) z = a + 1@, as a front end writes it: a slot assigned on one side
-- and read at the join, so once the slot is a local the other side holds
-- nothing.
triangle :: Text
triangle =
  T.unlines
    [ "define i32 @f(i1 %c, i32 %a) {"
    , "entry:"
    , "  %z = alloca i32, align 4"
    , "  store i32 %a, ptr %z, align 4"
    , "  br i1 %c, label %yes, label %join"
    , "yes:"
    , "  %s = add i32 %a, 1"
    , "  store i32 %s, ptr %z, align 4"
    , "  br label %join"
    , "join:"
    , "  %r = load i32, ptr %z, align 4"
    , "  ret i32 %r"
    , "}"
    ]

-- | An @else if@: the second test stands on one side of the first.
nested :: Text
nested =
  T.unlines
    [ "define i32 @f(i32 %x, i32 %lo, i32 %hi) {"
    , "entry:"
    , "  %below = icmp slt i32 %x, %lo"
    , "  br i1 %below, label %clamped, label %check"
    , "check:"
    , "  %above = icmp sgt i32 %x, %hi"
    , "  br i1 %above, label %capped, label %same"
    , "capped:"
    , "  br label %join"
    , "same:"
    , "  br label %join"
    , "join:"
    , "  %inner = phi i32 [ %hi, %capped ], [ %x, %same ]"
    , "  br label %out"
    , "clamped:"
    , "  br label %out"
    , "out:"
    , "  %z = phi i32 [ %lo, %clamped ], [ %inner, %join ]"
    , "  ret i32 %z"
    , "}"
    ]

-- | A branch inside a loop whose sides decide what it will branch on next time
-- round, so one of the locals being selected is the condition itself.
deciding :: Text
deciding =
  T.unlines
    [ "define i32 @f(i1 %s, i32 %n) {"
    , "entry:"
    , "  br label %loop"
    , "loop:"
    , "  %v = phi i1 [ %s, %entry ], [ false, %yes ], [ true, %no ]"
    , "  %i = phi i32 [ 0, %entry ], [ %j, %yes ], [ %n, %no ]"
    , "  br label %head"
    , "head:"
    , "  %j = add i32 %i, 1"
    , "  br i1 %v, label %yes, label %no"
    , "yes:"
    , "  br label %loop"
    , "no:"
    , "  br label %loop"
    , "}"
    ]

-- | A diamond with the given line on one side of it.
sideDoing :: Text -> Text
sideDoing line =
  T.unlines
    [ "declare i32 @g(i32)"
    , "define i32 @f(i1 %c, i32 %a, i32 %b, ptr %p) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , line
    , "  br label %join"
    , "no:"
    , "  br label %join"
    , "join:"
    , "  ret i32 %a"
    , "}"
    ]

-- | A diamond with a chain of arithmetic on one side, as long as asked for, and
-- the end of it read at the join so that every step of it counts.
sideComputing :: Int -> Text
sideComputing steps =
  T.unlines
    ( [ "define i32 @f(i1 %c, i32 %a) {"
      , "entry:"
      , "  br i1 %c, label %yes, label %no"
      , "yes:"
      ]
        <> [ "  %p" <> T.pack (show k) <> " = add i32 " <> from (k - 1) <> ", 1"
           | k <- [1 .. steps]
           ]
        <> [ "  br label %join"
           , "no:"
           , "  br label %join"
           , "join:"
           , "  %z = phi i32 [ %p" <> T.pack (show steps) <> ", %yes ], [ 0, %no ]"
           , "  ret i32 %z"
           , "}"
           ]
    )
  where
    -- The chain starts from the parameter and each step reads the one before it.
    from 0 = "%a"
    from k = "%p" <> T.pack (show k)

-- | A side holding one more instruction than the budget allows, of which one is
-- read by nothing at all — which is what a front end writes for @c ? x > 0 : 0@,
-- the @zext@ of a comparison it went on not to use.
spare :: Text
spare =
  T.unlines
    [ "define i32 @f(i1 %c, i32 %a) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  %p = icmp sgt i32 %a, 0"
    , "  %q = zext i1 %p to i32"
    , "  br label %join"
    , "no:"
    , "  br label %join"
    , "join:"
    , "  %z = phi i32 [ %q, %yes ], [ 0, %no ]"
    , "  ret i32 %z"
    , "}"
    ]

-- | A block on one side that something else branches to as well.
shared :: Text
shared =
  T.unlines
    [ "define i32 @f(i1 %c, i1 %d, i32 %a) {"
    , "entry:"
    , "  br i1 %d, label %top, label %yes"
    , "top:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  br label %join"
    , "no:"
    , "  br label %join"
    , "join:"
    , "  ret i32 %a"
    , "}"
    ]

-- | Sides that leave the function rather than meeting.
returning :: Text
returning =
  T.unlines
    [ "define i32 @f(i1 %c, i32 %a) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  ret i32 %a"
    , "no:"
    , "  ret i32 0"
    , "}"
    ]

switched :: Text
switched =
  T.unlines
    [ "define i32 @f(i32 %x) {"
    , "entry:"
    , "  switch i32 %x, label %other [ i32 0, label %zero i32 1, label %one ]"
    , "zero:"
    , "  br label %join"
    , "one:"
    , "  br label %join"
    , "other:"
    , "  br label %join"
    , "join:"
    , "  %z = phi i32 [ 10, %zero ], [ 20, %one ], [ 30, %other ]"
    , "  ret i32 %z"
    , "}"
    ]

-- | A branch whose sides do nothing at all, which control flow simplification
-- would have folded before this ran.
empty :: Text
empty =
  T.unlines
    [ "define i32 @f(i1 %c, i32 %a) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  br label %join"
    , "no:"
    , "  br label %join"
    , "join:"
    , "  ret i32 %a"
    , "}"
    ]

-- | What a front end writes for @int z = c ? a : b@ before anything has run:
-- a slot for the variable, a store on each side, and a load at the join.
frontEnd :: Text
frontEnd =
  T.unlines
    [ "define i32 @f(i1 %c, i32 %a, i32 %b) {"
    , "entry:"
    , "  %z = alloca i32, align 4"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  store i32 %a, ptr %z, align 4"
    , "  br label %join"
    , "no:"
    , "  store i32 %b, ptr %z, align 4"
    , "  br label %join"
    , "join:"
    , "  %r = load i32, ptr %z, align 4"
    , "  ret i32 %r"
    , "}"
    ]
