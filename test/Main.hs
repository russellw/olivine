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
import Folding (foldingTests)
import Declares (declareTests)
import Definitions (definitionTests)
import Globals (globalTests)
import Indirects (indirectTests)
import Inlining (inliningTests)
import Memory (memoryTests)
import Metadata (metadataTests)
import Offsets (offsetTests)
import Phis (phiTests)
import Promotion (promotionTests)
import RoundTrip (roundTripTests)
import Structure (headerSyntaxTests, structureTests)
import Subexpressions (subexpressionTests)
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
      ([typeTests, globalTests, comdatTests, indirectTests, declareTests, attributeTests, metadataTests, terminatorTests, memoryTests, arithmeticTests, callTests, phiTests, vectorTests, deadCodeTests, deadSymbolTests, foldingTests, controlFlowTests, promotionTests, inliningTests, subexpressionTests, offsetTests, headerSyntaxTests] <> discovered)
