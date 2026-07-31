-- | Tail recursion elimination: which self calls become branches, what the
-- function is once one has, and which it must leave alone.
--
-- Whether a call was taken is asked by counting the calls left, which is the
-- one thing every refusal has in common and does not depend on how the blocks
-- come out numbered.  What the edit produced is asked separately, by the
-- shape of the blocks and by the verifier, since a rewrite that loses a
-- definition or branches to the entry block is wrong in a way no count of
-- calls would show.
module TailRecursion (tailRecursionTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.TailRecursion (eliminateTailRecursion)
import Olivine.Core.Program
import Olivine.Core.Verify (renderProblem, verify)
import Olivine.Pipeline (optimize)
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Value (TypedValue (..), Value (..))

tailRecursionTests :: TestTree
tailRecursionTests =
  testGroup
    "tail recursion"
    [ testGroup
        "what becomes a loop"
        [ -- The shape a front end writes: the call's result goes to the block
          -- the function returns from, which promotion has turned into a copy
          -- here and a @ret@ of it there.
          testCase "a self call whose result is returned through a copy" $
            callsIn gcd' @?>= 0
        , testCase "a self call standing in the block that returns" $
            callsIn straight @?>= 0
        , testCase "a self call in a function that returns nothing" $
            callsIn voided @?>= 0
        , -- @musttail@ promises the call will not grow the stack, and a call
          -- that is not made at all keeps that promise absolutely.  @tail@
          -- says the callee cannot see this frame, which is true of a callee
          -- that is not called.
          testCase "a musttail call" $ callsIn (marked "musttail") @?>= 0
        , testCase "a tail call" $ callsIn (marked "tail") @?>= 0
        , -- The block made in front of the loop is where the function now
          -- starts, and the loop is entered at the block it used to start at.
          -- Nothing branches to the new one, which is what LLVM requires of an
          -- entry block and what the old one can no longer promise.
          testCase "the function starts one block earlier than it did" $ do
            edges <- edgesIn gcd'
            assertEqual
              "the made block falls into the old entry, which the call branches back to"
              [ (Label 4, [Label 0])
              , (Label 0, [Label 1, Label 2])
              , (Label 1, [Label 3])
              , (Label 2, [Label 0])
              , (Label 3, [])
              ]
              edges
        , -- Every argument into a local of its own before any parameter is
          -- written.  Assigning them in order would hand @f(b, a)@ the value
          -- the first parameter has just been given rather than the one it
          -- had.
          testCase "the arguments are handed over all at once" $
            handedOver swapping @?>= [False, False]
        , -- The allocation runs once, in front of the loop, and every turn
          -- shares what it made.  That is the whole reason the frame is worth
          -- reusing, and it is what an allocation left in the loop would
          -- undo.
          testCase "an allocation moves in front of the loop" $
            allocationsPerBlock holding @?>= [1, 0, 0, 0]
        , -- A rewritten function holds no self call, so the second round finds
          -- nothing.  Which it has to: a second block in front of the first
          -- would be branched back to, and the parameters would be given their
          -- original values again every turn.
          testCase "turning one twice does nothing the second time" $ do
            once <- turned gcd'
            assertEqual "the second round changes nothing" once (eliminateTailRecursion once)
        , -- What no count of calls can say: that what came out is a program.
          -- A local read after the instructions that defined it have gone, or
          -- a branch to the entry block, is exactly what this reports.
          testCase "what comes out is a program the verifier accepts" $
            complaintsIn (gcd' <> swapping <> voided <> holding) @?>= []
        ]
    , testGroup
        "what is left alone"
        [ testCase "a call to another function" $ leftAlone other
        , -- The value the function gives back is not the one the call left,
          -- so the frame is still wanted after the call comes back.
          testCase "a result the function computes with before returning" $
            leftAlone accumulating
        , testCase "a result the function discards" $ leftAlone discarding
        , -- Assignments are all that may stand between the call and the
          -- @ret@; a branch that decides is a decision taken after the call.
          testCase "a branch between the call and the return" $ leftAlone deciding
        , -- The walk from the call is what refuses this: it follows the branch
          -- and finds work rather than a return.
          testCase "work done in the block the call branches to" $ leftAlone working
        , testCase "a call marked notail" $ leftAlone (marked "notail")
        , testCase "a variadic function" $ leftAlone variadic
        , testCase "a call with the wrong number of arguments" $ leftAlone miscounted
        , testCase "a parameter passed byval" $ leftAlone byval
        , -- The call may not be a call to this body at all: the linker picks
          -- among the candidates, and branching into this one has decided.
          testCase "a weak definition" $ leftAlone (linked "weak")
        , testCase "a linkonce_odr definition" $ callsIn (linked "linkonce_odr") @?>= 0
        , -- A second return arrives in the frame as @longjmp@ left it, and the
          -- next turn of the loop has written over it.
          testCase "a body that calls a function declared returns_twice" $
            leftAlone jumping
        , testCase "a body the code generator is told to write itself" $
            leftAlone (attributed "naked")
        , -- The next turn would be handed a pointer into storage it is about
          -- to reuse.
          testCase "an allocation whose address is passed to the call" $
            leftAlone escaping
        , -- Moving it in front of the loop would run it where control does not
          -- go, and leaving it where it is would allocate once a turn.
          testCase "an allocation outside the entry block" $ leftAlone allocatingLate
        , -- The size is this turn's, and the next turn asks for another.
          testCase "an allocation whose size is computed" $ leftAlone allocatingComputed
        , -- The result is read in a block the edit leaves nothing branching
          -- to, and taking the call away leaves that read naming a local
          -- nothing defines.  Merging the two blocks first is what makes this
          -- the ordinary case instead, which is why the shape a front end
          -- writes is not this one.
          testCase "a result read in the block the call branches to" $ leftAlone forwarded
        ]
    , testGroup
        "what it is for"
        [ -- The whole pipeline on the shape clang emits at -O0: what comes out
          -- is the loop clang itself writes at -O2, the header holding the
          -- two values that go round and the test at the bottom.
          testCase "a recursion becomes the loop clang writes" $ do
            written <- rendered gcd'
            assertBool ("expected no call in:\n" <> T.unpack written) $
              not ("call" `T.isInfixOf` written)
            assertEqual "the two values that go round" 3 (T.count " = phi " written)
        ]
    ]

-- | The lowered program with the pass run over it.
turned :: Text -> IO Program
turned source = eliminateTailRecursion . lower <$> expectParse "<inline>" source

-- | That the pass leaves a program exactly as it found it.
leftAlone :: Text -> Assertion
leftAlone source = do
  program <- lower <$> expectParse "<inline>" source
  assertBool "expected a function" (not (null (functionsIn program)))
  assertEqual "unchanged" program (eliminateTailRecursion program)

-- | How many calls @\@f@ still makes once the pass has run.
--
-- The pass alone, not the pipeline: nothing else may be what removed the call.
callsIn :: Text -> IO Int
callsIn source = do
  program <- turned source
  pure (length [() | f <- functionsIn program, b <- functionBlocks f, i <- blockInstructions b, OCall _ <- [instructionOperation i]])

-- | Every block after the pass with where it branches, in the order written.
edgesIn :: Text -> IO [(Label, [Label])]
edgesIn source = do
  program <- turned source
  case functionsIn program of
    f : _ -> pure [(blockLabel b, targetsOf (blockTerminator b)) | b <- functionBlocks f]
    [] -> assertFailure "expected a function"

-- | Whether each parameter is handed a parameter, which is what assigning them
-- in order rather than all at once would do.
--
-- The parameters are what the function's blocks read, which after the edit are
-- the locals the block made in front of the loop assigns to.  Everything
-- reaching them at the bottom of the loop has to come from somewhere else.
handedOver :: Text -> IO [Bool]
handedOver source = do
  program <- turned source
  case functionsIn program of
    f : _ ->
      let parameters = bodyLocals f
       in pure
            [ value `elem` map VLocal parameters
            | b <- drop 1 (functionBlocks f)
            , Instruction (Just target) (OAssign (TypedValue _ value)) _ <- blockInstructions b
            , target `elem` parameters
            ]
    [] -> assertFailure "expected a function"

-- | The locals the body refers to its parameters by, which are the ones the
-- block in front of the loop assigns to.
bodyLocals :: Function -> [Local]
bodyLocals f =
  [ target
  | b <- take 1 (functionBlocks f)
  , Instruction (Just target) (OAssign _) _ <- blockInstructions b
  ]

-- | How many allocations stand in each block after the pass.
allocationsPerBlock :: Text -> IO [Int]
allocationsPerBlock source = do
  program <- turned source
  case functionsIn program of
    f : _ ->
      pure
        [ length [() | i <- blockInstructions b, OAlloca _ <- [instructionOperation i]]
        | b <- functionBlocks f
        ]
    [] -> assertFailure "expected a function"

-- | What the core verifier finds in what the pass produced.
complaintsIn :: Text -> IO [Text]
complaintsIn source = do
  program <- turned source
  pure (map renderProblem (verify program))

rendered :: Text -> IO Text
rendered source = renderModule . optimize <$> expectParse "<inline>" source

(@?>=) :: (Eq a, Show a) => IO a -> a -> Assertion
got @?>= expected = got >>= (@?= expected)

-- | The shape clang writes at @-O0@ for @int gcd(int a, int b)@ returning
-- @gcd(b, a % b)@, with the return slot promoted: the call's result reaches
-- the @ret@ through an assignment in another block.
gcd' :: Text
gcd' =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b) {"
    , "entry:"
    , "  %c = icmp eq i32 %b, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  br label %done"
    , "step:"
    , "  %m = srem i32 %a, %b"
    , "  %r = call i32 @f(i32 %b, i32 %m)"
    , "  br label %done"
    , "done:"
    , "  %v = phi i32 [ %a, %base ], [ %r, %step ]"
    , "  ret i32 %v"
    , "}"
    ]

-- | The call and the return in one block, which is what the shape above comes
-- to once the blocks between them have been merged.
straight :: Text
straight =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  ret i32 %r"
    , "}"
    ]

