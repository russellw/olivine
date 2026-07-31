-- | The inlining pass.
--
-- Two questions asked separately: which calls the pass decides it may replace,
-- which is nearly the whole of it, and what the body looks like once it has
-- been copied in.
--
-- The first is asked by counting the calls that survive, because that is the
-- one thing every refusal has in common and it does not depend on how the
-- copy is numbered.  Each case gives @\@g@ a different definition and leaves
-- @\@f@ calling it once, so a surviving call means the pass looked at that
-- definition and said no.
module Inlining (inliningTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.Inline (bodySize, inlineCalls, sizeThreshold)
import Olivine.Core.Program
import Olivine.Core.Raise (raise)
import Olivine.Pipeline (optimize)
import Olivine.Syntax.Function (Signature (..))
import Olivine.Syntax.Instruction (Call (..))
import Olivine.Syntax.Name (nameText)
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Value (TypedValue (..), Value (..))

inliningTests :: TestTree
inliningTests =
  testGroup
    "inlining"
    [ testGroup
        "what may be inlined"
        [ testCase "a small function" $
            callsTo "g" (small <> caller) @?>= 0
        , -- Reached by copying one body in and finding another call in it,
          -- which is what makes one sweep enough.
          testCase "a small function calling a small function" $
            callsLeft (relay <> small <> callerOf "relay") @?>= 0
        , testCase "a function calling itself" $
            callsTo "g" (recursive <> caller) @?>= 1
        , -- The pair a check against the caller lets through: neither of them
          -- reaches @f, so only asking whether the callee reaches itself
          -- refuses them.
          testCase "two functions calling each other" $
            callsTo "ping" (pinging <> ponging <> callerOf "ping") @?>= 1
        , testCase "a body over the size threshold" $
            callsTo "g" (large <> caller) @?>= 1
        , testCase "a body over the threshold marked alwaysinline" $
            callsTo "g" (attributed "alwaysinline" large <> caller) @?>= 0
        , testCase "a body marked noinline" $
            callsTo "g" (attributed "noinline" small <> caller) @?>= 1
        , testCase "a body marked optnone" $
            callsTo "g" (attributed "optnone noinline" small <> caller) @?>= 1
        , testCase "a body marked returns_twice" $
            callsTo "g" (attributed "returns_twice" small <> caller) @?>= 1
        , -- Not the callee's own attribute but one it calls through: a
          -- @setjmp@ has to stay in the function that wrote it, because the
          -- licence to hold that function's locals in registers across the
          -- second return is scoped to it and the caller was never given one.
          -- Either end may carry the attribute, and both are asked.
          testCase "a body calling a function declared returns_twice" $
            callsTo "g" (jumping "returns_twice" "" <> caller) @?>= 1
        , testCase "a body calling one with returns_twice on the call" $
            callsTo "g" (jumping "" "returns_twice" <> caller) @?>= 1
        , -- What clang actually writes: the attribute reaches the call site
          -- through a group, as everything else does at -O0.
          testCase "returns_twice written in a group on the call" $
            callsTo
              "g"
              (jumping "" "#0" <> caller <> "attributes #0 = { nounwind returns_twice }\n")
              @?>= 1
        , -- The control.  The same body calling the same declaration, with
          -- nothing saying it comes back twice, is copied like any other.
          testCase "a body calling an ordinary declared function" $
            callsTo "g" (jumping "" "" <> caller) @?>= 0
        , -- The attributes that decide this are nearly always written in a
          -- group rather than on the function, which is how clang emits
          -- noinline and optnone at -O0.
          testCase "noinline written in an attribute group" $
            callsTo "g" (grouped <> caller <> "attributes #0 = { noinline }\n") @?>= 1
        , -- Not what the callee says: what the caller says about being
          -- optimized at all.
          testCase "a caller marked optnone" $
            callsTo "g" (small <> attributed "optnone noinline" caller) @?>= 1
        , testCase "a function only declared" $
            callsTo "g" ("declare i32 @g(i32)\n" <> caller) @?>= 1
        , testCase "a call through a pointer" $
            callsLeft (small <> indirectCaller) @?>= 1
        , testCase "a variadic function" $
            callsTo "g" (variadic <> caller) @?>= 1
        , testCase "more arguments than parameters" $
            callsTo "g" (small <> misCaller) @?>= 1
        , -- musttail is a promise about the machine code that inlining would
          -- break rather than keep.  Plain tail says something about the
          -- callee that stays true wherever its body is written, so the
          -- marker simply has nowhere left to go.
          testCase "a musttail call" $
            callsTo "g" (small <> tailCaller "musttail") @?>= 1
        , testCase "a tail call" $
            callsTo "g" (small <> tailCaller "tail") @?>= 0
        , -- The same attribute slot as a function's, and the same answer: a
          -- body worth copying everywhere else may still be one this call was
          -- told to leave alone.
          testCase "noinline written on the call" $
            callsTo "g" (small <> noinlineCaller) @?>= 1
        , testCase "a calling convention the callee does not use" $
            callsTo "g" (small <> conventionCaller) @?>= 1
        , testCase "an argument passed byval" $
            callsTo "g" (byvalCallee <> byvalCaller) @?>= 1
        , -- A weak definition is one candidate and the linker picks; the _odr
          -- forms promise every candidate is the same body.
          testCase "a weak definition" $
            callsTo "g" (linked "weak" <> caller) @?>= 1
        , testCase "a linkonce definition" $
            callsTo "g" (linked "linkonce" <> caller) @?>= 1
        , testCase "a linkonce_odr definition" $
            callsTo "g" (linked "linkonce_odr" <> caller) @?>= 0
        , testCase "an internal definition" $
            callsTo "g" (linked "internal" <> caller) @?>= 0
        , -- An allocation that cannot be moved to the caller's entry block
          -- stops the whole body being copied, since leaving it where it is
          -- would let a call in a loop allocate once an iteration.
          testCase "an allocation in the entry block" $
            callsTo "g" (allocating <> caller) @?>= 0
        , testCase "an allocation outside the entry block" $
            callsTo "g" (allocatingLate <> caller) @?>= 1
        , testCase "an allocation whose size is computed" $
            callsTo "g" (allocatingComputed <> caller) @?>= 1
        ]
    , testGroup
        "what the copy says"
        [ -- Passing an argument is assigning to the parameter, so the constant
          -- reaches the body and folding takes it from there.
          testCase "an argument becomes the value the body computes with" $
            rendered (small <> constantCaller) @?>>= "ret i32 8"
        , -- The case that needs a phi in single assignment form.  Nothing in
          -- the pass builds one: each return assigns, and reconstruction works
          -- out on the way back to LLVM what that means where the paths meet.
          -- The pipeline goes on to make selects of both branches, which is
          -- "Olivine.Core.Pass.IfConversion"'s doing and is tested there.
          testCase "three returns become one phi" $
            phis (branching <> caller) @?>= 1
        , testCase "a void callee leaves the result unnamed" $
            rendered (voided <> voidCaller) @?>>= "store i32 7"
        , -- The allocation moves to the caller's entry block, which is where
          -- it has to be for a call in a loop to allocate once.
          testCase "an allocation lands in the caller's entry block" $
            allocasInEntry (allocating <> loopingCaller) @?>= 1
        , -- Nothing of the callee's numbering may survive into the caller's.
          testCase "two calls to one function in one block" $
            callsTo "g" (small <> twiceCaller) @?>= 0
        ]
    , testGroup
        "the size a body is judged by"
        [ -- A block counts one more than it holds, for its terminator.
          testCase "instructions and terminators" $
            sizeOf small @?>= 2
        , testCase "a body written in several blocks" $
            sizeOf branching @?>= 7
        , testCase "the threshold is where the cases above put it" $
            (sizeOf large >>= \n -> pure (n > sizeThreshold)) @?>= True
        ]
    ]

-- The callee, defined a different way in each case.  Two instructions, well
-- under the threshold, and nothing about it refuses inlining.
small :: Text
small =
  T.unlines
    [ "define i32 @g(i32 %x) {"
    , "entry:"
    , "  %r = add i32 %x, 1"
    , "  ret i32 %r"
    , "}"
    ]

-- | A callee whose own body calls another, so that one sweep has to look again
-- at what it just copied in.
relay :: Text
relay =
  T.unlines
    [ "define i32 @relay(i32 %x) {"
    , "entry:"
    , "  %r = call i32 @g(i32 %x)"
    , "  ret i32 %r"
    , "}"
    ]

recursive :: Text
recursive =
  T.unlines
    [ "define i32 @g(i32 %x) {"
    , "entry:"
    , "  %z = icmp sle i32 %x, 0"
    , "  br i1 %z, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %x, 1"
    , "  %r = call i32 @g(i32 %m)"
    , "  ret i32 %r"
    , "}"
    ]

pinging :: Text
pinging = mutual "ping" "pong"

ponging :: Text
ponging = mutual "pong" "ping"

mutual :: Text -> Text -> Text
mutual here there =
  T.unlines
    [ "define i32 @" <> here <> "(i32 %x) {"
    , "entry:"
    , "  %z = icmp sle i32 %x, 0"
    , "  br i1 %z, label %base, label %step"
    , "base:"
    , "  ret i32 0"
    , "step:"
    , "  %m = sub i32 %x, 1"
    , "  %r = call i32 @" <> there <> "(i32 %m)"
    , "  ret i32 %r"
    , "}"
    ]

-- | Three returns reaching one use, which is the shape a phi is for.
branching :: Text
branching =
  T.unlines
    [ "define i32 @g(i32 %x) {"
    , "entry:"
    , "  %below = icmp slt i32 %x, 0"
    , "  br i1 %below, label %low, label %check"
    , "low:"
    , "  ret i32 0"
    , "check:"
    , "  %above = icmp sgt i32 %x, 9"
    , "  br i1 %above, label %high, label %same"
    , "high:"
    , "  ret i32 9"
    , "same:"
    , "  ret i32 %x"
    , "}"
    ]

-- | Comfortably past the threshold, and one straight line so that nothing but
-- its size can be what refuses it.
large :: Text
large =
  T.unlines
    ( ["define i32 @g(i32 %x) {", "entry:", "  %v0 = add i32 %x, 0"]
        <> [ "  %v" <> T.pack (show n) <> " = add i32 %v" <> T.pack (show (n - 1 :: Int)) <> ", 1"
           | n <- [1 .. 20 :: Int]
           ]
        <> ["  ret i32 %v20", "}"]
    )

variadic :: Text
variadic =
  T.unlines
    [ "define i32 @g(i32 %x, ...) {"
    , "entry:"
    , "  %r = add i32 %x, 1"
    , "  ret i32 %r"
    , "}"
    ]

allocating :: Text
allocating =
  T.unlines
    [ "define i32 @g(i32 %x) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %x, ptr %s, align 4"
    , "  call void @sink(ptr %s)"
    , "  %r = load i32, ptr %s, align 4"
    , "  ret i32 %r"
    , "}"
    , "declare void @sink(ptr)"
    ]

-- | An allocation reached more than once, which is a body deliberately asking
-- for storage per iteration and not one slot to be shared.
allocatingLate :: Text
allocatingLate =
  T.unlines
    [ "define i32 @g(i32 %x) {"
    , "entry:"
    , "  br label %body"
    , "body:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %x, ptr %s, align 4"
    , "  call void @sink(ptr %s)"
    , "  %r = load i32, ptr %s, align 4"
    , "  ret i32 %r"
    , "}"
    , "declare void @sink(ptr)"
    ]

-- | A size that is a parameter, so the allocation cannot go above the block
-- that binds it.
allocatingComputed :: Text
allocatingComputed =
  T.unlines
    [ "define i32 @g(i32 %x) {"
    , "entry:"
    , "  %s = alloca i32, i32 %x, align 4"
    , "  call void @sink(ptr %s)"
    , "  ret i32 %x"
    , "}"
    , "declare void @sink(ptr)"
    ]

voided :: Text
voided =
  T.unlines
    [ "define void @g(ptr %p, i32 %v) {"
    , "entry:"
    , "  store i32 %v, ptr %p, align 4"
    , "  ret void"
    , "}"
    ]

byvalCallee :: Text
byvalCallee =
  T.unlines
    [ "define i32 @g(ptr byval(i32) %p) {"
    , "entry:"
    , "  %r = load i32, ptr %p, align 4"
    , "  ret i32 %r"
    , "}"
    ]

-- | A callee that calls @setjmp@, with the attribute written where the
-- argument puts it: on the declaration, on the call site, in neither.
--
-- Two instructions like 'small', so nothing but the attribute can be what
-- refuses it, and the same body with both arguments empty is the control.
jumping :: Text -> Text -> Text
jumping onDeclaration onCall =
  T.unlines
    [ "@env = global [64 x i64] zeroinitializer, align 16"
    , "define i32 @g(i32 %x) {"
    , "entry:"
    , "  %r = call i32 @setjmp(ptr @env)" <> spaced onCall
    , "  ret i32 %r"
    , "}"
    , "declare i32 @setjmp(ptr)" <> spaced onDeclaration
    ]
  where
    spaced "" = ""
    spaced attribute = " " <> attribute

grouped :: Text
grouped =
  T.unlines
    [ "define i32 @g(i32 %x) #0 {"
    , "entry:"
    , "  %r = add i32 %x, 1"
    , "  ret i32 %r"
    , "}"
    ]

-- | The callee with an attribute written on it, by putting one in front of the
-- opening brace.
attributed :: Text -> Text -> Text
attributed attribute = T.replace ") {" (") " <> attribute <> " {")

linked :: Text -> Text
linked linkage = T.replace "define i32 @g" ("define " <> linkage <> " i32 @g") small

-- The caller, calling @g once.
caller :: Text
caller = callerOf "g"

callerOf :: Text -> Text
callerOf callee =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %r = call i32 @" <> callee <> "(i32 %n)"
    , "  ret i32 %r"
    , "}"
    ]

