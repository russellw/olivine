-- | The common subexpression pass.
--
-- Two things are checked separately: which computations are shared, and which
-- must not be.  The second is where the bugs are — sharing a call, or an
-- expression whose operand was reassigned in between, gives a module LLVM
-- accepts and a program that computes something else.
module Subexpressions (subexpressionTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.CommonSubexpressions (eliminateCommonSubexpressions, shareable)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Program
import Olivine.Syntax.Instruction hiding (Operation (..))
import Olivine.Syntax.Name
import Olivine.Syntax.Type
import Olivine.Syntax.Value

subexpressionTests :: TestTree
subexpressionTests =
  testGroup
    "common subexpressions"
    [ testGroup
        "what is shared"
        [ -- Locals are numbered as they are defined: the two parameters, then
          -- %x %y %z as 2 to 4.
          testCase "the same sum twice in one block" $ do
            copies <- copiesIn twice
            assertEqual "the second reads the first" [(Local 3, Local 2)] copies
        , -- The point of walking the blocks rather than each block alone: the
          -- entry block is the only way to reach %again, so what it worked out
          -- is worked out wherever control is in there.
          testCase "across a branch, from the block above it" $ do
            copies <- copiesIn dominating
            assertEqual "the second reads the first" [(Local 4, Local 3)] copies
        , -- Two pointer steps written identically arrive here reading two
          -- different locals, because the lowering splits a getelementptr and
          -- what LLVM wrote once becomes a chain.  Resolving the operands
          -- through the copies is what makes them one expression again.
          testCase "a pointer step whose operands are copies" $ do
            copies <- copiesIn stepped
            assertBool
              ("expected a shared step in " <> show copies)
              (not (null copies))
        , -- Within one turn of a loop the walk sees both computations, which
          -- is the case the corpus has.  The locals here are the three
          -- parameters, then %e %i %c %x %y %j as 3 to 8.
          testCase "twice in a loop body" $ do
            copies <- copiesIn looping
            assertEqual "the second reads the first" [(Local 7, Local 6)] copies
        ]
    , testGroup
        "what one walk costs"
        [ -- What the block before the loop worked out is not available inside
          -- it, because the block the loop begins at has a predecessor the
          -- walk has not been to.  Stated as a test rather than left to the
          -- module comment, so that the pass acquiring a fixed point is a test
          -- that changes rather than a claim somebody has to notice is stale.
          testCase "an expression carried into a loop is recomputed" $ do
            copies <- copiesIn looping
            assertBool
              ("expected %x to compute it afresh in " <> show copies)
              (Local 6 `notElem` map fst copies)
        ]
    , testGroup
        "what is not"
        [ -- @add nsw@ is poison where it overflows and @add@ is a number, so
          -- the two are not one expression.  Sharing the plain result for the
          -- flagged instruction would be sound and is not done; sharing the
          -- flagged result for the plain one would spread poison.
          testCase "the same sum with different flags" $ do
            copies <- copiesIn flagged
            assertEqual "nothing is shared" [] copies
        , -- The reason availability is a question at all.  Promotion turns
          -- the slot into a local assigned twice, and the second addition
          -- reads what the second assignment left there.
          testCase "an operand reassigned in between" $ do
            copies <- promotedCopiesIn reassigned
            assertEqual "nothing is shared" [] copies
        , -- The other half of the same rule: %a was a copy of the slot, and
          -- the store means it is no longer, so the additions that read %a and
          -- the slot are not the same expression however alike they look.
          testCase "an operand that has stopped being a copy" $ do
            copies <- promotedCopiesIn stale
            assertEqual "nothing is shared" [] copies
        , -- Available means computed on every path that arrives, and one arm
          -- of a branch is not every path.
          testCase "computed on only one path to here" $ do
            copies <- copiesIn oneArm
            assertEqual "nothing is shared" [] copies
        , -- Both arms compute it, but into different locals, so there is no
          -- one local a block below can read it from.  The core could hold
          -- the answer — two arms assigning to one local is exactly what
          -- reconstruction turns into a phi — which makes this a refinement
          -- this pass does not make rather than something it cannot say.
          testCase "computed on both paths into different locals" $ do
            copies <- copiesIn bothArms
            assertEqual "nothing is shared" [] copies
        , testCase "two calls to the same function" $ do
            copies <- copiesIn calling
            assertEqual "nothing is shared" [] copies
        , -- What a load answers is what memory holds, and the store in
          -- between changes that.  No load is shared at all, so this holds
          -- whether or not the store is there to see.
          testCase "two loads through the same pointer" $ do
            copies <- copiesIn loading
            assertEqual "nothing is shared" [] copies
        , testCase "two allocations of the same size" $ do
            copies <- copiesIn allocating
            assertEqual "nothing is shared" [] copies
        ]
    , testGroup
        "what may be shared at all"
        [ testCase "arithmetic" $ shareable (binary OpAdd) @?= True
        , testCase "a comparison" $ shareable comparison @?= True
        , testCase "a conversion" $ shareable conversion @?= True
        , testCase "a pointer step" $ shareable step @?= True
        , testCase "a field selection" $ shareable field @?= True
        , -- Dividing by zero is poison rather than a fault, so a division is
          -- as shareable as an addition: two of them with the same operands
          -- are poison together or a number together.
          testCase "division" $ shareable (binary OpSDiv) @?= True
        , -- Fresh storage each time, so two allocations are two objects.
          testCase "an allocation" $ shareable allocation @?= False
        , testCase "a load" $ shareable load' @?= False
        , testCase "a store" $ shareable store' @?= False
        , -- Nothing here can tell whether a call answers the same thing
          -- twice, or what it does on the way to answering.
          testCase "a call" $ shareable call' @?= False
        , -- Already the value it holds; there is no computation to repeat.
          testCase "an assignment" $ shareable assignment @?= False
        ]
    ]

-- | The instructions the pass turned into a copy of an earlier local, as the
-- local assigned and the local read.
--
-- An assignment of anything but a local is not one of these: the lowering
-- writes those itself, for a phi and for a pointer step that moves nowhere,
-- and they are not what this pass leaves behind.
copiesIn :: Text -> IO [(Local, Local)]
copiesIn = copiesAfter id

-- | The same, of a function promotion has already been over.
--
-- Promotion is what puts a local assigned more than once in front of this
-- pass, which no LLVM function can be written to produce directly: single
-- assignment is what the input is in.  The pipeline runs them in this order
-- for its own reasons, and these cases are why the order is not the only
-- thing keeping the answer right.
promotedCopiesIn :: Text -> IO [(Local, Local)]
promotedCopiesIn = copiesAfter promoteMemory

copiesAfter :: (Program -> Program) -> Text -> IO [(Local, Local)]
copiesAfter before source = do
  parsed <- expectParse "<inline>" source
  let shared = eliminateCommonSubexpressions (before (lower parsed))
      original = before (lower parsed)
      copies program =
        [ (name, read')
        | f <- functionsIn program
        , b <- functionBlocks f
        , Instruction (Just name) (OAssign (TypedValue _ (VLocal read'))) _ <-
            blockInstructions b
        ]
  -- What the pass added, rather than every copy in the result: lowering and
  -- promotion write their own, and those are not this pass's doing.
  pure [copy | copy <- copies shared, copy `notElem` copies original]

twice :: Text
twice =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b) {"
    , "entry:"
    , "  %x = add i32 %a, %b"
    , "  %y = add i32 %a, %b"
    , "  %z = add i32 %x, %y"
    , "  ret i32 %z"
    , "}"
    ]

flagged :: Text
flagged =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b) {"
    , "entry:"
    , "  %x = add nsw i32 %a, %b"
    , "  %y = add i32 %a, %b"
    , "  %z = add i32 %x, %y"
    , "  ret i32 %z"
    , "}"
    ]

dominating :: Text
dominating =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
    , "entry:"
    , "  %x = mul i32 %a, %b"
    , "  br i1 %c, label %again, label %done"
    , "again:"
    , "  %y = mul i32 %a, %b"
    , "  %z = add i32 %x, %y"
    , "  ret i32 %z"
    , "done:"
    , "  ret i32 %x"
    , "}"
    ]

oneArm :: Text
oneArm =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %join"
    , "yes:"
    , "  %x = mul i32 %a, %b"
    , "  br label %join"
    , "join:"
    , "  %y = mul i32 %a, %b"
    , "  ret i32 %y"
    , "}"
    ]

bothArms :: Text
bothArms =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  %x = mul i32 %a, %b"
    , "  br label %join"
    , "no:"
    , "  %y = mul i32 %a, %b"
    , "  br label %join"
    , "join:"
    , "  %z = mul i32 %a, %b"
    , "  ret i32 %z"
    , "}"
    ]

