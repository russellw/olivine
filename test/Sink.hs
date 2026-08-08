-- | Sinking what every way into a block ends with.
--
-- Two kinds of case.  What a run comes to, which is where the instructions end
-- up and what the arms are left holding; and what is refused, checked by the
-- program coming back equal to itself — no change at all being a stronger
-- statement than nothing particular having moved.
--
-- The operands are what most of these are really about.  An operand the arms
-- disagree about becomes an assignment in each arm, which is this core's phi; one
-- the run itself computed becomes nothing at all, there being one such value
-- after sinking where there was one per arm; and one they already agreed on is
-- left alone.
module Sink (sinkTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.Sink (sinkCommonTails)
import Olivine.Core.Program

sinkTests :: TestTree
sinkTests =
  testGroup
    "sinking"
    [ testGroup
        "what a run comes to"
        [ -- A store is as sinkable as anything else: the arm's only successor is
          -- the join, so the store happens where it happened.  Nothing here asks
          -- whether it could be speculated, because nothing is speculated.
          testCase "a store both arms end with" $ do
            shapes <- shapesIn shared
            assertEqual
              "one store, at the top of the join"
              [["icmp"], [], [], ["store", "ret"]]
              shapes
        , -- The interesting half.  The addition's operand differs, so each arm
          -- assigns what it had to one fresh local; the store's value operand is
          -- what the addition produced, and that needs nothing, there being one
          -- addition now where there were two.  The last copy in the join is the
          -- other arm's name for the addition's result.
          testCase "an operand the arms disagree about" $ do
            shapes <- shapesIn disagreeing
            assertEqual
              "a copy in each arm and both instructions in the join"
              [["icmp"], ["copy"], ["copy"], ["add", "store", "copy", "ret"]]
              shapes
        , -- Locals are numbered as they are defined, the four parameters first:
          -- %n %p %x %y are 0 1 2 3, %c is 4, the two additions 5 and 6, and the
          -- local this pass minted for the operand they disagreed about is 7.  So
          -- the addition reads the minted one and the store reads the addition —
          -- not a phi of the two results, there being one result now.
          testCase "and the run's own result needs no copy" $ do
            reads' <- readsIn disagreeing
            assertEqual
              "the store reads the addition itself"
              [[Local 0], [Local 2], [Local 3], [Local 7, Local 5, Local 1, Local 5]]
              reads'
        , -- Three arms rather than two, which is the shape a dispatch has and the
          -- one this was written for: what it saves grows with the number of ways
          -- in while what it costs does not.
          testCase "three arms" $ do
            shapes <- shapesIn threeWays
            assertEqual
              "one copy of the tail for three ways in"
              [ ["switch"]
              , ["copy"]
              , ["copy"]
              , ["copy"]
              , ["add", "store", "copy", "copy", "ret"]
              ]
              shapes
        , -- The arms named the one result differently, so the instruction keeps
          -- the first arm's name and an assignment carries it into the other's.
          -- Both are copies, which reconstruction removes.
          testCase "a result the arms named differently" $ do
            shapes <- shapesIn named
            assertEqual
              "the sunk result is copied into the name the other arm used"
              [["icmp"], [], [], ["add", "copy", "copy", "ret"]]
              shapes
        ]
    , testGroup
        "what is refused"
        [ -- One way in is 'Olivine.Core.Blocks.mergeBlocks' putting the two
          -- blocks together instead, which is better than this in every way.
          testCase "a join with one way in" $ unchanged single
        , -- A predecessor that does not take part is an edge with no value on it
          -- for every phi this would make.
          testCase "a predecessor that branches two ways" $ unchanged conditional
        , testCase "arms that end differently" $ unchanged differing
        , -- An alloca out of the entry block is a frame that grows a turn at a
          -- time, and a static allocation that is no longer static.
          testCase "an allocation" $ unchanged allocating
        , -- A run of nothing but assignments is the join's own phi written as
          -- itself: sinking it takes nothing out of the output and puts the same
          -- phi back.
          testCase "a run of nothing but assignments" $ unchanged copies
        , -- Sinking within one block would move the run above the instructions it
          -- came after rather than below them.
          testCase "a block that branches to itself" $ unchanged looping
        , -- Control can arrive at a block whose address is taken without any
          -- branch here saying so, and what the run belongs to is the arms.
          testCase "a join whose address is taken" $ unchanged addressed
        , -- One store removed against one phi put back is no gain, and this
          -- spends nothing it does not get back.
          testCase "a run that only breaks even" $ unchanged breakingEven
        ]
    ]

-- | Two arms ending in the same store.
shared :: Text
shared =
  T.unlines
    [ "define void @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  %c = icmp slt i32 %n, 4"
    , "  br i1 %c, label %a, label %b"
    , "a:"
    , "  store i32 7, ptr %p"
    , "  br label %join"
    , "b:"
    , "  store i32 7, ptr %p"
    , "  br label %join"
    , "join:"
    , "  ret void"
    , "}"
    ]

-- | The same two instructions in each arm, over an operand that differs.
disagreeing :: Text
disagreeing =
  T.unlines
    [ "define void @f(i32 %n, ptr %p, i32 %x, i32 %y) {"
    , "entry:"
    , "  %c = icmp slt i32 %n, 4"
    , "  br i1 %c, label %a, label %b"
    , "a:"
    , "  %u = add i32 %x, 1"
    , "  store i32 %u, ptr %p"
    , "  br label %join"
    , "b:"
    , "  %v = add i32 %y, 1"
    , "  store i32 %v, ptr %p"
    , "  br label %join"
    , "join:"
    , "  ret void"
    , "}"
    ]

-- | Three ways into one join, which is the shape a dispatch has.
threeWays :: Text
threeWays =
  T.unlines
    [ "define void @f(i32 %n, ptr %p, i32 %x, i32 %y, i32 %z) {"
    , "entry:"
    , "  switch i32 %n, label %a [ i32 1, label %b"
    , "                            i32 2, label %c ]"
    , "a:"
    , "  %u = add i32 %x, 1"
    , "  store i32 %u, ptr %p"
    , "  br label %join"
    , "b:"
    , "  %v = add i32 %y, 1"
    , "  store i32 %v, ptr %p"
    , "  br label %join"
    , "c:"
    , "  %w = add i32 %z, 1"
    , "  store i32 %w, ptr %p"
    , "  br label %join"
    , "join:"
    , "  ret void"
    , "}"
    ]

-- | One value computed the same way in each arm, and read at the join.
--
-- The phi is what makes the arms name it differently, and after lowering it is
-- an assignment at the end of each arm — so the run is the addition and that
-- assignment, and both come out.
named :: Text
named =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %x) {"
    , "entry:"
    , "  %c = icmp slt i32 %n, 4"
    , "  br i1 %c, label %a, label %b"
    , "a:"
    , "  %u = add i32 %x, 1"
    , "  br label %join"
    , "b:"
    , "  %v = add i32 %x, 1"
    , "  br label %join"
    , "join:"
    , "  %r = phi i32 [ %u, %a ], [ %v, %b ]"
    , "  ret i32 %r"
    , "}"
    ]

