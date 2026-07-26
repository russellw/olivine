-- | Attribute groups and the function attribute vocabulary.
module Attributes (attributeTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Data.List.NonEmpty (NonEmpty ((:|)))
import Numeric.Natural (Natural)
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Attribute
import Olivine.Syntax.Printer (renderModule)

-- | Groups in the spelling LLVM itself emits.
emitted :: [Text]
emitted =
  [ "attributes #0 = { nounwind }"
  , "attributes #12 = { nounwind }"
  , -- The flags, in the order LLVM writes them.
    "attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn }"
  , "attributes #0 = { noinline nounwind optnone }"
  , "attributes #0 = { cold hot minsize optsize }"
  , "attributes #0 = { alwaysinline convergent inlinehint }"
  , "attributes #0 = { naked nobuiltin nocallback noduplicate noimplicitfloat }"
  , "attributes #0 = { returns_twice safestack speculatable strictfp }"
  , "attributes #0 = { ssp sspreq sspstrong }"
  , "attributes #0 = { sanitize_address sanitize_memory sanitize_thread }"
  , "attributes #0 = { sanitize_hwaddress sanitize_memtag sanitize_type }"
  , "attributes #0 = { jumptable nocf_check null_pointer_is_valid }"
  , "attributes #0 = { nosanitize_bounds nosanitize_coverage }"
  , "attributes #0 = { speculative_load_hardening }"
  , "attributes #0 = { disable_sanitizer_instrumentation }"
  , "attributes #0 = { fn_ret_thunk_extern }"
  , "attributes #0 = { presplitcoroutine }"
  , -- builtin is absent above because it belongs on a call site rather than
    -- on a function, so it can never appear in a group.  It stays in the
    -- vocabulary for the call instructions still to come.
    -- Attributes taking arguments.
    "attributes #0 = { uwtable }"
  , "attributes #0 = { uwtable(sync) }"
  , "attributes #0 = { alignstack=16 }"
  , "attributes #0 = { vscale_range(1,16) }"
  , "attributes #0 = { allocsize(0,1) }"
  , "attributes #0 = { memory(none) }"
  , "attributes #0 = { memory(argmem: read) }"
  , "attributes #0 = { memory(readwrite, argmem: none, inaccessiblemem: none) }"
  , "attributes #0 = { allockind(\"alloc,uninitialized\") }"
  , -- String attributes, which are the one open-ended kind.
    "attributes #0 = { \"no-trapping-math\"=\"true\" }"
  , "attributes #0 = { \"target-features\"=\"+cmov,+cx8,+sse2,+x87\" }"
  , -- The shapes clang actually emitted into the corpus.
    "attributes #0 = { noinline nounwind optnone uwtable \"frame-pointer\"=\"all\" \"min-legal-vector-width\"=\"0\" \"no-trapping-math\"=\"true\" \"stack-protector-buffer-size\"=\"8\" \"target-cpu\"=\"x86-64\" \"target-features\"=\"+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87\" \"tune-cpu\"=\"generic\" }"
  , "attributes #2 = { mustprogress nofree nounwind willreturn allockind(\"alloc,uninitialized\") allocsize(0) memory(inaccessiblemem: readwrite) \"alloc-family\"=\"malloc\" }"
  , "attributes #7 = { mustprogress nounwind willreturn allockind(\"free\") memory(argmem: readwrite, inaccessiblemem: readwrite) \"alloc-family\"=\"malloc\" }"
  ]

-- | Accepted, but LLVM writes them differently.
accepted :: [Text]
accepted =
  [ -- A bare string attribute is written back with an empty value.
    "attributes #0 = { \"bare\" }"
  , -- LLVM sorts the attributes it prints into an order of its own, which is
    -- neither alphabetical nor the order they were written.
    "attributes #0 = { nomerge nonlazybind noprofile noredzone noreturn }"
  , "attributes #0 = { optdebug optforfuzzing shadowcallstack }"
  ]

-- | Input that Olivine itself rewrites, with the form it produces.
--
-- Everywhere else a list is separated by a comma and a space, but LLVM writes
-- these two attributes closed up, and the printer follows LLVM rather than
-- its own habit.  Spacing is the only thing lost, and only for input LLVM
-- would not have written that way in the first place.
renormalized :: [(Text, Text)]
renormalized =
  [ ("attributes #0 = { vscale_range(1, 16) }", "attributes #0 = { vscale_range(1,16) }")
  , ("attributes #0 = { allocsize(0, 1) }", "attributes #0 = { allocsize(0,1) }")
  ]

rejected :: [Text]
rejected =
  [ "attributes #0 = { }" -- LLVM rejects a group with nothing in it
  , "attributes #0 = { nounwind" -- unbalanced
  , "attributes 0 = { nounwind }" -- the sigil is not optional
  , "attributes #0 = nounwind" -- nor are the braces
  , "attributes #0 = { nounwind } trailing"
  , "attributes #0 = { align 8 }" -- a parameter attribute, not a function one
  , "attributes #0 = { alignstack(16) }" -- the spelling used on a function
  ]

attributeTests :: TestTree
attributeTests =
  testGroup
    "attribute groups"
    [ testGroup
        "round trip"
        [testCase (T.unpack line) (roundTrips line) | line <- emitted <> accepted]
    , testGroup
        "renormalized"
        [ testCase (T.unpack before) (printsAs before after)
        | (before, after) <- renormalized
        ]
    , testGroup
        "rejected"
        [testCase (T.unpack line) (staysOpaque line) | line <- rejected]
    , fieldTests
    ]

roundTrips :: Text -> Assertion
roundTrips line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EAttributeGroup _ _] -> renderModule parsed @?= line <> "\n"
    entries -> assertFailure ("expected one attribute group, got " <> show entries)

