-- | The aggregate splitting pass.
--
-- Three things are checked separately: which slots the pass decides it may
-- take apart and into what, which is the whole of the analysis; what the
-- instructions become, which is the whole of the rewrite; and what comes out
-- of the pipeline, which is the reason for doing either — a struct a front end
-- put on the stack should not be on the stack at the end.
module Split (splitTests) where

import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Numeric.Natural (Natural)
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.Split (Aggregate (..), splitAggregates, splittableIn)
import Olivine.Core.Program
import Olivine.Pipeline (optimize)
import Olivine.Syntax.Instruction (Alloca (..))
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value (TypedValue)

splitTests :: TestTree
splitTests =
  testGroup
    "aggregate splitting"
    [ testGroup
        "what may be split"
        [ testCase "a slot every field of which is stepped to" $
            slots (holding both) @?>= 1
        , -- Only the fields the program names get storage: the struct said how
          -- much room to leave for the other, and a slot per field says
          -- nothing about a field there is no slot for.
          testCase "the fields stepped to are the fields taken" $
            taken (holding both) @?>= [0, 1]
        , testCase "a field nothing steps to is not taken" $
            taken (holding second) @?>= [1]
        , -- What each of these covers is a number of bytes, and this pass
          -- measures none.
          testCase "a slot loaded whole" $
            slots (holding ("  %w = load %s, ptr %a, align 4" : both)) @?>= 0
        , testCase "a slot stored whole" $
            slots (holding ("  store %s zeroinitializer, ptr %a, align 4" : both)) @?>= 0
        , testCase "a slot strided over" $
            slots (holding ("  %w = getelementptr inbounds %s, ptr %a, i64 1" : both)) @?>= 0
        , testCase "a slot stepped into as another struct" $
            slots (holding ("  %w = getelementptr inbounds %t, ptr %a, i32 0, i32 0" : both))
              @?>= 0
        , -- A pointer into the allocation, once it is out of sight, is a
          -- pointer to the whole of it: whatever holds it may arrive at any
          -- other field, which separate slots would no longer answer for.
          testCase "a slot passed to a call" $
            slots (holding ("  call void @g(ptr %a)" : both)) @?>= 0
        , testCase "the address of a field passed to a call" $
            slots (holding (both <> ["  call void @g(ptr %p)"])) @?>= 0
        , -- The call every front end above @-O0@ writes round a local
          -- aggregate, and the one that is not a pointer getting out: a marker
          -- neither follows the address nor keeps it.  Refusing these left
          -- every struct in the newer half of the corpus in memory.
          testCase "a slot bracketed by lifetime markers" $
            slots (holding ([started "%a"] <> both <> [ended "%a"])) @?>= 1
        , -- A member bracketed rather than the struct around it.  Where the
          -- bracket stands says nothing about what may be split, so these go
          -- after the accesses like every other line a case adds.
          testCase "the address of a field bracketed" $
            slots (holding (both <> [started "%q", ended "%q"])) @?>= 1
        , testCase "the address of a field returned" $
            slots escapingByReturn @?>= 0
        , testCase "the address of a field compared" $
            slots (holding (both <> ["  %c = icmp eq ptr %p, null"])) @?>= 0
        , testCase "the address of a field written into memory" $
            slots
              ( holding
                  ( ["  %b = alloca ptr, align 8"]
                      <> both
                      <> ["  store ptr %p, ptr %b, align 8"]
                  )
              )
              @?>= 0
        , -- Counted by difference rather than by case, so that the same local
          -- in both positions of one store is an escape in one of them.
          testCase "a field holding its own address" $
            slots selfAddressed @?>= 0
        , -- Reading eight bytes at a four byte field reads the field beside
          -- it, which is not something separate slots can be asked for.
          testCase "a field read wider than itself" $
            slots (holding (both <> ["  %w = load i64, ptr %p, align 4"])) @?>= 0
        , testCase "a field strided into" $
            slots (holding (both <> ["  %w = getelementptr inbounds i32, ptr %p, i64 1"]))
              @?>= 0
        , -- How well aligned a field is is the allocation's alignment and the
          -- offset together, so the allocation's own is what a slot of its own
          -- can honestly claim.  One that states none states nothing to pass
          -- on.
          testCase "a slot stating no alignment" $
            slots (allocating "alloca %s") @?>= 0
        , testCase "a slot asking for one element" $
            slots (allocating "alloca %s, i32 1, align 4") @?>= 1
        , testCase "a slot of many elements" $
            slots (allocating "alloca %s, i32 %v, align 4") @?>= 0
        , testCase "an inalloca slot" $
            slots (allocating "alloca inalloca %s, align 4") @?>= 0
        , testCase "a slot allocated as something other than a struct" $
            slots (allocating "alloca [2 x i32], align 4") @?>= 0
        , -- The first field begins where the struct begins, packed or not, so
          -- an access at that field's own type through the slot's own address
          -- is an access to that field and reaches no further.  This is the
          -- shape a front end writes where it wrote no step at all.
          testCase "the first field reached by the slot's own address" $
            slots (holding ["  store i32 %v, ptr %a, align 4"]) @?>= 1
        , testCase "the slot's own address read at another type" $
            slots (holding ["  store i16 1, ptr %a, align 2"]) @?>= 0
        ]
    , testGroup
        "what the instructions become"
        [ -- The one allocation becomes one per field, where it stood; the
          -- steps go; and what read them reads the slots they arrived at.
          testCase "one allocation per field, and no steps left" $
            shapes (holding both) @?>= ["alloca", "alloca", "store", "load"]
        , testCase "each slot holds what its field held" $
            allocated (holding both) @?>= [TInteger 32, TInteger 32]
        , testCase "a slot taken for one field allocates for one field" $
            allocated (holding second) @?>= [TInteger 32]
        , -- Not the field's own type's alignment, which for a field the struct
          -- put at an odd offset would be more than the storage really has.
          testCase "the new slots keep the allocation's alignment" $
            alignments (holding both) @?>= [Just 4, Just 4]
        , testCase "the new slots keep the allocation's address space" $
            spaces (allocating "alloca %s, align 4, addrspace(1)") @?>= [Just 1, Just 1]
        , -- Splitting the outer one leaves the inner a slot of its own, whose
          -- steps are then steps off a slot: the sweep runs until it finds
          -- nothing.
          testCase "a struct inside a struct is split twice" $
            allocated nested @?>= [TInteger 32]
        , -- Nothing is left naming the whole, because there is no longer a
          -- whole to name: what a marker said is where a stack slot may be
          -- reused, and the slot it said it about has just become several.
          testCase "the markers go with the slot they bracketed" $
            shapes (holding ([started "%a"] <> both <> [ended "%a"]))
              @?>= ["alloca", "alloca", "store", "load"]
        , -- The access that covers the whole slot is written out as one per
          -- field and an @insertvalue@ chain assembling them, which is what a
          -- struct returned by value arrives as.  The steps it writes are the
          -- ones the split then renames away, so what is left is a slot per
          -- field, the accesses, and the chain.
          testCase "a slot loaded whole is loaded a field at a time" $
            shapes (holding ("  %w = load %s, ptr %a, align 4" : both))
              @?>= [ "alloca"
                   , "alloca"
                   , "load"
                   , "load"
                   , "other"
                   , "other"
                   , "store"
                   , "load"
                   ]
        , testCase "a slot stored whole is stored a field at a time" $
            shapes (holding ("  store %s zeroinitializer, ptr %a, align 4" : both))
              @?>= [ "alloca"
                   , "alloca"
                   , "other"
                   , "store"
                   , "other"
                   , "store"
                   , "store"
                   , "load"
                   ]
        , -- An access at some other type covers some other bytes, so there is
          -- nothing to write out and the slot keeps its storage.
          testCase "a slot read whole at another type is left as it was" $
            shapes (holding ("  %w = load %t, ptr %a, align 4" : both))
              @?>= ["alloca", "load", "field", "store", "field", "load"]
        , -- The point of a volatile access is that it happens as it was
          -- written, and several narrower ones are not that.
          testCase "a slot read whole and volatile is left as it was" $
            shapes (holding ("  %w = load volatile %s, ptr %a, align 4" : both))
              @?>= ["alloca", "load", "field", "store", "field", "load"]
        , -- Writing the access out is a pessimization on its own — one access
          -- for several — so it is only done where the slot then goes.
          testCase "a slot loaded whole that would not split is left as it was" $
            shapes
              ( holding
                  ( ["  %w = load %s, ptr %a, align 4"]
                      <> both
                      <> ["  call void @g(ptr %p)"]
                  )
              )
              @?>= ["alloca", "load", "field", "store", "field", "load", "other"]
        , -- A fill covering the whole slot is a zero written into each field.
          -- @zeroinitializer@ is the one spelling of a zero that needs to know
          -- nothing about the type it is a zero of.
          testCase "a slot filled with zeroes is filled a field at a time" $
            shapes (holding (filling "i8 0" "i64 8" : both))
              @?>= ["alloca", "alloca", "store", "store", "store", "load"]
        , -- A count that does not cover the slot leaves bytes of it holding
          -- what they held, and this pass cannot say which.
          testCase "a fill that does not cover the slot is left as it was" $
            shapes (holding (filling "i8 0" "i64 4" : both))
              @?>= ["alloca", "other", "field", "store", "field", "load"]
        , -- A byte repeated to a field's width is arithmetic on a
          -- representation, and for a field that is a float it is a literal
          -- this has no business inventing.
          testCase "a fill of something other than zero is left as it was" $
            shapes (holding (filling "i8 -1" "i64 8" : both))
              @?>= ["alloca", "other", "field", "store", "field", "load"]
        , testCase "a fill of a length nothing knows is left as it was" $
            shapes (holding (filling "i8 0" "i64 %n" : both))
              @?>= ["alloca", "other", "field", "store", "field", "load"]
        , -- Both ends hold the same struct, so the copy is a load and a store
          -- per field and no byte of either is named except through a field.
          testCase "a copy between two slots is a copy per field" $
            shapes (holding (copying <> both))
              @?>= [ "alloca"
                   , "alloca"
                   , "alloca"
                   , "alloca"
                   , "load"
                   , "store"
                   , "load"
                   , "store"
                   , "store"
                   , "load"
                   ]
        , -- Its fields would have to be stepped to at an alignment nothing here
          -- knows, this function not having allocated it.
          testCase "a copy one end of which is not a slot is left as it was" $
            shapes (holding (copyingOut <> both))
              @?>= ["alloca", "other", "field", "store", "field", "load"]
        ]
    , testGroup
        "what the pipeline makes of it"
        [ -- The whole of the point: promotion could do nothing with a slot
          -- holding a struct, and now there is no such slot to ask it about.
          testCase "a struct on the stack is not on the stack" $ do
            output <- rendered (holding both)
            assertBool ("expected no allocation, got " <> T.unpack output) $
              not ("alloca" `T.isInfixOf` output)
        , testCase "a struct a field of which escapes stays" $ do
            output <- rendered (holding (both <> ["  call void @g(ptr %p)"]))
            assertBool ("expected an allocation, got " <> T.unpack output) $
              "alloca" `T.isInfixOf` output
        ]
    ]
  where
    -- The steps a program takes to reach both fields, and the accesses through
    -- them.  Most cases below are this with a line added, so that what a case
    -- is about is the line it added.
    both =
      [ "  %p = getelementptr inbounds %s, ptr %a, i32 0, i32 0"
      , "  store i32 %v, ptr %p, align 4"
      , "  %q = getelementptr inbounds %s, ptr %a, i32 0, i32 1"
      , "  %r = load i32, ptr %q, align 4"
      ]

    second =
      [ "  %q = getelementptr inbounds %s, ptr %a, i32 0, i32 1"
      , "  %r = load i32, ptr %q, align 4"
      ]

    filling what count =
      "  call void @llvm.memset.p0.i64(ptr align 4 %a, " <> what <> ", " <> count <> ", i1 false)"

    -- A second slot of the same struct, copied into from the first.
    copying =
      [ "  %b = alloca %s, align 4"
      , "  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %b, ptr align 4 %a, i64 8, i1 false)"
      ]

    -- And the same copy where the other end is a pointer handed in.
    copyingOut =
      [ "  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %out, ptr align 4 %a, i64 8, i1 false)"
      ]

    started pointer = "  call void @llvm.lifetime.start.p0(i64 8, ptr " <> pointer <> ")"
    ended pointer = "  call void @llvm.lifetime.end.p0(i64 8, ptr " <> pointer <> ")"

    holding body = surrounding "  %a = alloca %s, align 4" body

    allocating what = surrounding ("  %a = " <> what) both

    surrounding allocation body =
      T.unlines
        ( [ -- The layout string is here for the two cases that are a byte
            -- count: a fill and a copy have to be shown to cover exactly the
            -- type the slot was allocated as, and that is the one question the
            -- pass asks it.  Everything else answers the same without it.
            "target datalayout = \"e-m:e-i64:64-f80:128-n8:16:32:64-S128\""
          , "%s = type { i32, i32 }"
          , "%t = type { i32, i8 }"
          , "declare void @g(ptr)"
          , "declare void @llvm.memset.p0.i64(ptr captures(none), i8, i64, i1 immarg)"
          , "declare void @llvm.memcpy.p0.p0.i64(ptr captures(none), ptr captures(none), i64, i1 immarg)"
          , "declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none))"
          , "declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none))"
          , "define i32 @f(i32 %v, i64 %n, ptr %out) {"
          , "entry:"
          , allocation
          ]
            <> body
            <> ["  ret i32 %v", "}"]
        )

    escapingByReturn =
      T.unlines
        ( [ "%s = type { i32, i32 }"
          , "define ptr @f(i32 %v) {"
          , "entry:"
          , "  %a = alloca %s, align 4"
          ]
            <> both
            <> ["  ret ptr %q", "}"]
        )

    selfAddressed =
      T.unlines
        [ "%u = type { ptr }"
        , "define void @f() {"
        , "entry:"
        , "  %a = alloca %u, align 8"
        , "  %p = getelementptr inbounds %u, ptr %a, i32 0, i32 0"
        , "  store ptr %p, ptr %p, align 8"
        , "  ret void"
        , "}"
        ]

    nested =
      T.unlines
        [ "%outer = type { %inner, i32 }"
        , "%inner = type { i32, i32 }"
        , "define i32 @f(i32 %v) {"
        , "entry:"
        , "  %a = alloca %outer, align 4"
        , "  %p = getelementptr inbounds %outer, ptr %a, i32 0, i32 0"
        , "  %q = getelementptr inbounds %inner, ptr %p, i32 0, i32 1"
        , "  store i32 %v, ptr %q, align 4"
        , "  %r = load i32, ptr %q, align 4"
        , "  ret i32 %r"
        , "}"
        ]

