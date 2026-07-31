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
import Olivine.Syntax.Value
import Olivine.Syntax.Function
import Olivine.Syntax.Instruction
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type

-- | Functions in the spelling LLVM emits, with the terminators each should
-- parse to, in order.
emitted :: [(String, Text, [Operation (TypedValue Name)])]
emitted =
  [ ( "ret void"
    , T.unlines ["define void @f() {", "  ret void", "}"]
    , [ORet Nothing]
    )
  , ( "ret a constant"
    , T.unlines ["define i32 @f() {", "  ret i32 0", "}"]
    , [ORet (Just (TypedValue (TInteger 32) (VInteger 0)))]
    )
  , ( "ret a local"
    , T.unlines ["define i32 @f(i32 %0) {", "  ret i32 %0", "}"]
    , [ORet (Just (TypedValue (TInteger 32) (VLocal (Name Bare "0"))))]
    )
  , ( "ret a global"
    , T.unlines ["define ptr @f() {", "  ret ptr @g", "}"]
    , [ORet (Just (TypedValue (TPointer Nothing) (VGlobal (Name Bare "g"))))]
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
    , [OBr (Name Bare "a"), ORet Nothing]
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
    , [ OCondBr
          (TypedValue (TInteger 1) (VLocal (Name Bare "0")))
          (Name Bare "2")
          (Name Bare "3")
      , ORet Nothing
      , ORet Nothing
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
    , [ OSwitch
          (TypedValue (TInteger 32) (VLocal (Name Bare "0")))
          (Name Bare "2")
          [ (TypedValue (TInteger 32) (VInteger 0), Name Bare "2")
          , (TypedValue (TInteger 32) (VInteger 7), Name Bare "2")
          ]
      , ORet Nothing
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
    , [ OSwitch
          (TypedValue (TInteger 32) (VLocal (Name Bare "0")))
          (Name Bare "2")
          []
      , ORet Nothing
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
    , [ OIndirectBr
          (TypedValue (TPointer Nothing) (VLocal (Name Bare "0")))
          [Name Bare "2", Name Bare "3"]
      , ORet Nothing
      , ORet Nothing
      ]
    )
  , ( "unreachable"
    , T.unlines ["define void @f() {", "  unreachable", "}"]
    , [OUnreachable]
    )
  , -- The two terminators exception handling adds, and the landing pad
    -- between them.  LLVM writes an invoke's destinations and a pad's clauses
    -- on lines of their own, indented ten spaces, which is what the round trip
    -- half of this checks.
    ( "invoke and resume"
    , T.unlines
        [ "define i32 @f(i32 %x) personality ptr @p {"
        , "  %r = invoke i32 @h(i32 %x)"
        , "          to label %ok unwind label %bad"
        , ""
        , "ok:                                               ; preds = %0"
        , "  ret i32 %r"
        , ""
        , "bad:                                              ; preds = %0"
        , "  %l = landingpad { ptr, i32 }"
        , "          cleanup"
        , "          catch ptr @t"
        , "          filter [1 x ptr] [ptr @t]"
        , "  resume { ptr, i32 } %l"
        , "}"
        ]
    , [ OInvoke
          Invoke
            { invokeCall =
                Call
                  { callTail = Nothing
                  , callFlags = []
                  , callCallingConvention = Nothing
                  , callReturnAttributes = []
                  , callAddrSpace = Nothing
                  , callType = TInteger 32
                  , callCallee =
                      TypedValue (TPointer Nothing) (VGlobal (Name Bare "h"))
                  , callArguments =
                      [ Argument
                          []
                          (TypedValue (TInteger 32) (VLocal (Name Bare "x")))
                      ]
                  , callAttributes = []
                  , callBundles = []
                  }
            , invokeNormal = Name Bare "ok"
            , invokeUnwind = Name Bare "bad"
            }
      , ORet (Just (TypedValue (TInteger 32) (VLocal (Name Bare "r"))))
      , OResume
          ( TypedValue
              (TStruct Unpacked [TPointer Nothing, TInteger 32])
              (VLocal (Name Bare "l"))
          )
      ]
    )
  , -- Assembly that branches, with a result and two labels to jump to.  The
    -- template names them by position — @${2:l}@ is the first of the two,
    -- the operand before them being the input — which is why the destinations
    -- are a list and stay in the order written.
    ( "callbr"
    , T.unlines
        [ "define i32 @f(i32 %x) {"
        , "  %r = callbr i32 asm sideeffect \"bswapl $0; jmp ${2:l}\", \"=r,0,!i,!i\"(i32 %x)"
        , "          to label %ok [label %a, label %b]"
        , ""
        , "ok:                                               ; preds = %0"
        , "  ret i32 %r"
        , ""
        , "a:                                                ; preds = %0"
        , "  ret i32 1"
        , ""
        , "b:                                                ; preds = %0"
        , "  ret i32 2"
        , "}"
        ]
    , [ OCallBr
          CallBr
            { callBrCall =
                Call
                  { callTail = Nothing
                  , callFlags = []
                  , callCallingConvention = Nothing
                  , callReturnAttributes = []
                  , callAddrSpace = Nothing
                  , callType = TInteger 32
                  , callCallee =
                      TypedValue
                        (TPointer Nothing)
                        ( VAsm
                            InlineAsm
                              { asmSideEffect = True
                              , asmAlignStack = False
                              , asmIntelDialect = False
                              , asmUnwind = False
                              , asmTemplate = "bswapl $0; jmp ${2:l}"
                              , asmConstraints = "=r,0,!i,!i"
                              }
                        )
                  , callArguments =
                      [ Argument
                          []
                          (TypedValue (TInteger 32) (VLocal (Name Bare "x")))
                      ]
                  , callAttributes = []
                  , callBundles = []
                  }
            , callBrFallthrough = Name Bare "ok"
            , callBrIndirect = [Name Bare "a", Name Bare "b"]
            }
      , ORet (Just (TypedValue (TInteger 32) (VLocal (Name Bare "r"))))
      , ORet (Just (TypedValue (TInteger 32) (VInteger 1)))
      , ORet (Just (TypedValue (TInteger 32) (VInteger 2)))
      ]
    )
  , -- A bundle on the one instruction that writes brackets of its own.  They
    -- stand in different places — a bundle before the @to@, the destinations
    -- after it — and the parser tells them apart by what follows the bracket
    -- rather than by which of the two it happens to try first.
    ( "callbr carrying an operand bundle"
    , T.unlines
        [ "define void @f(i32 %x) {"
        , "  callbr void asm \"jmp ${1:l}\", \"r,!i\"(i32 %x) [ \"foo\"(i32 %x) ]"
        , "          to label %ok [label %a]"
        , ""
        , "ok:                                               ; preds = %0"
        , "  ret void"
        , ""
        , "a:                                                ; preds = %0"
        , "  ret void"
        , "}"
        ]
    , [ OCallBr
          CallBr
            { callBrCall =
                Call
                  { callTail = Nothing
                  , callFlags = []
                  , callCallingConvention = Nothing
                  , callReturnAttributes = []
                  , callAddrSpace = Nothing
                  , callType = TVoid
                  , callCallee =
                      TypedValue
                        (TPointer Nothing)
                        ( VAsm
                            InlineAsm
                              { asmSideEffect = False
                              , asmAlignStack = False
                              , asmIntelDialect = False
                              , asmUnwind = False
                              , asmTemplate = "jmp ${1:l}"
                              , asmConstraints = "r,!i"
                              }
                        )
                  , callArguments =
                      [ Argument
                          []
                          (TypedValue (TInteger 32) (VLocal (Name Bare "x")))
                      ]
                  , callAttributes = []
                  , callBundles =
                      [ OperandBundle
                          { bundleTag = "foo"
                          , bundleOperands =
                              [TypedValue (TInteger 32) (VLocal (Name Bare "x"))]
                          }
                      ]
                  }
            , callBrFallthrough = Name Bare "ok"
            , callBrIndirect = [Name Bare "a"]
            }
      , ORet Nothing
      , ORet Nothing
      ]
    )
  , -- The same with nothing to jump to and nothing to assign.  LLVM writes
    -- the brackets whether or not they hold anything, and accepts them empty.
    ( "callbr with no indirect destinations"
    , T.unlines
        [ "define void @g() {"
        , "  callbr void asm \"\", \"\"()"
        , "          to label %ok []"
        , ""
        , "ok:                                               ; preds = %0"
        , "  ret void"
        , "}"
        ]
    , [ OCallBr
          CallBr
            { callBrCall =
                Call
                  { callTail = Nothing
                  , callFlags = []
                  , callCallingConvention = Nothing
                  , callReturnAttributes = []
                  , callAddrSpace = Nothing
                  , callType = TVoid
                  , callCallee =
                      TypedValue
                        (TPointer Nothing)
                        ( VAsm
                            InlineAsm
                              { asmSideEffect = False
                              , asmAlignStack = False
                              , asmIntelDialect = False
                              , asmUnwind = False
                              , asmTemplate = ""
                              , asmConstraints = ""
                              }
                        )
                  , callArguments = []
                  , callAttributes = []
                  , callBundles = []
                  }
            , callBrFallthrough = Name Bare "ok"
            , callBrIndirect = []
            }
      , ORet Nothing
      ]
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
        , ""
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
        , ""
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
  [ "  catchret from %c to label %a"
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

terminatorsOf :: Text -> [Operation (TypedValue Name)] -> Assertion
terminatorsOf source expected = do
  instructions <- instructionsIn source
  [op | IOperation _ op _ <- instructions, isTerminator op] @?= expected

attachmentsOf :: Text -> [MetadataAttachment] -> Assertion
attachmentsOf source expected = do
  instructions <- instructionsIn source
  concat [as | IOperation _ _ as <- instructions] @?= expected

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
