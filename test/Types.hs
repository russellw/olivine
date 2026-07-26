-- | The type grammar, checked in both directions.
--
-- Types are exercised through @%t = type ...@, which is the one place a bare
-- type appears at the top level, so these tests go through the same entry
-- point as the corpus rather than a parser export that exists only for them.
module Types (typeTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderType)
import Olivine.Syntax.Type

-- | Types in the spelling LLVM itself emits.  Each must parse to the given
-- value and print back to the same text.
canonical :: [(Text, Type)]
canonical =
  [ ("void", TVoid)
  , ("i1", TInteger 1)
  , ("i32", TInteger 32)
  , ("i128", TInteger 128)
  , -- LLVM permits widths far past any machine word.
    ("i8388607", TInteger 8388607)
  , ("half", TFloat FHalf)
  , ("bfloat", TFloat FBFloat)
  , ("float", TFloat FFloat)
  , ("double", TFloat FDouble)
  , ("fp128", TFloat FFP128)
  , ("x86_fp80", TFloat FX86FP80)
  , ("ppc_fp128", TFloat FPPCFP128)
  , ("ptr", TPointer Nothing)
  , ("ptr addrspace(1)", TPointer (Just 1))
  , ("[8 x i8]", TArray 8 (TInteger 8))
  , ("[4 x [8 x i8]]", TArray 4 (TArray 8 (TInteger 8)))
  , ("[0 x i32]", TArray 0 (TInteger 32))
  , ("<4 x i32>", TVector FixedWidth 4 (TInteger 32))
  , ("<vscale x 4 x i32>", TVector Scalable 4 (TInteger 32))
  , ("{}", TStruct Unpacked [])
  , ("{ i32, i32 }", TStruct Unpacked [TInteger 32, TInteger 32])
  , ("<{ i32, i8 }>", TStruct Packed [TInteger 32, TInteger 8])
  , ( "{ %struct.point, double, [8 x i8] }"
    , TStruct
        Unpacked
        [ TNamed (Name Bare "struct.point")
        , TFloat FDouble
        , TArray 8 (TInteger 8)
        ]
    )
  , ("%struct.point", TNamed (Name Bare "struct.point"))
  , -- A hyphen is an ordinary identifier character in LLVM.
    ("%my-type", TNamed (Name Bare "my-type"))
  , ("%\"a name\"", TNamed (Name Quoted "a name"))
  , ("void ()", TFunction TVoid [] FixedArity)
  , ( "i32 (i32, i32)"
    , TFunction (TInteger 32) [TInteger 32, TInteger 32] FixedArity
    )
  , ("i32 (ptr, ...)", TFunction (TInteger 32) [TPointer Nothing] VariadicArity)
  , ("i32 (...)", TFunction (TInteger 32) [] VariadicArity)
  , ("opaque", TOpaqueStruct)
  , ("label", TLabel)
  , ("token", TToken)
  , ("metadata", TMetadata)
  ]

-- | Spellings LLVM accepts but does not emit.  These need only parse; what
-- they print as is settled by 'canonical'.
accepted :: [(Text, Type)]
accepted =
  [ ("[ 8 x i8 ]", TArray 8 (TInteger 8))
  , ("< 4 x i32 >", TVector FixedWidth 4 (TInteger 32))
  , ("{i32,i32}", TStruct Unpacked [TInteger 32, TInteger 32])
  , ("{ }", TStruct Unpacked [])
  , ("i32(i32)", TFunction (TInteger 32) [TInteger 32] FixedArity)
  , ("ptr  addrspace( 3 )", TPointer (Just 3))
  ]

-- | Text that is not a type, and so must leave the line opaque rather than
-- being parsed as some prefix of itself.
rejected :: [Text]
rejected =
  [ "i32x" -- a keyword may not run into an identifier
  , "doublet"
  , "[8 i8]" -- the x is not optional
  , "[8 x ]"
  , "{ i32, }"
  , "<4 x i32]" -- brackets have to match
  , "ptr addrspace(x)"
  ]

typeTests :: TestTree
typeTests =
  testGroup
    "types"
    [ testGroup
        "parsing"
        [ testCase (T.unpack source) (parsesAs source expected)
        | (source, expected) <- canonical <> accepted
        ]
    , testGroup
        "printing"
        [ testCase (T.unpack source) (renderType expected @?= source)
        | (source, expected) <- canonical
        ]
    , testGroup
        "rejected"
        [testCase (T.unpack source) (staysOpaque source) | source <- rejected]
    ]

parsesAs :: Text -> Type -> Assertion
parsesAs source expected = do
  parsed <- expectParse "<inline>" (definition source)
  moduleEntries parsed @?= [ETypeDefinition (Name Bare "t") expected]

staysOpaque :: Text -> Assertion
staysOpaque source = do
  parsed <- expectParse "<inline>" (definition source)
  moduleEntries parsed @?= [EOpaque (T.stripEnd (definition source))]

definition :: Text -> Text
definition source = "%t = type " <> source <> "\n"
