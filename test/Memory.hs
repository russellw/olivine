-- | The memory operations: @alloca@, @load@, @store@ and @getelementptr@.
--
-- These are the first instructions that name a result, so what is checked
-- here is the result name as much as the operations themselves.
module Memory (memoryTests) where

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

-- | Instruction lines in the spelling LLVM emits, with what each should parse
-- to.  They are placed in a function before being handed to @opt -S@, so the
-- spellings are confirmed rather than assumed.
--
-- Values are named rather than numbered.  LLVM numbers unnamed values
-- densely, counting the entry block among them, so a numbered line is only
-- valid at one position in one function — which says nothing about the syntax
-- under test.  The corpus covers the numbered form, in quantity.
emitted :: [(Text, Maybe Name, Operation Name)]
emitted =
  [ ( "  %r = alloca i32, align 4"
    , Just (Name Bare "r")
    , OAlloca (alloca (TInteger 32)) {allocaAlignment = Just 4}
    )
  , ( "  %r = alloca [4 x i8], align 16"
    , Just (Name Bare "r")
    , OAlloca (alloca (TArray 4 (TInteger 8))) {allocaAlignment = Just 16}
    )
  , -- An element count, which makes the allocation dynamic.
    ( "  %r = alloca i32, i64 %n, align 4"
    , Just (Name Bare "r")
    , OAlloca
        (alloca (TInteger 32))
          { allocaElementCount =
              Just (TypedValue (TInteger 64) (VLocal (Name Bare "n")))
          , allocaAlignment = Just 4
          }
    )
  , ( "  %r = load i32, ptr %p, align 4"
    , Just (Name Bare "r")
    , OLoad (load (TInteger 32) (VLocal (Name Bare "p"))) {loadAlignment = Just 4}
    )
  , ( "  %r = load volatile i32, ptr %p, align 4"
    , Just (Name Bare "r")
    , OLoad
        (load (TInteger 32) (VLocal (Name Bare "p")))
          { loadVolatile = True
          , loadAlignment = Just 4
          }
    )
  , -- Loading from a global rather than a local.
    ( "  %r = load i32, ptr @g, align 4"
    , Just (Name Bare "r")
    , OLoad (load (TInteger 32) (VGlobal (Name Bare "g"))) {loadAlignment = Just 4}
    )
  , ( "  store i32 0, ptr %p, align 4"
    , Nothing
    , OStore
        (store (TypedValue (TInteger 32) (VInteger 0)) (VLocal (Name Bare "p")))
          { storeAlignment = Just 4
          }
    )
  , ( "  store volatile i32 %v, ptr %p, align 4"
    , Nothing
    , OStore
        ( store
            (TypedValue (TInteger 32) (VLocal (Name Bare "v")))
            (VLocal (Name Bare "p"))
        )
          { storeVolatile = True
          , storeAlignment = Just 4
          }
    )
  , ( "  %r = getelementptr i8, ptr %p, i64 8"
    , Just (Name Bare "r")
    , OGetElementPtr
        (gep (TInteger 8) [TypedValue (TInteger 64) (VInteger 8)])
    )
  , ( "  %r = getelementptr inbounds nuw i8, ptr %p, i64 8"
    , Just (Name Bare "r")
    , OGetElementPtr
        (gep (TInteger 8) [TypedValue (TInteger 64) (VInteger 8)])
          { gepFlags = [GepInbounds, GepNuw]
          }
    )
  , -- Several indices, which is the form the core representation will later
    -- break into one offset at a time.
    ( "  %r = getelementptr inbounds [4 x i32], ptr %p, i64 0, i64 2"
    , Just (Name Bare "r")
    , OGetElementPtr
        ( gep
            (TArray 4 (TInteger 32))
            [ TypedValue (TInteger 64) (VInteger 0)
            , TypedValue (TInteger 64) (VInteger 2)
            ]
        )
          { gepFlags = [GepInbounds]
          }
    )
  , ( "  %r = getelementptr inbounds nuw %struct.point, ptr %p, i32 0, i32 1"
    , Just (Name Bare "r")
    , OGetElementPtr
        ( gep
            (TNamed (Name Bare "struct.point"))
            [ TypedValue (TInteger 32) (VInteger 0)
            , TypedValue (TInteger 32) (VInteger 1)
            ]
        )
          { gepFlags = [GepInbounds, GepNuw]
          }
    )
  ]
  where
    alloca t =
      Alloca
        { allocaInalloca = False
        , allocaType = t
        , allocaElementCount = Nothing
        , allocaAlignment = Nothing
        , allocaAddrSpace = Nothing
        }
    load t pointer =
      Load
        { loadVolatile = False
        , loadType = t
        , loadPointer = TypedValue (TPointer Nothing) pointer
        , loadAlignment = Nothing
        }
    store value pointer =
      Store
        { storeVolatile = False
        , storeValue = value
        , storePointer = TypedValue (TPointer Nothing) pointer
        , storeAlignment = Nothing
        }
    gep sourceType indices =
      GetElementPtr
        { gepFlags = []
        , gepSourceType = sourceType
        , gepPointer = TypedValue (TPointer Nothing) (VLocal (Name Bare "p"))
        , gepIndices = indices
        }