-- | Nothing to give back, so nothing to check about what is given back.
voided :: Text
voided =
  T.unlines
    [ "define void @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret void"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  call void @f(i32 %m)"
    , "  ret void"
    , "}"
    ]

-- | The arguments in the other order, so that assigning them one at a time
-- gives both parameters the same value.
swapping :: Text
swapping =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b) {"
    , "entry:"
    , "  %c = icmp eq i32 %b, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 %a"
    , "step:"
    , "  %r = call i32 @f(i32 %b, i32 %a)"
    , "  ret i32 %r"
    , "}"
    ]

-- | Storage the function writes and reads and lets nobody else see.
holding :: Text
holding =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %n, ptr %s, align 4"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  %v = load i32, ptr %s, align 4"
    , "  ret i32 %v"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  ret i32 %r"
    , "}"
    ]

-- | The same, with the address handed to the next turn, which is about to
-- write over what it points at.
escaping :: Text
escaping =
  T.unlines
    [ "define i32 @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %n, ptr %s, align 4"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  %v = load i32, ptr %p, align 4"
    , "  ret i32 %v"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m, ptr %s)"
    , "  ret i32 %r"
    , "}"
    ]

allocatingLate :: Text
allocatingLate =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %n, ptr %s, align 4"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  ret i32 %r"
    , "}"
    ]

