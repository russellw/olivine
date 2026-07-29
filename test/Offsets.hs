-- | Taking @getelementptr@ apart.
--
-- CLAUDE.md asks the core for a form that calculates one pointer offset at a
-- time, so what is checked here is that one written @getelementptr@ becomes
-- as many steps as it walks, that each step says what it strides over, and
-- that the chain says the same thing the line did — which the corpus checks
-- by running the program and this checks by looking.
--
-- That no step has more than one index is not checked, because it cannot be
-- written: 'Offset' holds one operand and 'Field' holds one number.
module Offsets (offsetTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Numeric.Natural (Natural)
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Program
import Olivine.Core.Raise (raise)
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type

offsetTests :: TestTree
offsetTests =
  testGroup
    "offsets"
    [ testGroup
        "what one getelementptr becomes"
        [ -- One index is already one step, and stays one.
          testCase "a single index is one stride" $ do
            steps <- stepsIn "  %r = getelementptr i32, ptr %p, i64 %n"
            steps @?= [Stride (TInteger 32)]
        , -- Two indices walk two types: the array, then its element.
          testCase "an array subscript is two strides" $ do
            steps <- stepsIn "  %r = getelementptr [8 x i32], ptr %p, i64 %n, i64 %n"
            steps @?= [Stride (TArray 8 (TInteger 32)), Stride (TInteger 32)]
        , -- Three, and the last one strides over the innermost element.
          testCase "a nested array walks each dimension" $ do
            steps <-
              stepsIn "  %r = getelementptr [4 x [8 x i32]], ptr %p, i64 %n, i64 %n, i64 %n"
            steps
              @?= [ Stride (TArray 4 (TArray 8 (TInteger 32)))
                  , Stride (TArray 8 (TInteger 32))
                  , Stride (TInteger 32)
                  ]
        , -- A vector is indexed the way an array is.
          testCase "a vector subscript is a stride" $ do
            steps <- stepsIn "  %r = getelementptr <4 x i32>, ptr %p, i64 %n, i64 %n"
            steps @?= [Stride (TVector FixedWidth 4 (TInteger 32)), Stride (TInteger 32)]
        , -- A struct is not a stride: where a field begins is the layout's
          -- business, so the step names the field rather than a distance.
          testCase "a struct field is a selection" $ do
            steps <- stepsIn "  %r = getelementptr {i32, i64}, ptr %p, i32 0, i32 1"
            steps @?= [Select (TStruct Unpacked [TInteger 32, TInteger 64]) 1]
        , -- The zero in front of a field selection is part of it, not a step:
          -- LLVM has no way to name a field without one.
          testCase "arriving at the struct is not a step of its own" $ do
            steps <- stepsIn "  %r = getelementptr {i32, i64}, ptr %p, i32 0, i32 0"
            steps @?= [Select (TStruct Unpacked [TInteger 32, TInteger 64]) 0]
        , -- A stride that is not zero is a step, and the field selection
          -- after it is another.
          testCase "a subscripted struct strides and then selects" $ do
            steps <- stepsIn "  %r = getelementptr {i32, i64}, ptr %p, i64 2, i32 1"
            let s = TStruct Unpacked [TInteger 32, TInteger 64]
            steps @?= [Stride s, Select s 1]
        , -- Walking through a field's own type needs the field's type, which
          -- means reading the struct body rather than just counting.
          testCase "a walk continues into the field it selected" $ do
            steps <- stepsIn "  %r = getelementptr {i32, [4 x i8]}, ptr %p, i32 0, i32 1, i64 %n"
            steps
              @?= [ Select (TStruct Unpacked [TInteger 32, TArray 4 (TInteger 8)]) 1
                  , Stride (TInteger 8)
                  ]
        ]
    , testGroup
        "named types"
        [ -- A named struct says which field only by way of its definition, so
          -- the lowering has to have read the module's type table.
          testCase "a named struct is resolved to select a field" $ do
            steps <- stepsInModule namedStruct "  %r = getelementptr %pair, ptr %p, i32 0, i32 1"
            steps @?= [Select (TNamed (Name Bare "pair")) 1]
        , -- And the name is what comes back out: nothing here expands it.
          testCase "and stays named on the way out" $ do
            written <- renderedFrom namedStruct "  %r = getelementptr %pair, ptr %p, i32 0, i32 1"
            assertBool
              ("expected the name kept in " <> show written)
              ("%pair" `T.isInfixOf` written)
        , -- Continuing past a named struct needs the field's type, which the
          -- definition supplies.
          testCase "a walk continues through a named struct" $ do
            steps <-
              stepsInModule namedStruct "  %r = getelementptr %pair, ptr %p, i32 0, i32 2, i64 %n"
            steps @?= [Select (TNamed (Name Bare "pair")) 2, Stride (TInteger 8)]
        ]
    , testGroup
        "what cannot be walked"
        [ -- Indexing into something with no elements is not a walk LLVM
          -- defines, and guessing would be worse than refusing.
          testCase "an index into a scalar refuses the definition" $
            retained "  %r = getelementptr i32, ptr %p, i64 %n, i64 %n"
        , -- A struct field has to be a constant to be an offset at all.
          testCase "a computed struct field refuses the definition" $
            retained "  %r = getelementptr {i32, i64}, ptr %p, i32 0, i32 %v"
        , -- A field the struct does not have.
          testCase "a field past the end refuses the definition" $
            retained "  %r = getelementptr {i32, i64}, ptr %p, i32 0, i32 7"
        , -- A named type nothing defines cannot be walked into.
          testCase "an unresolvable name refuses the definition" $
            retained "  %r = getelementptr %missing, ptr %p, i32 0, i32 1"
        ]
    , testGroup
        "the chain says what the line said"
        [ -- One instruction in, one out, with both indices on it.  Nothing
          -- here is about the spelling: the locals are renumbered and the
          -- struct is written the printer's way, so what is checked is that
          -- the chain did not grow a step and the field is still named.
          testCase "a struct field comes back as one instruction" $ do
            written <- renderedFrom noTypes "  %r = getelementptr {i32, i64}, ptr %p, i32 0, i32 1"
            assertEqual
              ("one getelementptr in " <> show written)
              1
              (T.count "getelementptr" written)
            assertBool
              ("expected both indices in " <> show written)
              (", i32 0, i32 1" `T.isInfixOf` written)
        , -- A second trip must find nothing left to do.  This is the check
          -- that raising a step produces something lowering reads as that
          -- same step, rather than as a longer chain each time.
          testCase "a second trip changes nothing" $ do
            let source = inFunction "  %r = getelementptr [4 x {i32, i64}], ptr %p, i64 %n, i64 3, i32 1"
            once <- roundTrip source
            twice <- roundTrip once
            twice @?= once
        ]
    ]

-- | A step, as much of it as these cases care about.
--
-- What is dropped is the pointer each one starts from, which is the local the
-- step before it assigned and says nothing a reader of these cases wants.
data Step
  = Stride Type
  | Select Type Natural
  deriving (Eq, Show)

-- | The steps one line lowers to, in order.
stepsIn :: Text -> IO [Step]
stepsIn = stepsInModule noTypes

stepsInModule :: [Text] -> Text -> IO [Step]
stepsInModule types line = do
  parsed <- expectParse "<inline>" (inModule types line)
  pure
    [ step
    | f <- functionsIn (lower parsed)
    , b <- functionBlocks f
    , i <- blockInstructions b
    , Just step <- [stepOf (instructionOperation i)]
    ]
  where
    stepOf (OOffset o) = Just (Stride (offsetElementType o))
    stepOf (OField f) = Just (Select (fieldStructType f) (fieldIndex f))
    stepOf _ = Nothing

-- | That a definition did not lower, which is how the lowering refuses a walk
-- it cannot read: the whole definition is retained as syntax.
retained :: Text -> Assertion
retained line = do
  parsed <- expectParse "<inline>" (inModule noTypes line)
  assertEqual "the definition is retained" [] (functionsIn (lower parsed))

renderedFrom :: [Text] -> Text -> IO Text
renderedFrom types line = roundTrip (inModule types line)

roundTrip :: Text -> IO Text
roundTrip source = do
  parsed <- expectParse "<inline>" source
  pure (renderModule (raise (lower parsed)))

noTypes :: [Text]
noTypes = []

namedStruct :: [Text]
namedStruct = ["%pair = type { i32, [4 x i8], [4 x i8] }", ""]

inModule :: [Text] -> Text -> Text
inModule types line = T.unlines types <> inFunction line

-- | The result is stored so that nothing removes the offset as dead.
inFunction :: Text -> Text
inFunction line =
  T.unlines
    [ "define void @f(ptr %p, i32 %v, i64 %n) {"
    , line
    , "  store ptr %r, ptr %p"
    , "  ret void"
    , "}"
    ]
