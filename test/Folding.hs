-- | The folding pass.
--
-- Most of these are about where folding must stop.  Getting an answer wrong
-- is one kind of bug; inventing an answer where LLVM says the result is
-- poison is the other, and the harder one to notice.
module Folding (foldingTests) where

import Data.Text qualified as Text
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
    , testGroup
        "an operation on vectors, lane by lane"
        [ testCase "two vectors written out" $
            lanes OpAdd [] (vectorOf [1, 2, 3, 4]) (vectorOf [10, 20, 30, 40])
              @?= Just (vectorOf [11, 22, 33, 44])
        , testCase "a splat is the same value in every lane" $
            lanes OpAdd [] (splat 3) (vectorOf [1, 2, 3, 4]) @?= Just (vectorOf [4, 5, 6, 7])
        , -- And back out the same way: LLVM prints @splat (i32 0)@ as
          -- @zeroinitializer@, so that is what an answer of nothing in every
          -- lane is written as.
          testCase "zeroinitializer is a splat of nothing" $
            lanes OpMul [] zeroes (vectorOf [1, 2, 3, 4])
              @?= Just (TypedValue vectorType VZeroInitializer)
        , -- LLVM prints @\<i32 15, i32 15\>@ back as @splat (i32 15)@, so the
          -- long form would be text that does not survive a round trip.
          testCase "one answer in every lane is written as a splat" $
            lanes OpMul [] (splat 3) (splat 5) @?= Just (splat 15)
        , -- One lane is enough: the flag is a promise about the operation, and
          -- the operation is the one that has a lane where it does not hold.
          testCase "a lane that overflows a flag leaves the operation standing" $
            lanes OpAdd [FlagNSW] (splat 2147483647) (vectorOf [0, 0, 0, 1]) @?= Nothing
        , testCase "a vector of the wrong length" $
            lanes OpAdd [] (vectorOf [1, 2, 3]) (vectorOf [1, 2, 3]) @?= Nothing
        , -- How many lanes it has is not written down, so writing them out is
          -- not possible and one answer for all of them is the only answer.
          testCase "a scalable vector of splats" $
            scalable OpAdd (splatOf scalableVector 3) (splatOf scalableVector 5)
              @?= Just (splatOf scalableVector 8)
        ]
    , testGroup
        "a sum of two multiples of one value"
        [ testCase "two multiplications by constants" $
            summed (multiplying "x" 3) (multiplying "x" 5) @?= Just (multiplied (local "x") 8)
        , testCase "the constants written on the left" $
            summed (multiplying' "x" 3) (multiplying' "x" 5) @?= Just (multiplied (local "x") 8)
        , -- The two multiples are one instruction read twice, which the rule
          -- reads as a multiple twice over.
          testCase "one multiplication read as both operands" $
            doubled (multiplying "x" 3) @?= Just (multiplied (local "x") 6)
        , -- The sum wraps where neither multiplication did, so what the flags
          -- promised is not promised again.
          testCase "the flags are not carried over" $
            summed (multiplying "x" 3) {binaryFlags = [FlagNSW]} (multiplying "x" 5) {binaryFlags = [FlagNSW]}
              @?= Just (multiplied (local "x") 8)
        , -- Promotion is why this is not equality: a value that went through
          -- a slot reaches the two multiplications as two copies of one local.
          testCase "multiples reached through the copies of one local" $
            summed (multiplying "p" 3) (multiplying "q" 5) @?= Just (multiplied (local "p") 8)
        , testCase "multiples of two different values" $
            summed (multiplying "x" 3) (multiplying "y" 5) @?= Nothing
        , testCase "a multiplication by something unknown" $
            summed (multiplying "x" 3) (multiplying' "x" 5) {binaryLeft = local "n"} @?= Nothing
        , -- What the corpus has: an unrolled loop whose stores were forwarded
          -- to its loads leaves the sum of what each turn computed.
          testCase "multiples of a vector" $
            summed
              (Binary OpMul [] (vectorLocal "x") (vectorOf [0, 1, 2, 3]))
              (Binary OpMul [] (vectorLocal "x") (vectorOf [4, 5, 6, 7]))
              @?= Just (OBinary (Binary OpMul [] (vectorLocal "x") (vectorOf [4, 6, 8, 10])))
        ]
    , testGroup
        "an aggregate taken apart and put back together"
        [ -- What a landing pad costs: the pair is unpacked to test the
          -- selector and packed again to be resumed with.
          testCase "every field written from the aggregate it came from" $
            aggregate (rebuilt [(0, "a"), (1, "b")] VPoison) @?= Just (OAssign pair)
        , testCase "built on undef rather than poison" $
            aggregate (rebuilt [(0, "a"), (1, "b")] VUndef) @?= Just (OAssign pair)
        , -- Writing field 0 says nothing about field 1, so the aggregate
          -- assembled is not the one the field came from.
          testCase "a field left unwritten" $
            aggregate (rebuilt [(0, "a")] VPoison) @?= Nothing
        , -- The fields are one another's, so the pair is the pair reversed.
          testCase "the fields put back in the wrong places" $
            aggregate (rebuilt [(0, "b"), (1, "a")] VPoison) @?= Nothing
        , testCase "fields taken from two aggregates" $
            aggregate (rebuilt [(0, "a"), (1, "d")] VPoison) @?= Nothing
        , -- Whatever the base held stands wherever the chain did not write,
          -- and a chain covering every field never asks what that was.
          testCase "built on an aggregate rather than on nothing" $
            aggregate (rebuilt [(0, "a"), (1, "b")] (VLocal (Name Bare "p"))) @?= Nothing
        ]
    , testGroup
        "a field read out of an aggregate it was written into"
        [ testCase "read where it was written" $
            aggregate (readingAt [1] (writtenAt [1])) @?= Just (OAssign (int 7))
        , -- The write went somewhere else entirely, so the read goes past it
          -- to the aggregate that was written into.
          testCase "read somewhere the write did not reach" $
            aggregate (readingAt [0] (writtenAt [1]))
              @?= Just (OExtractValue (ExtractValue pair [0]))
        , -- The read wants part of what was written, and what part of a
          -- written field holds is not settled by knowing the field.
          testCase "read inside what was written" $
            aggregate (readingAt [1, 0] (writtenAt [1])) @?= Nothing
        , -- And the other way about: the write settled part of what is read.
          testCase "written inside what is read" $
            aggregate (readingAt [1] (writtenAt [1, 0])) @?= Nothing
        ]
    ]
  where
    int n = TypedValue (TInteger 32) (VInteger n)
    vectorType = TVector FixedWidth 4 (TInteger 32)
    vectorOf ns = TypedValue vectorType (VVector [int n | n <- ns])
    splat n = splatOf vectorType n
    splatOf t n = TypedValue t (VSplat (int n))
    zeroes = TypedValue vectorType VZeroInitializer
    vectorLocal name = TypedValue vectorType (VLocal (Name Bare name))
    scalableVector = TVector Scalable 4 (TInteger 32)

    lanes op flags left right =
      folded (OBinary Binary {binaryOp = op, binaryFlags = flags, binaryLeft = left, binaryRight = right})
    scalable op left right = lanes op [] left right

    -- A multiplication of a local by a constant, and the same written the
    -- other way about.
    multiplying name n = Binary OpMul [] (local name) (int n)
    multiplying' name n = Binary OpMul [] (int n) (local name)
    multiplied value n = OBinary (Binary OpMul [] value (int n))

    -- The two multiplications left in @%a@ and @%b@, added.
    summed left right =
      foldThrough
        ( \name -> case name of
            Name Bare "a" -> Just (OBinary left)
            Name Bare "b" -> Just (OBinary right)
            -- @%p@ and @%q@ are copies of one local, which is what a value
            -- that passed through a slot arrives as.
            Name Bare "p" -> Just (OAssign (local "c"))
            Name Bare "q" -> Just (OAssign (local "c"))
            _ -> Nothing
        )
        (OBinary (Binary OpAdd [] (local "a") (local "b")))
    doubled only =
      foldThrough
        ( \name -> case name of
            Name Bare "a" -> Just (OBinary only)
            _ -> Nothing
        )
        (OBinary (Binary OpAdd [] (local "a") (local "a")))
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
    -- The pair a landing pad leaves, and a second one to take a field from.
    pairType = TStruct Unpacked [TPointer Nothing, TInteger 32]
    pair = TypedValue pairType (VLocal (Name Bare "p"))
    other = TypedValue pairType (VLocal (Name Bare "o"))

    -- @%a@ and @%b@ are the fields of @%p@ read out of it, and @%d@ is the
    -- second field of the other pair.
    taken =
      [ (Name Bare "a", OExtractValue (ExtractValue pair [0]))
      , (Name Bare "b", OExtractValue (ExtractValue pair [1]))
      , (Name Bare "d", OExtractValue (ExtractValue other [1]))
      ]
    fieldValue name = TypedValue (typeOf name) (VLocal (Name Bare name))
      where
        typeOf "a" = TPointer Nothing
        typeOf _ = TInteger 32

    -- The operation asked about, against what the chain leading to it left in
    -- each of the locals it reads.
    aggregate (links, operation) = foldThrough (`lookup` (taken <> links)) operation

    -- A chain of inserts writing the named fields into @base@, each link left
    -- in a local of its own so that the walk has to follow them, and the
    -- outermost one the operation to ask about.
    rebuilt fields base = (zip names (init operations), last operations)
      where
        names = [Name Bare ("i" <> Text.pack (show (k :: Int))) | k <- [0 .. length fields - 1]]
        operations =
          [ OInsertValue
              InsertValue
                { insertValueAggregate = written k
                , insertValueValue = fieldValue name
                , insertValueIndices = [index]
                }
          | (k, (index, name)) <- zip [0 ..] fields
          ]
        written 0 = TypedValue pairType base
        written k = TypedValue pairType (VLocal (names !! (k - 1)))

    -- A write of @7@ into the pair at a path, left in @%i@.
    writtenAt path =
      OInsertValue
        InsertValue
          { insertValueAggregate = pair
          , insertValueValue = int 7
          , insertValueIndices = path
          }
    readingAt path written =
      ( [(Name Bare "i", written)]
      , OExtractValue (ExtractValue (TypedValue pairType (VLocal (Name Bare "i"))) path)
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
