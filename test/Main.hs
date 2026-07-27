module Main (main) where

import Test.Tasty

import Attributes (attributeTests)
import Declares (declareTests)
import Definitions (definitionTests)
import Globals (globalTests)
import Metadata (metadataTests)
import RoundTrip (roundTripTests)
import Structure (headerSyntaxTests, structureTests)
import Terminators (terminatorTests)
import Types (typeTests)

main :: IO ()
main = do
  discovered <- sequence [roundTripTests, structureTests, definitionTests]
  defaultMain $
    testGroup
      "olivine"
      ([typeTests, globalTests, declareTests, attributeTests, metadataTests, terminatorTests, headerSyntaxTests] <> discovered)
