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
    , -- Storage a call promised was fresh.  It does not die with the frame, so
      -- what makes a store into it dead is that every way of naming it has
      -- ended: the address never got out, and either the function returns or
      -- the storage goes back to the allocator.
      testGroup
        "a buffer a call handed back"
        [ testCase "filled and never read" $
            written (heap ["  store i32 1, ptr %b"]) @?>= []
        , -- The address is handed to the deallocator, which promises not to
          -- keep it, so it still never got out of sight.
          testCase "filled and given back" $
            written (heap ["  store i32 1, ptr %b", "  call void @release(ptr %b)"])
              @?>= []
        , -- And the same with the address named by an assume, which states a
          -- fact about the pointer and does nothing with it.
          testCase "filled with the pointer named by an assume" $
            written
              ( heap
                  [ "  call void @llvm.assume(i1 true) [ \"align\"(ptr %b, i64 16) ]"
                  , "  store i32 1, ptr %b"
                  ]
              )
              @?>= []
        , -- The store below the read is dead and the one above it is not,
          -- which is the ordinary rule arriving at storage it could not place
          -- until the promise told it what the buffer was.
          testCase "read between two stores" $
            written
              ( heap
                  [ "  store i32 1, ptr %b"
                  , "  %v = load i32, ptr %b"
                  , "  store i32 2, ptr %b"
                  ]
              )
              @?>= [1]
        , -- The soundness case for the whole of it.  @borrow@ promises not to
          -- keep the pointer, which is why the buffer is still unescaped — and
          -- it promises nothing about reading through it while it runs, so the
          -- store above it has to stay.  Getting this wrong is the failure the
          -- union in 'Olivine.Core.Effects.mayReach' exists to prevent.
          testCase "handed to a callee that may read it" $
            written (heap ["  store i32 1, ptr %b", "  call void @borrow(ptr %b)"])
              @?>= [1]
        , -- And where the address does get out, every later call can name the
          -- storage and nothing about it is known at all.
          testCase "handed to a callee that may keep it" $
            written (heap ["  store i32 1, ptr %b", "  call void @use(ptr %b)"])
              @?>= [1]
        , -- Two buffers, and the store into the one nothing names is dead
          -- while the store into the one handed over is not.  Telling them
          -- apart is what the promise on the return buys.
          testCase "two buffers, one of them handed over" $
            written
              ( module'
                  [ "define void @f() {"
                  , "entry:"
                  , "  %b = call noalias ptr @acquire(i64 16)"
                  , "  %c = call noalias ptr @acquire(i64 16)"
                  , "  store i32 1, ptr %b"
                  , "  store i32 2, ptr %c"
                  , "  call void @use(ptr %c)"
                  , "  ret void"
                  , "}"
                  ]
              )
              @?>= [2]
        ]
    , -- An offset need not be one number.  What a mask says is not which
      -- element but which four, and that is enough to tell the array from the
      -- integer beside it.
      --
      -- Each of these is the slot dying at the return with one load standing
      -- between the store and it, so what is being asked is exactly whether
      -- the load may be the read of what the store wrote.
      testGroup
        "an index the program bounded"
        [ testCase "a masked index cannot reach the field beside the array" $
            written
              ( labelled
                  [ "  store i32 1, ptr %s"
                  , "  %m = and i32 %i, 3"
                  , "  %w = sext i32 %m to i64"
                  , "  %a = getelementptr inbounds i8, ptr %t, i64 %w"
                  , "  %v = load i8, ptr %a, align 1"
                  ]
              )
              @?>= []
        , -- The same without the mask, where the index can be anywhere and the
          -- load may be the read of the integer.
          testCase "and an index nothing bounds may" $
            written
              ( labelled
                  [ "  store i32 1, ptr %s"
                  , "  %w = sext i32 %i to i64"
                  , "  %a = getelementptr inbounds i8, ptr %t, i64 %w"
                  , "  %v = load i8, ptr %a, align 1"
                  ]
              )
              @?>= [1]
        , -- A mask whose sign bit is set is no bound: @and i8 %b, -8@ clears
          -- the low three bits and leaves every negative value there was, so
          -- the index runs below zero and the load may be the read of the
          -- integer after all.  Reading the constant as written would have this
          -- bounded between zero and -8 and would be wrong twice over.
          testCase "and a mask that leaves the sign bit does not bound it" $
            written
              ( labelled
                  [ "  store i32 1, ptr %s"
                  , "  %m = and i8 %b, -8"
                  , "  %w = sext i8 %m to i64"
                  , "  %a = getelementptr inbounds i8, ptr %t, i64 %w"
                  , "  %v = load i8, ptr %a, align 1"
                  ]
              )
              @?>= [1]
        , -- The other half of the range: a store into one of the four bytes the
          -- index covers is a store the load may be reading.
          testCase "a store inside the range the index covers stays" $
            written
              ( labelled
                  [ "  store i8 1, ptr %t"
                  , "  %m = and i32 %i, 3"
                  , "  %w = sext i32 %m to i64"
                  , "  %a = getelementptr inbounds i8, ptr %t, i64 %w"
                  , "  %v = load i8, ptr %a, align 1"
                  ]
              )
              @?>= [1]
        ]
    , -- A range of addresses is not an address.  These are written through a
      -- pointer the function was handed, so no slot dies at the return and the
      -- only thing that can remove a store is a later one covering it.
      testGroup
        "a bounded address is no address"
        [ testCase "one bounded address does not write over another" $
            written
              ( handed
                  [ "  %m = and i32 %i, 3"
                  , "  %w = sext i32 %m to i64"
                  , "  %a = getelementptr inbounds i8, ptr %p, i64 %w"
                  , "  store i8 1, ptr %a"
                  , "  store i8 2, ptr %a"
                  ]
              )
              @?>= [1, 2]
        , -- And the same two stores through an address the program settled,
          -- which is the control: one offset and one extent make them one
          -- place, and the first goes.
          testCase "and a settled one does" $
            written
              ( handed
                  [ "  %a = getelementptr inbounds i8, ptr %p, i64 3"
                  , "  store i8 1, ptr %a"
                  , "  store i8 2, ptr %a"
                  ]
              )
              @?>= [2]
        ]
    , -- A slot of this frame handed to a callee that promises not to keep it.
      -- The slot has not escaped, which is what the promise is read for, and
      -- the callee may still read it.
      testGroup
        "a slot lent to a callee"
        [ testCase "a store above the call stays" $
            written (body ["  store i32 1, ptr %p", "  call void @borrow(ptr %p)"])
              @?>= [1]
        , -- What the promise buys is here, and the order is the whole of the
          -- test: the lend is /above/ the store, so nothing that runs after
          -- the store has been handed the address, and @stranger@ cannot name
          -- a slot that never got out.  The store dies with the frame.
          testCase "a store below the lend and above an unrelated call goes" $
            written
              ( slot
                  [ "  call void @borrow(ptr %s)"
                  , "  store i32 1, ptr %s"
                  , "  call void @stranger()"
                  ]
              )
              @?>= []
        , -- And without the promise it does not: handing the address over is
          -- how a stranger comes to know it, whether or not it is handed over
          -- before the store.
          testCase "and not where the callee may keep it" $
            written
              ( slot
                  [ "  call void @use(ptr %s)"
                  , "  store i32 1, ptr %s"
                  , "  call void @stranger()"
                  ]
              )
              @?>= [1]
        ]
    ]

