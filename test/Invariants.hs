-- | The loop invariant pass, and the dominance and loop finding it stands on.
--
-- Three things are checked separately: which blocks a loop is made of, what
-- comes out of one, and what must not.  The third is where the bugs are: an
-- instruction hoisted out of a loop it belonged in gives a module LLVM accepts
-- and a program that computes something else, or faults.
module Invariants (invariantTests) where

import Data.Char (toLower)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Loops (Loop (..), dominators, loopsOf)
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.LoopInvariants (hoistLoopInvariants)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Program
import Olivine.Syntax.Instruction hiding (Operation (..))
import Olivine.Syntax.Name
import Olivine.Syntax.Type
import Olivine.Syntax.Value

invariantTests :: TestTree
invariantTests =
  testGroup
    "loop invariants"
    [ testGroup
        "what dominates what"
        [ -- The blocks are numbered as they are written: entry 0, then the two
          -- arms, then the join.
          testCase "a diamond" $ do
            f <- functionOf diamond
            assertEqual
              "each arm dominated by the entry alone, and the join with it"
              ( Map.fromList
                  [ (Label 0, Set.fromList [Label 0])
                  , (Label 1, Set.fromList [Label 0, Label 1])
                  , (Label 2, Set.fromList [Label 0, Label 2])
                  , (Label 3, Set.fromList [Label 0, Label 3])
                  ]
              )
              (dominators f)
        , -- A block in a loop is dominated by the header, which is the whole
          -- of what makes a natural loop one.
          testCase "a loop" $ do
            f <- functionOf counted
            assertEqual
              "the body is dominated by the block above it"
              (Just (Set.fromList [Label 0, Label 1, Label 2]))
              (Map.lookup (Label 2) (dominators f))
        , -- Dominance is about the paths from the entry, and there are none.
          testCase "a block nothing reaches is not answered for" $ do
            f <- functionOf orphaned
            assertEqual "only the entry is there" [Label 0] (Map.keys (dominators f))
        ]
    , testGroup
        "which blocks a loop is"
        [ testCase "a loop with a body of its own" $ do
            f <- functionOf counted
            assertEqual
              "the header and the body"
              [(Label 1, [Label 1, Label 2])]
              (bodies f)
        , testCase "a block that branches to itself" $ do
            f <- functionOf spinning
            assertEqual "the one block" [(Label 1, [Label 1])] (bodies f)
        , -- The order the pass relies on: a value has to leave the inner loop
          -- before the outer one can see it as invariant at all.
          testCase "one loop inside another, innermost first" $ do
            f <- functionOf nested
            assertEqual
              "the inner loop, then the outer with everything in it"
              [ (Label 2, [Label 2])
              , (Label 1, [Label 1, Label 2, Label 3])
              ]
              (bodies f)
        , -- Two edges back to one header are two ways round one loop, not two
          -- loops, so the arms of the @if@ in the body are both in it.
          testCase "two edges back to one header" $ do
            f <- functionOf branching
            assertEqual
              "one loop, holding both arms"
              [(Label 1, [Label 1, Label 2, Label 3])]
              (bodies f)
        , testCase "a function with no loop at all" $ do
            f <- functionOf diamond
            assertEqual "none" [] (bodies f)
        , -- A cycle no block dominates is not a natural loop, and there is
          -- nowhere to put what would come out of it: a block in front of one
          -- entrance is not in front of the other.
          testCase "a cycle entered in two places" $ do
            f <- functionOf irreducible
            assertEqual "none" [] (bodies f)
        , -- Control never gets there, so it is not a loop the program has.
          testCase "a loop nothing reaches" $ do
            f <- functionOf orphaned
            assertEqual "none" [] (bodies f)
        ]
    , testGroup
        "what comes out"
        [ -- The block above the loop already branches nowhere else, so it is
          -- the preheader and the hoisted instruction is appended to it.  The
          -- copies before it are the phis the lowering eliminated.
          testCase "arithmetic on what the loop never assigns" $ do
            shapes <- shapesIn invariant
            assertEqual
              "the multiplication is in the block above the loop"
              [["copy", "copy", "mul"], ["icmp"], ["add", "add", "copy", "copy"], []]
              shapes
        , -- One instruction leaves per round: the second reads what the first
          -- assigns, and the loop is still assigning it until the first has
          -- gone.
          testCase "a chain of them, over rounds" $ do
            shapes <- shapesIn chained
            assertEqual
              "both, in the order they were computed"
              [["copy", "copy", "mul", "add"], ["icmp"], ["add", "add", "copy", "copy"], []]
              shapes
        , -- Out of the inner loop, then out of the outer one.
          testCase "out of two loops" $ do
            shapes <- shapesIn nestedInvariant
            assertBool
              ("expected the multiplication in the first block, got " <> show shapes)
              ("mul" `elem` firstOf shapes)
        , -- Invariant, and in a block the loop only sometimes reaches.
          -- Hoisting makes it run where it would not have run, which costs
          -- nothing for arithmetic that only computes a value.
          testCase "from a block the loop only sometimes reaches" $ do
            shapes <- shapesIn conditional
            assertBool
              ("expected the multiplication in the first block, got " <> show shapes)
              ("mul" `elem` firstOf shapes)
        , -- What promotion leaves is a copy where each load was, so the
          -- arithmetic reads locals the loop assigns and is invariant in
          -- nothing until the copies come out.  That the copies are hoisted is
          -- what this asks: the multiplication cannot leave without them.
          testCase "through the copies promotion leaves behind" $ do
            shapes <- promotedShapesIn slotted
            assertBool
              ("expected the multiplication in the first block, got " <> show shapes)
              ("mul" `elem` firstOf shapes)
        ]
    , testGroup
        "what a load answers"
        [ -- Nothing in the loop writes anywhere the pointer could be, and the
          -- load stands in the header, so the loop runs it whenever it is
          -- entered at all: moving it to the preheader moves it past nothing.
          testCase "from the header, out of a loop that writes nothing" $ do
            shapes <- shapesIn readInHeader
            assertEqual
              "the load is in the block above the loop"
              [["copy", "load"], ["icmp"], ["add", "copy"], []]
              shapes
        , -- Reading a symbol cannot fault, so this one comes out of a block
          -- the loop may never reach at all.
          testCase "of a symbol, from a block the loop may not reach" $ do
            shapes <- shapesIn readSymbol
            assertEqual
              "the load is in the block above the loop"
              [["copy", "load"], ["icmp"], ["add", "copy"], []]
              shapes
        , -- The store in the loop is to a slot whose address never left this
          -- function, and the symbol is not that slot.  Which is the whole of
          -- what makes this a question for "Olivine.Core.Alias" rather than a
          -- count of the stores in the body.
          testCase "past a store to somewhere else" $ do
            shapes <- shapesIn readPastStore
            assertBool
              ("expected the load in the first block, got " <> show shapes)
              ("load" `elem` firstOf shapes)
        ]
    , testGroup
        "where it goes"
        [ -- The loop is entered from a block that branches two ways, so that
          -- block is not the preheader: what is hoisted has to go somewhere
          -- the loop is reached from and nothing else is.
          testCase "a block is made when there is no preheader" $ do
            shapes <- shapesIn guarded
            assertEqual
              "a block of its own in front of the header"
              [[], ["mul"], ["call"], []]
              shapes
        , testCase "and every way into the loop goes through it" $ do
            edges <- edgesIn twoWays
            assertEqual
              "both blocks that entered the loop enter the made block"
              [ (Label 0, [Label 1, Label 2])
              , (Label 1, [Label 5])
              , (Label 2, [Label 5])
              , (Label 5, [Label 3])
              , (Label 3, [Label 3, Label 4])
              , (Label 4, [])
              ]
              edges
        , -- Nowhere, for a loop the function starts at: the block in front of
          -- the header would be in front of where the function starts.  LLVM
          -- rejects the shape anyway — an entry block must not have
          -- predecessors — so this is a question nothing valid asks, and the
          -- answer is to leave it alone rather than to move where a function
          -- begins.
          testCase "a loop at the top of the function is left alone" $ do
            shapes <- shapesIn leading
            assertEqual
              "the multiplication stays where it was"
              [["mul", "load", "icmp"], []]
              shapes
        ]
    , testGroup
        "what stays"
        [ -- Dividing by zero is undefined behaviour rather than poison, and
          -- the divisor is invariant however zero it is: run before a loop
          -- that never runs, it undefines a program that was defined.
          testCase "a division" $ do
            shapes <- shapesIn dividing
            assertEqual
              "in the loop, where it was"
              [["copy"], ["icmp"], ["sdiv", "add", "copy"], []]
              shapes
        , -- Nothing here can tell whether a call answers the same thing twice,
          -- or what it does on the way to answering.
          testCase "a call" $ do
            shapes <- shapesIn calling
            assertBool
              ("expected the call still in the loop, got " <> show shapes)
              ("call" `elem` (shapes !! 2))
        , -- Through a pointer the function was handed, in a block the loop may
          -- never reach: nothing says the address can be read at all where the
          -- loop is entered and the body is not.
          testCase "a load of what the function was handed" $ do
            shapes <- shapesIn loading
            assertBool
              ("expected the load still in the loop, got " <> show shapes)
              ("load" `elem` (shapes !! 2))
        , -- The store may be to the symbol, so what it reads is not what the
          -- iteration before it read.
          testCase "a load the loop may write" $ do
            shapes <- shapesIn writtenInLoop
            assertBool
              ("expected the load still in the loop, got " <> show shapes)
              ("load" `elem` (shapes !! 2))
        , -- A callee reaches every symbol, whatever it does with it.
          testCase "a load of a symbol the loop calls past" $ do
            shapes <- shapesIn callingPast
            assertBool
              ("expected the load still in the loop, got " <> show shapes)
              ("load" `elem` (shapes !! 2))
        , -- The slot is one no callee can name, so the call is not what writes
          -- it; what declines this is that the call may not come back, and the
          -- loop can therefore be entered without the load below it running.
          testCase "a load below a call in the header" $ do
            shapes <- shapesIn calledAbove
            assertBool
              ("expected the load still in the loop, got " <> show shapes)
              ("load" `elem` (shapes !! 1))
        , -- The point of a volatile access is that it happens, as many times
          -- as it is written to happen.
          testCase "a volatile load the loop is certain to run" $ do
            shapes <- shapesIn volatileInHeader
            assertBool
              ("expected the load still in the loop, got " <> show shapes)
              ("load" `elem` (shapes !! 1))
        , -- Without a data layout nothing here knows an @i64@ does not fit in
          -- the storage a symbol defined as @i32@ names.
          testCase "a load of a symbol at another type" $ do
            shapes <- shapesIn readWider
            assertBool
              ("expected the load still in the loop, got " <> show shapes)
              ("load" `elem` (shapes !! 2))
        , -- An access at an alignment the storage does not have is undefined
          -- when it runs, so running it where it would not have run invents
          -- that.
          testCase "a load of a symbol at an alignment it was not given" $ do
            shapes <- shapesIn readOveraligned
            assertBool
              ("expected the load still in the loop, got " <> show shapes)
              ("load" `elem` (shapes !! 2))
        , testCase "an operand the loop assigns" $ do
            shapes <- shapesIn variant
            assertEqual
              "nothing leaves"
              [["copy"], ["icmp"], ["mul", "add", "copy"], []]
              shapes
        , -- The bill the non-SSA core presents: promotion makes the variable a
          -- local assigned in two places, and moving the assignment earlier
          -- changes what the read above it sees on the first iteration.
          testCase "an assignment to a variable the loop assigns" $ do
            shapes <- promotedShapesIn carried
            assertEqual
              "the addition leaves and the assignment does not"
              [["copy", "copy", "add"], ["copy", "icmp", "copy"], []]
              shapes
        ]
    , testGroup
        -- The predicate is 'Olivine.Core.Instruction.speculatable', which this
        -- pass asks in order to compute something before a loop that may never
        -- run and "Olivine.Core.Pass.IfConversion" asks in order to run one side
        -- of a branch where control took the other.  What it means is the same
        -- either way, and these are the cases hoisting turns on.
        "what may be hoisted at all"
        [ testCase "arithmetic" $ speculatable (binary OpAdd) @?= True
        , testCase "a comparison" $ speculatable comparison @?= True
        , testCase "a conversion" $ speculatable conversion @?= True
        , testCase "a pointer step" $ speculatable step @?= True
        , testCase "a field selection" $ speculatable field @?= True
        , -- Not for what it computes, but because what reads it cannot leave
          -- the loop until it has.
          testCase "an assignment" $ speculatable assignment @?= True
        , -- Undefined behaviour on operands it may be given, so running it
          -- where the program would not have is inventing that behaviour.
          testCase "a signed division" $ speculatable (binary OpSDiv) @?= False
        , testCase "an unsigned remainder" $ speculatable (binary OpURem) @?= False
        , -- Dividing by zero here is an infinity, and nothing traps.
          testCase "a floating point division" $ speculatable (binary OpFDiv) @?= True
        , -- Not settled by what the operation is: what a load answers depends
          -- on what the loop does to memory and on where in the loop it
          -- stands, which is asked of the loop and tested above.
          testCase "a load" $ speculatable load' @?= False
        , testCase "a store" $ speculatable store' @?= False
        , testCase "a call" $ speculatable call' @?= False
        , -- Fresh storage each time, so one allocation before the loop is not
          -- the allocations the loop asked for.
          testCase "an allocation" $ speculatable allocation @?= False
        ]
    ]