constantCaller :: Text
constantCaller =
  T.unlines
    [ "define i32 @f() {"
    , "entry:"
    , "  %r = call i32 @g(i32 7)"
    , "  ret i32 %r"
    , "}"
    ]

twiceCaller :: Text
twiceCaller =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %a = call i32 @g(i32 %n)"
    , "  %b = call i32 @g(i32 %a)"
    , "  ret i32 %b"
    , "}"
    ]

loopingCaller :: Text
loopingCaller =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %j, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %r = call i32 @g(i32 %i)"
    , "  %j = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %i"
    , "}"
    ]

voidCaller :: Text
voidCaller =
  T.unlines
    [ "define void @f(ptr %p) {"
    , "entry:"
    , "  call void @g(ptr %p, i32 7)"
    , "  ret void"
    , "}"
    ]

indirectCaller :: Text
indirectCaller =
  T.unlines
    [ "define i32 @f(ptr %p, i32 %n) {"
    , "entry:"
    , "  %r = call i32 %p(i32 %n)"
    , "  ret i32 %r"
    , "}"
    ]

misCaller :: Text
misCaller =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %r = call i32 @g(i32 %n, i32 %n)"
    , "  ret i32 %r"
    , "}"
    ]

conventionCaller :: Text
conventionCaller =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %r = call fastcc i32 @g(i32 %n)"
    , "  ret i32 %r"
    , "}"
    ]

