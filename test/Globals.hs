-- | Global variable definitions and the constant grammar they carry.
--
-- Most of these are stated as a single line of LLVM that must survive
-- unchanged.  Writing the expected syntax tree out in full for each would be
-- far longer than the line itself and no more revealing, so the round trip
-- carries the weight, with 'fieldTests' pinning down the readings that a
-- printer bug could otherwise hide.
module Globals (globalTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Value
import Olivine.Syntax.Global
import Olivine.Syntax.Linkage
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type

-- | Definitions in the spelling LLVM itself emits: every line here was fed
-- to @opt -S@, which echoed it back character for character.
emitted :: [Text]
emitted =
  [ -- Linkage, preemption and the rest of the modifier sequence.
    "@g = global i32 0"
  , "@g = private global i32 0"
  , "@g = internal global i32 0"
  , "@g = linkonce_odr global i32 0"
  , "@g = weak_odr global i32 0"
  , "@g = available_externally global i32 0"
  , "@g = external global i32"
  , "@g = dso_local global i32 0"
  , "@g = hidden global i32 0"
  , "@g = protected global i32 0"
  , "@g = dllexport global i32 0"
  , "@g = thread_local global i32 0"
  , "@g = thread_local(localexec) global i32 0"
  , "@g = unnamed_addr global i32 0"
  , "@g = local_unnamed_addr global i32 0"
  , "@g = addrspace(3) global i32 0"
  , "@g = externally_initialized global i32 0"
  , "@g = internal local_unnamed_addr constant i32 0"
  , -- Trailing attributes.
    "@g = global i32 0, align 4"
  , "@g = global i32 0, section \"mysection\""
  , "@g = global i32 0, comdat"
  , "@g = global i32 0, comdat($c)"
  , "@g = global i32 0, section \"s\", align 8"
  , -- Constants.
    "@g = global i32 -1"
  , "@g = global i1 true"
  , "@g = global i1 false"
  , "@g = global double 1.000000e+00"
  , "@g = global double -2.500000e-01"
  , "@g = global double 0x400921FB54442D18"
  , "@g = global x86_fp80 0xK4000C90FDAA22168C235"
  , "@g = global ptr null"
  , "@g = global i32 undef"
  , "@g = global i32 poison"
  , "@g = global [4 x double] zeroinitializer"
  , "@g = global [8 x i8] c\"olivine\\00\""
  , "@g = global [5 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5]"
  , "@g = global <2 x i32> <i32 1, i32 2>"
  , "@g = global { i32, ptr } { i32 1, ptr @x }"
  , "@g = global <{ i32, i8 }> <{ i32 1, i8 2 }>"
  , "@g = global ptr @counter"
  , "@g = global ptr getelementptr (i8, ptr @t, i64 8)"
  , "@g = global ptr getelementptr inbounds nuw (i8, ptr @t, i64 8)"
  , "@g = global i64 ptrtoint (ptr @t to i64)"
  , "@g = global ptr inttoptr (i64 16 to ptr)"
  , -- The shapes clang actually emitted into the corpus.
    "@.str = private unnamed_addr constant [14 x i8] c\"hello, world\\0A\\00\", align 1"
  , "@paired = dso_local global { i32, [4 x i8], ptr } { i32 1, [4 x i8] zeroinitializer, ptr @.str.1 }, align 8"
  ]

-- | Definitions LLVM accepts but writes back differently: it drops modifiers
-- that its own defaults already imply, and it spells the empty aggregates its
-- own way.  Olivine keeps what was written, so these still have to round-trip
-- unchanged here — they are separated only so that 'emitted' can honestly
-- claim to be LLVM's own output.
accepted :: [Text]
accepted =
  [ -- Preemptability is the default, so LLVM leaves it off.
    "@g = dso_preemptable global i32 0"
  , -- Likewise implied by internal linkage.
    "@g = internal dso_local local_unnamed_addr constant i32 0"
  , -- LLVM writes these as poison and zeroinitializer respectively.
    "@g = global [0 x i32] []"
  , "@g = global {} {}"
  ]

-- | Text that must leave the line opaque rather than be parsed as some prefix
-- of itself.  The constant expressions here are the boundary of what is
-- modelled: LLVM still accepts the arithmetic ones, and they are not done.
rejected :: [Text]
rejected =
  [ "@g = i32 0" -- neither global nor constant
  , "@g = global i32 0 align 4" -- the comma is not optional
  , "@g = global i32 0, align" -- nor is the alignment
  , "@g = global i64 add (i64 1, i64 2)" -- not modelled
  , "@g = global i32 select (i1 true, i32 1, i32 2)" -- removed from LLVM
  , "@g = global i32 0, no_sanitize_address" -- not modelled
  , "@g = global [5 x i32] [i32 1,]"
  ]

globalTests :: TestTree
globalTests =
  testGroup
    "globals"
    [ testGroup
        "round trip"
        [testCase (T.unpack line) (roundTrips line) | line <- emitted <> accepted]
    , testGroup
        "rejected"
        [testCase (T.unpack line) (staysOpaque line) | line <- rejected]
    , fieldTests
    , constantTests
    ]

-- | The predicate that replaced the type distinction between constants and
-- operands.  Nothing enforces it yet — a verifier will — so it is tested
-- here rather than left to be discovered wrong later.
constantTests :: TestTree
constantTests =
  testGroup
    "isConstant"
    [ testCase "a literal" $ isConstant (VInteger 1) @?= True
    , testCase "a reference to a global" $
        isConstant (VGlobal (Name Bare "g")) @?= True
    , testCase "a local" $ isConstant (VLocal (Name Bare "x")) @?= False
    , testCase "an aggregate of literals" $
        isConstant (VArray [TypedValue (TInteger 32) (VInteger 1)]) @?= True
    , -- The recursion is the point: a local anywhere inside makes the whole
      -- operand non-constant.
      testCase "an aggregate holding a local" $
        isConstant (VArray [TypedValue (TInteger 32) (VLocal (Name Bare "x"))])
          @?= False
    , testCase "a nested aggregate holding a local" $
        isConstant
          ( VStruct
              Unpacked
              [ TypedValue
                  (TArray 1 (TInteger 32))
                  (VArray [TypedValue (TInteger 32) (VLocal (Name Bare "x"))])
              ]
          )
          @?= False
    , testCase "a constant expression over globals" $
        isConstant
          ( VGetElementPtr
              [GepInbounds]
              (TInteger 8)
              [TypedValue (TPointer Nothing) (VGlobal (Name Bare "t"))]
          )
          @?= True
    , testCase "a constant expression over a local" $
        isConstant
          ( VGetElementPtr
              []
              (TInteger 8)
              [TypedValue (TPointer Nothing) (VLocal (Name Bare "p"))]
          )
          @?= False
    ]

-- | The line must parse to exactly one global and print back unchanged.
roundTrips :: Text -> Assertion
roundTrips line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EGlobal _] -> renderModule parsed @?= line <> "\n"
    entries -> assertFailure ("expected one global, got " <> show entries)

