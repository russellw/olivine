-- | The control flow pass.
--
-- Two things are checked separately: what a branch comes to, which is
-- arithmetic on the terminator alone, and what becomes of the blocks it stops
-- reaching, which is the reason the arithmetic is worth doing.
module ControlFlow (controlFlowTests) where

import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Lower (lower)
import Olivine.Core.Instruction
import Olivine.Core.Pass.ControlFlow (foldTerminator, simplifyControlFlow)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Call (..))
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
            folds (condBr (VBoolean True) a b) @?= Just (Br a)
        , testCase "a branch on false" $
            folds (condBr (VBoolean False) a b) @?= Just (Br b)
        , -- An i1 written as a number is the same value spelled differently.
          testCase "a branch on a number" $
            folds (condBr (VInteger 1) a b) @?= Just (Br a)
        , -- This one needs no constant: it goes there either way.
          testCase "a branch whose arms agree" $
            folds (condBr (VLocal (Local 0)) a a) @?= Just (Br a)
        , testCase "a switch on a known value" $
            folds (switch (VInteger 2)) @?= Just (Br two)
        , testCase "a switch on a value no case matches" $
            folds (switch (VInteger 9)) @?= Just (Br fallback)
        , -- The same byte written two ways, which the widths make equal.
          testCase "a switch case spelled as the other sign" $
            folds (switchOn (TInteger 8) (VInteger (-1)) [(VInteger 255, hit)])
              @?= Just (Br hit)
        , testCase "a switch whose cases all name the default" $
            folds (switchOn (TInteger 8) (VLocal (Local 1)) [(VInteger 1, fallback)])
              @?= Just (Br fallback)
        , testCase "an indirect branch with one destination" $
            folds (IndirectBr pointer [a]) @?= Just (Br a)
        ]
    , testGroup
        "where it stops"
        [ testCase "a branch on a local" $
            folds (condBr (VLocal (Local 0)) a b) @?= Nothing
        , -- Branching on poison is undefined, and LLVM may treat it as
          -- unreachable.  Collecting on that is a decision this pass does not
          -- make: it folds branches whose value it knows.
          testCase "a branch on poison" $
            folds (condBr VPoison a b) @?= Nothing
        , testCase "a switch on a local" $
            folds (switch (VLocal (Local 1))) @?= Nothing
        , testCase "an indirect branch with a choice to make" $
            folds (IndirectBr pointer [a, b]) @?= Nothing
        , testCase "a return" $ folds (Ret Nothing) @?= Nothing
        ]
    , testGroup
        "what the blocks come to"
        [ -- The arm not taken goes, and what is left of the branch is not a
          -- branch, so the arm that was taken is merged into the block above.
          testCase "the arm not taken goes" $ do
            blocks <- blocksOf decided
            assertEqual "one block is left" [Label 0] blocks
        , testCase "and the taken arm keeps its instructions" $ do
            terminators <- terminatorsOf decided
            assertEqual
              "ending in what the taken arm ended in"
              [Ret (Just (TypedValue (TInteger 32) (VInteger 0)))]
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
            assertEqual "the loop is not kept alive by itself" [Label 0] blocks
        , -- The entry block is where the function starts, so it stays even
          -- when it does nothing but branch.  LLVM forbids an entry block
          -- predecessors, and the block this one forwards to has one.
          testCase "an entry block that only forwards stays" $ do
            blocks <- blocksOf forwarding
            assertEqual "the entry block survives" [Label 0, Label 1] blocks
        , testCase "a function whose branches decide nothing is left alone" $ do
            parsed <- expectParse "<inline>" undecided
            let lowered = lower parsed
            assertEqual "unchanged" lowered (simplifyControlFlow lowered)
        ]
    , testGroup
        "an invoke that cannot throw"
        [ -- The unwind edge cannot be taken, so the invoke is a call and the
          -- block below it is the rest of this one.  What that leaves is the
          -- landing pad, which nothing now reaches.
          testCase "becomes a call" $ do
            calls <- map nameText <$> calledIn cannotThrow
            assertEqual "an instruction, not a terminator" ["safe"] calls
        , testCase "and takes the landing pad with it" $ do
            blocks <- blocksOf cannotThrow
            assertEqual "one block is left" [Label 0] blocks
        , testCase "and what followed it is the rest of the block" $ do
            terminators <- terminatorsOf cannotThrow
            assertEqual "ending where the invoke returned to" [Ret Nothing] terminators
        , -- An invoke's result arrives only along the normal edge; an
          -- instruction's is in hand for the rest of the block.  So the
          -- addition below the invoke reads what the call assigns, in one
          -- block, which is the whole point of the widening.
          testCase "and its result is read below it" $ do
            reads' <- operandsOf withResult
            assertEqual
              "the call reads the parameter and the add reads the call"
              [[Local 0], [Local 1]]
              reads'
        , -- A callee that says nothing about unwinding may unwind, and an
          -- attribute list is a set of promises rather than a description.
          testCase "a callee that may throw is left alone" $ do
            parsed <- expectParse "<inline>" mayThrow
            let lowered = lower parsed
            assertEqual "unchanged" lowered (simplifyControlFlow lowered)
        , -- Two invokes reaching one pad, only one of which may be made plain:
          -- what decides the pad's fate is whether anything still throws to
          -- it, so it stays and the reachability walk is what says so.
          testCase "a pad another invoke still reaches stays" $ do
            calls <- map nameText <$> calledIn shared
            assertEqual "only the safe one became a call" ["safe"] calls
        , testCase "and the pad is still there to be reached" $ do
            blocks <- blocksOf shared
            assertEqual "the pad and the block that returns" 3 (length blocks)
        ]
    , testGroup
        "a block that only assigns"
        [ -- In the core a phi is assignments in the blocks above, so a block whose
          -- only content is the phi of the block below it holds nothing but
          -- copies.  Putting them where control came from leaves a detour, and
          -- what goes with the block is a phi: two phis deciding one value, one
          -- here and one below, become the one below.
          testCase "goes, and its copies go up" $ do
            blocks <- blocksOf carrying
            assertEqual "the block in the middle is gone" [Label 0, Label 1, Label 2, Label 3, Label 5, Label 6] blocks
        , testCase "and each way in makes them" $ do
            shapes <- shapesIn carrying
            assertEqual
              "both arms end with the copy the middle block made"
              [[], [], ["add", "copy", "copy"], ["add", "copy", "copy"], ["add", "copy"], []]
              shapes
        , -- The copies would be made on the other path too, and splitting the
          -- edge to stop that is a block put back for a block taken away.
          testCase "a way in that could go elsewhere is refused" $ unchanged elsewhere
        , -- Control can arrive at a block whose address is taken without any
          -- branch here saying so, and such an arrival would find the copies gone.
          testCase "a block whose address is taken is refused" $ do
            shapes <- shapesIn addressed
            assertEqual
              "the copy stays where the address points"
              [[], ["add", "copy"], ["add", "copy"], ["copy"]]
              shapes
        ]
    , testGroup
        "a branch the block above has settled"
        [ -- Short-circuit @&&@: one side leaves the answer false and joins the
          -- other at a block that branches on it, so the edge from that side has
          -- no decision left on it.  The block above settled the condition, so it
          -- goes straight where the branch would have sent it.
          -- The edge from the left side is the critical one, so phi elimination
          -- gave it a block of its own — label 5, holding the assignment of
          -- @false@ — and that is the block the threading is done from.  What is
          -- left of the test then has one way in and is merged into the right
          -- side, which is label 1.
          testCase "goes straight where it would have gone" $ do
            edges <- edgesIn shortCircuit
            assertEqual
              "the side that settled it reaches the answer without the test"
              [ (Label 0, [Label 1, Label 5])
              , (Label 5, [Label 4])
              , (Label 1, [Label 3, Label 4])
              , (Label 3, [])
              , (Label 4, [])
              ]
              edges
        , -- Control sent past a block skips what is in it, so there has to be
          -- nothing in it to skip.
          testCase "a block with something in it is not passed" $ unchanged occupied
        , testCase "a condition the block above did not settle is refused" $
            unchanged undetermined
        ]
    , testGroup
        "what is merged"
        [ -- A chain of blocks each reached from one place, by a block that
          -- goes nowhere else, is one block written as several.
          testCase "a chain becomes one block" $ do
            blocks <- blocksOf chain
            assertEqual "all of it merged into the entry" [Label 0] blocks
        , -- Locals are numbered as they are defined, the one parameter
          -- first, so %a %b %c are 1 2 3 and the order is the chain's.
          testCase "in the order the chain ran" $ do
            results <- resultsOf chain
            assertEqual
              "each block's instructions after the ones above it"
              [Just (Local 1), Just (Local 2), Just (Local 3)]
              results
        , -- Merging is about the edge, not about how little a block holds:
          -- two ways in means the block below is not the rest of the one
          -- above, whatever either of them does.
          testCase "a block reached from two places stays" $ do
            blocks <- blocksOf rejoining
            assertEqual "the join survives" [Label 0, Label 1, Label 2] blocks
        , -- And nor is it, when the block above can go elsewhere instead.
          testCase "a block below a real branch stays" $ do
            blocks <- blocksOf undecided
            assertEqual "both arms survive" [Label 0, Label 1, Label 2] blocks
        , testCase "a block that branches to itself is not merged into itself" $ do
            blocks <- blocksOf forwarding
            assertEqual "the loop survives" [Label 0, Label 1] blocks
        ]
    ]
  where
    -- A destination is a number in the core, so these stand for the blocks
    -- the cases used to name.  What a local is called is still a name here,
    -- which is the parameter doing its job: these cases care about neither.
    a = Label 1
    b = Label 2
    fallback = Label 3
    one = Label 4
    two = Label 5
    hit = Label 6
    pointer = TypedValue (TPointer Nothing) (VLocal (Local 2))
    condBr condition = CondBr (TypedValue (TInteger 1) condition)
    switch value =
      switchOn (TInteger 32) value [(VInteger 1, one), (VInteger 2, two)]
    switchOn t value cases =
      Switch (TypedValue t value) fallback [(TypedValue t v, l) | (v, l) <- cases]

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

