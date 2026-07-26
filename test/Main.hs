module Main (main) where

import Test.Tasty

import RoundTrip (roundTripTests)
import Structure (headerSyntaxTests, structureTests)

main :: IO ()
main = do
  discovered <- sequence [roundTripTests, structureTests]
  defaultMain (testGroup "olivine" (headerSyntaxTests : discovered))
