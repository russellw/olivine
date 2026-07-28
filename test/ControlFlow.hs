-- | The control flow pass.
--
-- Two things are checked separately: what a branch comes to, which is
-- arithmetic on the terminator alone, and what becomes of the blocks it stops
-- reaching, which is the reason the arithmetic is worth doing.
module ControlFlow (controlFlowTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.ControlFlow (foldTerminator, simplifyControlFlow)
import Olivine.Core.Program
import Olivine.Syntax.Instruction
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name
import Olivine.Syntax.Type
import Olivine.Syntax.Value

controlFlowTests :: TestTree
controlFlowTests =
  testGroup
    "control flow"
    [ testGroup
        "what a branch comes to"
        [ testCase "a branch on true" $
            foldTerminator (condBr (VBoolean True) "a" "b") @?= Just (OBr (label "a"))
        , testCase "a branch on false" $
            foldTerminator (condBr (VBoolean False) "a" "b") @?= Just (OBr (label "b"))
        , -- An i1 written as a number is the same value spelled differently.
          testCase "a branch on a number" $
            foldTerminator (condBr (VInteger 1) "a" "b") @?= Just (OBr (label "a"))
        , -- This one needs no constant: it goes there either way.
          testCase "a branch whose arms agree" $
            foldTerminator (condBr (VLocal (Name Bare "c")) "a" "a") @?= Just (OBr (label "a"))
        , testCase "a switch on a known value" $
            foldTerminator (switch (VInteger 2)) @?= Just (OBr (label "two"))
        , testCase "a switch on a value no case matches" $
            foldTerminator (switch (VInteger 9)) @?= Just (OBr (label "otherwise"))
        , -- The same byte written two ways, which the widths make equal.
          testCase "a switch case spelled as the other sign" $
            foldTerminator (switchOn (TInteger 8) (VInteger (-1)) [(VInteger 255, "hit")])
              @?= Just (OBr (label "hit"))
        , testCase "a switch whose cases all name the default" $
            foldTerminator (switchOn (TInteger 8) (VLocal (Name Bare "x")) [(VInteger 1, "otherwise")])
              @?= Just (OBr (label "otherwise"))
        , testCase "an indirect branch with one destination" $
            foldTerminator (OIndirectBr pointer [label "a"]) @?= Just (OBr (label "a"))
        ]
    , testGroup
        "where it stops"
        [ testCase "a branch on a local" $
            foldTerminator (condBr (VLocal (Name Bare "c")) "a" "b") @?= Nothing
        , -- Branching on poison is undefined, and LLVM may treat it as
          -- unreachable.  Collecting on that is a decision this pass does not
          -- make: it folds branches whose value it knows.
          testCase "a branch on poison" $
            foldTerminator (condBr VPoison "a" "b") @?= Nothing
        , testCase "a switch on a local" $
            foldTerminator (switch (VLocal (Name Bare "x"))) @?= Nothing
        , testCase "an indirect branch with a choice to make" $
            foldTerminator (OIndirectBr pointer [label "a", label "b"]) @?= Nothing
        , testCase "a return" $ foldTerminator (ORet Nothing) @?= Nothing
        ]
    , testGroup
        "what the blocks come to"
        [ -- The arm not taken goes, and what is left of the branch is not a
          -- branch, so the arm that was taken is merged into the block above.
          testCase "the arm not taken goes" $ do
            blocks <- blocksOf decided
            assertEqual "one block is left" [Just (label "entry")] blocks
        , testCase "and the taken arm keeps its instructions" $ do
            terminators <- terminatorsOf decided
            assertEqual
              "ending in what the taken arm ended in"
              [ORet (Just (TypedValue (TInteger 32) (VInteger 0)))]
              terminators
        , -- The point of the pass: unreachable blocks take their calls with
          -- them, which is what lets a later pass see the callee is dead.
          testCase "and takes what it called with it" $ do
            calls <- calledIn decided
            assertEqual "nothing calls the unreached function" [] calls
        , -- A loop nothing enters is unreachable however many blocks branch
          -- to it, which is why this walks from the entry rather than
          -- counting predecessors.
          testCase "a loop nothing enters goes" $ do
            blocks <- blocksOf orphaned
            assertEqual "the loop is not kept alive by itself" [Just (label "entry")] blocks
        , -- The entry block is where the function starts, so it stays even
          -- when it does nothing but branch.  LLVM forbids an entry block
          -- predecessors, and the block this one forwards to has one.
          testCase "an entry block that only forwards stays" $ do
            blocks <- blocksOf forwarding
            assertEqual "the entry block survives" [Just (label "entry"), Just (label "body")] blocks
        , testCase "a function whose branches decide nothing is left alone" $ do
            parsed <- expectParse "<inline>" undecided
            let lowered = lower parsed
            assertEqual "unchanged" lowered (simplifyControlFlow lowered)
        ]
    , testGroup
        "what is merged"
        [ -- A chain of blocks each reached from one place, by a block that
          -- goes nowhere else, is one block written as several.
          testCase "a chain becomes one block" $ do
            blocks <- blocksOf chain
            assertEqual "all of it merged into the entry" [Just (label "entry")] blocks
        , testCase "in the order the chain ran" $ do
            results <- resultsOf chain
            assertEqual
              "each block's instructions after the ones above it"
              [Just (Name Bare "a"), Just (Name Bare "b"), Just (Name Bare "c")]
              results
        , -- Merging is about the edge, not about how little a block holds:
          -- two ways in means the block below is not the rest of the one
          -- above, whatever either of them does.
          testCase "a block reached from two places stays" $ do
            blocks <- blocksOf rejoining
            assertEqual
              "the join survives"
              [Just (label "entry"), Just (label "yes"), Just (label "join")]
              blocks
        , -- And nor is it, when the block above can go elsewhere instead.
          testCase "a block below a real branch stays" $ do
            blocks <- blocksOf undecided
            assertEqual
              "both arms survive"
              [Just (label "entry"), Just (label "yes"), Just (label "no")]
              blocks
        , testCase "a block that branches to itself is not merged into itself" $ do
            blocks <- blocksOf forwarding
            assertEqual "the loop survives" [Just (label "entry"), Just (label "body")] blocks
        ]
    ]
  where
    label = Name Bare
    pointer = TypedValue (TPointer Nothing) (VLocal (Name Bare "p"))
    condBr condition true false =
      OCondBr (TypedValue (TInteger 1) condition) (label true) (label false)
    switch value =
      switchOn (TInteger 32) value [(VInteger 1, "one"), (VInteger 2, "two")]
    switchOn t value cases =
      OSwitch
        (TypedValue t value)
        (label "otherwise")
        [(TypedValue t v, label l) | (v, l) <- cases]

-- | A condition folding to @false@, an arm that then goes, and the only call
-- to a function in it.
decided :: Text
decided =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br i1 false, label %yes, label %no"
    , "yes:"
    , "  %a = call i32 @other(i32 %n)"
    , "  ret i32 %a"
    , "no:"
    , "  ret i32 0"
    , "}"
    ]