-- | Accepted, but LLVM writes it back differently.
--
-- Olivine keeps what was written; separating these lets 'emitted' honestly
-- claim to be LLVM's own output.
accepted :: [(Text, Maybe Name, Operation Name)]
accepted =
  [ -- Written without an alignment, LLVM supplies the target's own on the
    -- way out.  Olivine does not invent one.
    ( "  %r = alloca i32"
    , Just (Name Bare "r")
    , OAlloca
        Alloca
          { allocaInalloca = False
          , allocaType = TInteger 32
          , allocaElementCount = Nothing
          , allocaAlignment = Nothing
          , allocaAddrSpace = Nothing
          }
    )
  ]

-- | Metadata on a memory operation, which is where @!tbaa@ lives and where
-- @!dbg@ will.
attached :: [(Text, [MetadataAttachment])]
attached =
  [ ( "  %r = load i32, ptr %p, align 4, !tbaa !0"
    , [MetadataAttachment (Name Bare "tbaa") 0]
    )
  , ( "  store i32 0, ptr %p, align 4, !tbaa !0, !olivine.x !1"
    , [ MetadataAttachment (Name Bare "tbaa") 0
      , MetadataAttachment (Name Bare "olivine.x") 1
      ]
    )
  ]

-- | Forms Olivine does not model, and malformed lines.  Each must leave its
-- line opaque rather than half-parse.
rejected :: [Text]
rejected =
  [ -- Atomic accesses are not modelled.
    "  %r = load atomic i32, ptr %p unordered, align 4"
  , "  store atomic i32 0, ptr %p release, align 4"
  , "  %r = load atomic volatile i32, ptr %p syncscope(\"agent\") acquire, align 4"
  , -- Malformed rather than unmodelled.
    "  %r = alloca"
  , "  %r = load i32 ptr %p"
  , "  %r = load i32, ptr %p, align"
  , "  store i32 0"
  , "  %r = getelementptr i8 ptr %p"
  ]

memoryTests :: TestTree
memoryTests =
  testGroup
    "memory"
    [ testGroup
        "round trip"
        [ testCase (T.unpack (T.strip line)) (roundTrips line)
        | (line, _, _) <- emitted <> accepted
        ]
    , testGroup
        "parsed shape"
        [ testCase (T.unpack (T.strip line)) (parsesTo line result operation)
        | (line, result, operation) <- emitted <> accepted
        ]
    , testGroup
        "attachments"
        [ testCase (T.unpack (T.strip line)) (attachmentsOf line expected)
        | (line, expected) <- attached
        ]
    , testGroup
        "unmodelled or malformed stays opaque"
        [testCase (T.unpack (T.strip line)) (staysOpaque line) | line <- rejected]
    , testGroup
        "these are not terminators"
        [ testCase (T.unpack (T.strip line)) (isTerminator operation @?= False)
        | (line, _, operation) <- emitted <> accepted
        ]
    ]

-- | Wrapping a line in the smallest function that can hold it, with a
-- parameter of each type the lines need.
inFunction :: Text -> Text
inFunction line =
  T.unlines ["define void @f(ptr %p, i32 %v, i64 %n) {", line, "  ret void", "}"]

roundTrips :: Text -> Assertion
roundTrips line = do
  let source = inFunction line
  parsed <- expectParse "<inline>" source
  renderModule parsed @?= source

parsesTo :: Text -> Maybe Name -> Operation Name -> Assertion
parsesTo line result operation = do
  instructions <- instructionsIn (inFunction line)
  take 1 instructions @?= [IOperation result operation []]

attachmentsOf :: Text -> [MetadataAttachment] -> Assertion
attachmentsOf line expected = do
  instructions <- instructionsIn (inFunction line)
  case instructions of
    IOperation _ _ attachments : _ -> attachments @?= expected
    other -> assertFailure ("expected an operation, got " <> show other)

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