single :: Text
single =
  T.unlines
    [ "define void @f(ptr %p) {"
    , "entry:"
    , "  br label %join"
    , "join:"
    , "  store i32 7, ptr %p"
    , "  ret void"
    , "}"
    ]

-- | One arm reaches the join and the block above reaches it as well, by a branch
-- that can go elsewhere.
conditional :: Text
conditional =
  T.unlines
    [ "define void @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  %c = icmp slt i32 %n, 4"
    , "  store i32 7, ptr %p"
    , "  br i1 %c, label %a, label %join"
    , "a:"
    , "  store i32 7, ptr %p"
    , "  br label %join"
    , "join:"
    , "  ret void"
    , "}"
    ]

differing :: Text
differing =
  T.unlines
    [ "define void @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  %c = icmp slt i32 %n, 4"
    , "  br i1 %c, label %a, label %b"
    , "a:"
    , "  %u = add i32 %n, 1"
    , "  store i32 %u, ptr %p"
    , "  br label %join"
    , "b:"
    , "  %v = mul i32 %n, 1"
    , "  store i32 %v, ptr %p"
    , "  br label %join"
    , "join:"
    , "  ret void"
    , "}"
    ]

allocating :: Text
allocating =
  T.unlines
    [ "define void @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  %c = icmp slt i32 %n, 4"
    , "  br i1 %c, label %a, label %b"
    , "a:"
    , "  %u = alloca i32, align 4"
    , "  store ptr %u, ptr %p"
    , "  br label %join"
    , "b:"
    , "  %v = alloca i32, align 4"
    , "  store ptr %v, ptr %p"
    , "  br label %join"
    , "join:"
    , "  ret void"
    , "}"
    ]

