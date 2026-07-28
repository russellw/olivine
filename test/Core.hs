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
import Olivine.Core.Lower (lower)
import Olivine.Core.Program
import Olivine.Core.Raise (raise)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Instruction
import Olivine.Syntax.Name
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

assertInvariants :: [Function] -> Assertion
assertInvariants functions = do
  assertEqual
    "the terminator slot holds a terminator"
    []
    [t | b <- blocks, let t = terminatorOperation (blockTerminator b), not (isTerminator t)]
  assertEqual
    "nothing before the terminator is one"
    []
    [op | b <- blocks, i <- blockInstructions b, let op = perform i, any isTerminator op]
  assertEqual "no phi survives lowering" [] [() | b <- blocks, i <- blockInstructions b, isPhi i]
  -- Assignments may only sit in a block with a single successor.  A block
  -- that branches two ways would run them on the way to both, which is what
  -- splitting the edge exists to prevent, so this is the check that the
  -- splitting actually happened.
  assertEqual
    "assignments only where there is one way out"
    []
    [ ()
    | b <- blocks
    , length (targetsOf b) > 1
    , Instruction _ (Assign _) _ <- blockInstructions b
    ]
  where
    blocks = concatMap functionBlocks functions
    perform i = case instructionOperation i of Perform op -> [op]; Assign _ -> []
    isPhi i = case instructionOperation i of Perform (OPhi _) -> True; _ -> False
    targetsOf b = case terminatorOperation (blockTerminator b) of
      OBr t -> [t]
      OCondBr _ a c -> [a, c]
      OSwitch _ d cases -> d : map snd cases
      OIndirectBr _ ds -> ds
      _ -> []

-- | What comes back out must be a module Olivine can read again, and lowering
-- it must reach the same fixed point rather than finding new work each time.
stable :: FilePath -> Assertion
stable name = do
  (_, parsed) <- readCorpusFile name
  let once = renderModule (raise (lower parsed))
  reparsed <- expectParse name once
  let twice = renderModule (raise (lower reparsed))
  assertEqual "a second trip changes nothing" once twice

-- | Nothing Olivine invented on the way through may appear in what it writes.
--
-- Phi elimination puts a block on each split edge and names it; reconstructing
-- single assignment fills those blocks' assignments into phis, leaving nothing
-- but a branch; removing the forwarding blocks then takes them out again.  If
-- any survives, one of those three steps has not done its part, and the module
-- would carry a block that was never in the program.
noScaffolding :: FilePath -> Assertion
noScaffolding name = do
  (_, parsed) <- readCorpusFile name
  let written = renderModule (raise (lower parsed))
  assertEqual
    "blocks put on split edges"
    []
    [line | line <- T.lines written, "olivine.edge" `T.isInfixOf` line]

-- | Phi elimination, on the shapes the corpus does not have.
-- | The numbering written on the way out.
--
-- Nothing that arrives is kept: LLVM's numbers stop being true as soon as a
-- pass removes an instruction or moves code, so the sequence is issued afresh
-- by LLVM's own rule.  What that rule has to get right is that one counter
-- serves parameters, blocks and values alike.
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
          ["define i32 @f(i32 %a) {", "  %1 = add i32 %a, 1", "  ret i32 %1", "}"]
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
          [ "define i32 @f(i1 %c, i32 %n) {"
          , "  br i1 %c, label %1, label %2"
          , ""
          , "1:                                                ; preds = %0"
          , "  %sum = add i32 %n, 1"
          , "  ret i32 %sum"
          , ""
          , "2:                                                ; preds = %0"
          , "  ret i32 0"
          , "}"
          ]
    , -- A name somebody chose is not a number somebody issued, and survives.
      -- Whether it was quoted is what tells the two apart, which is why %"3"
      -- is a name and %3 is not.
      testCase "a name is left where it is" $
        numbered
          ["define i32 @f(i32 %a) {", "  %\"3\" = add i32 %a, 1", "  ret i32 %\"3\"", "}"]
          ["define i32 @f(i32 %a) {", "  %\"3\" = add i32 %a, 1", "  ret i32 %\"3\"", "}"]
    , -- The rule being LLVM's own is what makes the trip invisible: what
      -- clang numbered comes back numbered the same, parameters included.
      testCase "what LLVM numbered comes back as it was" $
        let text =
              [ "define i32 @f(i1 %0, i32 %1) {"
              , "  br i1 %0, label %3, label %4"
              , ""
              , "3:                                                ; preds = %2"
              , "  %x = add i32 %1, 1"
              , "  ret i32 %x"
              , ""
              , "4:                                                ; preds = %2"
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
          ("expected x and y assigned in " <> show assignments)
          (all (`elem` map fst assignments) [Name Bare "x", Name Bare "y"])
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
-- Those are the ones in a block the lowering added rather than one the source
-- wrote, and added blocks are told apart by their label: labels are issued in
-- the order blocks were written, so anything numbered past the last written
-- one is a block put on an edge.  The copies on the way in are not these —
-- the entry block has one successor, so they go at the end of it.
assignmentsIn :: Int -> Text -> IO [(Name, TypedValue)]
assignmentsIn written source = do
  parsed <- expectParse "<inline>" source
  let blocks = concatMap functionBlocks (functionsIn (lower parsed))
  pure
    [ (name, value)
    | b <- blocks
    , Label n <- [blockLabel b]
    , n >= written
    , Instruction (Just name) (Assign value) _ <- blockInstructions b
    ]