-- | The first function of a module, lowered.
functionOf :: Text -> IO Function
functionOf source = do
  parsed <- expectParse "<inline>" source
  case functionsIn (lower parsed) of
    f : _ -> pure f
    [] -> assertFailure "expected a function"

-- | Each loop as its header and the blocks in it, in the order 'loopsOf'
-- answers.
bodies :: Function -> [(Label, [Label])]
bodies f = [(loopHeader loop, Set.toList (loopBody loop)) | loop <- loopsOf f]

-- | The first function after the pass has run.
hoistedFunction :: Text -> IO Function
hoistedFunction = hoistedAfter id

hoistedAfter :: (Program -> Program) -> Text -> IO Function
hoistedAfter before source = do
  parsed <- expectParse "<inline>" source
  case functionsIn (hoistLoopInvariants (before (lower parsed))) of
    f : _ -> pure f
    [] -> assertFailure "expected a function"

-- | What each block computes after the pass, block by block in the order
-- written.
--
-- An operation is named by what it is rather than by the local it assigns,
-- since what these tests ask is where a computation ended up and the numbering
-- of a local is an accident of the lowering.  The assignments are here too, and
-- most of them are the phis the lowering eliminated: they are noise in the
-- blocks a loop carries a value round, and the point in the cases where a
-- variable is what the loop assigns.
shapesIn :: Text -> IO [[String]]
shapesIn source = map (map (shape . instructionOperation) . blockInstructions) . functionBlocks <$> hoistedFunction source

