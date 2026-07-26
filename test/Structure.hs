-- | Tests that constructs are actually modelled rather than merely surviving
-- the round trip.
--
-- The round-trip test passes just as happily when a construct is still an
-- 'EOpaque' line, so on its own it cannot tell growth of the grammar from the
-- appearance of it.  Each construct moved out of the opaque residue gets a
-- check here: that it is recognized, and that nothing resembling it is left
-- behind unmodelled.
module Structure (structureTests, targetSyntaxTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (corpusFiles, expectParse, parseCorpusFile)
import Olivine.Syntax.Ast
import Olivine.Syntax.Printer (renderModule)

structureTests :: IO TestTree
structureTests = do
  names <- corpusFiles
  pure $
    testGroup
      "target definitions are modelled"
      [testCase name (targetsRecognized name) | name <- names]

-- Every module clang emits names both its data layout and its triple.
targetsRecognized :: FilePath -> Assertion
targetsRecognized name = do
  entries <- moduleEntries <$> parseCorpusFile name
  assertBool "no data layout was recognized" (any isDataLayout entries)
  assertBool "no target triple was recognized" (any isTriple entries)
  case filter looksLikeTarget [t | EOpaque t <- entries] of
    [] -> pure ()
    leftover ->
      assertFailure ("target definition left unmodelled: " <> show leftover)
  where
    isDataLayout (ETargetDataLayout _) = True
    isDataLayout _ = False
    isTriple (ETargetTriple _) = True
    isTriple _ = False
    looksLikeTarget = T.isPrefixOf "target" . T.stripStart

-- | Value-level checks on the syntax itself, independent of the corpus, whose
-- exact contents depend on which clang generated it.
targetSyntaxTests :: TestTree
targetSyntaxTests =
  testGroup
    "target definition syntax"
    [ testCase "triple" $
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
    , testCase "anything else stays opaque" $
        parsesTo "target other = \"x\"\n" [EOpaque "target other = \"x\""]
    , testCase "printing is canonical" $
        renderModule (Module [ETargetTriple "aarch64"])
          @?= "target triple = \"aarch64\"\n"
    ]

parsesTo :: Text -> [Entry] -> Assertion
parsesTo source expected = do
  parsed <- expectParse "<inline>" source
  moduleEntries parsed @?= expected