-- | A loop with no way in.
orphaned :: Text
orphaned =
  T.unlines
    [ "define void @f() {"
    , "entry:"
    , "  ret void"
    , "loop:"
    , "  br label %body"
    , "body:"
    , "  br label %loop"
    , "}"
    ]

-- | An entry block that does nothing but branch, to a block that is branched
-- to from elsewhere as well.
forwarding :: Text
forwarding =
  T.unlines
    [ "define void @f() {"
    , "entry:"
    , "  br label %body"
    , "body:"
    , "  br label %body"
    , "}"
    ]

-- | Blocks in a row, each reached only from the one before it.
chain :: Text
chain =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %a = add i32 %n, 1"
    , "  br label %middle"
    , "middle:"
    , "  %b = mul i32 %a, 2"
    , "  br label %last"
    , "last:"
    , "  %c = sub i32 %b, 3"
    , "  ret i32 %c"
    , "}"
    ]

-- | A block both arms of a branch reach.
--
-- The arm has to do something, or it would be a detour and the branch would
-- go both ways to one place — which really does collapse to a single block,
-- and would be testing the opposite of what this is for.
rejoining :: Text
rejoining =
  T.unlines
    [ "define i32 @f(i1 %c, i32 %n) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %join"
    , "yes:"
    , "  %d = add i32 %n, 1"
    , "  br label %join"
    , "join:"
    , "  ret i32 0"
    , "}"
    ]

undecided :: Text
undecided =
  T.unlines
    [ "define i32 @f(i1 %c, i32 %n) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  ret i32 %n"
    , "no:"
    , "  ret i32 0"
    , "}"
    ]

blocksOf :: Text -> IO [Maybe Name]
blocksOf source = do
  simplified <- simplify source
  pure [blockLabel b | f <- functionsIn simplified, b <- functionBlocks f]

-- | What each surviving instruction assigns to, in order.
resultsOf :: Text -> IO [Maybe Name]
resultsOf source = do
  simplified <- simplify source
  pure
    [ instructionResult i
    | f <- functionsIn simplified
    , b <- functionBlocks f
    , i <- blockInstructions b
    ]

terminatorsOf :: Text -> IO [Syntax.Operation]
terminatorsOf source = do
  simplified <- simplify source
  pure
    [ terminatorOperation (blockTerminator b)
    | f <- functionsIn simplified
    , b <- functionBlocks f
    ]

-- | Every function still called, by name.
calledIn :: Text -> IO [Name]
calledIn source = do
  simplified <- simplify source
  pure
    [ name
    | f <- functionsIn simplified
    , b <- functionBlocks f
    , i <- blockInstructions b
    , Perform (OCall c) <- [instructionOperation i]
    , VGlobal name <- [callCallee c]
    ]

simplify :: Text -> IO Program
simplify source = do
  parsed <- expectParse "<inline>" source
  pure (simplifyControlFlow (lower parsed))