-- | The same, of a function promotion has already been over.
--
-- Promotion is what puts a copy where a load was, and a local assigned twice in
-- front of this pass; neither can be written in LLVM directly, since what the
-- input is in is single assignment form.
promotedShapesIn :: Text -> IO [[String]]
promotedShapesIn source =
  map (map (shape . instructionOperation) . blockInstructions) . functionBlocks <$> hoistedAfter promoteMemory source

shape :: Operation (TypedValue Local) -> String
shape operation = case operation of
  OAssign _ -> "copy"
  OBinary b -> map toLower (drop 2 (show (binaryOp b)))
  OICmp _ -> "icmp"
  OFCmp _ -> "fcmp"
  OConvert _ -> "convert"
  OCall _ -> "call"
  OAlloca _ -> "alloca"
  OLoad _ -> "load"
  OStore _ -> "store"
  OOffset _ -> "offset"
  OField _ -> "field"
  _ -> "other"

-- | What the first block holds, which is where a value hoisted out of every
-- loop it was in ends up.
firstOf :: [[String]] -> [String]
firstOf = concat . take 1

-- | Every block after the pass with where it branches, in the order written.
edgesIn :: Text -> IO [(Label, [Label])]
edgesIn source = do
  f <- hoistedFunction source
  pure [(blockLabel b, targetsOf (blockTerminator b)) | b <- functionBlocks f]