-- | An invoke of a callee that promises not to throw.
--
-- The @nounwind@ is on the declaration, which is where clang puts it and where
-- 'Olivine.Core.Effects' reads it from whether or not a body is here to read.
cannotThrow :: Text
cannotThrow =
  T.unlines
    [ "declare void @safe() nounwind"
    , "declare i32 @personality(...)"
    , "define void @f() personality ptr @personality {"
    , "entry:"
    , "  invoke void @safe() to label %next unwind label %pad"
    , "next:"
    , "  ret void"
    , "pad:"
    , "  %e = landingpad { ptr, i32 } cleanup"
    , "  resume { ptr, i32 } %e"
    , "}"
    ]

-- | The same, assigning a result that is read after the call returns.
withResult :: Text
withResult =
  T.unlines
    [ "declare i32 @safeval(i32) nounwind"
    , "declare i32 @personality(...)"
    , "define i32 @f(i32 %n) personality ptr @personality {"
    , "entry:"
    , "  %r = invoke i32 @safeval(i32 %n) to label %next unwind label %pad"
    , "next:"
    , "  %s = add i32 %r, 1"
    , "  ret i32 %s"
    , "pad:"
    , "  %e = landingpad { ptr, i32 } cleanup"
    , "  resume { ptr, i32 } %e"
    , "}"
    ]

