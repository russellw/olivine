-- | The dead function pass.
module DeadFunctions (deadFunctionTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.DeadFunctions
  ( eliminateDeadFunctions
  , mentionedIn
  , removableWhenUnreached
  )
import Olivine.Core.Program
import Olivine.Core.Raise (raise)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function
import Olivine.Syntax.Linkage
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type

deadFunctionTests :: TestTree
deadFunctionTests =
  testGroup
    "dead functions"
    [ testCase "an internal function nothing calls goes" $ do
        kept <- survivorsOf reachability
        assertBool ("expected no unused in " <> show kept) ("unused" `notElem` kept)
    , testCase "an internal function the program calls stays" $ do
        kept <- survivorsOf reachability
        assertBool ("expected helper in " <> show kept) ("helper" `elem` kept)
    , testCase "an external function stays although nothing calls it" $ do
        kept <- survivorsOf reachability
        assertBool ("expected exported in " <> show kept) ("exported" `elem` kept)
    , -- The point of reachability over a reference count: these two name each
      -- other as often as any live pair does, and no live path arrives at
      -- either.
      testCase "internal functions that only call each other go together" $ do
        kept <- survivorsOf reachability
        assertEqual "neither survives" [] (filter (`elem` ["ping", "pong"]) kept)
    , testCase "an internal function that only calls itself goes" $ do
        kept <- survivorsOf reachability
        assertBool ("expected no spin in " <> show kept) ("spin" `notElem` kept)
    , -- Stated as what should be there rather than by counting what went, so
      -- that a pass removing everything would not pass.
      testCase "everything reachable survives" $ do
        kept <- survivorsOf reachability
        assertEqual
          "the live set, in the order written"
          ["helper", "exported", "run"]
          kept
    , testGroup
        "a function pointer is a call"
        [ testCase "named by a global's initializer" $ do
            kept <- survivorsOf referenced
            assertBool ("expected tabled in " <> show kept) ("tabled" `elem` kept)
        , testCase "named inside a constant expression" $ do
            kept <- survivorsOf referenced
            assertBool ("expected measured in " <> show kept) ("measured" `elem` kept)
        , testCase "named by a metadata node" $ do
            kept <- survivorsOf referenced
            assertBool ("expected noted in " <> show kept) ("noted" `elem` kept)
        , -- An alias is not modelled, so the line naming this one comes
          -- through as text.  A name in text Olivine cannot read is a name it
          -- has to assume is used.
          testCase "named by a line not yet read" $ do
            kept <- survivorsOf referenced
            assertBool ("expected aliased in " <> show kept) ("aliased" `elem` kept)
        , testCase "and one named by none of them still goes" $ do
            kept <- survivorsOf referenced
            assertBool ("expected no forgotten in " <> show kept) ("forgotten" `notElem` kept)
        ]
    , -- Clang writes "; Function Attrs: ..." above every function it emits.
      -- The printer derives that line from the function's attributes, so it
      -- cannot be left behind saying of the next function what was true of
      -- the one removed — but only as long as this pass takes the function
      -- and not the line, which is what these check.
      testGroup
        "the attribute comment above a function"
        [ testCase "goes when the function goes" $ do
            lines' <- renderedFrom commented
            assertBool
              ("expected no noinline comment in " <> show lines')
              ("; Function Attrs: noinline nounwind" `notElem` lines')
        , testCase "stays when the function stays" $ do
            lines' <- renderedFrom commented
            assertBool
              ("expected the alwaysinline comment in " <> show lines')
              ("; Function Attrs: alwaysinline" `elem` lines')
        ]
    , testGroup
        "declarations"
        [ testCase "one nothing calls goes" $ do
            kept <- declaredIn reachability
            assertBool ("expected no unused_extern in " <> show kept) ("unused_extern" `notElem` kept)
        , -- It was called only from a function that went, so it goes too.
          testCase "one called only from a function that went goes" $ do
            kept <- declaredIn reachability
            assertBool ("expected no lonely in " <> show kept) ("lonely" `notElem` kept)
        , testCase "one the program still calls stays" $ do
            kept <- declaredIn reachability
            assertEqual "the one live declaration" ["puts"] kept
        ]
    , testGroup
        "what may go when nothing reaches it"
        [ testCase "private" $ removable (Just LinkPrivate) @?= True
        , testCase "internal" $ removable (Just LinkInternal) @?= True
        , -- A definition another module owns, never emitted from this one.
          testCase "available_externally" $ removable (Just LinkAvailableExternally) @?= True
        , testCase "linkonce" $ removable (Just LinkLinkOnce) @?= True
        , testCase "linkonce_odr" $ removable (Just LinkLinkOnceODR) @?= True
        , -- weak differs from linkonce in exactly this: an unreferenced weak
          -- definition may not be discarded, since the linker may pick it for
          -- a symbol another module refers to.
          testCase "weak" $ removable (Just LinkWeak) @?= False
        , testCase "weak_odr" $ removable (Just LinkWeakODR) @?= False
        , testCase "external" $ removable (Just LinkExternal) @?= False
        , -- No linkage written means external.
          testCase "none written" $ removable Nothing @?= False
        ]
    , testGroup
        "the globals a line of text mentions"
        [ testCase "an alias names its target" $
            mentionedIn "@a = alias void (), ptr @f" @?= ["a", "f"]
        , testCase "a quoted name" $
            mentionedIn "@\"a b\" = alias void (), ptr @f" @?= ["a b", "f"]
        , testCase "the sigil for a local is not this one" $
            mentionedIn "  %x = add i32 %a, %b" @?= []
        , testCase "nothing at all" $ mentionedIn "target triple = \"x\"" @?= []
        , -- The comment saying what a function is for is where its name gets
          -- written, so reading comments would keep nearly everything.
          testCase "a comment names nothing" $
            mentionedIn "; @f is what @g calls" @?= []
        , testCase "a comment after a mention ends it" $
            mentionedIn "@a = alias void (), ptr @f ; not @g" @?= ["a", "f"]
        , testCase "a string is data, not a mention" $
            mentionedIn "@s = constant [3 x i8] c\"@f\\00\"" @?= ["s"]
        , -- Which of the two comes first is the whole difference.
          testCase "a semicolon inside a string does not start a comment" $
            mentionedIn "@s = alias void (), ptr @f, section \";\", ptr @g" @?= ["s", "f", "g"]
        ]
    ]
  where
    removable linkage = removableWhenUnreached (signature linkage)
    signature linkage =
      Signature
        { signatureLinkage = linkage
        , signaturePreemption = Nothing
        , signatureVisibility = Nothing
        , signatureDLLStorage = Nothing
        , signatureCallingConvention = Nothing
        , signatureReturnAttributes = []
        , signatureReturnType = TVoid
        , signatureName = Name Bare "f"
        , signatureParameters = []
        , signatureArity = FixedArity
        , signatureUnnamedAddr = Nothing
        , signatureAddrSpace = Nothing
        , signatureAttributes = []
        }
    -- One external entry point, and around it every shape of function that
    -- has to be judged by what reaches it rather than by what names it.
    reachability =
      T.unlines
        [ "declare i32 @puts(ptr)"
        , "declare i32 @unused_extern(i32)"
        , "declare i32 @lonely(i32)"
        , ""
        , "define internal i32 @helper(i32 %x) {"
        , "  %r = add i32 %x, 1"
        , "  ret i32 %r"
        , "}"
        , ""
        , "define internal i32 @unused(i32 %x) {"
        , "  %r = call i32 @lonely(i32 %x)"
        , "  ret i32 %r"
        , "}"
        , ""
        , "define internal i32 @ping(i32 %x) {"
        , "  %r = call i32 @pong(i32 %x)"
        , "  ret i32 %r"
        , "}"
        , ""
        , "define internal i32 @pong(i32 %x) {"
        , "  %r = call i32 @ping(i32 %x)"
        , "  ret i32 %r"
        , "}"
        , ""
        , "define internal i32 @spin(i32 %x) {"
        , "  %r = call i32 @spin(i32 %x)"
        , "  ret i32 %r"
        , "}"
        , ""
        , "define i32 @exported(i32 %x) {"
        , "  ret i32 %x"
        , "}"
        , ""
        , "define i32 @run(ptr %s) {"
        , "  %a = call i32 @puts(ptr %s)"
        , "  %b = call i32 @helper(i32 %a)"
        , "  ret i32 %b"
        , "}"
        ]
    -- What clang actually writes: attributes on each function, and the
    -- comment above it that the printer puts back from them.
    commented =
      T.unlines
        [ "define internal i32 @dead(i32 %x) #0 {"
        , "  ret i32 %x"
        , "}"
        , ""
        , "define i32 @live(i32 %x) #1 {"
        , "  ret i32 %x"
        , "}"
        , ""
        , "attributes #0 = { noinline nounwind }"
        , "attributes #1 = { alwaysinline }"
        ]
    -- The ways a function can be named that are not a call.
    referenced =
      T.unlines
        [ "@table = internal constant [1 x ptr] [ptr @tabled]"
        , "@offset = internal constant i64 ptrtoint (ptr @measured to i64)"
        , "@aka = alias i32 (i32), ptr @aliased"
        , ""
        , "!named = !{!0}"
        , "!0 = !{ptr @noted}"
        , ""
        , "define internal i32 @tabled(i32 %x) {"
        , "  ret i32 %x"
        , "}"
        , ""
        , "define internal i32 @measured(i32 %x) {"
        , "  ret i32 %x"
        , "}"
        , ""
        , "define internal i32 @noted(i32 %x) {"
        , "  ret i32 %x"
        , "}"
        , ""
        , "define internal i32 @aliased(i32 %x) {"
        , "  ret i32 %x"
        , "}"
        , ""
        , "define internal i32 @forgotten(i32 %x) {"
        , "  ret i32 %x"
        , "}"
        , ""
        , "define i32 @run(i32 %x) {"
        , "  ret i32 %x"
        , "}"
        ]

-- | The functions still defined, in the order they were written.
survivorsOf :: Text -> IO [Text]
survivorsOf source = do
  program <- sifted source
  pure
    [ nameText (signatureName (functionSignature f))
    | f <- functionsIn program
    ]

-- | The functions still declared.
declaredIn :: Text -> IO [Text]
declaredIn source = do
  program <- sifted source
  pure
    [ nameText (signatureName s)
    | ERetained (Syntax.EDeclare s) <- programEntries program
    ]

sifted :: Text -> IO Program
sifted source = eliminateDeadFunctions . lower <$> expectParse "<inline>" source

-- | What the pass leaves, as written out.
renderedFrom :: Text -> IO [Text]
renderedFrom source = T.lines . renderModule . raise <$> sifted source
