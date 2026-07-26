-- | The load-bearing test for the ingest/egress layer.
module RoundTrip (roundTripTests) where

import Control.Monad (unless)
import Data.List (sort)
import Data.Text (Text)
import Data.Text.IO qualified as TIO
import System.Directory (listDirectory)
import System.FilePath (takeExtension, (</>))
import Test.Tasty
import Test.Tasty.HUnit

import Olivine.Syntax.Ast (Module)
import Olivine.Syntax.Parser (parseModule, renderParseError)
import Olivine.Syntax.Printer (renderModule)

-- Relative to the package root, which is where cabal runs test suites.
dataDir :: FilePath
dataDir = "test/data"

roundTripTests :: IO TestTree
roundTripTests = do
  names <- sort . filter ((== ".ll") . takeExtension) <$> listDirectory dataDir
  pure $
    testGroup
      "round trip"
      [testCase name (roundTrip (dataDir </> name)) | name <- names]

-- | Parsing, printing and reparsing must reach a fixed point.  Byte-exact
-- output is deliberately not required: the printer normalizes whitespace, and
-- it is the abstract syntax that passes have to preserve.
roundTrip :: FilePath -> Assertion
roundTrip path = do
  source <- TIO.readFile path
  parsed <- expectParse path source
  reparsed <- expectParse (path <> " (reprinted)") (renderModule parsed)
  unless (parsed == reparsed) $
    assertFailure "reparsing the printed module gave a different syntax tree"

expectParse :: FilePath -> Text -> IO Module
expectParse name source =
  case parseModule name source of
    Left err -> assertFailure (renderParseError err)
    Right m -> pure m