-- | An invoke of a callee that promises nothing.
mayThrow :: Text
mayThrow =
  T.unlines
    [ "declare void @risky()"
    , "declare i32 @personality(...)"
    , "define void @f() personality ptr @personality {"
    , "entry:"
    , "  invoke void @risky() to label %next unwind label %pad"
    , "next:"
    , "  ret void"
    , "pad:"
    , "  %e = landingpad { ptr, i32 } cleanup"
    , "  resume { ptr, i32 } %e"
    , "}"
    ]

-- | One landing pad, two invokes throwing to it, one of which cannot.
shared :: Text
shared =
  T.unlines
    [ "declare void @safe() nounwind"
    , "declare void @risky()"
    , "declare i32 @personality(...)"
    , "define void @f() personality ptr @personality {"
    , "entry:"
    , "  invoke void @safe() to label %mid unwind label %pad"
    , "mid:"
    , "  invoke void @risky() to label %next unwind label %pad"
    , "next:"
    , "  ret void"
    , "pad:"
    , "  %e = landingpad { ptr, i32 } cleanup"
    , "  resume { ptr, i32 } %e"
    , "}"
    ]

-- | A block whose only content is the phi of the block below it.
--
-- Both arms reach it by an unconditional branch, so the copy it holds can stand
-- at the end of each of them.
carrying :: Text
carrying =
  T.unlines
    [ "define i32 @f(i1 %c, i1 %d, i32 %x, i32 %y, i32 %z) {"
    , "entry:"
    , "  br i1 %c, label %head, label %other"
    , "head:"
    , "  br i1 %d, label %a, label %b"
    , "a:"
    , "  %u = add i32 %x, 1"
    , "  br label %mid"
    , "b:"
    , "  %v = add i32 %y, 1"
    , "  br label %mid"
    , "mid:"
    , "  %m = phi i32 [ %u, %a ], [ %v, %b ]"
    , "  br label %join"
    , "other:"
    , "  %w = add i32 %z, 1"
    , "  br label %join"
    , "join:"
    , "  %r = phi i32 [ %m, %mid ], [ %w, %other ]"
    , "  ret i32 %r"
    , "}"
    ]

