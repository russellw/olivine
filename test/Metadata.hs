-- | Metadata nodes, named and numbered.
module Metadata (metadataTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Value
import Olivine.Syntax.Metadata
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type

-- | Nodes in the spelling LLVM itself emits.
--
-- These could not be checked a line at a time the way the other constructs
-- were: LLVM numbers metadata densely in order of first use and drops any
-- node nothing refers to, so a line lifted out of its module comes back
-- renumbered or not at all.  They were verified two ways instead — @opt -S@
-- over each corpus file reproduces its whole metadata block unchanged, and
-- the shapes the corpus lacks were checked as a self-contained module.
emitted :: [Text]
emitted =
  [ "!0 = !{}"
  , "!0 = !{i32 1}"
  , "!0 = !{!1}"
  , "!0 = !{!\"a string\"}"
  , "!0 = !{null}"
  , "!0 = !{ptr @g}"
  , -- Distinctness is part of the node's identity, not decoration.
    "!0 = distinct !{}"
  , "!9 = distinct !{!9, !10}"
  , "!13 = distinct !{!13, !10, !12, !11}"
  , -- Named nodes, whose operands are always references.
    "!llvm.ident = !{!4}"
  , "!llvm.module.flags = !{!0, !1, !2, !3}"
  , "!name = !{}"
  , -- The shapes clang actually emitted into the corpus.
    "!0 = !{i32 1, !\"wchar_size\", i32 4}"
  , "!1 = !{i32 8, !\"PIC Level\", i32 2}"
  , "!4 = !{!\"Ubuntu clang version 21.1.8 (6ubuntu1)\"}"
  , "!5 = !{!\"Simple C/C++ TBAA\"}"
  , "!6 = !{!\"omnipotent char\", !10, i64 0}"
  , "!7 = !{!\"llvm.loop.mustprogress\"}"
  , "!8 = !{!\"llvm.loop.isvectorized\", i32 1}"
  , "!11 = !{!\"point\", !8, i64 0, !8, i64 4}"
  , "!12 = !{!\"body\", !7, i64 0, !7, i64 8, !11, i64 16, !9, i64 24}"
  ]

-- | Accepted, but LLVM writes it differently.
accepted :: [Text]
accepted =
  [ -- A tuple written inside another is hoisted out into a node of its own
    -- and referred to, so this spelling goes in but never comes back.
    "!0 = !{!{!1}}"
  ]

-- | Text that must leave the line opaque rather than be parsed as some prefix
-- of itself.  The specialized debug nodes are the boundary of what is
-- modelled, and the reason a module compiled with @-g@ would still be mostly
-- opaque.
rejected :: [Text]
rejected =
  [ "!0 = !DILocation(line: 1, column: 2, scope: !3)"
  , "!0 = distinct !DISubprogram(name: \"f\")"
  , "!0 = {i32 1}" -- the sigil on the tuple is not optional
  , "!0 = !{i32 1" -- unbalanced
  , "!0 = !{i32 1,}"
  , "!0 ="
  , "!llvm.foo = !{i32 1}" -- a named node takes references, not values
  ]

metadataTests :: TestTree
metadataTests =
  testGroup
    "metadata"
    [ testGroup
        "round trip"
        [testCase (T.unpack line) (roundTrips line) | line <- emitted <> accepted]
    , testGroup
        "rejected"
        [testCase (T.unpack line) (staysOpaque line) | line <- rejected]
    , fieldTests
    ]

roundTrips :: Text -> Assertion
roundTrips line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EMetadata _ _ _] -> renderModule parsed @?= line <> "\n"
    [ENamedMetadata _ _] -> renderModule parsed @?= line <> "\n"
    entries -> assertFailure ("expected one metadata node, got " <> show entries)

staysOpaque :: Text -> Assertion
staysOpaque line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  moduleEntries parsed @?= [EOpaque line]

fieldTests :: TestTree
fieldTests =
  testGroup
    "fields"
    [ testCase "number" $ entry "!42 = !{}" (EMetadata 42 Uniqued [])
    , testCase "uniqued" $ entry "!0 = !{}" (EMetadata 0 Uniqued [])
    , testCase "distinct" $ entry "!0 = distinct !{}" (EMetadata 0 Distinct [])
    , testCase "a reference" $ entry "!0 = !{!7}" (EMetadata 0 Uniqued [MDRef 7])
    , testCase "a string" $
        entry "!0 = !{!\"s\"}" (EMetadata 0 Uniqued [MDString "s"])
    , testCase "a value" $
        entry
          "!0 = !{i32 1}"
          (EMetadata 0 Uniqued [MDValue (TypedValue (TInteger 32) (VInteger 1))])
    , testCase "null" $ entry "!0 = !{null}" (EMetadata 0 Uniqued [MDNull])
    , testCase "an inline tuple" $
        entry "!0 = !{!{!1}}" (EMetadata 0 Uniqued [MDTuple [MDRef 1]])
    , testCase "mixed operands" $
        entry
          "!0 = !{i32 1, !\"wchar_size\", i32 4}"
          ( EMetadata
              0
              Uniqued
              [ MDValue (TypedValue (TInteger 32) (VInteger 1))
              , MDString "wchar_size"
              , MDValue (TypedValue (TInteger 32) (VInteger 4))
              ]
          )
    , testCase "a named node" $
        entry
          "!llvm.module.flags = !{!0, !3}"
          (ENamedMetadata (Name Bare "llvm.module.flags") [0, 3])
    ]

entry :: Text -> Entry -> Assertion
entry line expected = do
  parsed <- expectParse "<inline>" (line <> "\n")
  moduleEntries parsed @?= [expected]
