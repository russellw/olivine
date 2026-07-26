-- | The load-bearing test for the ingest/egress layer.
module RoundTrip (roundTripTests) where

import Control.Monad (unless)
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (corpusFiles, expectParse, parseCorpusFile)
import Olivine.Syntax.Printer (renderModule)

roundTripTests :: IO TestTree
roundTripTests = do
  names <- corpusFiles
  pure $
    testGroup
      "round trip"
      [testCase name (roundTrip name) | name <- names]

-- | Parsing, printing and reparsing must reach a fixed point.  Byte-exact
-- output is deliberately not required: the printer normalizes whitespace, and
-- it is the abstract syntax that passes have to preserve.
roundTrip :: FilePath -> Assertion
roundTrip name = do
  parsed <- parseCorpusFile name
  reparsed <- expectParse (name <> " (reprinted)") (renderModule parsed)
  unless (parsed == reparsed) $
    assertFailure "reparsing the printed module gave a different syntax tree"