-- | The same, where the one way in can go somewhere else instead.
elsewhere :: Text
elsewhere =
  T.unlines
    [ "define i32 @f(i1 %d, i32 %x, i32 %z) {"
    , "entry:"
    , "  %u = add i32 %x, 1"
    , "  br i1 %d, label %mid, label %other"
    , "mid:"
    , "  br label %join"
    , "other:"
    , "  %w = add i32 %z, 1"
    , "  br label %join"
    , "join:"
    , "  %r = phi i32 [ %u, %mid ], [ %w, %other ]"
    , "  ret i32 %r"
    , "}"
    ]

-- | A block that only assigns, and something holding its address.
addressed :: Text
addressed =
  T.unlines
    [ "@target = global ptr blockaddress(@f, %mid)"
    , "define i32 @f(i1 %d, i32 %x, i32 %y, i32 %z) {"
    , "entry:"
    , "  br i1 %d, label %a, label %b"
    , "a:"
    , "  %u = add i32 %x, 1"
    , "  br label %mid"
    , "b:"
    , "  %v = add i32 %y, 1"
    , "  br label %mid"
    , "mid:"
    , "  %m = phi i32 [ %u, %a ], [ %v, %b ]"
    , "  br label %join"
    , "join:"
    , "  %r = phi i32 [ %m, %mid ]"
    , "  ret i32 %r"
    , "}"
    ]

-- | What @c && e@ becomes: the left side leaves @false@ and joins the right at a
-- block that branches on the answer.
shortCircuit :: Text
shortCircuit =
  T.unlines
    [ "define i32 @f(i1 %c, i1 %e) {"
    , "entry:"
    , "  br i1 %c, label %rhs, label %test"
    , "rhs:"
    , "  br label %test"
    , "test:"
    , "  %p = phi i1 [ false, %entry ], [ %e, %rhs ]"
    , "  br i1 %p, label %yes, label %no"
    , "yes:"
    , "  ret i32 1"
    , "no:"
    , "  ret i32 0"
    , "}"
    ]

