-- | The @call@ instruction.
--
-- As elsewhere in the instruction tests, values are named rather than
-- numbered, since a numbered line is only valid at one position in one
-- function.
module Calls (callTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Attribute
import Olivine.Syntax.Function
import Olivine.Syntax.Instruction
import Olivine.Syntax.Linkage
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type
import Olivine.Syntax.Value

-- | Lines in the spelling LLVM emits, with what each should parse to.
emitted :: [(Text, Maybe Name, Operation (TypedValue Name))]
emitted =
  [ ( "  call void @g()"
    , Nothing
    , OCall (call TVoid (VGlobal (Name Bare "g")))
    )
  , ( "  %r = call i32 @h(i32 %a)"
    , Just (Name Bare "r")
    , OCall
        (call (TInteger 32) (VGlobal (Name Bare "h")))
          { callArguments = [argument (TInteger 32) [] (VLocal (Name Bare "a"))]
          }
    )
  , -- Argument attributes, which are the same vocabulary a declaration uses.
    ( "  call void @g(ptr nonnull %p)"
    , Nothing
    , OCall
        (call TVoid (VGlobal (Name Bare "g")))
          { callArguments =
              [argument (TPointer Nothing) [PANonNull] (VLocal (Name Bare "p"))]
          }
    )
  , ( "  call void @g(ptr align 8 %p, i8 0, i64 %n, i1 false)"
    , Nothing
    , OCall
        (call TVoid (VGlobal (Name Bare "g")))
          { callArguments =
              [ argument (TPointer Nothing) [PAAlign 8] (VLocal (Name Bare "p"))
              , argument (TInteger 8) [] (VInteger 0)
              , argument (TInteger 64) [] (VLocal (Name Bare "n"))
              , argument (TInteger 1) [] (VBoolean False)
              ]
          }
    )
  , -- A return attribute, before the type.
    ( "  %r = call noalias ptr @m(i64 noundef %n)"
    , Just (Name Bare "r")
    , OCall
        (call (TPointer Nothing) (VGlobal (Name Bare "m")))
          { callReturnAttributes = [PANoAlias]
          , callArguments =
              [argument (TInteger 64) [PANoUndef] (VLocal (Name Bare "n"))]
          }
    )
  , -- Tail calls.
    ( "  tail call void @g()"
    , Nothing
    , OCall (call TVoid (VGlobal (Name Bare "g"))) {callTail = Just Tail}
    )
  , -- musttail was confirmed separately: it demands that the caller and
    -- callee signatures match and that a ret follows immediately, which the
    -- shared wrapper below does not satisfy.  Given a matching pair, LLVM
    -- echoes this spelling unchanged.
    ( "  musttail call void @g()"
    , Nothing
    , OCall (call TVoid (VGlobal (Name Bare "g"))) {callTail = Just MustTail}
    )
  , ( "  notail call void @g()"
    , Nothing
    , OCall (call TVoid (VGlobal (Name Bare "g"))) {callTail = Just NoTail}
    )
  , -- An attribute group reference after the arguments.
    ( "  call void @g() #0"
    , Nothing
    , OCall (call TVoid (VGlobal (Name Bare "g"))) {callAttributes = [AIGroup 0]}
    )
  , -- An indirect call, through a local rather than a global.
    ( "  %r = call i32 %fp(i32 noundef %a)"
    , Just (Name Bare "r")
    , OCall
        (call (TInteger 32) (VLocal (Name Bare "fp")))
          { callArguments =
              [argument (TInteger 32) [PANoUndef] (VLocal (Name Bare "a"))]
          }
    )
  , -- A variadic callee, where LLVM writes the whole function type in place
    -- of the return type.  Both are types, so one field holds either.
    ( "  %r = call i32 (ptr, ...) @printf(ptr noundef @s)"
    , Just (Name Bare "r")
    , OCall
        ( call
            (TFunction (TInteger 32) [TPointer Nothing] VariadicArity)
            (VGlobal (Name Bare "printf"))
        )
          { callArguments =
              [argument (TPointer Nothing) [PANoUndef] (VGlobal (Name Bare "s"))]
          }
    )
  , ( "  call fastcc void @g()"
    , Nothing
    , OCall
        (call TVoid (VGlobal (Name Bare "g")))
          { callCallingConvention = Just FastCC
          }
    )
  ]
  where
    call t callee =
      Call
        { callTail = Nothing
        , callFlags = []
        , callCallingConvention = Nothing
        , callReturnAttributes = []
        , callAddrSpace = Nothing
        , callType = t
        , callCallee = TypedValue (TPointer Nothing) callee
        , callArguments = []
        , callAttributes = []
        }

-- | Not modelled, or malformed.  Each must leave its line opaque.
rejected :: [Text]
rejected =
  [ -- Inline assembly is not modelled.
    "  call void asm sideeffect \"nop\", \"\"()"
  , -- Nor are operand bundles.
    "  call void @g() [ \"deopt\"() ]"
  , -- Calls that also branch are still to come.
    "  invoke void @g() to label %a unwind label %b"
  , -- Malformed.
    "  call void @g("
  , "  call @g()"
  , "  call void @g(ptr)"
  ]

-- | An argument as it used to be written: a type, its attributes, and a bare
-- value.  The type is on the operand now, and this puts it there.
argument :: Type -> [ParamAttribute] -> Value Name -> Argument (TypedValue Name)
argument t attributes value = Argument attributes (TypedValue t value)

callTests :: TestTree
callTests =
  testGroup
    "calls"
    [ testGroup
        "round trip"
        [testCase (name line) (roundTrips line) | (line, _, _) <- emitted]
    , testGroup
        "parsed shape"
        [ testCase (name line) (parsesTo line result operation)
        | (line, result, operation) <- emitted
        ]
    , testGroup
        "not modelled or malformed stays opaque"
        [testCase (name line) (staysOpaque line) | line <- rejected]
    , testGroup
        "a call is not a terminator"
        [ testCase (name line) (isTerminator operation @?= False)
        | (line, _, operation) <- emitted
        ]
    ]
  where
    name = T.unpack . T.strip

inFunction :: Text -> Text
inFunction line =
  T.unlines
    [ "define void @f(i32 %a, i64 %n, ptr %p, ptr %fp, <4 x i32> %v) {"
    , line
    , "  ret void"
    , "}"
    ]

roundTrips :: Text -> Assertion
roundTrips line = do
  let source = inFunction line
  parsed <- expectParse "<inline>" source
  renderModule parsed @?= source

parsesTo :: Text -> Maybe Name -> Operation (TypedValue Name) -> Assertion
parsesTo line result operation = do
  instructions <- instructionsIn (inFunction line)
  take 1 instructions @?= [IOperation result operation []]

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