staysOpaque :: Text -> Assertion
staysOpaque line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  moduleEntries parsed @?= [EOpaque line]

-- | Checks that the parts are read as the things they mean, not merely
-- shuffled from input to output.
fieldTests :: TestTree
fieldTests =
  testGroup
    "fields"
    [ testCase "linkage" $
        field globalLinkage "@g = private global i32 0" (Just LinkPrivate)
    , testCase "no linkage" $
        field globalLinkage "@g = global i32 0" Nothing
    , testCase "preemption" $
        field globalPreemption "@g = dso_local global i32 0" (Just DsoLocal)
    , testCase "unnamed address" $
        field
          globalUnnamedAddr
          "@g = local_unnamed_addr global i32 0"
          (Just LocalUnnamedAddr)
    , testCase "address space" $
        field globalAddrSpace "@g = addrspace(3) global i32 0" (Just 3)
    , testCase "global is mutable" $
        field globalMutability "@g = global i32 0" Mutable
    , testCase "constant is not" $
        field globalMutability "@g = constant i32 0" Immutable
    , testCase "type" $
        field globalType "@g = global [8 x i8] zeroinitializer" (TArray 8 (TInteger 8))
    , testCase "initializer" $
        field globalInitializer "@g = global i32 7" (Just (VInteger 7))
    , testCase "a declaration has none" $
        field globalInitializer "@g = external global i32" Nothing
    , testCase "alignment" $
        field globalAttributes "@g = global i32 0, align 16" [GAAlign 16]
    , -- The escapes inside a string constant are carried as written rather
      -- than decoded, so nothing can be lost re-encoding them.
      testCase "string contents" $
        field
          globalInitializer
          "@g = global [8 x i8] c\"olivine\\00\""
          (Just (VString "olivine\\00"))
    , testCase "global reference" $
        field
          globalInitializer
          "@g = global ptr @counter"
          (Just (VGlobal (Name Bare "counter")))
    , testCase "getelementptr flags" $
        field
          globalInitializer
          "@g = global ptr getelementptr inbounds nuw (i8, ptr @t, i64 8)"
          ( Just
              ( VGetElementPtr
                  [GepInbounds, GepNuw]
                  (TInteger 8)
                  [ TypedValue (TPointer Nothing) (VGlobal (Name Bare "t"))
                  , TypedValue (TInteger 64) (VInteger 8)
                  ]
              )
          )
    ]

field :: (Show a, Eq a) => (Global -> a) -> Text -> a -> Assertion
field get line expected = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EGlobal g] -> get g @?= expected
    entries -> assertFailure ("expected one global, got " <> show entries)
