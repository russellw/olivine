module Main (main) where

import Test.Tasty

import RoundTrip (roundTripTests)
import Structure (headerSyntaxTests, structureTests)
import Types (typeTests)

main :: IO ()
main = do
  discovered <- sequence [roundTripTests, structureTests]
  defaultMain (testGroup "olivine" ([typeTests, headerSyntaxTests] <> discovered))