tailCaller :: Text -> Text
tailCaller kind =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %r = " <> kind <> " call i32 @g(i32 %n)"
    , "  ret i32 %r"
    , "}"
    ]

noinlineCaller :: Text
noinlineCaller =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %r = call i32 @g(i32 %n) noinline"
    , "  ret i32 %r"
    , "}"
    ]

byvalCaller :: Text
byvalCaller =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %r = call i32 @g(ptr byval(i32) %p)"
    , "  ret i32 %r"
    , "}"
    ]

(@?>=) :: (Eq a, Show a) => IO a -> a -> Assertion
got @?>= expected = got >>= (@?= expected)

-- | Whether the rendered output contains a line of text.
(@?>>=) :: IO Text -> Text -> Assertion
got @?>>= expected = do
  actual <- got
  assertBool (T.unpack ("expected " <> expected <> " in:\n" <> actual)) $
    expected `T.isInfixOf` actual

-- | How many calls to one function @\@f@ still makes once the pass has run.
--
-- Named rather than counted in total, because a body copied in brings its own
-- calls with it: inlining a callee that calls @\@sink@ leaves @\@f@ making a
-- call, and a count that could not tell the two apart would read that as a
-- refusal.
--
-- The pass alone, not the pipeline: nothing else may be what removed the call.
callsTo :: Text -> Text -> IO Int
callsTo callee source = do
  program <- inlineCalls . lower <$> expectParse "<inline>" source
  pure (length (filter (== Just callee) (callsIn program)))

