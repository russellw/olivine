module Main (main) where

import Test.Tasty

import Attributes (attributeTests)
import Declares (declareTests)
import Globals (globalTests)
import Metadata (metadataTests)
import RoundTrip (roundTripTests)
import Structure (headerSyntaxTests, structureTests)
import Types (typeTests)

main :: IO ()
main = do
  discovered <- sequence [roundTripTests, structureTests]
  defaultMain $
    testGroup
      "olivine"
      ([typeTests, globalTests, declareTests, attributeTests, metadataTests, headerSyntaxTests] <> discovered)
