-- | The constant folding pass.
--
-- Most of these are about where folding must stop.  Getting an answer wrong
-- is one kind of bug; inventing an answer where LLVM says the result is
-- poison is the other, and the harder one to notice.
module Folding (foldingTests) where

import Test.Tasty
import Test.Tasty.HUnit

import Olivine.Core.Instruction
import Olivine.Core.Pass.ConstantFold (foldOperation)
import Olivine.Syntax.Instruction hiding (Operation (..))
import Olivine.Syntax.Name
import Olivine.Syntax.Type
import Olivine.Syntax.Value

foldingTests :: TestTree
foldingTests =
  testGroup
    "constant folding"
    [ testGroup
        "arithmetic"
        [ testCase "add" $ binary OpAdd [] 20 22 @?= Just (int 42)
        , testCase "sub" $ binary OpSub [] 20 22 @?= Just (int (-2))
        , testCase "mul" $ binary OpMul [] 6 7 @?= Just (int 42)
        , testCase "signed division truncates toward zero" $
            binary OpSDiv [] (-7) 2 @?= Just (int (-3))
        , testCase "signed remainder takes the sign of the dividend" $
            binary OpSRem [] (-7) 2 @?= Just (int (-1))
        , -- The operands are the same bits; the operation decides how to read
          -- them, which is the whole reason both exist.
          testCase "unsigned division reads the same bits differently" $
            binary OpUDiv [] (-1) 2 @?= Just (int 2147483647)
        , testCase "wrapping is defined when nothing forbids it" $
            binary OpMul [] 65536 65536 @?= Just (int 0)
        ]
    , testGroup
        "bitwise"
        [ testCase "and" $ binary OpAnd [] 60 13 @?= Just (int 12)
        , testCase "or" $ binary OpOr [] 12 128 @?= Just (int 140)
        , testCase "xor" $ binary OpXor [] 140 255 @?= Just (int 115)
        , testCase "shift left" $ binary OpShl [] 115 2 @?= Just (int 460)
        , testCase "arithmetic shift right keeps the sign" $
            binary OpAShr [] (-8) 1 @?= Just (int (-4))
        , testCase "logical shift right does not" $
            binary OpLShr [] (-8) 1 @?= Just (int 2147483644)
        ]
    , testGroup
        "where it must stop"
        [ testCase "division by zero" $ binary OpSDiv [] 1 0 @?= Nothing
        , testCase "unsigned division by zero" $ binary OpUDiv [] 1 0 @?= Nothing
        , testCase "remainder by zero" $ binary OpSRem [] 1 0 @?= Nothing
        , -- The one signed division that overflows.
          testCase "the most negative divided by minus one" $
            binary OpSDiv [] (-2147483648) (-1) @?= Nothing
        , testCase "shifting by the width" $ binary OpShl [] 1 32 @?= Nothing
        , testCase "shifting by more than the width" $ binary OpLShr [] 1 33 @?= Nothing
        , testCase "shifting by a negative amount" $ binary OpShl [] 1 (-1) @?= Nothing
        , -- A flag promising no overflow is a promise about the program, and
          -- a broken promise gives poison rather than a wrapped answer.
          testCase "signed overflow that nsw said would not happen" $
            binary OpAdd [FlagNSW] 2147483647 1 @?= Nothing
        , testCase "unsigned overflow that nuw said would not happen" $
            binary OpAdd [FlagNUW] (-1) 1 @?= Nothing
        , testCase "the same addition without the flag wraps" $
            binary OpAdd [] 2147483647 1 @?= Just (int (-2147483648))
        , testCase "an inexact division marked exact" $
            binary OpSDiv [FlagExact] 7 2 @?= Nothing
        , testCase "an exact one marked exact" $
            binary OpSDiv [FlagExact] 8 2 @?= Just (int 4)
        , testCase "an or whose operands share bits, marked disjoint" $
            binary OpOr [FlagDisjoint] 12 10 @?= Nothing
        , testCase "one whose operands do not" $
            binary OpOr [FlagDisjoint] 12 128 @?= Just (int 140)
        , -- Float literals are held as written so that nothing rounds them;
          -- folding one would have to decode and re-encode.
          testCase "floating point is not folded" $
            folded
              ( OBinary
                  Binary
                    { binaryOp = OpFAdd
                    , binaryFlags = []
                    , binaryLeft = TypedValue (TFloat FDouble) (VFloat "1.000000e+00")
                    , binaryRight = TypedValue (TFloat FDouble) (VFloat "2.000000e+00")
                    }
              )
              @?= Nothing
        , testCase "an operand that is not known" $
            folded
              ( OBinary
                  Binary
                    { binaryOp = OpAdd
                    , binaryFlags = []
                    , binaryLeft = TypedValue (TInteger 32) (VLocal (Name Bare "x"))
                    , binaryRight = TypedValue (TInteger 32) (VInteger 1)
                    }
              )
              @?= Nothing
        ]
    , testGroup
        "comparisons"
        [ testCase "signed less than" $ icmp ISlt (-1) 0 @?= Just (bool True)
        , testCase "unsigned less than reads the same bits differently" $
            icmp IUlt (-1) 0 @?= Just (bool False)
        , testCase "equality" $ icmp IEq 3 3 @?= Just (bool True)
        ]
    , testGroup
        "conversions"
        [ testCase "truncating" $ convert CastTrunc 32 300 8 @?= Just (TypedValue (TInteger 8) (VInteger 44))
        , testCase "widening with the sign" $
            convert CastSExt 8 (-1) 32 @?= Just (TypedValue (TInteger 32) (VInteger (-1)))
        , testCase "widening without it" $
            convert CastZExt 8 (-1) 32 @?= Just (TypedValue (TInteger 32) (VInteger 255))
        ]
    , testGroup
        "select"
        [ testCase "a known condition chooses" $
            folded
              ( OSelect
                  Select
                    { selectFlags = []
                    , selectCondition = TypedValue (TInteger 1) (VBoolean True)
                    , selectTrue = TypedValue (TInteger 32) (VInteger 111)
                    , selectFalse = TypedValue (TInteger 32) (VInteger 222)
                    }
              )
              @?= Just (TypedValue (TInteger 32) (VInteger 111))
        , testCase "an unknown one does not" $
            folded
              ( OSelect
                  Select
                    { selectFlags = []
                    , selectCondition = TypedValue (TInteger 1) (VLocal (Name Bare "c"))
                    , selectTrue = TypedValue (TInteger 32) (VInteger 111)
                    , selectFalse = TypedValue (TInteger 32) (VInteger 222)
                    }
              )
              @?= Nothing
        ]
    ]
  where
    int n = TypedValue (TInteger 32) (VInteger n)
    bool b = TypedValue (TInteger 1) (VBoolean b)
    binary op flags left right =
      folded
        ( OBinary
            Binary
              { binaryOp = op
              , binaryFlags = flags
              , binaryLeft = int left
              , binaryRight = int right
              }
        )
    icmp predicate left right =
      folded
        ( OICmp
            Compare
              { compareFlags = []
              , comparePredicate = predicate
              , compareLeft = int left
              , compareRight = int right
              }
        )
    convert op from value to =
      folded
        ( OConvert
            Convert
              { convertOp = op
              , convertFlags = []
              , convertOperand = TypedValue (TInteger from) (VInteger value)
              , convertTarget = TInteger to
              }
        )

-- | 'foldOperation' at the names the syntax layer uses, which is what these
-- cases build.
--
-- Folding does not care what a local is called — it works on the constants —
-- so the pass is written for any, and every case here would otherwise have to
-- say which it meant.
folded :: Operation (TypedValue Name) -> Maybe (TypedValue Name)
folded = foldOperation