-- | How many calls of any kind @\@f@ still makes, for the cases where what is
-- called has no name to ask after or where nothing at all should be left.
callsLeft :: Text -> IO Int
callsLeft source = do
  program <- inlineCalls . lower <$> expectParse "<inline>" source
  pure (length (callsIn program))

-- | Every call in @\@f@, each as the symbol it names or nothing when it names
-- a pointer.
callsIn :: Program -> [Maybe Text]
callsIn program =
  [ case typedValue (callCallee call) of
      VGlobal name -> Just (nameText name)
      _ -> Nothing
  | f <- functionsIn program
  , named "f" f
  , b <- functionBlocks f
  , i <- blockInstructions b
  , OCall call <- [instructionOperation i]
  ]

-- | How many allocations stand in @\@f@'s entry block.
allocasInEntry :: Text -> IO Int
allocasInEntry source = do
  program <- inlineCalls . lower <$> expectParse "<inline>" source
  pure $
    length
      [ ()
      | f <- functionsIn program
      , named "f" f
      , b <- take 1 (functionBlocks f)
      , i <- blockInstructions b
      , OAlloca _ <- [instructionOperation i]
      ]

named :: Text -> Function -> Bool
named name f = nameText (signatureName (functionSignature f)) == name

sizeOf :: Text -> IO Int
sizeOf source = do
  program <- lower <$> expectParse "<inline>" source
  pure (sum (map bodySize (functionsIn program)))

-- | How many phis the whole pipeline writes, which is where the returns of an
-- inlined body meeting at one use become visible.
-- | How many phis the copied body needs once it is back in single assignment
-- form.
--
-- Inlining and the raising, not the pipeline: what the returns of a callee
-- become where the paths meet is the question, and further down the pipeline
-- "Olivine.Core.Pass.IfConversion" answers it a second time by removing the
-- paths.
phis :: Text -> IO Int
phis source = do
  program <- lower <$> expectParse "<inline>" source
  let written = renderModule (raise (inlineCalls program))
  pure (length (filter (" = phi " `T.isInfixOf`) (T.lines written)))

rendered :: Text -> IO Text
rendered source = renderModule . optimize <$> expectParse "<inline>" source
