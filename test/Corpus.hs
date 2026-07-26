-- | Shared access to the @.ll@ corpus in @test/data@, which is generated
-- from the C sources in @test/c@ by @tools/gen-corpus.sh@.
module Corpus
  ( dataDir
  , corpusFiles
  , parseCorpusFile
  , expectParse
  ) where

import Data.List (sort)
import Data.Text (Text)
import Data.Text.IO qualified as TIO
import System.Directory (listDirectory)
import System.FilePath (takeExtension, (</>))
import Test.Tasty.HUnit

import Olivine.Syntax.Ast (Module)
import Olivine.Syntax.Parser (parseModule, renderParseError)

-- Relative to the package root, which is where cabal runs test suites.
dataDir :: FilePath
dataDir = "test/data"

-- | Corpus file names, sorted, relative to 'dataDir'.
corpusFiles :: IO [FilePath]
corpusFiles =
  sort . filter ((== ".ll") . takeExtension) <$> listDirectory dataDir

-- | Read and parse one corpus file, failing the test if it does not parse.
parseCorpusFile :: FilePath -> IO Module
parseCorpusFile name = do
  let path = dataDir </> name
  expectParse path =<< TIO.readFile path

expectParse :: FilePath -> Text -> IO Module
expectParse name source =
  case parseModule name source of
    Left err -> assertFailure (renderParseError err)
    Right m -> pure m
