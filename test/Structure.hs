-- | Tests that constructs are actually modelled rather than merely surviving
-- the round trip.
--
-- The round-trip test passes just as happily when a construct is still an
-- 'EOpaque' line, so on its own it cannot tell growth of the grammar from the
-- appearance of it.  Each construct moved out of the opaque residue gets a
-- row in 'constructs' below, which is checked in both directions: it must be
-- recognized in exactly those files whose text contains it, and no line that
-- looks like it may be left behind.
--
-- Deriving the expectation from the source text rather than hard-coding
-- which files contain what means the checks keep their force when the corpus
-- is regenerated or extended.
module Structure (structureTests, headerSyntaxTests) where

import Data.Foldable (for_)
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (corpusFiles, expectParse, readCorpusFile)
import Olivine.Syntax.Ast
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type

-- | Each modelled construct: how to spot it in the syntax tree, and how to
-- spot a line of source that should have become it.
constructs :: [(String, Entry -> Bool, Text -> Bool)]
constructs =
  [ ("module identifier", isModuleId, T.isPrefixOf "; ModuleID")
  , ("source filename", isSourceFilename, T.isPrefixOf "source_filename")
  , ("data layout", isDataLayout, T.isPrefixOf "target datalayout")
  , ("target triple", isTriple, T.isPrefixOf "target triple")
  , ("type definition", isTypeDefinition, looksLikeTypeDefinition)
  , ("global variable", isGlobal, looksLikeGlobal)
  , ("declaration", isDeclare, T.isPrefixOf "declare")
  ]
  where
    isModuleId (EModuleId _) = True
    isModuleId _ = False
    isSourceFilename (ESourceFilename _) = True
    isSourceFilename _ = False
    isDataLayout (ETargetDataLayout _) = True
    isDataLayout _ = False
    isTriple (ETargetTriple _) = True
    isTriple _ = False
    isTypeDefinition (ETypeDefinition _ _) = True
    isTypeDefinition _ = False
    isGlobal (EGlobal _) = True
    isGlobal _ = False
    isDeclare (EDeclare _) = True
    isDeclare _ = False
    -- Narrow enough not to match the instructions that also start with %.
    looksLikeTypeDefinition line =
      "%" `T.isPrefixOf` line && " = type " `T.isInfixOf` line
    looksLikeGlobal line = "@" `T.isPrefixOf` line && " = " `T.isInfixOf` line

structureTests :: IO TestTree
structureTests = do
  names <- corpusFiles
  pure $
    testGroup
      "constructs are modelled"
      [testCase name (constructsRecognized name) | name <- names]

constructsRecognized :: FilePath -> Assertion
constructsRecognized name = do
  (source, parsed) <- readCorpusFile name
  let entries = moduleEntries parsed
      residue = [T.stripStart t | EOpaque t <- entries]
      sourceLines = map T.stripStart (T.lines source)
  for_ constructs $ \(label, inTree, looksLike) -> do
    assertEqual
      (label <> ": present in the source but not in the syntax tree, or vice versa")
      (any looksLike sourceLines)
      (any inTree entries)
    case filter looksLike residue of
      [] -> pure ()
      leftover ->
        assertFailure (label <> " left unmodelled: " <> show leftover)

-- | Value-level checks on the syntax itself, independent of the corpus, whose
-- exact contents depend on which clang generated it.
headerSyntaxTests :: TestTree
headerSyntaxTests =
  testGroup
    "module header syntax"
    [ testCase "module identifier" $
        parsesTo "; ModuleID = 'hello.c'\n" [EModuleId "hello.c"]
    , testCase "source filename" $
        parsesTo
          "source_filename = \"hello.c\"\n"
          [ESourceFilename "hello.c"]
    , testCase "triple" $
        parsesTo
          "target triple = \"x86_64-pc-linux-gnu\"\n"
          [ETargetTriple "x86_64-pc-linux-gnu"]
    , testCase "data layout" $
        parsesTo
          "target datalayout = \"e-m:e-i64:64-n8:16:32:64\"\n"
          [ETargetDataLayout "e-m:e-i64:64-n8:16:32:64"]
    , testCase "type definition" $
        parsesTo
          "%struct.point = type { i32, i32 }\n"
          [ ETypeDefinition
              (Name Bare "struct.point")
              (TStruct Unpacked [TInteger 32, TInteger 32])
          ]
    , testCase "spacing is not significant" $
        parsesTo
          "  target\ttriple  =\"aarch64\"  \n"
          [ETargetTriple "aarch64"]
    , testCase "a final line break is not required" $
        parsesTo "target triple = \"aarch64\"" [ETargetTriple "aarch64"]
    , -- The module identifier rule starts at a semicolon, so it has to leave
      -- every other comment alone.
      testCase "other comments stay opaque" $
        parsesTo
          "; Function Attrs: nounwind\n"
          [EOpaque "; Function Attrs: nounwind"]
    , testCase "a near miss stays opaque" $
        parsesTo "target other = \"x\"\n" [EOpaque "target other = \"x\""]
    , -- The type definition rule starts at a local name, so it has to leave
      -- the instructions that start the same way alone.
      testCase "instructions stay opaque" $
        parsesTo
          "  %retval = alloca i32, align 4\n"
          [EOpaque "  %retval = alloca i32, align 4"]
    , -- An identifier containing a quote cannot be read back, so it must not
      -- be silently truncated.
      testCase "an unreadable module identifier stays opaque" $
        parsesTo "; ModuleID = 'it's'\n" [EOpaque "; ModuleID = 'it's'"]
    , testCase "printing is canonical" $
        renderModule
          (Module [EModuleId "hello.c", ESourceFilename "hello.c"])
          @?= "; ModuleID = 'hello.c'\nsource_filename = \"hello.c\"\n"
    ]

parsesTo :: Text -> [Entry] -> Assertion
parsesTo source expected = do
  parsed <- expectParse "<inline>" source
  moduleEntries parsed @?= expected