-- | The same, with something in the block control would be sent past.
occupied :: Text
occupied =
  T.unlines
    [ "define i32 @f(i1 %c, i1 %e, ptr %p) {"
    , "entry:"
    , "  br i1 %c, label %rhs, label %test"
    , "rhs:"
    , "  br label %test"
    , "test:"
    , "  %q = phi i1 [ false, %entry ], [ %e, %rhs ]"
    , "  store i32 1, ptr %p"
    , "  br i1 %q, label %yes, label %no"
    , "yes:"
    , "  ret i32 1"
    , "no:"
    , "  ret i32 0"
    , "}"
    ]

-- | The same, where neither way in settles the condition.
undetermined :: Text
undetermined =
  T.unlines
    [ "define i32 @f(i1 %c, i1 %e, i1 %g) {"
    , "entry:"
    , "  br i1 %c, label %rhs, label %test"
    , "rhs:"
    , "  br label %test"
    , "test:"
    , "  %q = phi i1 [ %g, %entry ], [ %e, %rhs ]"
    , "  br i1 %q, label %yes, label %no"
    , "yes:"
    , "  ret i32 1"
    , "no:"
    , "  ret i32 0"
    , "}"
    ]

-- | What each block holds afterwards, said as the kind of each operation.
shapesIn :: Text -> IO [[String]]
shapesIn source = do
  simplified <- simplify source
  pure
    [ map (kindOf . instructionOperation) (blockInstructions b)
    | f <- functionsIn simplified
    , b <- functionBlocks f
    ]

kindOf :: Operation operand -> String
kindOf operation = case operation of
  OAssign _ -> "copy"
  OBinary _ -> "add"
  OICmp _ -> "icmp"
  OStore _ -> "store"
  _ -> "other"

-- | Which blocks each block can reach, in the order written.
edgesIn :: Text -> IO [(Label, [Label])]
edgesIn source = do
  simplified <- simplify source
  pure
    [ (blockLabel b, targetsOf (blockTerminator b))
    | f <- functionsIn simplified
    , b <- functionBlocks f
    ]

-- | A program the pass leaves exactly as it found it.
unchanged :: Text -> Assertion
unchanged source = do
  parsed <- expectParse "<inline>" source
  let lowered = lower parsed
  assertEqual "unchanged" lowered (simplifyControlFlow lowered)

blocksOf :: Text -> IO [Label]
blocksOf source = do
  simplified <- simplify source
  pure [blockLabel b | f <- functionsIn simplified, b <- functionBlocks f]

-- | What each surviving instruction assigns to, in order.
resultsOf :: Text -> IO [Maybe Local]
resultsOf source = do
  simplified <- simplify source
  pure
    [ instructionResult i
    | f <- functionsIn simplified
    , b <- functionBlocks f
    , i <- blockInstructions b
    ]

-- | What locals each surviving instruction reads, in order.
operandsOf :: Text -> IO [[Local]]
operandsOf source = do
  simplified <- simplify source
  pure
    [ localsUsedBy (instructionOperation i)
    | f <- functionsIn simplified
    , b <- functionBlocks f
    , i <- blockInstructions b
    ]

terminatorsOf :: Text -> IO [Transfer (TypedValue Local)]
terminatorsOf source = do
  simplified <- simplify source
  pure
    [ terminatorTransfer (blockTerminator b)
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
    , OCall c <- [instructionOperation i]
    , VGlobal name <- [typedValue (callCallee c)]
    ]

simplify :: Text -> IO Program
simplify source = do
  parsed <- expectParse "<inline>" source
  pure (simplifyControlFlow (lower parsed))

-- | 'foldTerminator' knowing nothing about where an address may land.
--
-- These cases are all about the value a branch reads, and none of them
-- computes an address; what a block says about the addresses in it is
-- exercised through the whole pass instead, by 'computed' below.
folds :: Transfer (TypedValue Local) -> Maybe (Transfer (TypedValue Local))
folds = foldTerminator Map.empty