-- | A subscript written twice, which is what the corpus contains: clang emits
-- the same @getelementptr@ for the same expression rather than reusing one.
stepped :: Text
stepped =
  T.unlines
    [ "define i32 @f(ptr %p, i64 %i) {"
    , "entry:"
    , "  %q = getelementptr inbounds [8 x i32], ptr %p, i64 %i, i64 3"
    , "  %a = load i32, ptr %q, align 4"
    , "  %r = getelementptr inbounds [8 x i32], ptr %p, i64 %i, i64 3"
    , "  store i32 %a, ptr %r, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | A loop whose body computes one thing twice, and one thing the block
-- before the loop already computed.
looping :: Text
looping =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i32 %n) {"
    , "entry:"
    , "  %e = mul i32 %a, %b"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %j, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %x = mul i32 %a, %b"
    , "  %y = mul i32 %a, %b"
    , "  %j = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %e"
    , "}"
    ]

reassigned :: Text
reassigned =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %n, ptr %s, align 4"
    , "  %v = load i32, ptr %s, align 4"
    , "  %x = add i32 %v, 1"
    , "  store i32 7, ptr %s, align 4"
    , "  %w = load i32, ptr %s, align 4"
    , "  %y = add i32 %w, 1"
    , "  %t = add i32 %x, %y"
    , "  ret i32 %t"
    , "}"
    ]

stale :: Text
stale =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %n, ptr %s, align 4"
    , "  %a = load i32, ptr %s, align 4"
    , "  store i32 7, ptr %s, align 4"
    , "  %b = load i32, ptr %s, align 4"
    , "  %x = add i32 %a, 1"
    , "  %y = add i32 %b, 1"
    , "  %t = mul i32 %x, %y"
    , "  ret i32 %t"
    , "}"
    ]

calling :: Text
calling =
  T.unlines
    [ "declare i32 @tick(i32)"
    , "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %a = call i32 @tick(i32 %n)"
    , "  %b = call i32 @tick(i32 %n)"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

loading :: Text
loading =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %a = load i32, ptr %p, align 4"
    , "  store i32 99, ptr %p, align 4"
    , "  %b = load i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

allocating :: Text
allocating =
  T.unlines
    [ "declare void @keep(ptr, ptr)"
    , "define void @f() {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %y = alloca i32, align 4"
    , "  call void @keep(ptr %x, ptr %y)"
    , "  ret void"
    , "}"
    ]

-- Operations at the core's own operand type, for 'shareable', which reads
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

word :: Integer -> TypedValue Local
word n = TypedValue (TInteger 32) (VInteger n)

pointer :: TypedValue Local
pointer = TypedValue (TPointer Nothing) (VLocal (Local 0))