diamond :: Text
diamond =
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

spinning :: Text
spinning =
  T.unlines
    [ "define void @f(i1 %c) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  br i1 %c, label %head, label %done"
    , "done:"
    , "  ret void"
    , "}"
    ]

nested :: Text
nested =
  T.unlines
    [ "define void @f(i1 %c, i1 %d) {"
    , "entry:"
    , "  br label %outer"
    , "outer:"
    , "  br label %inner"
    , "inner:"
    , "  br i1 %d, label %inner, label %latch"
    , "latch:"
    , "  br i1 %c, label %outer, label %done"
    , "done:"
    , "  ret void"
    , "}"
    ]

-- | A loop whose body has an @if@ in it, so two blocks branch back to the
-- header.
branching :: Text
branching =
  T.unlines
    [ "define void @f(i1 %c, i1 %d) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  br i1 %d, label %head, label %done"
    , "no:"
    , "  br label %head"
    , "done:"
    , "  ret void"
    , "}"
    ]

-- | A cycle reached in two places, so neither block in it dominates the other.
irreducible :: Text
irreducible =
  T.unlines
    [ "define void @f(i1 %c) {"
    , "entry:"
    , "  br i1 %c, label %one, label %two"
    , "one:"
    , "  br label %two"
    , "two:"
    , "  br label %one"
    , "}"
    ]

