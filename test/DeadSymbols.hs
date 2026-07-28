-- | The dead symbol pass.
module DeadSymbols (deadSymbolTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.DeadSymbols
  ( eliminateDeadSymbols
  , mentionedIn
  , removableWhenUnreached
  )
import Olivine.Core.Program
import Olivine.Core.Raise (raise)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function
import Olivine.Syntax.Global (globalName, indirectName)
import Olivine.Syntax.Linkage
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)

deadSymbolTests :: TestTree
deadSymbolTests =
  testGroup
    "dead symbols"
    [ testGroup
        "functions"
        [ testCase "an internal function nothing calls goes" $ do
            kept <- survivorsOf reachability
            assertBool ("expected no unused in " <> show kept) ("unused" `notElem` kept)
        , testCase "an internal function the program calls stays" $ do
            kept <- survivorsOf reachability
            assertBool ("expected helper in " <> show kept) ("helper" `elem` kept)
        , testCase "an external function stays although nothing calls it" $ do
            kept <- survivorsOf reachability
            assertBool ("expected exported in " <> show kept) ("exported" `elem` kept)
        , -- The point of reachability over a reference count: these two name
          -- each other as often as any live pair does, and no live path
          -- arrives at either.
          testCase "internal functions that only call each other go together" $ do
            kept <- survivorsOf reachability
            assertEqual "neither survives" [] (filter (`elem` ["ping", "pong"]) kept)
        , testCase "an internal function that only calls itself goes" $ do
            kept <- survivorsOf reachability
            assertBool ("expected no spin in " <> show kept) ("spin" `notElem` kept)
        , -- Stated as what should be there rather than by counting what went,
          -- so that a pass removing everything would not pass.
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
            , -- An arithmetic constant expression is not modelled, so the
              -- global whose initializer is one comes through as text.  A name
              -- in text Olivine cannot read is a name it has to assume is
              -- used, and this one is internal besides, so nothing but the
              -- text is keeping it.
              testCase "named by a line not yet read" $ do
                kept <- survivorsOf referenced
                assertBool ("expected summed in " <> show kept) ("summed" `elem` kept)
            , testCase "and one named by none of them still goes" $ do
                kept <- survivorsOf referenced
                assertBool ("expected no forgotten in " <> show kept) ("forgotten" `notElem` kept)
            ]
        , -- Clang writes "; Function Attrs: ..." above every function it
          -- emits.  The printer derives that line from the function's
          -- attributes, so it cannot be left behind saying of the next
          -- function what was true of the one removed — but only as long as
          -- this pass takes the function and not the line, which is what these
          -- check.
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
        ]
    , testGroup
        "globals"
        [ testCase "an internal global nothing reads goes" $ do
            kept <- globalsOf globals
            assertBool ("expected no hidden in " <> show kept) ("hidden" `notElem` kept)
        , testCase "an internal global the program reads stays" $ do
            kept <- globalsOf globals
            assertBool ("expected counted in " <> show kept) ("counted" `elem` kept)
        , testCase "an external global stays although nothing reads it" $ do
            kept <- globalsOf globals
            assertBool ("expected shown in " <> show kept) ("shown" `elem` kept)
        , -- The same point reachability makes about functions, made with
          -- initializers in place of calls.
          testCase "internal globals that only name each other go together" $ do
            kept <- globalsOf globals
            assertEqual "neither survives" [] (filter (`elem` ["ping", "pong"]) kept)
        , testCase "everything reachable survives" $ do
            kept <- globalsOf globals
            assertEqual
              "the live set, in the order written"
              ["wanted", "shown", "counted"]
              kept
        , testGroup
            "declarations"
            [ -- A global with no initializer is defined somewhere else, so one
              -- nothing names emits nothing, exactly as a @declare@ does.
              -- Their linkage is external, and would otherwise keep them all.
              testCase "one nothing reads goes" $ do
                kept <- globalsOf globals
                assertBool ("expected no unwanted in " <> show kept) ("unwanted" `notElem` kept)
            , testCase "one the program reads stays" $ do
                kept <- globalsOf globals
                assertBool ("expected wanted in " <> show kept) ("wanted" `elem` kept)
            ]
        , testGroup
            "what keeps one that its linkage does not say"
            [ -- A comdat is kept or discarded as a group, and the rest of the
              -- group cannot be seen from here.  LLVM's own globaldce, which
              -- does track membership, removes this one: the difference is the
              -- modelling and not a disagreement about what is dead.
              testCase "being in a comdat" $ do
                kept <- globalsOf pinned
                assertBool ("expected kept in " <> show kept) ("kept" `elem` kept)
            , -- externally_initialized says the value at startup is not the
              -- initializer, which is a fact about the value rather than about
              -- who can reach the symbol.
              testCase "but not externally_initialized, on its own" $ do
                kept <- globalsOf pinned
                assertBool ("expected no configured in " <> show kept) ("configured" `notElem` kept)
            , -- Which is how a module says it means an unreferenced global to
              -- survive, and works here for the reason it works for functions.
              testCase "and being named by llvm.used" $ do
                kept <- globalsOf pinned
                assertBool ("expected wired in " <> show kept) ("wired" `elem` kept)
            ]
        ]
    , testGroup
        "aliases and ifuncs"
        [ testCase "an internal alias nothing names goes" $ do
            kept <- indirectsOf aliased
            assertBool ("expected no hidden in " <> show kept) ("hidden" `notElem` kept)
        , testCase "an external alias stays although nothing names it" $ do
            kept <- indirectsOf aliased
            assertBool ("expected shown in " <> show kept) ("shown" `elem` kept)
        , -- Being aliased is the only thing keeping this one, so the alias
          -- has to count as a mention or the program loses what it resolves
          -- to.
          testCase "a live alias keeps what it names" $ do
            kept <- globalsOf aliased
            assertBool ("expected target in " <> show kept) ("target" `elem` kept)
        , -- And the other half of that: it has to count as a mention only
          -- while the alias itself is live.
          testCase "a dead alias does not" $ do
            kept <- globalsOf aliased
            assertBool
              ("expected no hidden_target in " <> show kept)
              ("hidden_target" `notElem` kept)
        , testCase "a function only a dead alias names goes" $ do
            kept <- survivorsOf aliased
            assertBool ("expected no kept_fn in " <> show kept) ("kept_fn" `notElem` kept)
        , -- An alias may name another alias, so the walk has to arrive at
          -- symbols of this kind as well as leave from them.
          testCase "an alias reached only through another survives" $ do
            kept <- indirectsOf aliased
            assertBool ("expected middle in " <> show kept) ("middle" `elem` kept)
        , -- An ifunc names the function that resolves it, which is the only
          -- mention this resolver gets.
          testCase "a live ifunc keeps its resolver" $ do
            kept <- survivorsOf aliased
            assertBool ("expected chooser in " <> show kept) ("chooser" `elem` kept)
        , testCase "an internal ifunc nothing names goes" $ do
            kept <- indirectsOf aliased
            assertBool ("expected no quiet in " <> show kept) ("quiet" `notElem` kept)
        , testCase "taking its resolver with it" $ do
            kept <- survivorsOf aliased
            assertBool ("expected no unchosen in " <> show kept) ("unchosen" `notElem` kept)
        , testCase "everything reachable survives" $ do
            indirects <- indirectsOf aliased
            globals <- globalsOf aliased
            functions <- survivorsOf aliased
            assertEqual
              "the live aliases and ifuncs"
              ["shown", "chain", "middle", "dispatch"]
              indirects
            assertEqual "the live globals" ["target", "deep_target"] globals
            assertEqual "the live functions" ["chooser", "run"] functions
        ]
    , -- A function's body names globals and a global's initializer names
      -- functions, so the two kinds are one graph and a dead chain can cross
      -- between them as often as it likes.  Two passes would each have to run
      -- again whenever the other found something; these say that one walk of
      -- the one graph reaches the end of such a chain the first time.
      testGroup
        "functions and globals are one graph"
        [ testCase "a function only a dead global names goes" $ do
            kept <- survivorsOf crossing
            assertBool ("expected no dead_link in " <> show kept) ("dead_link" `notElem` kept)
        , testCase "a global only a dead function reads goes" $ do
            kept <- globalsOf crossing
            assertBool ("expected no dead_read in " <> show kept) ("dead_read" `notElem` kept)
        , testCase "and a live chain crossing the same way survives" $ do
            functions <- survivorsOf crossing
            live <- globalsOf crossing
            assertEqual "the live functions" ["live_deep", "live_link", "run"] functions
            assertEqual "the live globals" ["live_chain", "live_read"] live
        ]
    , testGroup
        "what may go when nothing reaches it"
        [ testCase "private" $ removableWhenUnreached (Just LinkPrivate) @?= True
        , testCase "internal" $ removableWhenUnreached (Just LinkInternal) @?= True
        , -- A definition another module owns, never emitted from this one.
          testCase "available_externally" $
            removableWhenUnreached (Just LinkAvailableExternally) @?= True
        , testCase "linkonce" $ removableWhenUnreached (Just LinkLinkOnce) @?= True
        , testCase "linkonce_odr" $ removableWhenUnreached (Just LinkLinkOnceODR) @?= True
        , -- weak differs from linkonce in exactly this: an unreferenced weak
          -- definition may not be discarded, since the linker may pick it for
          -- a symbol another module refers to.
          testCase "weak" $ removableWhenUnreached (Just LinkWeak) @?= False
        , testCase "weak_odr" $ removableWhenUnreached (Just LinkWeakODR) @?= False
        , -- What @llvm.used and @llvm.global_ctors are written with, and so
          -- the reason naming something there keeps it.
          testCase "appending" $ removableWhenUnreached (Just LinkAppending) @?= False
        , testCase "external" $ removableWhenUnreached (Just LinkExternal) @?= False
        , -- No linkage written means external.
          testCase "none written" $ removableWhenUnreached Nothing @?= False
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
    -- The ways a function can be named that are not a call.  The two globals
    -- doing the naming are external, so that each question here is whether the
    -- mention was followed and not whether the thing making it was live —
    -- which, were they internal and unread, they would not be.
    referenced =
      T.unlines
        [ "@table = constant [1 x ptr] [ptr @tabled]"
        , "@offset = constant i64 ptrtoint (ptr @measured to i64)"
        , "@sum_offset = internal global i64 add (i64 ptrtoint (ptr @summed to i64), i64 1)"
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
        , "define internal i32 @summed(i32 %x) {"
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
    -- Every shape of global that has to be judged by what reaches it: two
    -- declarations, an external definition, two internal ones, and a pair
    -- naming only each other.
    globals =
      T.unlines
        [ "@wanted = external global i32"
        , "@unwanted = external global i32"
        , "@shown = global i32 0"
        , "@hidden = internal global i32 0"
        , "@counted = internal global i32 0"
        , "@ping = internal global ptr @pong"
        , "@pong = internal global ptr @ping"
        , ""
        , "define i32 @run() {"
        , "  %a = load i32, ptr @wanted"
        , "  %b = load i32, ptr @counted"
        , "  %c = add i32 %a, %b"
        , "  ret i32 %c"
        , "}"
        ]
    -- Globals nothing reads, each with some further claim on being kept.
    pinned =
      T.unlines
        [ "$kept = comdat any"
        , ""
        , "@kept = linkonce_odr global i32 0, comdat"
        , "@configured = internal externally_initialized global i32 0"
        , "@wired = internal global i32 0"
        , "@llvm.used = appending global [1 x ptr] [ptr @wired], section \"llvm.metadata\""
        , ""
        , "define void @run() {"
        , "  ret void"
        , "}"
        ]
    -- Aliases live and dead, and the symbols whose only mention is one.  Every
    -- expectation here is what LLVM's own globaldce leaves.
    aliased =
      T.unlines
        [ "@target = internal global i32 0"
        , "@shown = alias i32, ptr @target"
        , "@hidden_target = internal global i32 0"
        , "@hidden = internal alias i32, ptr @hidden_target"
        , "@fn_target = internal alias i32 (i32), ptr @kept_fn"
        , "@chain = alias i32, ptr @middle"
        , "@middle = internal alias i32, ptr @deep_target"
        , "@deep_target = internal global i32 0"
        , "@dispatch = ifunc i32 (i32), ptr @chooser"
        , "@quiet = internal ifunc i32 (i32), ptr @unchosen"
        , ""
        , "define internal i32 @kept_fn(i32 %x) {"
        , "  ret i32 %x"
        , "}"
        , ""
        , "define internal ptr @chooser() {"
        , "  ret ptr null"
        , "}"
        , ""
        , "define internal ptr @unchosen() {"
        , "  ret ptr null"
        , "}"
        , ""
        , "define void @run() {"
        , "  ret void"
        , "}"
        ]
    -- A dead chain and a live one, each running global to function to global,
    -- so that neither kind can be settled without the other.
    crossing =
      T.unlines
        [ "@dead_chain = internal constant ptr @dead_link"
        , "@dead_read = internal global i32 0"
        , "@live_chain = internal constant ptr @live_deep"
        , "@live_read = internal global i32 0"
        , ""
        , "define internal void @dead_link() {"
        , "  %v = load i32, ptr @dead_read"
        , "  ret void"
        , "}"
        , ""
        , "define internal void @live_deep() {"
        , "  ret void"
        , "}"
        , ""
        , "define internal void @live_link() {"
        , "  %p = load ptr, ptr @live_chain"
        , "  %v = load i32, ptr @live_read"
        , "  ret void"
        , "}"
        , ""
        , "define void @run() {"
        , "  call void @live_link()"
        , "  ret void"
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

-- | The globals still there, in the order they were written.
globalsOf :: Text -> IO [Text]
globalsOf source = do
  program <- sifted source
  pure
    [ nameText (globalName g)
    | ERetained (Syntax.EGlobal g) <- programEntries program
    ]

-- | The aliases and ifuncs still there, in the order they were written.
indirectsOf :: Text -> IO [Text]
indirectsOf source = do
  program <- sifted source
  pure
    [ nameText (indirectName i)
    | ERetained (Syntax.EIndirect i) <- programEntries program
    ]

sifted :: Text -> IO Program
sifted source = eliminateDeadSymbols . lower <$> expectParse "<inline>" source

-- | What the pass leaves, as written out.
renderedFrom :: Text -> IO [Text]
renderedFrom source = T.lines . renderModule . raise <$> sifted source
