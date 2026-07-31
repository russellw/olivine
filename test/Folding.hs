-- | The folding pass.
--
-- Most of these are about where folding must stop.  Getting an answer wrong
-- is one kind of bug; inventing an answer where LLVM says the result is
-- poison is the other, and the harder one to notice.
module Folding (foldingTests) where

import Test.Tasty
import Test.Tasty.HUnit

import Olivine.Core.Instruction
import Olivine.Core.Pass.Fold (foldOperation, foldThrough)
import Olivine.Syntax.Instruction hiding (Operation (..))
import Olivine.Syntax.Name
import Olivine.Syntax.Type
import Olivine.Syntax.Value

foldingTests :: TestTree
foldingTests =
  testGroup
    "folding"
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
        , testCase "two arms holding one value need no condition" $
            folded
              ( OSelect
                  Select
                    { selectFlags = []
                    , selectCondition = TypedValue (TInteger 1) (VLocal (Name Bare "c"))
                    , selectTrue = local "x"
                    , selectFalse = local "x"
                    }
              )
              @?= Just (local "x")
        ]
    , testGroup
        "identities"
        [ testCase "adding nothing" $ identity OpAdd [] (local "x") (int 0) @?= Just (local "x")
        , testCase "the same from the left" $ identity OpAdd [] (int 0) (local "x") @?= Just (local "x")
        , testCase "subtracting nothing" $ identity OpSub [] (local "x") (int 0) @?= Just (local "x")
        , -- The other way round is a negation and not an identity at all.
          testCase "subtracting from nothing" $
            identity OpSub [] (int 0) (local "x") @?= Nothing
        , testCase "multiplying by one" $ identity OpMul [] (local "x") (int 1) @?= Just (local "x")
        , testCase "dividing by one" $ identity OpSDiv [] (local "x") (int 1) @?= Just (local "x")
        , testCase "shifting by nothing" $ identity OpShl [] (local "x") (int 0) @?= Just (local "x")
        , testCase "anding with all ones" $
            identity OpAnd [] (local "x") (int (-1)) @?= Just (local "x")
        , testCase "oring with nothing" $ identity OpOr [] (local "x") (int 0) @?= Just (local "x")
        , testCase "a value with itself" $
            identity OpAnd [] (local "x") (local "x") @?= Just (local "x")
        , testCase "the same, ored" $ identity OpOr [] (local "x") (local "x") @?= Just (local "x")
        , testCase "two different values are not one" $
            identity OpAnd [] (local "x") (local "y") @?= Nothing
        , -- All ones at a width of one is @true@, which is how the type says
          -- the number, so the same rule has to recognize it.
          testCase "all ones at a single bit" $
            folded
              ( OBinary
                  Binary
                    { binaryOp = OpAnd
                    , binaryFlags = []
                    , binaryLeft = TypedValue (TInteger 1) (VLocal (Name Bare "x"))
                    , binaryRight = TypedValue (TInteger 1) (VBoolean True)
                    }
              )
              @?= Just (TypedValue (TInteger 1) (VLocal (Name Bare "x")))
        ]
    , testGroup
        "identities that come to a constant"
        [ testCase "multiplying by nothing" $ identity OpMul [] (local "x") (int 0) @?= Just (int 0)
        , testCase "subtracting a value from itself" $
            identity OpSub [] (local "x") (local "x") @?= Just (int 0)
        , testCase "exclusive-oring a value with itself" $
            identity OpXor [] (local "x") (local "x") @?= Just (int 0)
        , testCase "the remainder of a division by one" $
            identity OpURem [] (local "x") (int 1) @?= Just (int 0)
        , testCase "oring with all ones" $
            identity OpOr [] (local "x") (int (-1)) @?= Just (int (-1))
        , -- Shifting nothing leaves nothing however far, and the amounts that
          -- would make it poison are among the amounts it leaves nothing at.
          testCase "shifting nothing by an unknown amount" $
            identity OpShl [] (int 0) (local "x") @?= Just (int 0)
        , testCase "shifting all ones right, keeping the sign" $
            identity OpAShr [] (int (-1)) (local "x") @?= Just (int (-1))
        , -- The flag says the operands share no bits, which two ones do; the
          -- operation is poison and the answer given is a value, which is the
          -- direction that is allowed.
          testCase "oring with all ones, marked disjoint" $
            identity OpOr [FlagDisjoint] (local "x") (int (-1)) @?= Just (int (-1))
        ]
    , testGroup
        "a value compared with itself"
        [ testCase "equal to itself" $ reflexive IEq @?= Just (bool True)
        , testCase "not equal to itself" $ reflexive INe @?= Just (bool False)
        , testCase "less than itself" $ reflexive ISlt @?= Just (bool False)
        , testCase "at least itself" $ reflexive IUge @?= Just (bool True)
        , -- A comparison of vectors is a vector of answers, and a single
          -- @true@ is not one.
          testCase "a vector compared with itself" $
            folded
              ( OICmp
                  Compare
                    { compareFlags = []
                    , comparePredicate = IEq
                    , compareLeft = vector
                    , compareRight = vector
                    }
              )
              @?= Nothing
        ]
    , testGroup
        "conversions of conversions"
        [ testCase "widened and cut back to the width it came from" $
            chained (cast CastZExt 1 8) (cast CastTrunc 8 1)
              @?= Just (OAssign (TypedValue (TInteger 1) (VLocal (Name Bare "x"))))
        , testCase "cut back past it, so what is left is the cut" $
            chained (cast CastZExt 32 64) (cast CastTrunc 64 16)
              @?= Just (converted CastTrunc 32 16)
        , testCase "cut back short of it, so what is left is the extension" $
            chained (cast CastSExt 1 32) (cast CastTrunc 32 16)
              @?= Just (converted CastSExt 1 16)
        , testCase "two extensions the same way are one" $
            chained (cast CastZExt 8 16) (cast CastZExt 16 32)
              @?= Just (converted CastZExt 8 32)
        , testCase "two cuts are one" $
            chained (cast CastTrunc 64 32) (cast CastTrunc 32 8)
              @?= Just (converted CastTrunc 64 8)
        , -- A zero extension leaves the top bit of what it produced clear, so
          -- sign extending it copies a zero.
          testCase "a zero extension sign extended" $
            chained (cast CastZExt 8 16) (cast CastSExt 16 32)
              @?= Just (converted CastZExt 8 32)
        , -- And not the other way about: the sign extension may have set the
          -- top bit, and the zero extension keeps it where it is.
          testCase "a sign extension zero extended" $
            chained (cast CastSExt 8 16) (cast CastZExt 16 32) @?= Nothing
        , testCase "cut down and zeroed back where it came from is a mask" $
            chained (cast CastTrunc 32 8) (cast CastZExt 8 32)
              @?= Just
                ( OBinary
                    Binary
                      { binaryOp = OpAnd
                      , binaryFlags = []
                      , binaryLeft = TypedValue (TInteger 32) (VLocal (Name Bare "x"))
                      , binaryRight = TypedValue (TInteger 32) (VInteger 255)
                      }
                )
        , testCase "and not to any other width, which leaves both" $
            chained (cast CastTrunc 32 8) (cast CastZExt 8 64) @?= Nothing
        , -- Promotion writes an assignment between the two wherever the value
          -- travelled through a slot, which is most of the time.
          testCase "through the copy a promoted slot leaves" $
            foldThrough
              ( \name -> case name of
                  Name Bare "c" -> Just (OAssign (TypedValue (TInteger 8) (VLocal (Name Bare "w"))))
                  Name Bare "w" -> Just (OConvert (cast CastZExt 1 8))
                  _ -> Nothing
              )
              ( OConvert
                  (cast CastTrunc 8 1) {convertOperand = TypedValue (TInteger 8) (VLocal (Name Bare "c"))}
              )
              @?= Just (OAssign (TypedValue (TInteger 1) (VLocal (Name Bare "x"))))
        , testCase "nothing known about the operand" $
            foldThrough
              (const Nothing)
              (OConvert (cast CastTrunc 8 1) {convertOperand = TypedValue (TInteger 8) (VLocal (Name Bare "w"))})
              @?= Nothing
        ]
    , testGroup
        "a mask between two conversions"
        [ -- What a C bit field read comes to once the slot it was in is gone.
          testCase "cut down, masked, and zeroed back where it came from" $
            combining CastZExt OpAnd 32 16 32 (cut 16) (narrow 16 7) @?= Just (masking 7)
        , -- The bits above the narrow width are the ones the chain cleared, and
          -- a constant written negative at that width has them set.
          testCase "the mask read unsigned at the width it was written at" $
            combining CastZExt OpAnd 32 16 32 (cut 16) (narrow 16 (-9))
              @?= Just (masking 65527)
        , testCase "the mask written first" $
            combining CastZExt OpAnd 32 16 32 (narrow 16 7) (cut 16) @?= Just (masking 7)
        , testCase "a mask that is not a constant" $
            combining CastZExt OpAnd 32 16 32 (cut 16) (TypedValue (TInteger 16) (VLocal (Name Bare "y")))
              @?= Nothing
        , -- Back to any other width leaves a conversion standing beside the
          -- mask, which is no fewer instructions than there were.
          testCase "zeroed back past the width it came from" $
            combining CastZExt OpAnd 32 16 64 (cut 16) (narrow 16 7) @?= Nothing
        , -- The bits the cut took away come back set from the constant rather
          -- than staying away, so the cut still has to happen.
          testCase "a mask that sets bits rather than clearing them" $
            combining CastZExt OpOr 32 16 32 (cut 16) (narrow 16 7) @?= Nothing
        , -- Whether the top bits come back set depends on the value, not on
          -- the widths, so there is no one mask that says it.
          testCase "sign extended rather than zeroed" $
            combining CastSExt OpAnd 32 16 32 (cut 16) (narrow 16 7) @?= Nothing
        ]
    , testGroup
        "two operands that are copies of one local"
        [ -- What @b - b@ comes to once the slot holding @b@ is promoted: two
          -- loads of one slot are two copies of one local, and two copies are
          -- two locals however plainly the source said they were one value.
          testCase "a subtraction of a value from itself" $
            copies (OBinary (over OpSub "p" "q")) @?= Just (OAssign (int 0))
        , testCase "an and of a value with itself" $
            copies (OBinary (over OpAnd "p" "q")) @?= Just (OAssign (local "p"))
        , testCase "an equality between a value and itself" $
            copies (OICmp (compared IEq "p" "q")) @?= Just (OAssign (bool True))
        , -- One a copy of the local and one a copy of something else.
          testCase "operands that are copies of different locals" $
            copies (OBinary (over OpSub "p" "r")) @?= Nothing
        , -- The rule is for what settles an operation and not for respelling an
          -- operand: nothing about @p + q@ follows from the two being one
          -- value, so it is left as it stands.
          testCase "an operation knowing they are one value does not settle" $
            copies (OBinary (over OpAdd "p" "q")) @?= Nothing
        , testCase "nothing known about either operand" $
            copies (OBinary (over OpSub "s" "t")) @?= Nothing
        ]
    ]
  where
    int n = TypedValue (TInteger 32) (VInteger n)
    bool b = TypedValue (TInteger 1) (VBoolean b)
    local name = TypedValue (TInteger 32) (VLocal (Name Bare name))
    vector = TypedValue (TVector FixedWidth 4 (TInteger 32)) (VLocal (Name Bare "v"))
    identity op flags left right =
      folded (OBinary Binary {binaryOp = op, binaryFlags = flags, binaryLeft = left, binaryRight = right})
    reflexive predicate =
      folded
        ( OICmp
            Compare
              { compareFlags = []
              , comparePredicate = predicate
              , compareLeft = local "x"
              , compareRight = local "x"
              }
        )
    -- An operation over two locals, asked where @%p@ and @%q@ are copies of
    -- @%b@ and @%r@ is a copy of something else.  @%s@ and @%t@ are locals
    -- nothing is known about.
    copies =
      foldThrough
        ( \name -> case name of
            Name Bare "p" -> Just (OAssign (local "b"))
            Name Bare "q" -> Just (OAssign (local "b"))
            Name Bare "r" -> Just (OAssign (local "c"))
            _ -> Nothing
        )
    over op left right =
      Binary
        { binaryOp = op
        , binaryFlags = []
        , binaryLeft = local left
        , binaryRight = local right
        }
    compared predicate left right =
      Compare
        { compareFlags = []
        , comparePredicate = predicate
        , compareLeft = local left
        , compareRight = local right
        }
    -- A conversion from one width to another, over @%x@.
    cast op from to =
      Convert
        { convertOp = op
        , convertFlags = []
        , convertOperand = TypedValue (TInteger from) (VLocal (Name Bare "x"))
        , convertTarget = TInteger to
        }
    -- The inner conversion left in @%w@, and the outer one reading it.
    chained inner outer =
      foldThrough
        (\name -> if name == Name Bare "w" then Just (OConvert inner) else Nothing)
        (OConvert outer {convertOperand = TypedValue (convertTarget inner) (VLocal (Name Bare "w"))})
    converted op from to =
      OConvert (cast op from to) {convertOperand = TypedValue (TInteger from) (VLocal (Name Bare "x"))}
    -- The cut left in @%w@, and a constant at the width it was cut to.
    cut middle = TypedValue (TInteger middle) (VLocal (Name Bare "w"))
    narrow middle n = TypedValue (TInteger middle) (VInteger n)
    -- @%x@ cut from @from@ down to @middle@ in @%w@, an operation over that in
    -- @%m@, and @%m@ widened to @to@ by the conversion asked about.
    combining widening op from middle to left right =
      foldThrough
        ( \name -> case name of
            Name Bare "w" -> Just (OConvert (cast CastTrunc from middle))
            Name Bare "m" ->
              Just
                ( OBinary
                    Binary
                      { binaryOp = op
                      , binaryFlags = []
                      , binaryLeft = left
                      , binaryRight = right
                      }
                )
            _ -> Nothing
        )
        ( OConvert
            (cast widening middle to)
              {convertOperand = TypedValue (TInteger middle) (VLocal (Name Bare "m"))}
        )
    -- What the whole chain comes to: @%x@ at the width it started at, masked.
    masking n =
      OBinary
        Binary
          { binaryOp = OpAnd
          , binaryFlags = []
          , binaryLeft = TypedValue (TInteger 32) (VLocal (Name Bare "x"))
          , binaryRight = TypedValue (TInteger 32) (VInteger n)
          }
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