orphaned :: Text
orphaned =
  T.unlines
    [ "define void @f() {"
    , "entry:"
    , "  ret void"
    , "orphan:"
    , "  br label %orphan"
    , "}"
    ]

invariant :: Text
invariant =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %k) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %t = phi i32 [ 0, %entry ], [ %sum, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %sq = mul i32 %k, %k"
    , "  %sum = add i32 %t, %sq"
    , "  %next = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %t"
    , "}"
    ]

chained :: Text
chained =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %k) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %t = phi i32 [ 0, %entry ], [ %sum, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %sq = mul i32 %k, %k"
    , "  %adj = add i32 %sq, 3"
    , "  %sum = add i32 %t, %adj"
    , "  %next = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %t"
    , "}"
    ]

nestedInvariant :: Text
nestedInvariant =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %k) {"
    , "entry:"
    , "  br label %outer"
    , "outer:"
    , "  %i = phi i32 [ 0, %entry ], [ %step, %latch ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %inner, label %done"
    , "inner:"
    , "  %j = phi i32 [ 0, %outer ], [ %next, %inner ]"
    , "  %sq = mul i32 %k, %k"
    , "  %next = add i32 %j, %sq"
    , "  %d = icmp slt i32 %next, %n"
    , "  br i1 %d, label %inner, label %latch"
    , "latch:"
    , "  %step = add i32 %i, 1"
    , "  br label %outer"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

-- | An invariant computation in a block the body only reaches when the test in
-- it says so.
conditional :: Text
conditional =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %k, i1 %p) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %join ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  br i1 %p, label %some, label %join"
    , "some:"
    , "  %sq = mul i32 %k, %k"
    , "  br label %join"
    , "join:"
    , "  %next = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

-- | The shape the corpus is in: the value the loop computes with arrives
-- through a slot, so promotion leaves a copy of it inside the loop.
slotted :: Text
slotted =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %k) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %k, ptr %s, align 4"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %v = load i32, ptr %s, align 4"
    , "  %w = load i32, ptr %s, align 4"
    , "  %sq = mul i32 %v, %w"
    , "  %next = add i32 %i, %sq"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

-- | A loop entered from a block that branches two ways, so the block above it
-- is not a preheader.
--
-- What the loop goes round on is a call, which is the one thing left that is
-- variant without being carried: a counter would be a phi, and the edge a phi
-- needs a copy on is a critical edge the lowering splits, which would make the
-- preheader this is about before the pass could be asked for one.
guarded :: Text
guarded =
  T.unlines
    [ "declare i1 @more()"
    , "define i32 @f(i32 %n, i32 %k, i1 %p) {"
    , "entry:"
    , "  br i1 %p, label %head, label %done"
    , "head:"
    , "  %sq = mul i32 %k, %k"
    , "  %c = call i1 @more()"
    , "  br i1 %c, label %head, label %done"
    , "done:"
    , "  ret i32 %n"
    , "}"
    ]