-- | A body holding a @%label@ slot, called @%s@, with @%t@ at its array.
labelled :: [Text] -> Text
labelled lines' =
  module'
    ( [ "define void @f(i32 %n, i32 %i, i8 %b) {"
      , "entry:"
      , "  %s = alloca %label, align 4"
      , "  %t = getelementptr inbounds %label, ptr %s, i32 0, i32 1"
      ]
        <> lines'
        <> ["  ret void", "}"]
    )

-- | A body writing through a pointer it was handed, called @%p@.
--
-- Nothing here dies at the return, so a store goes only where a later one
-- covers it.
handed :: [Text] -> Text
handed lines' =
  module'
    ( ["define void @f(ptr %p, i32 %i) {", "entry:"]
        <> lines'
        <> ["  ret void", "}"]
    )

-- | A body holding a buffer a call handed back, called @%b@.
heap :: [Text] -> Text
heap lines' =
  module'
    ( ["define void @f() {", "entry:", "  %b = call noalias ptr @acquire(i64 16)"]
        <> lines'
        <> ["  ret void", "}"]
    )

-- | A body holding a slot of its own frame, called @%s@.
slot :: [Text] -> Text
slot lines' =
  module'
    ( ["define void @f() {", "entry:", "  %s = alloca i32, align 4"]
        <> lines'
        <> ["  ret void", "}"]
    )

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
    , -- An integer beside an array, which is the shape a bounded index is
      -- about: the four bytes the index can reach are the array and not the
      -- integer.
      "%label = type { i32, [4 x i8] }"
    , "declare void @use(ptr)"
    , "declare void @stranger()"
    , "declare void @quiet() memory(none) nounwind willreturn"
    , "declare void @reader() memory(read) nounwind willreturn"
    , "declare void @thrower() memory(none) willreturn"
    , "declare void @endless() memory(none) nounwind"
    , "declare void @llvm.lifetime.end.p0(i64, ptr)"
    , "declare void @llvm.assume(i1)"
    , -- An allocator, a deallocator, and a callee that is handed a pointer and
      -- promises only not to keep it.  The third is what tells the two rules
      -- apart: promising not to keep a pointer is not promising not to read
      -- through it.
      "declare noalias ptr @acquire(i64)"
    , "declare void @release(ptr allocptr captures(none)) allockind(\"free\")"
    , "declare void @borrow(ptr captures(none))"
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
