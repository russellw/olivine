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
import Olivine.Syntax.Instruction (Store (..))
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value
import Olivine.Syntax.Verify (renderProblem, verify)

coreTests :: IO TestTree
coreTests = do
  names <- corpusFiles
  pure $
    testGroup
      "core"
      [ testGroup
          "every definition reaches the core"
          [testCase name (lowersFully name) | name <- names]
      , -- The corpus is LLVM's own output and holds no comment among its
        -- instructions, so nothing above reaches this.  A hand-written one used
        -- to leave its line unread, and the lowering takes a definition whole:
        -- the entire function stayed out of the core over a line that says
        -- nothing.
        testCase "a comment among the instructions does not stop the lowering" $
          reachesTheCore $
            T.unlines
              [ "define i32 @f(i32 %x) {"
              , "  ; twice what came in"
              , "  %y = add i32 %x, %x ; here it is"
              , "  ret i32 %y"
              , "}"
              ]
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
      , reconstructionTests
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

-- | As 'lowersFully', for a definition written here rather than one of the
-- corpus.
reachesTheCore :: Text -> Assertion
reachesTheCore source = do
  parsed <- expectParse "<inline>" source
  let program = lower parsed
  assertEqual "functions lowered" 1 (length (functionsIn program))
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
    , -- A phi may name its own result as what arrives along an edge: the
      -- value is unchanged that way round.  The assignment that edge wants is
      -- then @%x = %x@, which does nothing — and which reads what it writes,
      -- so ordering it against anything is impossible and the temporary that
      -- breaks a cycle does not help.  Nothing clang writes has this shape;
      -- what does is a loop Olivine's own tail recursion pass wrote, so this
      -- is a module the optimizer could not read back its own output of.
      testCase "a phi naming itself is no assignment at all" $ do
        assignments <- assignmentsIn 4 unchanged
        assertEqual "only the other edge assigns" 1 (length assignments)
    , testCase "the invariants hold with one of those in it" $ do
        parsed <- expectParse "<inline>" unchanged
        assertInvariants (functionsIn (lower parsed))
    , -- An ordinary pair of phis needs no temporary.
      testCase "independent phis are written out as they are" $ do
        assignments <- assignmentsIn 3 independent
        assertEqual "no temporary" 2 (length assignments)
    , testCase "the invariants hold for these too" $ do
        parsed <- expectParse "<inline>" swap
        assertInvariants (functionsIn (lower parsed))
    , -- LLVM asks a phi for one operand per /edge/, not per predecessor
      -- block: a switch with four cases naming one block reaches it four
      -- times, and @llvm-as@ parses a phi with one entry for those four and
      -- its verifier then rejects the module.  Nothing in the corpus wrote
      -- that shape until a switch was added that does.
      testCase "a phi has an operand for each edge, not each block" $
        wellFormed manyCases
    , -- The same, one step removed: the cases arrive through a block that
      -- holds only the value they leave, so what removes it on the way out
      -- has to leave four edges from the switch where it found one from the
      -- detour.
      testCase "and after a detour between them is taken out" $
        wellFormed throughOne
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
    unchanged =
      T.unlines
        [ "define i32 @f(i32 %a, i1 %c) {"
        , "entry:"
        , "  br label %loop"
        , ""
        , "loop:"
        , "  %x = phi i32 [ %a, %entry ], [ %x, %again ], [ 1, %loop ]"
        , "  br i1 %c, label %loop, label %again"
        , ""
        , "again:"
        , "  br i1 %c, label %loop, label %done"
        , ""
        , "done:"
        , "  ret i32 %x"
        , "}"
        ]
    manyCases =
      T.unlines
        [ "define i32 @f(i32 %x) {"
        , "entry:"
        , "  switch i32 %x, label %other ["
        , "    i32 3, label %hit"
        , "    i32 4, label %hit"
        , "    i32 5, label %hit"
        , "  ]"
        , "other:"
        , "  br label %hit"
        , "hit:"
        , "  %r = phi i32 [ 1, %entry ], [ 1, %entry ], [ 1, %entry ], [ 0, %other ]"
        , "  ret i32 %r"
        , "}"
        ]
    throughOne =
      T.unlines
        [ "define i32 @f(i32 %x) {"
        , "entry:"
        , "  switch i32 %x, label %other ["
        , "    i32 3, label %some"
        , "    i32 4, label %some"
        , "    i32 5, label %some"
        , "  ]"
        , "some:"
        , "  br label %hit"
        , "other:"
        , "  br label %hit"
        , "hit:"
        , "  %r = phi i32 [ 1, %some ], [ 0, %other ]"
        , "  ret i32 %r"
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

-- | Putting the phis back, on the shapes that decide what order it has to
-- happen in.
--
-- A value is carried forwards by one walk over the blocks, so the walk has to
-- reach a block after the blocks control arrives from.  Reading the order the
-- blocks were written in as that order was a bug: LLVM puts no requirement on
-- it, and clang at @-O1@ writes a block before the only block that branches to
-- it, on which reconstruction carried a value to the block before the block it
-- came from and it arrived as nothing.
--
-- What both cases check is that every local the output reads is a local the
-- output assigns, which is what the syntax verifier already knows how to say.
-- Stated that way rather than by pinning the text, because the numbering is not
-- what is being tested and moving a block moves all of it.
reconstructionTests :: TestTree
reconstructionTests =
  testGroup
    "putting the phis back"
    [ testCase "a block written before the one it is reached from" $
        wellFormed outOfOrder
    , -- The same function with the blocks in the order the walk wants.  It
      -- always worked; it is here so that the case above is known to be about
      -- the order and not about the function.
      testCase "the same function with its blocks in walk order" $
        wellFormed inOrder
    , -- Every phi here has 0 on every edge, so reconstruction collapses the
      -- lot and the use gets the value.  Before the fix it got the name of a
      -- local that no longer existed.
      testCase "the value still arrives" $ do
        text <- raised outOfOrder
        assertBool
          ("expected the value to arrive in " <> T.unpack text)
          ("ret i32 0" `T.isInfixOf` text)
    , -- The other way a block can have nothing arriving at it.  Nothing
      -- reaches it, so nothing was ever assigned on the way, and a local whose
      -- name this pass takes away has no name left to be read by: what it
      -- holds there is poison, which is also what it holds along an edge that
      -- brings it nothing.
      testCase "a value read in a block nothing reaches" $
        wellFormed orphaned
    , testCase "and it reads as poison" $ do
        text <- raised orphaned
        assertBool
          ("expected poison in " <> T.unpack text)
          ("ret i32 poison" `T.isInfixOf` text)
    , -- Where an instruction stands is a position and not the instruction
      -- itself.  Two in one block can be written identically — one naming a
      -- result is told apart by the local it names, but a store names none —
      -- and the local they read can be assigned again in between, which is what
      -- makes the second one mean something the first did not.
      testCase "two instructions in one block that are written identically" $ do
        text <- raisedFrom (twiceStored 1 2)
        assertBool
          ("expected both values stored in " <> T.unpack text)
          ("store i32 1" `T.isInfixOf` text && "store i32 2" `T.isInfixOf` text)
    , -- The order a phi's operands come back in has to be the same order the
      -- second time, and what makes that a question is the block being removed
      -- here.  On the way in the copy goes in the source's own forwarding block;
      -- on the way out that block is empty and taken away, and the operand is
      -- renamed to the block above it, which stands somewhere else.  The trip
      -- after this one has no forwarding block to use and makes one instead, in
      -- the position made blocks go, so the two trips agree about the order only
      -- because 'Olivine.Core.Phi.inWrittenOrder' settles it.  The corpus has
      -- this shape as well, in @pick-O0.ll@, which is where it was found.
      testCase "a phi whose block the raising takes away comes back the same twice" $
        aFixedPoint absorbed
    ]
  where
    -- %late is written before %mid, which is the only block that branches to
    -- it, so a walk in the written order reaches %late with nothing.  %out
    -- then reads %y, which is a phi in %mid, and %y is a local the lowering
    -- assigns rather than one the output can name.
    outOfOrder =
      T.unlines
        [ "define i32 @f(i1 %c) {"
        , "entry:"
        , "  br label %head"
        , ""
        , "late:"
        , "  br i1 %c, label %out, label %head"
        , ""
        , "head:"
        , "  %x = phi i32 [ 0, %entry ], [ %y, %late ]"
        , "  br label %mid"
        , ""
        , "mid:"
        , "  %y = phi i32 [ %x, %head ]"
        , "  br label %late"
        , ""
        , "out:"
        , "  ret i32 %y"
        , "}"
        ]
    inOrder =
      T.unlines
        [ "define i32 @f(i1 %c) {"
        , "entry:"
        , "  br label %head"
        , ""
        , "head:"
        , "  %x = phi i32 [ 0, %entry ], [ %y, %late ]"
        , "  br label %mid"
        , ""
        , "mid:"
        , "  %y = phi i32 [ %x, %head ]"
        , "  br label %late"
        , ""
        , "late:"
        , "  br i1 %c, label %out, label %head"
        , ""
        , "out:"
        , "  ret i32 %y"
        , "}"
        ]
    -- @b ? a \/ b : -1@ as clang writes it at @-O0@: the constant side is an
    -- empty block, standing after the side that computes rather than before it.
    absorbed =
      T.unlines
        [ "define i32 @f(i32 %a, i32 %b) {"
        , "entry:"
        , "  %c = icmp ne i32 %b, 0"
        , "  br i1 %c, label %divide, label %spare"
        , ""
        , "divide:"
        , "  %d = sdiv i32 %a, %b"
        , "  br label %join"
        , ""
        , "spare:"
        , "  br label %join"
        , ""
        , "join:"
        , "  %z = phi i32 [ %d, %divide ], [ -1, %spare ]"
        , "  ret i32 %z"
        , "}"
        ]
    orphaned =
      T.unlines
        [ "define i32 @f() {"
        , "entry:"
        , "  br label %join"
        , ""
        , "arm:"
        , "  br label %join"
        , ""
        , "join:"
        , "  %x = phi i32 [ 0, %entry ], [ 1, %arm ]"
        , "  ret i32 %x"
        , ""
        , "orphan:"
        , "  ret i32 %x"
        , "}"
        ]

-- | Raising leaves a module with nothing wrong with it — in particular, with
-- no local read that nothing assigns.
wellFormed :: Text -> Assertion
wellFormed source = do
  parsed <- expectParse "<inline>" source
  assertEqual
    "nothing wrong with what came out"
    []
    (map (T.unpack . renderProblem) (verify (raise (lower parsed))))

raised :: Text -> IO Text
raised source = renderModule . raise . lower <$> expectParse "<inline>" source

raisedFrom :: (Function -> Function) -> IO Text
raisedFrom rewrite = do
  parsed <- expectParse "<inline>" storing
  let program = lower parsed
  pure (renderModule (raise program {programEntries = map entry (programEntries program)}))
  where
    entry (EFunction f) = EFunction (rewrite f)
    entry other = other

-- | A function whose one block is replaced by two stores of the same local,
-- with the local assigned in between.  The two stores are equal as values.
twiceStored :: Integer -> Integer -> Function -> Function
twiceStored first second f =
  f
    { functionBlocks =
        [ b
          { blockInstructions =
              [ assigned first
              , store
              , assigned second
              , store
              ]
          }
        | b <- functionBlocks f
        ]
    }
  where
    held = Local 9
    pointer = case functionParameters f of
      p : _ -> p
      [] -> Local 0
    assigned n =
      Instruction (Just held) (OAssign (TypedValue (TInteger 32) (VInteger n))) []
    store =
      Instruction
        Nothing
        ( OStore
            Store
              { storeVolatile = False
              , storeValue = TypedValue (TInteger 32) (VLocal held)
              , storePointer = TypedValue (TPointer Nothing) (VLocal pointer)
              , storeAlignment = Nothing
              }
        )
        []

-- | One block, one store, one parameter to store through.
storing :: Text
storing =
  T.unlines
    [ "define void @f(ptr %p) {"
    , "entry:"
    , "  store i32 0, ptr %p"
    , "  ret void"
    , "}"
    ]

-- | That the trip through the core is one, on a definition written here rather
-- than one of the corpus.  'stable' asks the same of every file in it.
aFixedPoint :: Text -> Assertion
aFixedPoint source = do
  once <- raised source
  reparsed <- expectParse "<inline>" once
  assertEqual "a second trip changes nothing" once (renderModule (raise (lower reparsed)))

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
