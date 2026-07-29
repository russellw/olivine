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
        , testCase "a slot offset into" $
            slots (escaping "%p = getelementptr inbounds i32, ptr %a, i64 1") @?>= 0
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
        , -- Storing a byte into a word writes part of it, and an assignment
          -- cannot name part of a local.
          testCase "a slot written at another type" $
            slots (escaping "store i8 3, ptr %a, align 1") @?>= 0
        , testCase "a slot read at another type" $
            slots (escaping "%r = load i8, ptr %a, align 1") @?>= 0
        , -- An array of a length nothing here knows is not one object.
          testCase "a slot of many elements" $
            slots (allocating "alloca i32, i32 %n") @?>= 0
        , -- Storage the caller passes rather than storage the function owns.
          testCase "an inalloca slot" $
            slots (allocating "alloca inalloca i32") @?>= 0
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
        , testCase "a slot that may not go is left alone" $
            shapes (escaping "call void @g(ptr %a)")
              @?>= ["alloca", "store", "load", "other"]
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
  pure (sum [length (promotableIn f) | f <- functionsIn program])

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
