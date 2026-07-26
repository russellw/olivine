module Main (main) where

import Test.Tasty

import Declares (declareTests)
import Globals (globalTests)
import RoundTrip (roundTripTests)
import Structure (headerSyntaxTests, structureTests)
import Types (typeTests)

main :: IO ()
main = do
  discovered <- sequence [roundTripTests, structureTests]
  defaultMain $
    testGroup
      "olivine"
      ([typeTests, globalTests, declareTests, headerSyntaxTests] <> discovered)
