-- | @select@ and the vector operations.
module Vectors (vectorTests) where

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
emitted :: [(Text, Operation (TypedValue Name))]
emitted =
  [ ( "  %r = select i1 %c, i32 %a, i32 %b"
    , OSelect
        Select
          { selectFlags = []
          , selectCondition = TypedValue (TInteger 1) (VLocal (Name Bare "c"))
          , selectTrue = TypedValue (TInteger 32) (VLocal (Name Bare "a"))
          , selectFalse = TypedValue (TInteger 32) (VLocal (Name Bare "b"))
          }
    )
  , -- Fast-math flags, which a floating point select may carry.
    ( "  %r = select fast i1 %c, double %d, double %e"
    , OSelect
        Select
          { selectFlags = [FlagFast]
          , selectCondition = TypedValue (TInteger 1) (VLocal (Name Bare "c"))
          , selectTrue = TypedValue (TFloat FDouble) (VLocal (Name Bare "d"))
          , selectFalse = TypedValue (TFloat FDouble) (VLocal (Name Bare "e"))
          }
    )
  , -- An elementwise select, where the condition is a vector of i1.  This is
    -- why the condition carries its own type rather than being assumed i1.
    ( "  %r = select <4 x i1> %m, <4 x i32> %v, <4 x i32> %w"
    , OSelect
        Select
          { selectFlags = []
          , selectCondition =
              TypedValue (TVector FixedWidth 4 (TInteger 1)) (VLocal (Name Bare "m"))
          , selectTrue = TypedValue vector (VLocal (Name Bare "v"))
          , selectFalse = TypedValue vector (VLocal (Name Bare "w"))
          }
    )
  , ( "  %r = select i1 %c, i32 0, i32 %b"
    , OSelect
        Select
          { selectFlags = []
          , selectCondition = TypedValue (TInteger 1) (VLocal (Name Bare "c"))
          , selectTrue = TypedValue (TInteger 32) (VInteger 0)
          , selectFalse = TypedValue (TInteger 32) (VLocal (Name Bare "b"))
          }
    )
  , ( "  %r = extractelement <4 x i32> %v, i32 0"
    , OExtractElement
        ExtractElement
          { extractElementVector = TypedValue vector (VLocal (Name Bare "v"))
          , extractElementIndex = TypedValue (TInteger 32) (VInteger 0)
          }
    )
  , ( "  %r = extractelement <4 x i32> %v, i32 %a"
    , OExtractElement
        ExtractElement
          { extractElementVector = TypedValue vector (VLocal (Name Bare "v"))
          , extractElementIndex = TypedValue (TInteger 32) (VLocal (Name Bare "a"))
          }
    )
  , ( "  %r = insertelement <4 x i32> %v, i32 %a, i32 0"
    , OInsertElement
        InsertElement
          { insertElementVector = TypedValue vector (VLocal (Name Bare "v"))
          , insertElementValue = TypedValue (TInteger 32) (VLocal (Name Bare "a"))
          , insertElementIndex = TypedValue (TInteger 32) (VInteger 0)
          }
    )
  , -- The shape the corpus has, building a vector out of poison.
    ( "  %r = insertelement <4 x i32> poison, i32 %a, i64 0"
    , OInsertElement
        InsertElement
          { insertElementVector = TypedValue vector VPoison
          , insertElementValue = TypedValue (TInteger 32) (VLocal (Name Bare "a"))
          , insertElementIndex = TypedValue (TInteger 64) (VInteger 0)
          }
    )
  , -- A mask written out as a vector constant.
    ( "  %r = shufflevector <4 x i32> %v, <4 x i32> %w, <4 x i32> <i32 0, i32 1, i32 2, i32 3>"
    , OShuffleVector
        ShuffleVector
          { shuffleVectorLeft = TypedValue vector (VLocal (Name Bare "v"))
          , shuffleVectorRight = TypedValue vector (VLocal (Name Bare "w"))
          , shuffleVectorMask =
              TypedValue
                vector
                ( VVector
                    [ TypedValue (TInteger 32) (VInteger n)
                    | n <- [0 .. 3]
                    ]
                )
          }
    )
  , -- And the splat the corpus has, where the mask is zeroinitializer.  A
    -- list of indices could not have held that.
    ( "  %r = shufflevector <4 x i32> %v, <4 x i32> poison, <4 x i32> zeroinitializer"
    , OShuffleVector
        ShuffleVector
          { shuffleVectorLeft = TypedValue vector (VLocal (Name Bare "v"))
          , shuffleVectorRight = TypedValue vector VPoison
          , shuffleVectorMask = TypedValue vector VZeroInitializer
          }
    )
  , -- LLVM's canonical spelling of a uniform vector constant, and the reason
    -- it has to be read: it normalizes @\<i32 4, i32 4, i32 4, i32 4\>@ to
    -- this, so this is the form its own output arrives in.  How wide the
    -- vector is comes from the operand's type and is nowhere in the constant.
    ( "  %r = add <4 x i32> %v, splat (i32 4)"
    , OBinary
        Binary
          { binaryOp = OpAdd
          , binaryFlags = []
          , binaryLeft = TypedValue vector (VLocal (Name Bare "v"))
          , binaryRight = TypedValue vector (VSplat (TypedValue (TInteger 32) (VInteger 4)))
          }
    )
  , -- A negative element, which is where a splat could be confused for a
    -- unary operator on the way in.
    ( "  %r = icmp eq <4 x i32> %v, splat (i32 -1)"
    , OICmp
        Compare
          { compareFlags = []
          , comparePredicate = IEq
          , compareLeft = TypedValue vector (VLocal (Name Bare "v"))
          , compareRight = TypedValue vector (VSplat (TypedValue (TInteger 32) (VInteger (-1))))
          }
    )
  , -- A float element, held as the text it was written in like any other float
    -- literal, so that nothing decodes and re-encodes it.
    ( "  %r = fadd <4 x float> %f, splat (float 1.500000e+00)"
    , OBinary
        Binary
          { binaryOp = OpFAdd
          , binaryFlags = []
          , binaryLeft = TypedValue floats (VLocal (Name Bare "f"))
          , binaryRight =
              TypedValue floats (VSplat (TypedValue (TFloat FFloat) (VFloat "1.500000e+00")))
          }
    )
  , -- A field read out of an aggregate held as a value, which is how a struct
    -- small enough to travel in registers is returned.
    ( "  %r = extractvalue { i32, i32 } %s, 0"
    , OExtractValue
        ExtractValue
          { extractValueAggregate = TypedValue pair (VLocal (Name Bare "s"))
          , extractValueIndices = [0]
          }
    )
  , ( "  %r = insertvalue { i32, i32 } %s, i32 %a, 1"
    , OInsertValue
        InsertValue
          { insertValueAggregate = TypedValue pair (VLocal (Name Bare "s"))
          , insertValueValue = TypedValue (TInteger 32) (VLocal (Name Bare "a"))
          , insertValueIndices = [1]
          }
    )
  , -- And a path of more than one index, which is why the indices are a list
    -- rather than the single step a pointer walk was split into.
    ( "  %r = extractvalue { i32, { i32, i32 } } %n, 1, 0"
    , OExtractValue
        ExtractValue
          { extractValueAggregate = TypedValue nested (VLocal (Name Bare "n"))
          , extractValueIndices = [1, 0]
          }
    )
  ]
  where
    vector = TVector FixedWidth 4 (TInteger 32)
    floats = TVector FixedWidth 4 (TFloat FFloat)
    pair = TStruct Unpacked [TInteger 32, TInteger 32]
    nested = TStruct Unpacked [TInteger 32, pair]

