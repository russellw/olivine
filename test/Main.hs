module Main (main) where

import Test.Tasty

import RoundTrip (roundTripTests)
import Structure (structureTests, targetSyntaxTests)

main :: IO ()
main = do
  discovered <- sequence [roundTripTests, structureTests]
  defaultMain (testGroup "olivine" (targetSyntaxTests : discovered))
