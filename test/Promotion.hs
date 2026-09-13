-- | The memory promotion pass.
--
-- Three things are checked separately: which slots the pass decides it may
-- take, which is the whole of the analysis; what the instructions become,
-- which is the whole of the rewrite; and what comes out of the pipeline with
-- the phis put back, which is the reason for doing either.
module Promotion (promotionTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Layout (endiannessOf, layoutOf)
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.Promote (promotableIn, promoteMemory)
import Olivine.Core.Program
import Olivine.Pipeline (optimize)
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Value

promotionTests :: TestTree
promotionTests =
  testGroup
    "memory promotion"
    [ testGroup
        "what may be promoted"
        [ testCase "a slot only stored to and loaded from" $
            slots plain @?>= 1
        , -- One element asked for explicitly is the same one object.
          testCase "a slot asking for one element" $
            slots (allocating "alloca i32, i32 1") @?>= 1
        , -- Every one of these reaches the storage by some route other than
          -- the loads and stores this pass can count, so none of them may go.
          testCase "a slot passed to a call" $
            slots (escaping "call void @g(ptr %a)") @?>= 0
        , testCase "a slot returned" $
            slots (escaping "ret ptr %a") @?>= 0
        , -- The exception among calls, and the one every optimizing front end
          -- writes: a lifetime marker is handed the address and neither
          -- follows it nor keeps it, which is what @captures(none)@ on the
          -- declaration says.  Before this the bracket a front end puts round
          -- every local above @-O0@ left the slot in memory.
          testCase "a slot bracketed by lifetime markers" $
            slots (bracketed "llvm.lifetime" "%a") @?>= 1
        , -- The marker names the step and the step names the slot, so what is
          -- marked is the storage the slot is.
          testCase "a slot whose step of zero is bracketed" $
            slots (bracketed "llvm.lifetime" "%p") @?>= 1
        , -- The reserved prefix is the whole of the test and the word is none
          -- of it.  A function anybody could define is a function that could
          -- do anything with what it is handed.
          testCase "a slot passed to something else called lifetime" $
            slots (bracketed "lifetime" "%a") @?>= 0
        , testCase "a slot offset into" $
            slots (escaping "%p = getelementptr inbounds i32, ptr %a, i64 1") @?>= 0
        , -- A step of zero names the address it steps from, so an access
          -- through one is an access to the slot.  This is the shape a front
          -- end writes for the first element of an array or the first member
          -- of a union, and it used to stop the slot going at all.
          testCase "a slot reached through a step of zero" $
            slots (stepped "getelementptr inbounds i32, ptr %a, i64 0") @?>= 1
        , -- Field zero of a struct begins where the struct begins, packed or
          -- not, which is a fact about no type's size.
          testCase "a slot reached through field zero" $
            slots (stepped "getelementptr inbounds { i32, i8 }, ptr %a, i32 0, i32 0") @?>= 1
        , -- Where the later field is is what a data layout says and nothing
          -- here reads one.
          testCase "a slot reached through a later field" $
            slots (stepped "getelementptr inbounds { i8, i32 }, ptr %a, i32 0, i32 1") @?>= 0
        , -- What reads the step reads the slot, an escape as much as any
          -- other: the address got out under another name.
          testCase "a slot whose step of zero is passed to a call" $
            slots
              ( T.unlines
                  [ "declare void @g(ptr)"
                  , "define i32 @f(i32 %v) {"
                  , "entry:"
                  , "  %a = alloca i32, align 4"
                  , "  %p = getelementptr inbounds i32, ptr %a, i64 0"
                  , "  store i32 %v, ptr %p, align 4"
                  , "  %r = load i32, ptr %p, align 4"
                  , "  call void @g(ptr %p)"
                  , "  ret i32 %r"
                  , "}"
                  ]
              )
              @?>= 0
        , testCase "a slot compared" $
            slots (escaping "%c = icmp eq ptr %a, null") @?>= 0
        , testCase "a slot selected between" $
            slots (escaping "%q = select i1 true, ptr %a, ptr null") @?>= 0
        , -- The address of one slot written into another: the second may go,
          -- the first may not, and which is which is the point of the case.
          testCase "a slot whose address is stored elsewhere" $
            slots
              ( T.unlines
                  [ "define void @f() {"
                  , "entry:"
                  , "  %a = alloca i32, align 4"
                  , "  %b = alloca ptr, align 8"
                  , "  store ptr %a, ptr %b, align 8"
                  , "  ret void"
                  , "}"
                  ]
              )
              @?>= 1
        , -- Counted by difference rather than by case, so that the same local
          -- in both positions of one store is an escape in one of them.
          testCase "a slot holding its own address" $
            slots
              ( T.unlines
                  [ "define void @f() {"
                  , "entry:"
                  , "  %a = alloca ptr, align 8"
                  , "  store ptr %a, ptr %a, align 8"
                  , "  ret void"
                  , "}"
                  ]
              )
              @?>= 0
        , -- A volatile access is a side effect, and an assignment happens
          -- nowhere, so neither kind of slot may go.
          testCase "a slot read volatile" $
            slots (escaping "%r = load volatile i32, ptr %a, align 4") @?>= 0
        , testCase "a slot written volatile" $
            slots (escaping "store volatile i32 1, ptr %a, align 4") @?>= 0
        , -- A load with no result has no name to give what it read, so it has
          -- to stay, and a slot it reads has to stay a slot.
          testCase "a slot read into nothing" $
            slots (escaping "load i32, ptr %a, align 4") @?>= 0
        , -- Storing a byte into a word writes part of it and leaves the rest,
          -- and an assignment cannot name part of a local.  This is the one
          -- the group below does not settle: it holds whatever the module
          -- says about byte order.
          testCase "a slot written at another type" $
            slots (escaping "store i8 3, ptr %a, align 1") @?>= 0
        , -- Reading part of one is a conversion of the value, but only where
          -- the module says which part.  This module states no data layout.
          testCase "a slot read at another type, the module saying nothing" $
            slots (escaping "%r = load i8, ptr %a, align 1") @?>= 0
        , -- An array of a length nothing here knows is not one object.
          testCase "a slot of many elements" $
            slots (allocating "alloca i32, i32 %n") @?>= 0
        , -- Storage the caller passes rather than storage the function owns.
          testCase "an inalloca slot" $
            slots (allocating "alloca inalloca i32") @?>= 0
        ]
    , testGroup
        "a slot read at a type other than the one written"
        [ -- What the whole group is for: an @i32@ put in and an @i16@ taken
          -- out is the low half of the value on a little endian target, and
          -- the local holds the value.
          testCase "a narrower read where the layout says little endian" $
            slots (punning little "i32" "i16") @?>= 1
        , -- The same read on a big endian target is the high half, which is a
          -- shift as well as a truncation, and nothing here has been run
          -- against such a target.
          testCase "a narrower read where the layout says big endian" $
            slots (punning big "i32" "i16") @?>= 0
        , testCase "a narrower read where the module states no layout" $
            slots (punning "" "i32" "i16") @?>= 0
        , -- The byte order component stands alone.  A layout that says @m:e@
          -- and nothing else has an @e@ in it and says nothing about which end
          -- of a value an address is.
          testCase "a narrower read where only a mangling names e" $
            slots (punning "target datalayout = \"m:e-p:64:64\"" "i32" "i16") @?>= 0
        , -- Equal widths are the same bits either way round, so this one does
          -- not need the layout at all.
          testCase "a read of the same width, the module saying nothing" $
            slots (punning "" "float" "i32") @?>= 1
        , testCase "a read of the same width on a big endian target" $
            slots (punning big "float" "i32") @?>= 1
        , -- Above what was written is whatever the storage held, and a value
          -- has no such thing.
          testCase "a read wider than what was written" $
            slots (punning little "i16" "i32") @?>= 0
        , -- How wide a pointer is is exactly what the data layout is for, and
          -- nothing here reads that part of it.
          testCase "a read of a slot written as a pointer" $
            slots (punning little "ptr" "i64") @?>= 0
        , -- Two stores at two widths: the narrower leaves the bits it did not
          -- write, which the local says by reading itself back and masking.
          testCase "two stores of different widths" $
            slots (widths "i32" "i16") @?>= 1
        , -- Which of them is written first decides nothing: what the local
          -- holds is the widest of them wherever it stands.
          testCase "the narrower store first" $
            slots (widths "i16" "i32") @?>= 1
        , -- Which end of the value the narrower store lands in is the byte
          -- order, and a module that does not say declines.
          testCase "a narrower store on a big endian target" $
            slots (T.replace little big (widths "i32" "i16")) @?>= 0
        , -- Two stores at one width and two types: the local holds the first,
          -- and the other store is a conversion into it.
          testCase "two stores of one width" $
            slots
              ( T.unlines
                  [ little
                  , "define i32 @f(i32 %v, float %w) {"
                  , "entry:"
                  , "  %a = alloca i32, align 4"
                  , "  store i32 %v, ptr %a, align 4"
                  , "  store float %w, ptr %a, align 4"
                  , "  %r = load i32, ptr %a, align 4"
                  , "  ret i32 %r"
                  , "}"
                  ]
              )
              @?>= 1
        , -- The rewrite: the allocation and the store are assignments as
          -- before, the load is the conversion and an assignment carrying it
          -- into the local the load named.
          testCase "a narrower read becomes a truncation" $
            shapes (punning little "i32" "i16")
              @?>= ["assign", "assign", "convert", "assign", "other"]
        , -- Truncation is an operation on integers, so a floating point value
          -- goes to its bits and back: three conversions rather than one.
          testCase "a narrower floating point read becomes three conversions" $
            shapes (punning little "double" "float")
              @?>= ["assign", "assign", "convert", "convert", "convert", "assign", "other"]
        , -- A conversion cannot assign to the local the load named, that local
          -- being one the rest of the function reads and one an assignment
          -- elsewhere may also write.  So it writes a name of its own.
          testCase "the conversion writes a name of its own" $ do
            names <- resultsOf (punning little "i32" "i16")
            case names of
              [Just slot, Just stored, Just made, Just read', Nothing] -> do
                stored @?= slot
                assertBool "the conversion writes the load's local" (made /= read')
              other -> assertFailure ("expected five results, got " <> show other)
        ]
    , testGroup
        "what the instructions become"
        [ -- The allocation, the store and the load, all three assignments.
          testCase "nothing is left addressing memory" $ do
            shapes plain @?>= ["assign", "assign", "assign"]
        , -- Fresh storage holds whatever it holds, and reading it before
          -- writing it is undefined; poison says that and nothing more.
          testCase "the allocation becomes poison" $
            firstOperand plain @?>= Just VPoison
        , -- The slot keeps the local the allocation named, so the value ends
          -- up where a reader of the output would look for it: the store
          -- assigns to it and the load assigns from it.
          testCase "the slot keeps its own local" $ do
            names <- resultsOf plain
            case names of
              [Just slot, Just stored, Just _] -> stored @?= slot
              other -> assertFailure ("expected three results, got " <> show other)
        , -- An allocation reached twice is new storage each time, so the
          -- poison has to stay where the allocation was rather than being
          -- hoisted or dropped: the local must forget each time round what the
          -- last iteration left in it.
          testCase "an allocation in a loop is re-poisoned there" $
            blockShapes
              ( T.unlines
                  [ "define void @f() {"
                  , "entry:"
                  , "  br label %again"
                  , "again:"
                  , "  %a = alloca i32, align 4"
                  , "  store i32 1, ptr %a, align 4"
                  , "  br label %again"
                  , "}"
                  ]
              )
              @?>= [[], ["assign", "assign"]]
        , -- The step named an address, and there is no longer an address to
          -- name: the allocation, the store and the load are the three
          -- assignments, and the step is gone.
          testCase "a step of zero goes with the slot" $
            shapes (stepped "getelementptr inbounds i32, ptr %a, i64 0")
              @?>= ["assign", "assign", "assign"]
        , -- The markers go with the storage they marked.  What they said is
          -- where an object's contents begin and end being anyone's business,
          -- and a local has no such span: it holds the poison the allocation
          -- became until something assigns to it.
          testCase "the markers go with the slot" $
            shapes (bracketed "llvm.lifetime" "%a")
              @?>= ["assign", "assign", "assign"]
        , testCase "a slot that may not go is left alone" $
            shapes (escaping "call void @g(ptr %a)")
              @?>= ["alloca", "store", "load", "other"]
        ]
    , testGroup
        "a byte copy that covers a slot"
        [ -- A @memcpy@ is a call, and a call naming an address is what stops a
          -- slot being promoted at all — but one that moves exactly the bytes
          -- the slot holds reads or writes the whole of it and nothing else,
          -- which is what a load or a store does.  This is how a struct
          -- returned by value reaches the local it was built in.
          testCase "a copy out of a slot is a read of it" $
            slots (copying little "i32" 4 "%p" "%a") @?>= 1
        , testCase "a copy into a slot is a write of it" $
            slots (copying little "i32" 4 "%a" "%p") @?>= 1
        , -- Fewer bytes than the slot holds is a write to part of it, and more
          -- is a write past its end.
          testCase "a copy of fewer bytes than the slot holds" $
            slots (copying little "i32" 2 "%p" "%a") @?>= 0
        , testCase "a copy of more" $
            slots (copying little "i64" 4 "%p" "%a") @?>= 0
        , -- How many bytes the slot holds is the one question the layout is
          -- asked, so a module that states none declines.
          testCase "a copy in a module with no layout" $
            slots (copying "" "i32" 4 "%p" "%a") @?>= 0
        , -- Three bytes is an @i24@ and a kilobyte an @i8192@; neither is
          -- something a machine moves, and the point of this is to stop moving
          -- bytes.
          testCase "a copy of a width no machine has" $
            slots (copying little "i24" 3 "%p" "%a") @?>= 0
        , -- The point of a volatile access is that it happens.
          testCase "a volatile copy" $
            slots (T.replace "i1 false" "i1 true" (copying little "i32" 4 "%p" "%a")) @?>= 0
        , -- The rewrite: a copy out of the slot is a store of what the local
          -- holds, and the allocation, the store and the load around it are the
          -- assignments they always were.
          testCase "what a copy out of the slot becomes" $
            shapes (copying little "i32" 4 "%p" "%a")
              @?>= ["assign", "assign", "store", "assign"]
        , -- And a copy into it is a load of the bits at the other end, left in
          -- a name of its own, and then the assignment to the local.
          testCase "and what a copy into it becomes" $
            shapes (copying little "i32" 4 "%a" "%p")
              @?>= ["assign", "assign", "load", "assign", "assign"]
        ]
    , testGroup
        "what comes out"
        [ -- What the pass exists for.  A value carried round a loop through
          -- memory arrives as a phi, and no dominance frontier was computed to
          -- put it there: reconstruction places phis for every local at once,
          -- and promotion made this one a local.
          testCase "a value carried round a loop becomes a phi" $ do
            text <- rendered counter
            assertBool ("expected a phi in " <> T.unpack text) ("phi" `T.isInfixOf` text)
            assertBool ("expected no alloca in " <> T.unpack text) (not ("alloca" `T.isInfixOf` text))
        , -- Storage read before anything is written to it reads as poison, and
          -- the poison the promotion put where the allocation was carries from
          -- there to the use.
          testCase "a slot read before it is written comes out poison" $ do
            text <- rendered uninitialized
            assertBool ("expected poison in " <> T.unpack text) ("ret i32 poison" `T.isInfixOf` text)
        ]
    ]
  where
    plain = allocating "alloca i32, align 4"

    -- One slot, stored to and loaded from, with a line of the caller's
    -- choosing before the return.  The load is there in every case so that a
    -- slot rejected for the extra line is rejected for that and not for
    -- having no accesses to count.
    escaping extra =
      T.unlines
        [ "declare void @g(ptr)"
        , "define i32 @f(ptr %p) {"
        , "entry:"
        , "  %a = alloca i32, align 4"
        , "  store i32 7, ptr %a, align 4"
        , "  %r = load i32, ptr %a, align 4"
        , "  " <> extra
        , "  ret i32 %r"
        , "}"
        ]

    -- One slot bracketed the way a front end above @-O0@ brackets a local.
    -- Both the symbol called and the address it is handed are the caller's
    -- choice: what makes a marker a marker is the name, and what it marks may
    -- be said as the slot or as a step of zero off it.
    bracketed callee pointer =
      T.unlines
        [ "declare void @" <> callee <> ".start.p0(i64 immarg, ptr captures(none))"
        , "declare void @" <> callee <> ".end.p0(i64 immarg, ptr captures(none))"
        , "define i32 @f(i32 %v) {"
        , "entry:"
        , "  %a = alloca i32, align 4"
        , "  %p = getelementptr inbounds i32, ptr %a, i64 0"
        , "  call void @" <> callee <> ".start.p0(i64 4, ptr " <> pointer <> ")"
        , "  store i32 %v, ptr %a, align 4"
        , "  %r = load i32, ptr %a, align 4"
        , "  call void @" <> callee <> ".end.p0(i64 4, ptr " <> pointer <> ")"
        , "  ret i32 %r"
        , "}"
        ]

    -- One slot, accessed through whatever the step names rather than through
    -- the allocation's own local.
    stepped step =
      T.unlines
        [ "define i32 @f(i32 %v) {"
        , "entry:"
        , "  %a = alloca i32, align 4"
        , "  %p = " <> step
        , "  store i32 %v, ptr %p, align 4"
        , "  %r = load i32, ptr %p, align 4"
        , "  ret i32 %r"
        , "}"
        ]

    -- One slot written at one type and read at another, under whatever the
    -- module says about byte order — which is what decides which part of the
    -- stored value a narrower read gets.  The allocation is at neither type,
    -- since what the local holds is what the stores agree on rather than what
    -- was allocated.  The load's result is handed to a call so that the value
    -- is read by something and the slot's address by nothing.
    punning layout stored read =
      T.unlines
        [ layout
        , "declare void @g(" <> read <> ")"
        , "define void @f(" <> stored <> " %v) {"
        , "entry:"
        , "  %a = alloca i64, align 8"
        , "  store " <> stored <> " %v, ptr %a, align 8"
        , "  %r = load " <> read <> ", ptr %a, align 8"
        , "  call void @g(" <> read <> " %r)"
        , "  ret void"
        , "}"
        ]

    -- One slot written twice at two widths and read at the wider of them,
    -- which is what a bit field assignment comes to once the struct holding
    -- it is one word.
    widths first second =
      T.unlines
        [ little
        , "define " <> first <> " @f(" <> first <> " %v, " <> second <> " %w) {"
        , "entry:"
        , "  %a = alloca i64, align 8"
        , "  store " <> first <> " %v, ptr %a, align 8"
        , "  store " <> second <> " %w, ptr %a, align 8"
        , "  %r = load " <> first <> ", ptr %a, align 8"
        , "  ret " <> first <> " %r"
        , "}"
        ]

    -- A slot the program only loads and stores, with a copy of @bytes@ bytes
    -- between it and a pointer handed in.  Which way the copy goes is which of
    -- the two addresses is written first.
    copying layout held bytes into from =
      T.unlines
        [ layout
        , "define " <> held <> " @f(ptr %p) {"
        , "entry:"
        , "  %a = alloca " <> held <> ", align 8"
        , "  store " <> held <> " 7, ptr %a, align 8"
        , "  call void @llvm.memcpy.p0.p0.i64(ptr align 8 " <> into <> ", ptr align 8 " <> from <> ", i64 " <> T.pack (show (bytes :: Int)) <> ", i1 false)"
        , "  %r = load " <> held <> ", ptr %a, align 8"
        , "  ret " <> held <> " %r"
        , "}"
        , "declare void @llvm.memcpy.p0.p0.i64(ptr captures(none), ptr captures(none), i64, i1)"
        ]

    little = "target datalayout = \"e-m:e-p:64:64-i64:64\""
    big = "target datalayout = \"E-m:e-p:64:64-i64:64\""

    -- The same shape, varying the allocation itself.
    allocating what =
      T.unlines
        [ "define i32 @f(i32 %v, i32 %n) {"
        , "entry:"
        , "  %a = " <> what
        , "  store i32 %v, ptr %a, align 4"
        , "  %r = load i32, ptr %a, align 4"
        , "  ret i32 %r"
        , "}"
        ]

    uninitialized =
      T.unlines
        [ "define i32 @f() {"
        , "entry:"
        , "  %a = alloca i32, align 4"
        , "  %r = load i32, ptr %a, align 4"
        , "  ret i32 %r"
        , "}"
        ]

    counter =
      T.unlines
        [ "define i32 @f(i32 %n) {"
        , "entry:"
        , "  %i = alloca i32, align 4"
        , "  store i32 0, ptr %i, align 4"
        , "  br label %head"
        , "head:"
        , "  %x = load i32, ptr %i, align 4"
        , "  %c = icmp slt i32 %x, %n"
        , "  br i1 %c, label %body, label %done"
        , "body:"
        , "  %y = load i32, ptr %i, align 4"
        , "  %z = add nsw i32 %y, 1"
        , "  store i32 %z, ptr %i, align 4"
        , "  br label %head"
        , "done:"
        , "  %r = load i32, ptr %i, align 4"
        , "  ret i32 %r"
        , "}"
        ]

-- | @?=@ against something read out of a parse, which is in 'IO'.
(@?>=) :: (Eq a, Show a) => IO a -> a -> Assertion
got @?>= expected = got >>= (@?= expected)

-- | How many slots the pass decided it could take, across the program.
--
-- Counted rather than named, so that a case says what it is about — this line
-- may be promoted, that one may not — without also fixing the numbering the
-- lowering happened to give the locals around it.
slots :: Text -> IO Int
slots source = do
  program <- lowered source
  pure (sum [length (promotableIn (endiannessOf program) (layoutOf program) f) | f <- functionsIn program])

-- | What each instruction of the one function is, after promotion, named
-- coarsely enough that a test can state the whole list.
shapes :: Text -> IO [Text]
shapes source = concat <$> blockShapes source

-- | The same, block by block, for saying where something ended up.
blockShapes :: Text -> IO [[Text]]
blockShapes source = do
  program <- promoted source
  pure
    [ map (shapeOf . instructionOperation) (blockInstructions b)
    | f <- functionsIn program
    , b <- functionBlocks f
    ]

shapeOf :: Operation operand -> Text
shapeOf operation = case operation of
  OAssign _ -> "assign"
  OAlloca _ -> "alloca"
  OLoad _ -> "load"
  OStore _ -> "store"
  OConvert _ -> "convert"
  _ -> "other"

-- | What each surviving instruction assigns to, in order.
resultsOf :: Text -> IO [Maybe Local]
resultsOf source = do
  program <- promoted source
  pure
    [ instructionResult i
    | f <- functionsIn program
    , b <- functionBlocks f
    , i <- blockInstructions b
    ]

-- | The value the first instruction of the first function reads.
firstOperand :: Text -> IO (Maybe (Value Local))
firstOperand source = do
  program <- promoted source
  pure $ case [i | f <- functionsIn program, b <- functionBlocks f, i <- blockInstructions b] of
    Instruction _ (OAssign value) _ : _ -> Just (typedValue value)
    _ -> Nothing

lowered :: Text -> IO Program
lowered source = lower <$> expectParse "<inline>" source

promoted :: Text -> IO Program
promoted source = promoteMemory <$> lowered source

-- | Through the whole pipeline and back out as LLVM, which is where a phi
-- becomes visible: the core has nowhere to write one.
rendered :: Text -> IO Text
rendered source = renderModule . optimize <$> expectParse "<inline>" source
