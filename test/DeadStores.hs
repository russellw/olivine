-- | The dead store pass.
--
-- Every case is written as which stores come back, named by the constants they
-- write, so that a test says what the function still does rather than how many
-- instructions it has.  The pass is run on its own rather than through the
-- pipeline: what these are about is what the walk concludes, and running
-- promotion first would take most of the slots away before it could conclude
-- anything.
module DeadStores (deadStoreTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.DeadStores (eliminateDeadStores)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (AtomicStore (..), Store (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

deadStoreTests :: TestTree
deadStoreTests =
  testGroup
    "dead stores"
    [ testGroup
        "a store answered by a later one"
        [ testCase "the same address written twice" $
            written (body ["  store i32 1, ptr %p", "  store i32 2, ptr %p"])
              @?>= [2]
        , -- The point of the whole walk: what stands between them is what
          -- decides, not the two stores.
          testCase "a load of the same address between them" $
            written
              ( body
                  [ "  store i32 1, ptr %p"
                  , "  %v = load i32, ptr %p"
                  , "  store i32 2, ptr %p"
                  ]
              )
              @?>= [1, 2]
        , -- The aliasing answering: two allocations are two objects, so a read
          -- of one is no reason to keep a write to the other.
          testCase "a load of other storage between them" $
            written
              ( body
                  [ "  %q = alloca i32, align 4"
                  , "  store i32 1, ptr %p"
                  , "  %v = load i32, ptr %q"
                  , "  store i32 2, ptr %p"
                  ]
              )
              @?>= [2]
        , -- A narrower write leaves the rest of the earlier one readable, so
          -- it is no answer to it.  'mustAlias' is what declines this, and it
          -- declines the other way round as well: a wider write covers the
          -- earlier one and more, which this does not read as covering it.
          testCase "a narrower store over it" $
            written
              ( body
                  [ "  store i32 1, ptr %p"
                  , "  store i8 2, ptr %p"
                  ]
              )
              @?>= [1, 2]
        , -- Two names for one address, which is what promotion leaves behind
          -- everywhere and what makes this a question for the aliasing rather
          -- than a comparison of two operands.
          testCase "the same address reached two ways" $
            written
              ( body
                  [ "  %q = getelementptr inbounds i32, ptr %p, i64 0"
                  , "  store i32 1, ptr %p"
                  , "  store i32 2, ptr %q"
                  ]
              )
              @?>= [2]
        , testCase "another element of the same array" $
            written
              ( body
                  [ "  %q = getelementptr inbounds i32, ptr %p, i64 1"
                  , "  store i32 1, ptr %p"
                  , "  store i32 2, ptr %q"
                  ]
              )
              @?>= [1, 2]
        ]
    , testGroup
        "a store answered by the storage going away"
        [ -- The frame goes at the return, so nothing can read what was left in
          -- it.
          testCase "a slot of this function's own frame" $
            written
              (body ["  %s = alloca i32, align 4", "  store i32 1, ptr %s"])
              @?>= []
        , -- Storage the caller has, which outlives the call.
          testCase "storage handed in" $
            written (body ["  store i32 1, ptr %p"]) @?>= [1]
        , -- The address having been let out changes nothing about the frame:
          -- the storage is gone at the return however far its address
          -- travelled, and reading it afterwards is undefined rather than
          -- something to keep the store for.  @opt -passes=dse@ agrees.
          testCase "a slot whose address was let out earlier" $
            written
              ( body
                  [ "  %s = alloca i32, align 4"
                  , "  call void @use(ptr %s)"
                  , "  store i32 1, ptr %s"
                  ]
              )
              @?>= []
        , -- And what that escape does decide: a call after the store can read
          -- the value through the address it was given.
          testCase "a slot read through by a later call" $
            written
              ( body
                  [ "  %s = alloca i32, align 4"
                  , "  call void @use(ptr %s)"
                  , "  store i32 1, ptr %s"
                  , "  call void @stranger()"
                  ]
              )
              @?>= [1]
        , testCase "a slot no call was ever given" $
            written
              ( body
                  [ "  %s = alloca i32, align 4"
                  , "  store i32 1, ptr %s"
                  , "  call void @stranger()"
                  ]
              )
              @?>= []
        , -- What the program itself says about where storage begins and ends.
          testCase "a slot whose lifetime ends after it" $
            written
              ( body
                  [ "  %s = alloca i32, align 4"
                  , "  call void @use(ptr %s)"
                  , "  store i32 1, ptr %s"
                  , "  call void @llvm.lifetime.end.p0(i64 4, ptr %s)"
                  , "  call void @stranger()"
                  ]
              )
              @?>= []
        ]
    , testGroup
        "what a call in between leaves standing"
        [ testCase "one that may do anything" $
            written
              ( body
                  [ "  store i32 1, ptr %p"
                  , "  call void @stranger()"
                  , "  store i32 2, ptr %p"
                  ]
              )
              @?>= [1, 2]
        , testCase "one that does nothing at all" $
            written
              ( body
                  [ "  store i32 1, ptr %p"
                  , "  call void @quiet()"
                  , "  store i32 2, ptr %p"
                  ]
              )
              @?>= [2]
        , -- Three promises and each of them is needed.  A call that only reads
          -- can read the value; one that may throw is a way out of the
          -- function that never reaches the later store; one that may not come
          -- back is another.  @opt -passes=dse@ keeps the store in all three.
          testCase "one that only reads" $
            written
              ( body
                  [ "  store i32 1, ptr %p"
                  , "  call void @reader()"
                  , "  store i32 2, ptr %p"
                  ]
              )
              @?>= [1, 2]
        , testCase "one that may throw" $
            written
              ( body
                  [ "  store i32 1, ptr %p"
                  , "  call void @thrower()"
                  , "  store i32 2, ptr %p"
                  ]
              )
              @?>= [1, 2]
        , testCase "one that may not come back" $
            written
              ( body
                  [ "  store i32 1, ptr %p"
                  , "  call void @endless()"
                  , "  store i32 2, ptr %p"
                  ]
              )
              @?>= [1, 2]
        , -- None of which is about this function's own frame: nothing that
          -- happens after such a call has a way to name a slot whose address
          -- never left.
          testCase "one that may do anything, over a slot of this frame" $
            written
              ( body
                  [ "  %s = alloca i32, align 4"
                  , "  store i32 1, ptr %s"
                  , "  call void @stranger()"
                  , "  store i32 2, ptr %s"
                  ]
              )
              @?>= []
        ]
    , testGroup
        "what is never removed"
        [ -- The point of writing one is that the write happens.
          testCase "a volatile store" $
            written
              ( body
                  [ "  store volatile i32 1, ptr %p"
                  , "  store i32 2, ptr %p"
                  ]
              )
              @?>= [1, 2]
        , -- And a volatile store settles nothing about what stands at the
          -- address afterwards, so it is no answer to the store above it
          -- either.
          testCase "a store a volatile one writes over" $
            written
              ( body
                  [ "  store i32 1, ptr %p"
                  , "  store volatile i32 2, ptr %p"
                  ]
              )
              @?>= [1, 2]
        , testCase "an atomic store" $
            written
              ( body
                  [ "  store atomic i32 1, ptr %p seq_cst, align 4"
                  , "  store i32 2, ptr %p"
                  ]
              )
              @?>= [1, 2]
        , -- An atomic is where another thread's reads are ordered against this
          -- one's writes, so everything a stranger can reach may be read at
          -- it.
          testCase "a store an atomic stands after" $
            written
              ( body
                  [ "  store i32 1, ptr %p"
                  , "  fence seq_cst"
                  , "  store i32 2, ptr %p"
                  ]
              )
              @?>= [1, 2]
        ]
    , testGroup
        "over the whole graph"
        [ -- Dead on one way on and not the other is not dead: the answer has
          -- to hold on every path from the store.
          testCase "overwritten on one arm of a branch" $
            written (branching ["  store i32 2, ptr %p"] []) @?>= [1, 2]
        , testCase "overwritten on both arms" $
            written (branching ["  store i32 2, ptr %p"] ["  store i32 3, ptr %p"])
              @?>= [2, 3]
        , -- Read on one arm and overwritten on the other, which is the same
          -- question the other way up.
          testCase "read on one arm and overwritten on the other" $
            written (branching ["  store i32 2, ptr %p"] ["  %v = load i32, ptr %p"])
              @?>= [1, 2]
        , -- A store whose only overwrite is itself, next time round.  LLVM
          -- declines it too: @opt -passes=dse@ leaves this loop as written.
          testCase "overwritten by the next turn of a loop" $
            written (spinning ["  store i32 1, ptr %p"]) @?>= [1]
        ]
    ]

-- | The values the surviving stores write, in order.
--
-- Every store in these writes a distinct constant, so this says which of them
-- came back without saying anything about how they are numbered.  The atomic
-- form counts: it is a different operation and this pass never removes one,
-- which is a thing to check rather than a thing to leave out — reading only
-- 'OStore' made the case that asks it pass whatever the pass did.
written :: Text -> IO [Integer]
written source = do
  parsed <- expectParse "<inline>" source
  let program = eliminateDeadStores (lower parsed)
  pure
    [ n
    | f <- functionsIn program
    , b <- functionBlocks f
    , i <- blockInstructions b
    , TypedValue _ (VInteger n) <- stored (instructionOperation i)
    ]
  where
    stored operation = case operation of
      OStore s -> [storeValue s]
      OAtomicStore s -> [atomicStoreValue s]
      _ -> []

-- | A module with the declarations these are written against, and one function
-- holding the given lines.
--
-- The layout is here because two accesses are the same bytes only where their
-- extents are known, and a step is measured in bytes: without it every pointer
-- arithmetic case would be declined for a reason none of them is about.
module' :: [Text] -> Text
module' lines' =
  T.unlines $
    [ "target datalayout = \"e-m:e-i64:64-f80:128-n8:16:32:64-S128\""
    , "declare void @use(ptr)"
    , "declare void @stranger()"
    , "declare void @quiet() memory(none) nounwind willreturn"
    , "declare void @reader() memory(read) nounwind willreturn"
    , "declare void @thrower() memory(none) willreturn"
    , "declare void @endless() memory(none) nounwind"
    , "declare void @llvm.lifetime.end.p0(i64, ptr)"
    ]
      <> lines'

body :: [Text] -> Text
body lines' =
  module' (["define void @f(ptr %p) {", "entry:"] <> lines' <> ["  ret void", "}"])

-- | The same store on two paths that meet, with whatever each path holds.
branching :: [Text] -> [Text] -> Text
branching left right =
  module' $
    [ "define void @f(ptr %p, i1 %c) {"
    , "entry:"
    , "  store i32 1, ptr %p"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    ]
      <> left
      <> ["  br label %join", "no:"]
      <> right
      <> ["  br label %join", "join:", "  ret void", "}"]

-- | A loop with no way out of it, which is the only shape where a store's own
-- next run is all that could answer it.
spinning :: [Text] -> Text
spinning lines' =
  module' $
    ["define void @f(ptr %p) {", "entry:", "  br label %loop", "loop:"]
      <> lines'
      <> ["  br label %loop", "}"]

infix 1 @?>=

-- | Compare against what an @IO@ action gives, which is how the sources here
-- have to be read: parsing is where a malformed one is reported.
(@?>=) :: (Eq a, Show a) => IO a -> a -> Assertion
actual @?>= expected = do
  got <- actual
  got @?= expected
