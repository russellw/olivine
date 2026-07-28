-- | The arithmetic, comparison and conversion instructions.
--
-- LangRef's binary, bitwise binary and floating point operations, plus
-- @fneg@, @icmp@, @fcmp@, and the conversions.
--
-- As in "Memory", values are named rather than numbered: LLVM numbers unnamed
-- values densely and counts the entry block among them, so a numbered line is
-- only valid at one position in one function.
module Arithmetic (arithmeticTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Function
import Olivine.Syntax.Instruction
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type
import Olivine.Syntax.Value

-- | Lines in the spelling LLVM emits, with what each should parse to.
emitted :: [(Text, Operation Name)]
emitted =
  [ ("  %r = add i32 %a, %b", binary OpAdd [] (TInteger 32))
  , ("  %r = sub i32 %a, %b", binary OpSub [] (TInteger 32))
  , ("  %r = mul i32 %a, %b", binary OpMul [] (TInteger 32))
  , ("  %r = udiv i32 %a, %b", binary OpUDiv [] (TInteger 32))
  , ("  %r = sdiv i32 %a, %b", binary OpSDiv [] (TInteger 32))
  , ("  %r = urem i32 %a, %b", binary OpURem [] (TInteger 32))
  , ("  %r = srem i32 %a, %b", binary OpSRem [] (TInteger 32))
  , ("  %r = shl i32 %a, %b", binary OpShl [] (TInteger 32))
  , ("  %r = lshr i32 %a, %b", binary OpLShr [] (TInteger 32))
  , ("  %r = ashr i32 %a, %b", binary OpAShr [] (TInteger 32))
  , ("  %r = and i32 %a, %b", binary OpAnd [] (TInteger 32))
  , ("  %r = or i32 %a, %b", binary OpOr [] (TInteger 32))
  , ("  %r = xor i32 %a, %b", binary OpXor [] (TInteger 32))
  , -- The wrapping flags, in the order LLVM writes them.
    ("  %r = add nsw i32 %a, %b", binary OpAdd [FlagNSW] (TInteger 32))
  , ("  %r = add nuw i32 %a, %b", binary OpAdd [FlagNUW] (TInteger 32))
  , ("  %r = add nuw nsw i32 %a, %b", binary OpAdd [FlagNUW, FlagNSW] (TInteger 32))
  , ("  %r = sub nsw i32 %a, %b", binary OpSub [FlagNSW] (TInteger 32))
  , ("  %r = mul nuw nsw i32 %a, %b", binary OpMul [FlagNUW, FlagNSW] (TInteger 32))
  , ("  %r = shl nuw i32 %a, %b", binary OpShl [FlagNUW] (TInteger 32))
  , ("  %r = sdiv exact i32 %a, %b", binary OpSDiv [FlagExact] (TInteger 32))
  , ("  %r = lshr exact i32 %a, %b", binary OpLShr [FlagExact] (TInteger 32))
  , ("  %r = or disjoint i32 %a, %b", binary OpOr [FlagDisjoint] (TInteger 32))
  , -- Vectors work through the same rule as scalars.
    ( "  %r = add nsw <4 x i32> %va, %vb"
    , OBinary
        Binary
          { binaryOp = OpAdd
          , binaryFlags = [FlagNSW]
          , binaryType = TVector FixedWidth 4 (TInteger 32)
          , binaryLeft = VLocal (Name Bare "va")
          , binaryRight = VLocal (Name Bare "vb")
          }
    )
  , -- Floating point, and its fast-math flags.
    ("  %r = fadd double %d, %e", binary OpFAdd [] (TFloat FDouble))
  , ("  %r = fsub double %d, %e", binary OpFSub [] (TFloat FDouble))
  , ("  %r = fmul double %d, %e", binary OpFMul [] (TFloat FDouble))
  , ("  %r = fdiv double %d, %e", binary OpFDiv [] (TFloat FDouble))
  , ("  %r = frem double %d, %e", binary OpFRem [] (TFloat FDouble))
  , ("  %r = fadd fast double %d, %e", binary OpFAdd [FlagFast] (TFloat FDouble))
  , ( "  %r = fadd nnan ninf double %d, %e"
    , binary OpFAdd [FlagNNaN, FlagNInf] (TFloat FDouble)
    )
  , ( "  %r = fmul reassoc contract double %d, %e"
    , binary OpFMul [FlagReassoc, FlagContract] (TFloat FDouble)
    )
  , -- The one unary arithmetic operation.
    ( "  %r = fneg double %d"
    , OUnary
        Unary
          { unaryOp = OpFNeg
          , unaryFlags = []
          , unaryType = TFloat FDouble
          , unaryOperand = VLocal (Name Bare "d")
          }
    )
  , ( "  %r = fneg fast double %d"
    , OUnary
        Unary
          { unaryOp = OpFNeg
          , unaryFlags = [FlagFast]
          , unaryType = TFloat FDouble
          , unaryOperand = VLocal (Name Bare "d")
          }
    )
  , -- Integer comparisons, over the whole predicate set.
    ("  %r = icmp eq i32 %a, %b", icmp [] IEq (TInteger 32))
  , ("  %r = icmp ne i32 %a, %b", icmp [] INe (TInteger 32))
  , ("  %r = icmp ugt i32 %a, %b", icmp [] IUgt (TInteger 32))
  , ("  %r = icmp uge i32 %a, %b", icmp [] IUge (TInteger 32))
  , ("  %r = icmp ult i32 %a, %b", icmp [] IUlt (TInteger 32))
  , ("  %r = icmp ule i32 %a, %b", icmp [] IUle (TInteger 32))
  , ("  %r = icmp sgt i32 %a, %b", icmp [] ISgt (TInteger 32))
  , ("  %r = icmp sge i32 %a, %b", icmp [] ISge (TInteger 32))
  , ("  %r = icmp slt i32 %a, %b", icmp [] ISlt (TInteger 32))
  , ("  %r = icmp sle i32 %a, %b", icmp [] ISle (TInteger 32))
  , ("  %r = icmp samesign ugt i32 %a, %b", icmp [FlagSameSign] IUgt (TInteger 32))
  , -- Pointers compare too, which is why the type is not assumed integer.
    ( "  %r = icmp eq ptr %p, %q"
    , OICmp
        Compare
          { compareFlags = []
          , comparePredicate = IEq
          , compareType = TPointer Nothing
          , compareLeft = VLocal (Name Bare "p")
          , compareRight = VLocal (Name Bare "q")
          }
    )
  , -- Floating point comparisons, over the whole predicate set.
    ("  %r = fcmp false double %d, %e", fcmp [] FFalse)
  , ("  %r = fcmp oeq double %d, %e", fcmp [] FOeq)
  , ("  %r = fcmp ogt double %d, %e", fcmp [] FOgt)
  , ("  %r = fcmp oge double %d, %e", fcmp [] FOge)
  , ("  %r = fcmp olt double %d, %e", fcmp [] FOlt)
  , ("  %r = fcmp ole double %d, %e", fcmp [] FOle)
  , ("  %r = fcmp one double %d, %e", fcmp [] FOne)
  , ("  %r = fcmp ord double %d, %e", fcmp [] FOrd)
  , ("  %r = fcmp ueq double %d, %e", fcmp [] FUeq)
  , ("  %r = fcmp ugt double %d, %e", fcmp [] FUgt)
  , ("  %r = fcmp uge double %d, %e", fcmp [] FUge)
  , ("  %r = fcmp ult double %d, %e", fcmp [] FUlt)
  , ("  %r = fcmp ule double %d, %e", fcmp [] FUle)
  , ("  %r = fcmp une double %d, %e", fcmp [] FUne)
  , ("  %r = fcmp uno double %d, %e", fcmp [] FUno)
  , ("  %r = fcmp true double %d, %e", fcmp [] FTrue)
  , ("  %r = fcmp fast olt double %d, %e", fcmp [FlagFast] FOlt)
  , -- The conversions, every opcode LLVM 21 has.  There is no ptrtoaddr:
    -- it does not exist in this release.
    ("  %r = trunc i64 %w to i32", convert CastTrunc [] (TInteger 64) "w" (TInteger 32))
  , ("  %r = trunc nuw i64 %w to i32", convert CastTrunc [FlagNUW] (TInteger 64) "w" (TInteger 32))
  , ( "  %r = trunc nuw nsw i64 %w to i32"
    , convert CastTrunc [FlagNUW, FlagNSW] (TInteger 64) "w" (TInteger 32)
    )
  , ("  %r = zext i32 %a to i64", convert CastZExt [] (TInteger 32) "a" (TInteger 64))
  , -- The flag the corpus already carries.
    ("  %r = zext nneg i32 %a to i64", convert CastZExt [FlagNNeg] (TInteger 32) "a" (TInteger 64))
  , ("  %r = sext i32 %a to i64", convert CastSExt [] (TInteger 32) "a" (TInteger 64))
  , ("  %r = fptrunc double %d to float", convert CastFPTrunc [] (TFloat FDouble) "d" (TFloat FFloat))
  , ("  %r = fpext float %s to double", convert CastFPExt [] (TFloat FFloat) "s" (TFloat FDouble))
  , ("  %r = fptoui double %d to i32", convert CastFPToUI [] (TFloat FDouble) "d" (TInteger 32))
  , ("  %r = fptosi double %d to i32", convert CastFPToSI [] (TFloat FDouble) "d" (TInteger 32))
  , ("  %r = uitofp i32 %a to double", convert CastUIToFP [] (TInteger 32) "a" (TFloat FDouble))
  , ("  %r = uitofp nneg i32 %a to double", convert CastUIToFP [FlagNNeg] (TInteger 32) "a" (TFloat FDouble))
  , ("  %r = sitofp i32 %a to double", convert CastSIToFP [] (TInteger 32) "a" (TFloat FDouble))
  , ("  %r = ptrtoint ptr %p to i64", convert CastPtrToInt [] (TPointer Nothing) "p" (TInteger 64))
  , ("  %r = inttoptr i64 %w to ptr", convert CastIntToPtr [] (TInteger 64) "w" (TPointer Nothing))
  , ("  %r = bitcast i64 %w to double", convert CastBitcast [] (TInteger 64) "w" (TFloat FDouble))
  , ( "  %r = addrspacecast ptr %p to ptr addrspace(1)"
    , convert CastAddrSpaceCast [] (TPointer Nothing) "p" (TPointer (Just 1))
    )
  , -- A literal operand rather than a local.
    ( "  %r = add nsw i32 %a, 1"
    , OBinary
        Binary
          { binaryOp = OpAdd
          , binaryFlags = [FlagNSW]
          , binaryType = TInteger 32
          , binaryLeft = VLocal (Name Bare "a")
          , binaryRight = VInteger 1
          }
    )
  ]
  where
    binary op flags t =
      OBinary
        Binary
          { binaryOp = op
          , binaryFlags = flags
          , binaryType = t
          , binaryLeft = VLocal (Name Bare (if isFloat t then "d" else "a"))
          , binaryRight = VLocal (Name Bare (if isFloat t then "e" else "b"))
          }
    icmp flags predicate t =
      OICmp
        Compare
          { compareFlags = flags
          , comparePredicate = predicate
          , compareType = t
          , compareLeft = VLocal (Name Bare "a")
          , compareRight = VLocal (Name Bare "b")
          }
    fcmp flags predicate =
      OFCmp
        Compare
          { compareFlags = flags
          , comparePredicate = predicate
          , compareType = TFloat FDouble
          , compareLeft = VLocal (Name Bare "d")
          , compareRight = VLocal (Name Bare "e")
          }
    convert op flags sourceType operand target =
      OConvert
        Convert
          { convertOp = op
          , convertFlags = flags
          , convertOperand = TypedValue sourceType (VLocal (Name Bare operand))
          , convertTarget = target
          }
    isFloat (TFloat _) = True
    isFloat _ = False

-- | Malformed lines, which must leave their line opaque rather than
-- half-parse.
rejected :: [Text]
rejected =
  [ "  %r = add i32 %a"
  , "  %r = add i32 %a,"
  , "  %r = add nsw %a, %b"
  , "  %r = icmp i32 %a, %b" -- the predicate is not optional
  , "  %r = icmp zzz i32 %a, %b"
  , "  %r = fcmp oeq %d, %e"
  , "  %r = fneg double"
  , -- Conversions, malformed or absent from this release of LLVM.
    "  %r = zext i32 %a"
  , "  %r = zext i32 %a to"
  , "  %r = ptrtoaddr ptr %p to i64"
  ]

arithmeticTests :: TestTree
arithmeticTests =
  testGroup
    "arithmetic"
    [ testGroup
        "round trip"
        [testCase (name line) (roundTrips line) | (line, _) <- emitted]
    , testGroup
        "parsed shape"
        [testCase (name line) (parsesTo line operation) | (line, operation) <- emitted]
    , testGroup
        "malformed stays opaque"
        [testCase (name line) (staysOpaque line) | line <- rejected]
    , testGroup
        "none of these is a terminator"
        [ testCase (name line) (isTerminator operation @?= False)
        | (line, operation) <- emitted
        ]
    ]
  where
    name = T.unpack . T.strip

-- | A function with a parameter of each type the lines need.
inFunction :: Text -> Text
inFunction line =
  T.unlines
    [ "define void @f(i32 %a, i32 %b, double %d, double %e, ptr %p, ptr %q, <4 x i32> %va, <4 x i32> %vb) {"
    , line
    , "  ret void"
    , "}"
    ]

roundTrips :: Text -> Assertion
roundTrips line = do
  let source = inFunction line
  parsed <- expectParse "<inline>" source
  renderModule parsed @?= source

parsesTo :: Text -> Operation Name -> Assertion
parsesTo line operation = do
  instructions <- instructionsIn (inFunction line)
  take 1 instructions @?= [IOperation (Just (Name Bare "r")) operation []]

staysOpaque :: Text -> Assertion
staysOpaque line = do
  let source = inFunction line
  instructions <- instructionsIn source
  case instructions of
    IOpaque raw : _ -> raw @?= line
    other -> assertFailure ("expected an opaque instruction, got " <> show other)
  parsed <- expectParse "<inline>" source
  renderModule parsed @?= source

instructionsIn :: Text -> IO [Instruction]
instructionsIn source = do
  parsed <- expectParse "<inline>" source
  case [d | EDefine d <- moduleEntries parsed] of
    [d] -> pure (concatMap blockBody (definitionBlocks d))
    _ -> assertFailure "expected exactly one definition"
