-- | The core representation, and the two conversions either side of it.
--
-- What is checked here is that lowering and raising are inverse, and how much
-- of the corpus lowers at all.  Byte-identical output alone would not show the
-- second: it holds just as well when every definition is retained as syntax
-- and nothing reaches the core.
module Core (coreTests) where

import Test.Tasty
import Test.Tasty.HUnit

import Corpus (corpusFiles, readCorpusFile)
import Olivine.Core.Lower (lower)
import Olivine.Core.Program
import Olivine.Core.Raise (raise)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction
import Olivine.Syntax.Printer (renderModule)

coreTests :: IO TestTree
coreTests = do
  names <- corpusFiles
  pure $
    testGroup
      "core"
      [ testGroup
          "lowering and raising are inverse"
          [testCase name (roundTrips name) | name <- names]
      , testGroup
          "definitions reach the core"
          [testCase name (lowersEnough name) | name <- names]
      , testGroup
          "what the core guarantees"
          [testCase name (invariants name) | name <- names]
      ]

-- | While the two representations differ only in shape, raising what was
-- lowered gives back the same text.  Once phi elimination lands this becomes
-- a statement about behavior instead, and this test will have to change with
-- it — deliberately, not by surprise.
roundTrips :: FilePath -> Assertion
roundTrips name = do
  (source, parsed) <- readCorpusFile name
  renderModule (raise (lower parsed)) @?= source

-- | Every definition without a phi must reach the core.  A definition with
-- one must not, since eliminating them is not written yet, and quietly
-- lowering a function whose phis had been dropped would be far worse than
-- retaining it.
lowersEnough :: FilePath -> Assertion
lowersEnough name = do
  (_, parsed) <- readCorpusFile name
  let definitions = [d | Syntax.EDefine d <- Syntax.moduleEntries parsed]
      (withPhi, withoutPhi) = span' hasPhi definitions
      program = lower parsed
  assertEqual
    "definitions without a phi are lowered"
    (length withoutPhi)
    (length (functionsIn program))
  assertEqual
    "definitions with a phi are retained"
    (length withPhi)
    (length [() | ERetained (Syntax.EDefine _) <- programEntries program])
  where
    span' p xs = (filter p xs, filter (not . p) xs)
    hasPhi d =
      or
        [ True
        | b <- Syntax.definitionBlocks d
        , IOperation _ (OPhi _) _ <- Syntax.blockBody b
        ]

-- | The invariants the core has that the syntax layer could not.
invariants :: FilePath -> Assertion
invariants name = do
  (_, parsed) <- readCorpusFile name
  let blocks = concatMap functionBlocks (functionsIn (lower parsed))
  -- A block's terminator slot really does hold a terminator.  The position is
  -- structural; that what sits in it is a terminator is a predicate, so it is
  -- worth asserting rather than assuming.
  assertEqual
    "the terminator slot holds a terminator"
    []
    [ terminatorOperation t
    | b <- blocks
    , let t = blockTerminator b
    , not (isTerminator (terminatorOperation t))
    ]
  assertEqual
    "nothing before the terminator is one"
    []
    [ instructionOperation i
    | b <- blocks
    , i <- blockInstructions b
    , isTerminator (instructionOperation i)
    ]
  assertEqual
    "no phi survives lowering"
    []
    [() | b <- blocks, i <- blockInstructions b, isPhi (instructionOperation i)]
  where
    isPhi (OPhi _) = True
    isPhi _ = False