-- | A loop entered from two blocks, which is what makes a preheader a block of
-- its own rather than one of them.
twoWays :: Text
twoWays =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %k, i1 %p) {"
    , "entry:"
    , "  br i1 %p, label %one, label %two"
    , "one:"
    , "  br label %head"
    , "two:"
    , "  br label %head"
    , "head:"
    , "  %sq = mul i32 %k, %k"
    , "  %c = icmp slt i32 %sq, %n"
    , "  br i1 %c, label %head, label %done"
    , "done:"
    , "  ret i32 %n"
    , "}"
    ]

-- | A loop the function starts at, which LLVM does not accept: the entry block
-- has the latch as a predecessor.  Here to be declined rather than optimized.
leading :: Text
leading =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %k, ptr %q) {"
    , "head:"
    , "  %sq = mul i32 %k, %k"
    , "  %v = load i32, ptr %q, align 4"
    , "  %c = icmp slt i32 %v, %n"
    , "  br i1 %c, label %head, label %done"
    , "done:"
    , "  ret i32 %n"
    , "}"
    ]

dividing :: Text
dividing =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %a, i32 %b) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %t, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %q = sdiv i32 %a, %b"
    , "  %t = add i32 %i, %q"
    , "  br label %head"
    , "done:"
    , "  ret i32 %n"
    , "}"
    ]

calling :: Text
calling =
  T.unlines
    [ "declare i32 @tick(i32)"
    , "define i32 @f(i32 %n, i32 %k) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %c = icmp slt i32 %k, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %x = call i32 @tick(i32 %k)"
    , "  br label %head"
    , "done:"
    , "  ret i32 %n"
    , "}"
    ]

-- | A load through a pointer the function was handed, in the body rather than
-- the header.  The loop writes nothing, so what it reads is the same every
-- time round; what is not known is whether the address can be read at all on
-- the turn where the loop is entered and the body is not.
loading :: Text
loading =
  T.unlines
    [ "define i32 @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %x = load i32, ptr %p, align 4"
    , "  %next = add i32 %i, %x"
    , "  br label %head"
    , "done:"
    , "  ret i32 %n"
    , "}"
    ]

-- | The multiplication reads the counter, so it is a different number every
-- time round.
variant :: Text
variant =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %sq = mul i32 %i, %n"
    , "  %next = add i32 %sq, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %n"
    , "}"
    ]

