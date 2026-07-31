module Main (main) where

import Test.Tasty

import Arithmetic (arithmeticTests)
import Attributes (attributeTests)
import Calls (callTests)
import Comdats (comdatTests)
import ControlFlow (controlFlowTests)
import Core (coreTests)
import DeadCode (deadCodeTests)
import DeadSymbols (deadSymbolTests)
import Debug (debugTests)
import Folding (foldingTests)
import Declares (declareTests)
import Definitions (definitionTests)
import Globals (globalTests)
import IfConversion (ifConversionTests)
import Indirects (indirectTests)
import Inlining (inliningTests)
import Invariants (invariantTests)
import Layout (layoutTests)
import Memory (memoryTests)
import Metadata (metadataTests)
import Offsets (offsetTests)
import Phis (phiTests)
import Promotion (promotionTests)
import Redundancies (redundancyTests)
import Rotation (rotationTests)
import Split (splitTests)
import RoundTrip (roundTripTests)
import Structure (headerSyntaxTests, structureTests)
import SyntaxVerify (syntaxVerifyTests)
import Terminators (terminatorTests)
import Types (typeTests)
import Verify (verifyTests)
import Vectors (vectorTests)

main :: IO ()
main = do
  discovered <-
    sequence [roundTripTests, structureTests, definitionTests, coreTests, verifyTests, syntaxVerifyTests]
  defaultMain $
    testGroup
      "olivine"
      ([typeTests, globalTests, comdatTests, indirectTests, declareTests, attributeTests, metadataTests, debugTests, terminatorTests, memoryTests, arithmeticTests, callTests, phiTests, vectorTests, deadCodeTests, deadSymbolTests, foldingTests, controlFlowTests, promotionTests, splitTests, inliningTests, redundancyTests, rotationTests, ifConversionTests, invariantTests, offsetTests, layoutTests, headerSyntaxTests] <> discovered)