-- | @?=@ against something read out of a parse, which is in 'IO'.
(@?>=) :: (Eq a, Show a) => IO a -> a -> Assertion
got @?>= expected = got >>= (@?= expected)

-- | How many slots the pass decided it could take apart, across the program.
slots :: Text -> IO Int
slots source = length <$> aggregates source

-- | Which fields it decided to take, across the program.
--
-- The indices rather than the locals, so that a case says which field it is
-- about without also fixing the numbering the lowering gave the locals around
-- it.
taken :: Text -> IO [Natural]
taken source = concatMap (Map.keys . aggregateFields) <$> aggregates source

aggregates :: Text -> IO [Aggregate]
aggregates source = do
  program <- lowered source
  pure (concatMap (Map.elems . splittableIn (namedTypes program)) (functionsIn program))

-- | What each instruction of the one function is, after splitting, named
-- coarsely enough that a test can state the whole list.
shapes :: Text -> IO [Text]
shapes source = do
  program <- split source
  pure
    [ shapeOf (instructionOperation i)
    | f <- functionsIn program
    , b <- functionBlocks f
    , i <- blockInstructions b
    ]

shapeOf :: Operation operand -> Text
shapeOf operation = case operation of
  OAlloca _ -> "alloca"
  OLoad _ -> "load"
  OStore _ -> "store"
  OField _ -> "field"
  OOffset _ -> "offset"
  _ -> "other"

-- | What each allocation left standing allocates.
allocated :: Text -> IO [Type]
allocated source = map allocaType <$> allocations source

alignments :: Text -> IO [Maybe Natural]
alignments source = map allocaAlignment <$> allocations source

spaces :: Text -> IO [Maybe Natural]
spaces source = map allocaAddrSpace <$> allocations source

allocations :: Text -> IO [Alloca (TypedValue Local)]
allocations source = do
  program <- split source
  pure
    [ a
    | f <- functionsIn program
    , b <- functionBlocks f
    , i <- blockInstructions b
    , OAlloca a <- [instructionOperation i]
    ]

lowered :: Text -> IO Program
lowered source = lower <$> expectParse "<inline>" source

split :: Text -> IO Program
split source = splitAggregates <$> lowered source

-- | Through the whole pipeline and back out as LLVM, which is where the point
-- of the pass shows: what promotion could not touch is gone.
rendered :: Text -> IO Text
rendered source = renderModule . optimize <$> expectParse "<inline>" source