-- | Malformed, and so left opaque.
rejected :: [Text]
rejected =
  [ "  %r = select i1 %c, i32 %a"
  , "  %r = select %c, i32 %a, i32 %b"
  , "  %r = extractelement <4 x i32> %v"
  , "  %r = insertelement <4 x i32> %v, i32 %a"
  , "  %r = shufflevector <4 x i32> %v, <4 x i32> %w"
  , -- An aggregate operation has to say which field, and one index is the
    -- fewest it can say it in.
    "  %r = extractvalue { i32, i32 } %s"
  , "  %r = insertvalue { i32, i32 } %s, i32 %a"
  ]

vectorTests :: TestTree
vectorTests =
  testGroup
    "select and vectors"
    [ testGroup
        "round trip"
        [testCase (name line) (roundTrips line) | (line, _) <- emitted]
    , testGroup
        "parsed shape"
        [testCase (name line) (parsesTo line operation) | (line, operation) <- emitted]
    , testGroup
        "malformed or unmodelled stays opaque"
        [testCase (name line) (staysOpaque line) | line <- rejected]
    , testGroup
        "none of these is a terminator"
        [ testCase (name line) (isTerminator operation @?= False)
        | (line, operation) <- emitted
        ]
    , -- A global's initializer is written without a type in front of it, so it
      -- reaches the value grammar by a different route than an operand does.
      testCase "a splat initializes a global" $ do
        let source = "@g = global <4 x i32> splat (i32 7)\n"
        parsed <- expectParse "<inline>" source
        renderModule parsed @?= source
    ]
  where
    name = T.unpack . T.strip

inFunction :: Text -> Text
inFunction line =
  T.unlines
    [ "define void @f(i1 %c, i32 %a, i32 %b, double %d, double %e, <4 x i32> %v, <4 x i32> %w, <4 x i1> %m, <4 x float> %f, { i32, i32 } %s, { i32, { i32, i32 } } %n) {"
    , line
    , "  ret void"
    , "}"
    ]

roundTrips :: Text -> Assertion
roundTrips line = do
  let source = inFunction line
  parsed <- expectParse "<inline>" source
  renderModule parsed @?= source

parsesTo :: Text -> Operation (TypedValue Name) -> Assertion
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