-- | A load in the header of a loop that writes nothing at all: the loop runs
-- it whenever it is entered, so where it lands is a block the loop is entered
-- through.
readInHeader :: Text
readInHeader =
  T.unlines
    [ "define i32 @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %v = load i32, ptr %p, align 4"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %next = add i32 %i, %v"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

-- | A symbol read in the body, which the loop reaches only while the count
-- lasts.  Nothing writes it and reading it cannot fault, so it comes out
-- anyway.
readSymbol :: Text
readSymbol =
  T.unlines
    [ "@scale = internal global i32 3, align 4"
    , "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %s = load i32, ptr @scale, align 4"
    , "  %next = add i32 %i, %s"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

-- | The same, with a store in the loop to a slot that is not the symbol.
readPastStore :: Text
readPastStore =
  T.unlines
    [ "@scale = internal global i32 3, align 4"
    , "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %t = alloca i32, align 4"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  store i32 %i, ptr %t, align 4"
    , "  %s = load i32, ptr @scale, align 4"
    , "  %next = add i32 %i, %s"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

-- | A store through a pointer the function was handed, which may be where the
-- symbol is.
writtenInLoop :: Text
writtenInLoop =
  T.unlines
    [ "@scale = internal global i32 3, align 4"
    , "define i32 @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %s = load i32, ptr @scale, align 4"
    , "  store i32 %i, ptr %p, align 4"
    , "  %next = add i32 %i, %s"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

-- | A call in the loop, which reaches every symbol the program has.
callingPast :: Text
callingPast =
  T.unlines
    [ "@scale = internal global i32 3, align 4"
    , "declare void @tick()"
    , "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %s = load i32, ptr @scale, align 4"
    , "  call void @tick()"
    , "  %next = add i32 %i, %s"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

-- | A load in the header with a call above it.  The slot it reads is one whose
-- address never leaves the function, so the call cannot be what writes it.
calledAbove :: Text
calledAbove =
  T.unlines
    [ "declare void @tick()"
    , "define i32 @f(i32 %n, i32 %k) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %k, ptr %s, align 4"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %head ]"
    , "  call void @tick()"
    , "  %v = load i32, ptr %s, align 4"
    , "  %next = add i32 %i, %v"
    , "  %c = icmp slt i32 %next, %n"
    , "  br i1 %c, label %head, label %done"
    , "done:"
    , "  ret i32 %next"
    , "}"
    ]

-- | The same slot read in the header of a loop with nothing in it that could
-- write it, and written @volatile@.
volatileInHeader :: Text
volatileInHeader =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %k) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %k, ptr %s, align 4"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %head ]"
    , "  %v = load volatile i32, ptr %s, align 4"
    , "  %next = add i32 %i, %v"
    , "  %c = icmp slt i32 %next, %n"
    , "  br i1 %c, label %head, label %done"
    , "done:"
    , "  ret i32 %next"
    , "}"
    ]

-- | A symbol defined as an @i32@ and read as an @i64@.
readWider :: Text
readWider =
  T.unlines
    [ "@scale = internal global i32 3, align 4"
    , "define i64 @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %s = load i64, ptr @scale, align 4"
    , "  %next = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i64 0"
    , "}"
    ]

-- | A symbol given @align 1@ and read at @align 4@.
readOveraligned :: Text
readOveraligned =
  T.unlines
    [ "@scale = internal global i32 3, align 1"
    , "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %next, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %s = load i32, ptr @scale, align 4"
    , "  %next = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

-- | A variable read at the top of the body and assigned an invariant value
-- below it, so the first iteration reads what was there before the loop.
carried :: Text
carried =
  T.unlines
    [ "define i32 @f(i32 %k) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 0, ptr %s, align 4"
    , "  br label %head"
    , "head:"
    , "  %seen = load i32, ptr %s, align 4"
    , "  %c = icmp sgt i32 %seen, 0"
    , "  %inv = add i32 %k, 1"
    , "  store i32 %inv, ptr %s, align 4"
    , "  br i1 %c, label %done, label %head"
    , "done:"
    , "  ret i32 %seen"
    , "}"
    ]

-- Operations at the core's own operand type, for 'speculatable', which reads
-- nothing but which operation it is.

binary :: BinaryOp -> Operation (TypedValue Local)
binary op = OBinary (Binary op [] (word 1) (word 2))

comparison :: Operation (TypedValue Local)
comparison = OICmp (Compare [] IEq (word 1) (word 2))

conversion :: Operation (TypedValue Local)
conversion = OConvert (Convert CastZExt [] (word 1) (TInteger 64))

step :: Operation (TypedValue Local)
step = OOffset (Offset [] (TInteger 32) pointer (word 1))

field :: Operation (TypedValue Local)
field = OField (Field [] (TStruct Unpacked [TInteger 32]) pointer 0)

allocation :: Operation (TypedValue Local)
allocation = OAlloca (Alloca False (TInteger 32) Nothing Nothing Nothing)

load' :: Operation (TypedValue Local)
load' = OLoad (Load False (TInteger 32) pointer Nothing)

store' :: Operation (TypedValue Local)
store' = OStore (Store False (word 1) pointer Nothing)

call' :: Operation (TypedValue Local)
call' =
  OCall
    ( Call
        Nothing
        []
        Nothing
        []
        Nothing
        (TInteger 32)
        (TypedValue (TPointer Nothing) (VGlobal (Name Bare "tick")))
        []
        []
    )

assignment :: Operation (TypedValue Local)
assignment = OAssign (word 1)

word :: Int -> TypedValue Local
word n = TypedValue (TInteger 32) (VLocal (Local n))

pointer :: TypedValue Local
pointer = TypedValue (TPointer Nothing) (VLocal (Local 0))