printsAs :: Text -> Text -> Assertion
printsAs before after = do
  parsed <- expectParse "<inline>" (before <> "\n")
  case moduleEntries parsed of
    [EAttributeGroup _ _] -> renderModule parsed @?= after <> "\n"
    entries -> assertFailure ("expected one attribute group, got " <> show entries)

staysOpaque :: Text -> Assertion
staysOpaque line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  moduleEntries parsed @?= [EOpaque line]

fieldTests :: TestTree
fieldTests =
  testGroup
    "fields"
    [ testCase "number" $
        group "attributes #7 = { nounwind }" 7 (FANoUnwind :| [])
    , testCase "flags" $
        group "attributes #0 = { cold nounwind }" 0 (FACold :| [FANoUnwind])
    , -- Stack alignment is the one attribute spelled differently inside a
      -- group than on a function.
      testCase "stack alignment" $
        group "attributes #0 = { alignstack=16 }" 0 (FAAlignStack 16 :| [])
    , testCase "an unwind table with no argument" $
        group "attributes #0 = { uwtable }" 0 (FAUwTable Nothing :| [])
    , testCase "an unwind table with one" $
        group "attributes #0 = { uwtable(async) }" 0 (FAUwTable (Just "async") :| [])
    , testCase "one allocation size" $
        group "attributes #0 = { allocsize(0) }" 0 (FAAllocSize 0 Nothing :| [])
    , testCase "two" $
        group "attributes #0 = { allocsize(0, 1) }" 0 (FAAllocSize 0 (Just 1) :| [])
    , -- The memory effects are their own small language, carried as written.
      testCase "memory effects" $
        group
          "attributes #0 = { memory(argmem: read, inaccessiblemem: write) }"
          0
          (FAMemory "argmem: read, inaccessiblemem: write" :| [])
    , testCase "a string attribute with a value" $
        group
          "attributes #0 = { \"target-cpu\"=\"x86-64\" }"
          0
          (FAString "target-cpu" (Just "x86-64") :| [])
    , testCase "a string attribute without one" $
        group "attributes #0 = { \"bare\" }" 0 (FAString "bare" Nothing :| [])
    , testCase "an allocation kind" $
        group
          "attributes #0 = { allockind(\"alloc,uninitialized\") }"
          0
          (FAAllocKind "alloc,uninitialized" :| [])
    ]

group :: Text -> Natural -> NonEmpty FunctionAttribute -> Assertion
group line number attributes = do
  parsed <- expectParse "<inline>" (line <> "\n")
  moduleEntries parsed @?= [EAttributeGroup number attributes]
