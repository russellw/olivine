-- | Tests that constructs are actually modelled rather than merely surviving
-- the round trip.
--
-- The round-trip test passes just as happily when a construct is still an
-- 'EOpaque' line, so on its own it cannot tell growth of the grammar from the
-- appearance of it.  Each construct moved out of the opaque residue gets a
-- pair of checks here: that it is recognized, and that no line which should
-- have become it is left behind.
module Structure (structureTests, headerSyntaxTests) where

import Data.Foldable (for_)
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (corpusFiles, expectParse, parseCorpusFile)
import Olivine.Syntax.Ast
import Olivine.Syntax.Printer (renderModule)

-- | Each modelled header construct: how to spot it in the syntax tree, and
-- how to spot a line that should have become it but did not.
headerConstructs :: [(String, Entry -> Bool, Text -> Bool)]
headerConstructs =
  [ ("module identifier", isModuleId, T.isPrefixOf "; ModuleID")
  , ("source filename", isSourceFilename, T.isPrefixOf "source_filename")
  , ("data layout", isDataLayout, T.isPrefixOf "target datalayout")
  , ("target triple", isTriple, T.isPrefixOf "target triple")
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

structureTests :: IO TestTree
structureTests = do
  names <- corpusFiles
  pure $
    testGroup
      "module headers are modelled"
      [testCase name (headerRecognized name) | name <- names]

-- Every module clang emits carries all four of these.
headerRecognized :: FilePath -> Assertion
headerRecognized name = do
  entries <- moduleEntries <$> parseCorpusFile name
  let residue = [T.stripStart t | EOpaque t <- entries]
  for_ headerConstructs $ \(label, inTree, inResidue) -> do
    assertBool (label <> " was not recognized") (any inTree entries)
    case filter inResidue residue of
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