-- | Two arms whose whole tail is the phi at the join.
copies :: Text
copies =
  T.unlines
    [ "define i32 @f(i32 %n, i32 %x, i32 %y) {"
    , "entry:"
    , "  %c = icmp slt i32 %n, 4"
    , "  br i1 %c, label %a, label %b"
    , "a:"
    , "  br label %join"
    , "b:"
    , "  br label %join"
    , "join:"
    , "  %r = phi i32 [ %x, %a ], [ %y, %b ]"
    , "  ret i32 %r"
    , "}"
    ]

-- | A block reached from itself and from above, which is a loop.
looping :: Text
looping =
  T.unlines
    [ "define void @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  store i32 7, ptr %p"
    , "  br label %loop"
    , "loop:"
    , "  store i32 7, ptr %p"
    , "  br label %loop"
    , "}"
    ]

-- | A join something takes the address of.
addressed :: Text
addressed =
  T.unlines
    [ "@target = global ptr blockaddress(@f, %join)"
    , "define void @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  %c = icmp slt i32 %n, 4"
    , "  br i1 %c, label %a, label %b"
    , "a:"
    , "  store i32 7, ptr %p"
    , "  br label %join"
    , "b:"
    , "  store i32 7, ptr %p"
    , "  br label %join"
    , "join:"
    , "  ret void"
    , "}"
    ]

-- | One store removed and one phi put back in its place.
breakingEven :: Text
breakingEven =
  T.unlines
    [ "define void @f(i32 %n, ptr %p) {"
    , "entry:"
    , "  %c = icmp slt i32 %n, 4"
    , "  br i1 %c, label %a, label %b"
    , "a:"
    , "  store i32 7, ptr %p"
    , "  br label %join"
    , "b:"
    , "  store i32 9, ptr %p"
    , "  br label %join"
    , "join:"
    , "  ret void"
    , "}"
    ]

-- | What each block holds afterwards, said as the kind of each operation.
shapesIn :: Text -> IO [[String]]
shapesIn source = do
  sunk <- sink source
  pure
    [ map (kindOf . instructionOperation) (blockInstructions b) <> ending b
    | f <- functionsIn sunk
    , b <- functionBlocks f
    ]
  where
    ending b = case terminatorTransfer (blockTerminator b) of
      Ret _ -> ["ret"]
      Switch {} -> ["switch"]
      _ -> []

-- | What each instruction reads, block by block, in order.
readsIn :: Text -> IO [[Local]]
readsIn source = do
  sunk <- sink source
  pure
    [ concatMap (localsUsedBy . instructionOperation) (blockInstructions b)
    | f <- functionsIn sunk
    , b <- functionBlocks f
    ]

kindOf :: Operation operand -> String
kindOf operation = case operation of
  OAssign _ -> "copy"
  OBinary _ -> "add"
  OICmp _ -> "icmp"
  OStore _ -> "store"
  OAlloca _ -> "alloca"
  _ -> "other"

-- | A program the pass leaves exactly as it found it.
unchanged :: Text -> Assertion
unchanged source = do
  parsed <- expectParse "<inline>" source
  let lowered = lower parsed
  assertEqual "unchanged" lowered (sinkCommonTails lowered)

sink :: Text -> IO Program
sink source = do
  parsed <- expectParse "<inline>" source
  pure (sinkCommonTails (lower parsed))
