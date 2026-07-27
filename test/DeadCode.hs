-- | The dead code pass.
module DeadCode (deadCodeTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.DeadCode (eliminateDeadCode, removableWhenUnused)
import Olivine.Core.Program
import Olivine.Syntax.Instruction
import Olivine.Syntax.Name
import Olivine.Syntax.Type
import Olivine.Syntax.Value

deadCodeTests :: TestTree
deadCodeTests =
  testGroup
    "dead code"
    [ testCase "what survives the sift" $ do
        results <- resultsOf sifted
        assertEqual
          "only what is read or does something"
          [Just (Name Bare "noisy"), Nothing, Just (Name Bare "answer")]
          results
    , -- Removing one instruction leaves the one feeding it unread, so a
      -- single sweep is not enough.
      testCase "a chain of dead instructions goes entirely" $ do
        results <- resultsOf sifted
        assertBool
          ("expected no chain in " <> show results)
          (Just (Name Bare "chain") `notElem` results)
    , -- Stated as what should be there rather than by comparing the pass
      -- with itself, which would hold however much it removed.
      testCase "nothing is removed when everything is read" $ do
        results <- resultsOf live
        assertEqual
          "every instruction survives"
          [Just (Name Bare "sum"), Just (Name Bare "doubled")]
          results
    , testGroup
        "what may go when nothing reads it"
        [ testCase "arithmetic" $ removableWhenUnused (binary OpAdd) @?= True
        , -- Dividing by zero is undefined in LLVM rather than a fault to be
          -- kept, so an unread division is as dead as an unread addition.
          testCase "division" $ removableWhenUnused (binary OpSDiv) @?= True
        , testCase "a plain load" $ removableWhenUnused (load False) @?= True
        , -- A volatile load is a side effect that happens to return a value.
          testCase "a volatile load" $ removableWhenUnused (load True) @?= False
        , testCase "a store" $ removableWhenUnused store' @?= False
        , -- Nothing here can tell whether a call does anything, so none goes.
          testCase "a call" $ removableWhenUnused call' @?= False
        , testCase "a terminator" $ removableWhenUnused (ORet Nothing) @?= False
        , testCase "a branch" $ removableWhenUnused (OBr (Name Bare "b")) @?= False
        ]
    ]
  where
    binary op =
      OBinary
        Binary
          { binaryOp = op
          , binaryFlags = []
          , binaryType = TInteger 32
          , binaryLeft = VLocal (Name Bare "a")
          , binaryRight = VLocal (Name Bare "b")
          }
    load volatile =
      OLoad
        Load
          { loadVolatile = volatile
          , loadType = TInteger 32
          , loadPointer = TypedValue (TPointer Nothing) (VLocal (Name Bare "p"))
          , loadAlignment = Nothing
          }
    store' =
      OStore
        Store
          { storeVolatile = False
          , storeValue = TypedValue (TInteger 32) (VInteger 0)
          , storePointer = TypedValue (TPointer Nothing) (VLocal (Name Bare "p"))
          , storeAlignment = Nothing
          }
    call' =
      OCall
        Call
          { callTail = Nothing
          , callFlags = []
          , callCallingConvention = Nothing
          , callReturnAttributes = []
          , callAddrSpace = Nothing
          , callType = TVoid
          , callCallee = VGlobal (Name Bare "g")
          , callArguments = []
          , callAttributes = []
          }
    sifted =
      T.unlines
        [ "define i32 @f(i32 %a, i32 %b, ptr %p) {"
        , "entry:"
        , "  %unread = add i32 %a, %b"
        , "  %chain = mul i32 %unread, 3"
        , "  %quiet = load i32, ptr %p"
        , "  %noisy = load volatile i32, ptr %p"
        , "  %risky = sdiv i32 %a, %b"
        , "  %room = alloca i32, align 4"
        , "  store i32 %a, ptr %p, align 4"
        , "  %answer = add i32 %a, 1"
        , "  ret i32 %answer"
        , "}"
        ]
    live =
      T.unlines
        [ "define i32 @f(i32 %a, i32 %b) {"
        , "entry:"
        , "  %sum = add i32 %a, %b"
        , "  %doubled = mul i32 %sum, 2"
        , "  ret i32 %doubled"
        , "}"
        ]

-- | What each surviving instruction assigns to, in order.
resultsOf :: Text -> IO [Maybe Name]
resultsOf source = do
  parsed <- expectParse "<inline>" source
  let program = eliminateDeadCode (lower parsed)
  pure
    [ instructionResult i
    | f <- functionsIn program
    , b <- functionBlocks f
    , i <- blockInstructions b
    ]