allocatingComputed :: Text
allocatingComputed =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %s = alloca i32, i32 %n, align 4"
    , "  store i32 %n, ptr %s, align 4"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  ret i32 %r"
    , "}"
    ]

-- | A call to somebody else, which is a tail call the code generator may make
-- something of and this pass may not.
other :: Text
other =
  T.unlines
    [ "declare i32 @g(i32)"
    , "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %r = call i32 @g(i32 %n)"
    , "  ret i32 %r"
    , "}"
    ]

-- | @n * f(n - 1)@: the multiplication happens after the call comes back, so
-- the frame is still wanted.
accumulating :: Text
accumulating =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 1"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  %p = mul i32 %n, %r"
    , "  ret i32 %p"
    , "}"
    ]

discarding :: Text
discarding =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  ret i32 7"
    , "}"
    ]

deciding :: Text
deciding =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  %z = icmp slt i32 %r, 0"
    , "  br i1 %z, label %low, label %high"
    , "low:"
    , "  ret i32 %r"
    , "high:"
    , "  ret i32 %r"
    , "}"
    ]

working :: Text
working =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  br label %after"
    , "after:"
    , "  %p = mul i32 %r, 2"
    , "  ret i32 %p"
    , "}"
    ]

-- | The call's result read in the block it branches to, which nothing else
-- reaches: taking the call away would leave that read naming a local nothing
-- defines.
forwarded :: Text
forwarded =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  br label %done"
    , "done:"
    , "  ret i32 %r"
    , "}"
    ]

marked :: Text -> Text
marked kind =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = " <> kind <> " call i32 @f(i32 %m)"
    , "  ret i32 %r"
    , "}"
    ]

variadic :: Text
variadic =
  T.unlines
    [ "define i32 @f(i32 %n, ...) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 (i32, ...) @f(i32 %m)"
    , "  ret i32 %r"
    , "}"
    ]

miscounted :: Text
miscounted =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m, i32 %n)"
    , "  ret i32 %r"
    , "}"
    ]

byval :: Text
byval =
  T.unlines
    [ "define i32 @f(ptr byval(i32) %p) {"
    , "entry:"
    , "  %n = load i32, ptr %p, align 4"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %r = call i32 @f(ptr byval(i32) %p)"
    , "  ret i32 %r"
    , "}"
    ]

linked :: Text -> Text
linked linkage =
  T.unlines
    [ "define " <> linkage <> " i32 @f(i32 %n) {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  ret i32 %r"
    , "}"
    ]

attributed :: Text -> Text
attributed attributes =
  T.unlines
    [ "define i32 @f(i32 %n) " <> attributes <> " {"
    , "entry:"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m)"
    , "  ret i32 %r"
    , "}"
    ]

jumping :: Text
jumping =
  T.unlines
    [ "declare i32 @setjmp(ptr) returns_twice"
    , "define i32 @f(i32 %n, ptr %env) {"
    , "entry:"
    , "  %j = call i32 @setjmp(ptr %env)"
    , "  %c = icmp eq i32 %n, 0"
    , "  br i1 %c, label %base, label %step"
    , "base:"
    , "  ret i32 %j"
    , "step:"
    , "  %m = sub i32 %n, 1"
    , "  %r = call i32 @f(i32 %m, ptr %env)"
    , "  ret i32 %r"
    , "}"
    ]
