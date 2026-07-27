-- | The instructions that end a basic block.
--
-- Each case is a whole function rather than a bare instruction line, so that
-- the text can be handed to @opt -S@ unchanged, and so that the expected
-- terminators are checked against something LLVM agrees is well formed.
module Terminators (terminatorTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Constant
import Olivine.Syntax.Function
import Olivine.Syntax.Instruction
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type
import Olivine.Syntax.Value

-- | Functions in the spelling LLVM emits, with the terminators each should
-- parse to, in order.
emitted :: [(String, Text, [Terminator])]
emitted =
  [ ( "ret void"
    , T.unlines ["define void @f() {", "  ret void", "}"]
    , [TRet Nothing]
    )
  , ( "ret a constant"
    , T.unlines ["define i32 @f() {", "  ret i32 0", "}"]
    , [TRet (Just (TypedValue (TInteger 32) (VConstant (CInteger 0))))]
    )
  , ( "ret a local"
    , T.unlines ["define i32 @f(i32 %0) {", "  ret i32 %0", "}"]
    , [TRet (Just (TypedValue (TInteger 32) (VLocal (Name Bare "0"))))]
    )
  , ( "ret a global"
    , T.unlines ["define ptr @f() {", "  ret ptr @g", "}"]
    , [TRet (Just (TypedValue (TPointer Nothing) (VConstant (CGlobal (Name Bare "g")))))]
    )
  , ( "unconditional branch"
    , T.unlines
        [ "define void @f() {"
        , "  br label %a"
        , ""
        , "a:                                                ; preds = %0"
        , "  ret void"
        , "}"
        ]
    , [TBr (Name Bare "a"), TRet Nothing]
    )
  , ( "conditional branch"
    , T.unlines
        [ "define void @f(i1 %0) {"
        , "  br i1 %0, label %2, label %3"
        , ""
        , "2:                                                ; preds = %1"
        , "  ret void"
        , ""
        , "3:                                                ; preds = %1"
        , "  ret void"
        , "}"
        ]
    , [ TCondBr
          (TypedValue (TInteger 1) (VLocal (Name Bare "0")))
          (Name Bare "2")
          (Name Bare "3")
      , TRet Nothing
      , TRet Nothing
      ]
    )
  , ( "switch"
    , T.unlines
        [ "define void @f(i32 %0) {"
        , "  switch i32 %0, label %2 ["
        , "    i32 0, label %2"
        , "    i32 7, label %2"
        , "  ]"
        , ""
        , "2:                                                ; preds = %1, %1, %1"
        , "  ret void"
        , "}"
        ]
    , [ TSwitch
          (TypedValue (TInteger 32) (VLocal (Name Bare "0")))
          (Name Bare "2")
          [ (TypedConstant (TInteger 32) (CInteger 0), Name Bare "2")
          , (TypedConstant (TInteger 32) (CInteger 7), Name Bare "2")
          ]
      , TRet Nothing
      ]
    )
  , -- The brackets stay on their own lines even with nothing between them.
    ( "switch with no cases"
    , T.unlines
        [ "define void @f(i32 %0) {"
        , "  switch i32 %0, label %2 ["
        , "  ]"
        , ""
        , "2:                                                ; preds = %1"
        , "  ret void"
        , "}"
        ]
    , [ TSwitch
          (TypedValue (TInteger 32) (VLocal (Name Bare "0")))
          (Name Bare "2")
          []
      , TRet Nothing
      ]
    )
  , ( "indirectbr"
    , T.unlines
        [ "define void @f(ptr %0) {"
        , "  indirectbr ptr %0, [label %2, label %3]"
        , ""
        , "2:                                                ; preds = %1"
        , "  ret void"
        , ""
        , "3:                                                ; preds = %1"
        , "  ret void"
        , "}"
        ]
    , [ TIndirectBr
          (TypedValue (TPointer Nothing) (VLocal (Name Bare "0")))
          [Name Bare "2", Name Bare "3"]
      , TRet Nothing
      , TRet Nothing
      ]
    )
  , ( "unreachable"
    , T.unlines ["define void @f() {", "  unreachable", "}"]
    , [TUnreachable]
    )
  ]

-- | Metadata attached to a terminator, which is how debug locations will
-- arrive: on the same footing as the @!llvm.loop@ the corpus already has.
attached :: [(String, Text, [MetadataAttachment])]
attached =
  [ ( "a loop annotation on a branch"
    , T.unlines
        [ "define void @f() {"
        , "  br label %1"
        , ""
        , "1:                                                ; preds = %1, %0"
        , "  br label %1, !llvm.loop !0"
        , "}"
        , "!0 = distinct !{!0}"
        ]
    , [MetadataAttachment (Name Bare "llvm.loop") 0]
    )
  , -- Custom metadata kinds, so that two attachments can be checked without
    -- dragging in what the verifier demands of the kinds it knows.  The two
    -- nodes are given different contents deliberately: uniqued nodes that
    -- agree are the same node, and LLVM would merge them.
    ( "two attachments"
    , T.unlines
        [ "define void @f() {"
        , "  ret void, !olivine.a !0, !olivine.b !1"
        , "}"
        , "!0 = !{i32 0}"
        , "!1 = !{i32 1}"
        ]
    , [ MetadataAttachment (Name Bare "olivine.a") 0
      , MetadataAttachment (Name Bare "olivine.b") 1
      ]
    )
  ]

-- | Terminators Olivine does not model.  Each must leave its line opaque
-- rather than half-parse, and the enclosing definition must still be read as
-- a definition.
rejected :: [Text]
rejected =
  [ "  invoke void @g() to label %a unwind label %b"
  , "  callbr void asm \"\", \"\"() to label %a []"
  , "  resume { ptr, i32 } %e"
  , "  catchret from %c to label %a"
  , "  cleanupret from %c unwind label %a"
  , -- Malformed rather than unmodelled.
    "  ret i32"
  , "  br label"
  , "  br i1 %c, label %a"
  , "  switch i32 %x, label %a"
  ]

terminatorTests :: TestTree
terminatorTests =
  testGroup
    "terminators"
    [ testGroup
        "round trip"
        [testCase name (roundTrips source) | (name, source, _) <- emitted <> map dropAttachments attached]
    , testGroup
        "parsed shape"
        [ testCase name (terminatorsOf source expected)
        | (name, source, expected) <- emitted
        ]
    , testGroup
        "attachments"
        [ testCase name (attachmentsOf source expected)
        | (name, source, expected) <- attached
        ]
    , testGroup
        "unmodelled or malformed stays opaque"
        [testCase (T.unpack (T.strip line)) (staysOpaque line) | line <- rejected]
    ]
  where
    dropAttachments (name, source, _) = (name, source, [])

roundTrips :: Text -> Assertion
roundTrips source = do
  parsed <- expectParse "<inline>" source
  renderModule parsed @?= source

terminatorsOf :: Text -> [Terminator] -> Assertion
terminatorsOf source expected = do
  instructions <- instructionsIn source
  [t | ITerminator t _ <- instructions] @?= expected

attachmentsOf :: Text -> [MetadataAttachment] -> Assertion
attachmentsOf source expected = do
  instructions <- instructionsIn source
  concat [as | ITerminator _ as <- instructions] @?= expected

-- | The line must survive as an opaque instruction inside a definition that
-- was still recognized as one.
staysOpaque :: Text -> Assertion
staysOpaque line = do
  let source = T.unlines ["define void @f() {", line, "}"]
  parsed <- expectParse "<inline>" source
  instructions <- instructionsIn source
  case instructions of
    [IOpaque raw] -> raw @?= line
    other -> assertFailure ("expected one opaque instruction, got " <> show other)
  renderModule parsed @?= source

instructionsIn :: Text -> IO [Instruction]
instructionsIn source = do
  parsed <- expectParse "<inline>" source
  case [d | EDefine d <- moduleEntries parsed] of
    [d] -> pure (concatMap blockBody (definitionBlocks d))
    _ -> assertFailure "expected exactly one definition"
