-- | The core representation, and the two conversions either side of it.
--
-- Byte-identical output no longer speaks for this layer.  Eliminating phi
-- nodes changes the text by design, so what is checked here is structure —
-- that the invariants the core claims actually hold — while
-- @tools/check-behaviour.sh@ checks that the program still does the same
-- thing, which is the part text comparison can no longer reach.
module Core (coreTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (corpusFiles, expectParse, readCorpusFile)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Program
import Olivine.Core.Raise (raise)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Value

coreTests :: IO TestTree
coreTests = do
  names <- corpusFiles
  pure $
    testGroup
      "core"
      [ testGroup
          "every definition reaches the core"
          [testCase name (lowersFully name) | name <- names]
      , testGroup
          "what the core guarantees"
          [testCase name (invariants name) | name <- names]
      , testGroup
          "raising gives back something that lowers again"
          [testCase name (stable name) | name <- names]
      , testGroup
          "the scaffolding does not escape"
          [testCase name (noScaffolding name) | name <- names]
      , phiTests
      , numberingTests
      ]

-- | Nothing is retained as syntax any more, so a definition failing to lower
-- would be a construct the lowering has lost the ability to read.
lowersFully :: FilePath -> Assertion
lowersFully name = do
  (_, parsed) <- readCorpusFile name
  let definitions = [() | Syntax.EDefine _ <- Syntax.moduleEntries parsed]
      program = lower parsed
  assertEqual "definitions lowered" (length definitions) (length (functionsIn program))
  assertEqual
    "definitions retained"
    []
    [() | ERetained (Syntax.EDefine _) <- programEntries program]

-- | The invariants the core has and the syntax layer could not.
invariants :: FilePath -> Assertion
invariants name = do
  (_, parsed) <- readCorpusFile name
  assertInvariants (functionsIn (lower parsed))

-- | Three of the four this used to check are gone, and their going is the
-- point.  That the terminator slot holds a terminator, that nothing before it
-- is one, and that no phi survives lowering were assertions about a type that
-- could express the opposite.  It cannot now: a 'Terminator' holds a
-- 'Transfer' and an 'Instruction' holds an 'Operation', and neither type is
-- the other, so those tests would no longer compile.  A test that cannot be
-- written is a better guarantee than one that passes.
assertInvariants :: [Function] -> Assertion
assertInvariants functions =
  -- Assignments may only sit in a block with a single successor.  A block
  -- that branches two ways would run them on the way to both, which is what
  -- splitting the edge exists to prevent, so this is the check that the
  -- splitting actually happened.
  assertEqual
    "assignments only where there is one way out"
    []
    [ ()
    | b <- blocks
    , length (targetsOf (blockTerminator b)) > 1
    , Instruction _ (OAssign _) _ <- blockInstructions b
    ]
  where
    blocks = concatMap functionBlocks functions

-- | What comes back out must be a module Olivine can read again, and lowering
-- it must reach the same fixed point rather than finding new work each time.
stable :: FilePath -> Assertion
stable name = do
  (_, parsed) <- readCorpusFile name
  let once = renderModule (raise (lower parsed))
  reparsed <- expectParse name once
  let twice = renderModule (raise (lower reparsed))
  assertEqual "a second trip changes nothing" once twice

-- | The blocks phi elimination puts on split edges do not reach the output.
--
-- This used to look for the name those blocks were given.  They have no name
-- now — a block is a number — so what is checked is what the name was
-- standing in for: a split block that escaped would be a block the input did
-- not have, and there are never more blocks out than in.
--
-- Not equality, because raising removes detours as well as the ones it made,
-- and a source can arrive with one of its own.
noScaffolding :: FilePath -> Assertion
noScaffolding name = do
  (_, parsed) <- readCorpusFile name
  let blocksIn m =
        [ length (Syntax.definitionBlocks d)
        | Syntax.EDefine d <- Syntax.moduleEntries m
        ]
  let arriving = blocksIn parsed
      leaving = blocksIn (raise (lower parsed))
  assertBool
    ("blocks per function: " <> show arriving <> " in, " <> show leaving <> " out")
    (length arriving == length leaving && and (zipWith (>=) arriving leaving))

-- | The numbering written on the way out.
--
-- No name that arrives is kept, chosen or issued: a name is a local's or a
-- block's identity and nothing else, and identity inside the optimizer is a
-- number.  So the whole sequence is written afresh by LLVM's own rule, which
-- has to get right that one counter serves parameters, blocks and results
-- alike.  A global is the exception, and the only one.
numberingTests :: TestTree
numberingTests =
  testGroup
    "numbering"
    [ -- The point of issuing it rather than carrying it.  LLVM accepts a gap,
      -- so this is not about what it will read back; it is that a number
      -- surviving from the input means nothing after a pass has run.
      testCase "a gap in what arrived is closed" $
        numbered
          ["define i32 @f(i32 %a) {", "  %9 = add i32 %a, 1", "  ret i32 %9", "}"]
          ["define i32 @f(i32 %0) {", "  %2 = add i32 %0, 1", "  ret i32 %2", "}"]
    , -- One counter, so a block and a value can never both be %2.  The entry
      -- block spends a number without printing a label, which is why the
      -- first instruction here is %3 and not %2.
      testCase "blocks and values come from one sequence" $
        numbered
          [ "define i32 @f(i1 %c, i32 %n) {"
          , "start:"
          , "  br i1 %c, label %yes, label %no"
          , "yes:"
          , "  %sum = add i32 %n, 1"
          , "  ret i32 %sum"
          , "no:"
          , "  ret i32 0"
          , "}"
          ]
          [ "define i32 @f(i1 %0, i32 %1) {"
          , "  br i1 %0, label %3, label %5"
          , ""
          , "3:                                                ; preds = %2"
          , "  %4 = add i32 %1, 1"
          , "  ret i32 %4"
          , ""
          , "5:                                                ; preds = %2"
          , "  ret i32 0"
          , "}"
          ]
    , -- A name somebody chose goes the same way as a number, quoted or not.
      -- Nothing in the core could have kept it: what a local is called there
      -- is a number, and there is nowhere for a spelling to have been put.
      testCase "a name somebody chose is not kept either" $
        numbered
          ["define i32 @f(i32 %count) {", "  %\"3\" = add i32 %count, 1", "  ret i32 %\"3\"", "}"]
          ["define i32 @f(i32 %0) {", "  %2 = add i32 %0, 1", "  ret i32 %2", "}"]
    , -- The exception, and the reason it is one: a global's name is how the
      -- rest of the world refers to it, so it is not the optimizer's to
      -- reissue.  A local's name reaches nobody.
      testCase "a global keeps its name" $
        numbered
          [ "@counter = global i32 0"
          , ""
          , "define i32 @f() {"
          , "  %seen = load i32, ptr @counter"
          , "  ret i32 %seen"
          , "}"
          ]
          [ "@counter = global i32 0"
          , ""
          , "define i32 @f() {"
          , "  %1 = load i32, ptr @counter"
          , "  ret i32 %1"
          , "}"
          ]
    , -- The rule being LLVM's own is what makes the trip invisible: what
      -- clang numbered comes back numbered the same, parameters included.
      testCase "what LLVM numbered comes back as it was" $
        let text =
              [ "define i32 @f(i1 %0, i32 %1) {"
              , "  br i1 %0, label %3, label %5"
              , ""
              , "3:                                                ; preds = %2"
              , "  %4 = add i32 %1, 1"
              , "  ret i32 %4"
              , ""
              , "5:                                                ; preds = %2"
              , "  ret i32 0"
              , "}"
              ]
         in numbered text text
    ]
  where
    numbered source expected = do
      parsed <- expectParse "<inline>" (T.unlines source)
      assertEqual
        "the sequence written out"
        (T.unlines expected)
        (renderModule (raise (lower parsed)))

-- | Phi elimination, on the shapes the corpus does not have.
phiTests :: TestTree
phiTests =
  testGroup
    "phi elimination"
    [ -- Phis at the head of a block all happen at once.  These two exchange
      -- their values, so writing them out in order would leave both holding
      -- what the second one had.  A temporary has to break the cycle.
      testCase "an exchange is not written out in order" $ do
        assignments <- assignmentsIn 3 swap
        assertBool
          ("expected a temporary among " <> show assignments)
          (length assignments > 2)
    , testCase "an exchange still assigns both locals" $ do
        assignments <- assignmentsIn 3 swap
        assertBool
          ("expected both phi locals assigned in " <> show assignments)
          (all (`elem` map fst assignments) [Local 3, Local 4])
    , -- An ordinary pair of phis needs no temporary.
      testCase "independent phis are written out as they are" $ do
        assignments <- assignmentsIn 3 independent
        assertEqual "no temporary" 2 (length assignments)
    , testCase "the invariants hold for these too" $ do
        parsed <- expectParse "<inline>" swap
        assertInvariants (functionsIn (lower parsed))
    ]
  where
    swap =
      T.unlines
        [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
        , "entry:"
        , "  br label %loop"
        , ""
        , "loop:"
        , "  %x = phi i32 [ %a, %entry ], [ %y, %loop ]"
        , "  %y = phi i32 [ %b, %entry ], [ %x, %loop ]"
        , "  br i1 %c, label %loop, label %done"
        , ""
        , "done:"
        , "  ret i32 %x"
        , "}"
        ]
    independent =
      T.unlines
        [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
        , "entry:"
        , "  br label %loop"
        , ""
        , "loop:"
        , "  %x = phi i32 [ %a, %entry ], [ %b, %loop ]"
        , "  %y = phi i32 [ %b, %entry ], [ %a, %loop ]"
        , "  br i1 %c, label %loop, label %done"
        , ""
        , "done:"
        , "  ret i32 %x"
        , "}"
        ]

-- | The assignments made on the edge that loops back, which is where the
-- interesting copies are.
--
-- Locals are numbered in the order they are defined: the parameters first,
-- then each result as it was written.  So in both functions below @%x@ is
-- 'Local' 3 and @%y@ is 'Local' 4, after the three parameters.
--
-- Those are the ones in a block the lowering added rather than one the source
-- wrote, and added blocks are told apart by their label: labels are issued in
-- the order blocks were written, so anything numbered past the last written
-- one is a block put on an edge.  The copies on the way in are not these —
-- the entry block has one successor, so they go at the end of it.
assignmentsIn :: Int -> Text -> IO [(Local, TypedValue Local)]
assignmentsIn written source = do
  parsed <- expectParse "<inline>" source
  let blocks = concatMap functionBlocks (functionsIn (lower parsed))
  pure
    [ (name, value)
    | b <- blocks
    , Label n <- [blockLabel b]
    , n >= written
    , Instruction (Just name) (OAssign value) _ <- blockInstructions b
    ]
