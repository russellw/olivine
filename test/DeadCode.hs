-- | The dead code pass.
module DeadCode (deadCodeTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Lower (lower)
import Olivine.Core.Instruction
import Olivine.Core.Effects (Behaviour (..), anything, nothing)
import Olivine.Core.Pass.DeadCode (eliminateDeadCode, removableWhenUnused)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Program
import Olivine.Syntax.Instruction hiding (Operation (..))
import Olivine.Syntax.Name
import Olivine.Syntax.Type
import Olivine.Syntax.Value

deadCodeTests :: TestTree
deadCodeTests =
  testGroup
    "dead code"
    [ -- Locals are numbered as they are defined: the three parameters,
      -- then %unread %chain %quiet %noisy %risky %room %answer as 3 to 9.
      testCase "what survives the sift" $ do
        results <- resultsOf sifted
        assertEqual
          "only what is read or does something"
          [Just (Local 6), Nothing, Just (Local 9)]
          results
    , -- Removing one instruction leaves the one feeding it unread, so a
      -- single sweep is not enough.
      testCase "a chain of dead instructions goes entirely" $ do
        results <- resultsOf sifted
        assertBool
          ("expected no chain in " <> show results)
          (Just (Local 4) `notElem` results)
    , -- Stated as what should be there rather than by comparing the pass
      -- with itself, which would hold however much it removed.
      testCase "nothing is removed when everything is read" $ do
        results <- resultsOf live
        assertEqual
          "every instruction survives"
          [Just (Local 2), Just (Local 3)]
          results
    , -- A marker says where storage begins and ends, so a pair of them around
      -- a slot nothing else names is a pair of them around nothing.  The dead
      -- store pass is what leaves these behind: it takes away every store to a
      -- slot, and what is left standing is the allocation and its brackets.
      testCase "a slot only its lifetime markers name goes" $ do
        results <- resultsOf marked
        assertEqual "the allocation and both markers" [Just (Local 2)] results
    , -- A value read only by the computation that produces it.  Each of the two
      -- is read by the other, so a sweep that keeps whatever anything reads
      -- keeps both for ever; what settles it is that neither is reached from a
      -- terminator or from anything that stays for its effects.  A loop counter
      -- nothing else reads is the case that matters, and it is what a loop
      -- whose test has been rewritten to ask about something else is left with.
      testCase "a value read only by what computes it" $ do
        results <- promotedResultsOf spinning
        assertEqual "the counter goes and the write stays" [Nothing] results
    , -- The same loop with the counter read once outside the cycle, which is
      -- what keeps it: the pair is only dead together.
      testCase "and the same one read from outside the cycle" $ do
        results <- promotedResultsOf spinningRead
        assertBool
          ("expected the counter kept in " <> show results)
          (length results > 1)
    , -- What the dead store pass leaves on the heap: a buffer written and
      -- never read, so the allocation is as dead as an @alloca@ nothing names
      -- and the deallocation is all that is left holding it.
      testCase "an allocation nothing reads goes, and its free with it" $ do
        results <- resultsOf (allocating "  call void @free(ptr %p)")
        assertEqual "nothing is left" [] results
    , -- The one part of this that is a choice: an allocation that is not made
      -- cannot fail, so the test of whether it succeeded is answered rather
      -- than kept.
      testCase "the test of whether it succeeded is answered" $ do
        operations <-
          operationsOf
            ( allocating
                ( T.unlines
                    [ "  %c = icmp eq ptr %p, null"
                    , "  %w = zext i1 %c to i32"
                    , "  store volatile i32 %w, ptr %q"
                    , "  call void @free(ptr %p)"
                    ]
                )
            )
        assertEqual
          "the pointer is not null"
          [OAssign (TypedValue (TInteger 1) (VBoolean False))]
          [o | o@(OAssign _) <- operations]
    , testCase "and the other way round" $ do
        operations <- operationsOf (allocating "  %c = icmp ne ptr %p, null\n  store volatile i1 %c, ptr %q")
        assertEqual
          "the pointer is not null"
          [OAssign (TypedValue (TInteger 1) (VBoolean True))]
          [o | o@(OAssign _) <- operations]
    , -- A fact stated about the pointer is not a use of the storage, which is
      -- the same line 'Olivine.Core.Instruction.assumedAbout' draws for what
      -- gets out of sight.
      testCase "an assumption about the pointer is not a use" $ do
        results <-
          resultsOf
            (allocating "  call void @llvm.assume(i1 true) [ \"align\"(ptr %p, i64 16) ]\n  call void @free(ptr %p)")
        assertEqual "nothing is left" [] results
    , testCase "storage something reads stays" $ do
        results <- resultsOf (allocating "  %v = load i32, ptr %p\n  store volatile i32 %v, ptr %q\n  call void @free(ptr %p)")
        assertBool ("expected the allocation kept in " <> show results) (length results == 4)
    , -- Where the pointer goes is not known, so neither is what is done with
      -- the storage.
      testCase "a pointer handed to something else stays" $ do
        results <- resultsOf (allocating "  call void @sink(ptr %p)\n  call void @free(ptr %p)")
        assertBool ("expected the allocation kept in " <> show results) (length results == 3)
    , -- Not every pointer a function frees is one it made: this one was handed
      -- in, and the caller is entitled to have it released.
      testCase "a pointer the function was handed is not one it allocated" $ do
        results <-
          resultsOf
            ( T.unlines
                [ prelude
                , "define void @f(ptr %p) {"
                , "entry:"
                , "  call void @free(ptr %p)"
                , "  ret void"
                , "}"
                ]
            )
        assertEqual "the deallocation stays" [Nothing] results
    , -- @operator new@ throws where it cannot allocate, and a way out of the
      -- function is not something an unread result makes removable.
      testCase "an allocation that may throw stays" $ do
        results <- resultsOf (throwing "  call void @free(ptr %p)")
        assertBool ("expected the allocation kept in " <> show results) (length results == 2)
    , -- Which of two allocations this is, is a question about where the
      -- storage is, and an allocation that never happened has no answer to it.
      testCase "a comparison with something other than null stays" $ do
        results <- resultsOf (allocating "  %c = icmp eq ptr %p, %q\n  store volatile i1 %c, ptr %q\n  call void @free(ptr %p)")
        assertBool ("expected the allocation kept in " <> show results) (length results == 4)
    , testCase "a slot something else names keeps its markers" $ do
        results <- resultsOf held
        assertEqual
          "nothing is removed"
          [Just (Local 1), Nothing, Nothing, Just (Local 2), Nothing]
          results
    , testGroup
        "what may go when nothing reads it"
        [ testCase "arithmetic" $ removableWhenUnused opaque (binary OpAdd) @?= True
        , -- Dividing by zero is undefined in LLVM rather than a fault to be
          -- kept, so an unread division is as dead as an unread addition.
          testCase "division" $ removableWhenUnused opaque (binary OpSDiv) @?= True
        , testCase "a plain load" $ removableWhenUnused opaque (load False) @?= True
        , -- A volatile load is a side effect that happens to return a value.
          testCase "a volatile load" $ removableWhenUnused opaque (load True) @?= False
        , testCase "a store" $ removableWhenUnused opaque store' @?= False
        , -- A call nothing is known about may do anything, so it stays.
          testCase "a call" $ removableWhenUnused opaque call' @?= False
        , -- One the whole program says writes nothing, always comes back and
          -- never throws is a computation like any other once its result is
          -- unread.  All three are needed: a call that throws is a way out of
          -- the function, and one that never returns is what the rest of the
          -- function stands behind.
          testCase "a call that does nothing" $
            removableWhenUnused (const nothing) call' @?= True
        , testCase "a call that only reads" $
            removableWhenUnused (const nothing {readsMemory = True}) call' @?= True
        , testCase "a call that writes" $
            removableWhenUnused (const nothing {writesMemory = True}) call' @?= False
        , testCase "a call that may throw" $
            removableWhenUnused (const nothing {mayUnwind = True}) call' @?= False
        , testCase "a call that may not return" $
            removableWhenUnused (const nothing {mayNotReturn = True}) call' @?= False
        , -- An atomic is an ordering as much as an access, and an ordering
          -- nothing here reads is one another thread reads.  That holds of
          -- the read as much as of the write, which is what makes an unread
          -- atomic load different from an unread plain one.
          testCase "an atomic load" $ removableWhenUnused opaque atomicLoad' @?= False
        , testCase "a read modify write" $ removableWhenUnused opaque atomicRmw' @?= False
        , testCase "a compare and exchange" $ removableWhenUnused opaque cmpXchg' @?= False
        , -- Which is the whole of what a fence is.
          testCase "a fence" $ removableWhenUnused opaque fence' @?= False
          -- There were two more here, asking that a return and a branch are
          -- never removable.  Neither can be asked now: a terminator is a
          -- 'Transfer' and this takes an 'Operation', so handing it one does
          -- not compile.  That is the answer those cases were checking for.
        ]
    ]
  where
    -- What every one of these was written against: a call this knows nothing
    -- about.
    opaque = const anything

    binary op =
      OBinary
        Binary
          { binaryOp = op
          , binaryFlags = []
          , binaryLeft = TypedValue (TInteger 32) (VLocal (Name Bare "a"))
          , binaryRight = TypedValue (TInteger 32) (VLocal (Name Bare "b"))
          }
    load volatile =
      OLoad
        Load
          { loadVolatile = volatile
          , loadType = TInteger 32
          , loadPointer = TypedValue (TPointer Nothing) (VLocal (Name Bare "p"))
          , loadAlignment = Nothing
          }
    store' =
      OStore
        Store
          { storeVolatile = False
          , storeValue = TypedValue (TInteger 32) (VInteger 0)
          , storePointer = TypedValue (TPointer Nothing) (VLocal (Name Bare "p"))
          , storeAlignment = Nothing
          }
    pointer = TypedValue (TPointer Nothing) (VLocal (Name Bare "p"))
    atomicLoad' =
      OAtomicLoad
        AtomicLoad
          { atomicLoadVolatile = False
          , atomicLoadType = TInteger 32
          , atomicLoadPointer = pointer
          , atomicLoadScope = Nothing
          , atomicLoadOrdering = SequentiallyConsistent
          , atomicLoadAlignment = Nothing
          }
    atomicRmw' =
      OAtomicRmw
        AtomicRmw
          { atomicRmwVolatile = False
          , atomicRmwOp = RmwAdd
          , atomicRmwPointer = pointer
          , atomicRmwValue = TypedValue (TInteger 32) (VInteger 1)
          , atomicRmwScope = Nothing
          , atomicRmwOrdering = SequentiallyConsistent
          , atomicRmwAlignment = Nothing
          }
    cmpXchg' =
      OCmpXchg
        CmpXchg
          { cmpXchgWeak = False
          , cmpXchgVolatile = False
          , cmpXchgPointer = pointer
          , cmpXchgCompare = TypedValue (TInteger 32) (VInteger 0)
          , cmpXchgReplacement = TypedValue (TInteger 32) (VInteger 1)
          , cmpXchgScope = Nothing
          , cmpXchgSuccess = SequentiallyConsistent
          , cmpXchgFailure = Monotonic
          , cmpXchgAlignment = Nothing
          }
    fence' = OFence Fence {fenceScope = Nothing, fenceOrdering = SequentiallyConsistent}
    call' =
      OCall
        Call
          { callTail = Nothing
          , callFlags = []
          , callCallingConvention = Nothing
          , callReturnAttributes = []
          , callAddrSpace = Nothing
          , callType = TVoid
          , callCallee = TypedValue (TPointer Nothing) (VGlobal (Name Bare "g"))
          , callArguments = []
          , callAttributes = []
          }
    sifted =
      T.unlines
        [ "define i32 @f(i32 %a, i32 %b, ptr %p) {"
        , "entry:"
        , "  %unread = add i32 %a, %b"
        , "  %chain = mul i32 %unread, 3"
        , "  %quiet = load i32, ptr %p"
        , "  %noisy = load volatile i32, ptr %p"
        , "  %risky = sdiv i32 %a, %b"
        , "  %room = alloca i32, align 4"
        , "  store i32 %a, ptr %p, align 4"
        , "  %answer = add i32 %a, 1"
        , "  ret i32 %answer"
        , "}"
        ]
    -- The shape the dead store pass leaves: an allocation, the two markers
    -- around it, and nothing in between for them to bracket.
    marked =
      T.unlines
        [ "declare void @llvm.lifetime.start.p0(i64, ptr)"
        , "declare void @llvm.lifetime.end.p0(i64, ptr)"
        , "define i32 @f(i32 %a) {"
        , "entry:"
        , "  %s = alloca i32, align 4"
        , "  call void @llvm.lifetime.start.p0(i64 4, ptr %s)"
        , "  call void @llvm.lifetime.end.p0(i64 4, ptr %s)"
        , "  %answer = add i32 %a, 1"
        , "  ret i32 %answer"
        , "}"
        ]
    held =
      T.unlines
        [ "declare void @llvm.lifetime.start.p0(i64, ptr)"
        , "declare void @llvm.lifetime.end.p0(i64, ptr)"
        , "define i32 @f(i32 %a) {"
        , "entry:"
        , "  %s = alloca i32, align 4"
        , "  call void @llvm.lifetime.start.p0(i64 4, ptr %s)"
        , "  store i32 %a, ptr %s, align 4"
        , "  %v = load i32, ptr %s, align 4"
        , "  call void @llvm.lifetime.end.p0(i64 4, ptr %s)"
        , "  ret i32 %v"
        , "}"
        ]
    -- A function that allocates, does whatever is written in the middle, and
    -- returns.  The volatile stores are what keep a value read.
    allocating middle = body "@malloc" middle
    throwing middle = body "@risky" middle
    body allocator middle =
      T.unlines
        [ prelude
        , "define void @f(ptr %q) {"
        , "entry:"
        , "  %p = call noalias ptr " <> allocator <> "(i64 64)"
        , T.stripEnd middle
        , "  ret void"
        , "}"
        ]

    live =
      T.unlines
        [ "define i32 @f(i32 %a, i32 %b) {"
        , "entry:"
        , "  %sum = add i32 %a, %b"
        , "  %doubled = mul i32 %sum, 2"
        , "  ret i32 %doubled"
        , "}"
        ]

-- | A loop whose counter nothing but the counter reads.  The volatile store is
-- what keeps the loop itself from going.
spinning :: Text
spinning =
  T.unlines
    [ "define void @f(ptr %p) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  store i32 0, ptr %i"
    , "  br label %loop"
    , "loop:"
    , "  %i1 = load i32, ptr %i"
    , "  %next = add i32 %i1, 1"
    , "  store i32 %next, ptr %i"
    , "  store volatile i32 7, ptr %p"
    , "  br label %loop"
    , "}"
    ]

-- | The same, with the count written somewhere that is read.
spinningRead :: Text
spinningRead =
  T.unlines
    [ "define void @f(ptr %p) {"
    , "entry:"
    , "  %i = alloca i32"
    , "  store i32 0, ptr %i"
    , "  br label %loop"
    , "loop:"
    , "  %i1 = load i32, ptr %i"
    , "  %next = add i32 %i1, 1"
    , "  store i32 %next, ptr %i"
    , "  store volatile i32 %next, ptr %p"
    , "  br label %loop"
    , "}"
    ]

-- | The same, with the counter taken out of memory first — a slot is kept
-- alive by the stores to it, so a value read only by what computes it is only
-- written that way once promotion has made it a local.
promotedResultsOf :: Text -> IO [Maybe Local]
promotedResultsOf source = do
  parsed <- expectParse "<inline>" source
  let program = eliminateDeadCode (promoteMemory (lower parsed))
  pure
    [ instructionResult i
    | f <- functionsIn program
    , b <- functionBlocks f
    , i <- blockInstructions b
    ]

-- | The declarations an allocation is read against.
--
-- Written as clang writes them at @-O1@ and above, which is the only place the
-- attributes that decide any of this appear: @allockind@ says what the call
-- does with storage, @allocptr@ which argument is the storage, and the
-- @memory@ clause that the allocator's own writing lands where nothing here
-- can name.  @\@risky@ is the same allocator without the promise not to
-- throw.
prelude :: Text
prelude =
  T.unlines
    [ "declare noalias ptr @malloc(i64) #0"
    , "declare noalias ptr @risky(i64) #2"
    , "declare void @free(ptr allocptr captures(none)) #1"
    , "declare void @sink(ptr)"
    , "declare void @llvm.assume(i1)"
    , "attributes #0 = { nounwind willreturn allockind(\"alloc,uninitialized\") memory(inaccessiblemem: readwrite) }"
    , "attributes #1 = { nounwind willreturn allockind(\"free\") memory(argmem: readwrite, inaccessiblemem: readwrite) }"
    , "attributes #2 = { willreturn allockind(\"alloc,uninitialized\") memory(inaccessiblemem: readwrite) }"
    ]

-- | What each surviving instruction does, in order.
operationsOf :: Text -> IO [Operation (TypedValue Local)]
operationsOf source = do
  parsed <- expectParse "<inline>" source
  let program = eliminateDeadCode (lower parsed)
  pure
    [ instructionOperation i
    | f <- functionsIn program
    , b <- functionBlocks f
    , i <- blockInstructions b
    ]

-- | What each surviving instruction assigns to, in order.
resultsOf :: Text -> IO [Maybe Local]
resultsOf source = do
  parsed <- expectParse "<inline>" source
  let program = eliminateDeadCode (lower parsed)
  pure
    [ instructionResult i
    | f <- functionsIn program
    , b <- functionBlocks f
    , i <- blockInstructions b
    ]
