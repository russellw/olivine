module Main (main) where

import Test.Tasty

import RoundTrip (roundTripTests)

main :: IO ()
main = do
  tests <- sequence [roundTripTests]
  defaultMain (testGroup "olivine" tests)
