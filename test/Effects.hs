-- | What the whole program says a call does.
--
-- Every case here is one call in one function called @asks@, and what is
-- checked is the four answers 'behaviourOf' gives about it.  The interesting
-- ones are the refusals: an answer that is too strong here is not a wrong
-- number somewhere, it is a load kept across a write, a call removed that had
-- to happen, or a computation moved above the thing that guarded it.
module Effects (effectTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Effects
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Program
import Olivine.Syntax.Function (Signature (..))
import Olivine.Syntax.Name (nameText)

effectTests :: TestTree
effectTests =
  testGroup
    "what a call does"
    [ testGroup
        "read off a body"
        [ testCase "arithmetic and nothing else" $
            behaviourIn (asking "%r = add i32 %0, 3" "ret i32 %r") >>= (@?= nothing)
        , -- The one that makes a function that spills to the stack a function
          -- that writes nothing.  LLVM's own inference calls this memory(none).
          testCase "its own storage written and read back" $
            behaviourIn
              ( asking
                  ( T.unlines
                      [ "  %s = alloca i32"
                      , "  store i32 %0, ptr %s"
                      , "  %r = load i32, ptr %s"
                      ]
                  )
                  "ret i32 %r"
              )
              >>= (@?= nothing)
        , testCase "a global read" $
            behaviourIn (asking "%r = load i32, ptr @counter" "ret i32 %r")
              >>= (@?= nothing {readsMemory = True})
        , testCase "a global written" $
            behaviourIn (asking "store i32 %0, ptr @counter" "ret i32 %0")
              >>= (@?= nothing {writesMemory = True})
        , testCase "a pointer it was handed written through" $
            behaviourIn (asking' "ptr" "store i32 3, ptr %0" "ret i32 0")
              >>= (@?= nothing {writesMemory = True})
        , -- The address got out, so what is written there is not the frame's
          -- own business any more.
          testCase "its own storage after the address escapes" $
            behaviourIn
              ( asking
                  ( T.unlines
                      [ "  %s = alloca i32"
                      , "  store ptr %s, ptr @held"
                      , "  store i32 %0, ptr %s"
                      ]
                  )
                  "ret i32 %0"
              )
              >>= (@?= nothing {writesMemory = True})
        , -- A volatile access is a side effect however narrow the storage.
          testCase "a volatile read of its own storage" $
            behaviourIn
              ( asking
                  ( T.unlines
                      ["  %s = alloca i32", "  %r = load volatile i32, ptr %s"]
                  )
                  "ret i32 %r"
              )
              >>= (@?= nothing {readsMemory = True, writesMemory = True})
        , -- An ordering is where another thread's writes become visible.
          testCase "an atomic read" $
            behaviourIn (asking "%r = load atomic i32, ptr @counter monotonic, align 4" "ret i32 %r")
              >>= (@?= nothing {readsMemory = True, writesMemory = True})
        ]
    , testGroup
        "whether it comes back"
        [ testCase "a loop" $
            (mayNotReturn <$> behaviourIn (counting "")) >>= (@?= True)
        , -- What a language guaranteeing forward progress buys, and only for a
          -- body with nothing observable in the loop.
          testCase "a loop in a function promising progress" $
            (mayNotReturn <$> behaviourIn (counting "mustprogress")) >>= (@?= False)
        , testCase "a loop that writes, in a function promising progress" $
            (mayNotReturn <$> behaviourIn (spinning "mustprogress")) >>= (@?= True)
        , testCase "a function that can reach itself" $
            (mayNotReturn <$> behaviourIn recursive) >>= (@?= True)
        , -- Neither of them writes anything, and neither of them is known to
          -- come back: the optimistic rounds settle the first and the cycle is
          -- held to the second from the start.
          testCase "two functions that call each other" $
            behaviourIn mutual >>= (@?= nothing {mayNotReturn = True})
        ]
    , testGroup
        "read off what is written down"
        [ testCase "a declaration that promises nothing" $
            behaviourIn (declaring "" "") >>= (@?= anything)
        , testCase "a declaration that promises everything" $
            behaviourIn (declaring "memory(none) nounwind willreturn" "") >>= (@?= nothing)
        , testCase "memory(read)" $
            behaviourIn (declaring "memory(read) nounwind willreturn" "")
              >>= (@?= nothing {readsMemory = True})
        , -- Which location a promise is about is not modelled; that it is a
          -- read and not a write is.
          testCase "memory(argmem: read)" $
            behaviourIn (declaring "memory(argmem: read) nounwind willreturn" "")
              >>= (@?= nothing {readsMemory = True})
        , testCase "memory(read, argmem: none)" $
            behaviourIn (declaring "memory(read, argmem: none) nounwind willreturn" "")
              >>= (@?= nothing {readsMemory = True})
        , testCase "memory(argmem: write)" $
            behaviourIn (declaring "memory(argmem: write) nounwind willreturn" "")
              >>= (@?= nothing {writesMemory = True})
        , -- The site's attributes are a promise about this call, so either
          -- place saying it is enough.  LLVM reads them the same way.
          testCase "promised at the call site instead" $
            behaviourIn (declaring "" "memory(none) nounwind willreturn") >>= (@?= nothing)
        , -- A body says what a signature does not, and a signature says what a
          -- body cannot: nothing here writes, and only the attributes rule out
          -- throwing.
          testCase "a body and a promise together" $
            behaviourIn (asking'' "nounwind willreturn" "i32" "%r = add i32 %0, 1" "ret i32 %r")
              >>= (@?= nothing)
        ]
    , testGroup
        "what is not answered for"
        [ -- The linker picks another candidate and it does something else.
          testCase "a body the linker may replace" $
            behaviourIn weakly >>= (@?= anything)
        , testCase "a call through a pointer" $
            behaviourIn indirect >>= (@?= anything)
        , -- Its template is text nothing here reads.
          testCase "inline assembly" $
            behaviourIn assembly >>= (@?= anything)
        , -- The bundle means whatever its tag means, and no tag is understood.
          testCase "a call carrying an operand bundle" $
            behaviourIn bundle >>= (@?= anything)
        ]
    ]

-- | The behaviour of the one call in @\@asks@.
behaviourIn :: Text -> IO Behaviour
behaviourIn source = do
  program <- lower <$> expectParse "<inline>" source
  case [c | f <- functionsIn program, named f, c <- callsOf f] of
    call : _ -> pure (behaviourOf (effectsOf program) call)
    [] -> assertFailure "expected a call in @asks"
  where
    named f = nameText (signatureName (functionSignature f)) == "asks"
    callsOf f =
      [ c
      | b <- functionBlocks f
      , c <-
          [x | i <- blockInstructions b, OCall x <- [instructionOperation i]]
            <> [x | Just x <- [callIn (terminatorTransfer (blockTerminator b))]]
      ]

-- | A caller of a callee whose body is the given instructions.
asking :: Text -> Text -> Text
asking body ret = asking' "i32" body ret

asking' :: Text -> Text -> Text -> Text
asking' parameter body ret = asking'' "" parameter body ret

asking'' :: Text -> Text -> Text -> Text -> Text
asking'' attributes parameter body ret =
  module'
    [ "@counter = global i32 0"
    , "@held = global ptr null"
    , "define internal i32 @callee(" <> parameter <> " %0) " <> attributes <> " {"
    , body
    , "  " <> ret
    , "}"
    , "define i32 @asks(" <> parameter <> " %0) {"
    , "  %r = call i32 @callee(" <> parameter <> " %0)"
    , "  ret i32 %r"
    ]

counting :: Text -> Text
counting attributes = looping attributes "  %s = add i32 %n, 1"

spinning :: Text -> Text
spinning attributes =
  looping attributes (T.unlines ["  store i32 %n, ptr @counter", "  %s = add i32 %n, 1"])

looping :: Text -> Text -> Text
looping attributes work =
  module'
    [ "@counter = global i32 0"
    , "define internal i32 @callee(i32 %0) " <> attributes <> " {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %n = phi i32 [ 0, %entry ], [ %s, %head ]"
    , work
    , "  %c = icmp slt i32 %s, %0"
    , "  br i1 %c, label %head, label %done"
    , "done:"
    , "  ret i32 %n"
    , "}"
    , "define i32 @asks(i32 %0) {"
    , "  %r = call i32 @callee(i32 %0)"
    , "  ret i32 %r"
    ]

recursive :: Text
recursive =
  module'
    [ "define internal i32 @callee(i32 %0) {"
    , "  %c = icmp sgt i32 %0, 0"
    , "  br i1 %c, label %down, label %done"
    , "down:"
    , "  %n = sub i32 %0, 1"
    , "  %r = call i32 @callee(i32 %n)"
    , "  ret i32 %r"
    , "done:"
    , "  ret i32 0"
    , "}"
    , "define i32 @asks(i32 %0) {"
    , "  %r = call i32 @callee(i32 %0)"
    , "  ret i32 %r"
    ]

mutual :: Text
mutual =
  module'
    [ "define internal i32 @callee(i32 %0) {"
    , "  %r = call i32 @other(i32 %0)"
    , "  ret i32 %r"
    , "}"
    , "define internal i32 @other(i32 %0) {"
    , "  %r = call i32 @callee(i32 %0)"
    , "  ret i32 %r"
    , "}"
    , "define i32 @asks(i32 %0) {"
    , "  %r = call i32 @callee(i32 %0)"
    , "  ret i32 %r"
    ]

declaring :: Text -> Text -> Text
declaring promised atSite =
  module'
    [ "declare i32 @callee(i32) " <> promised
    , "define i32 @asks(i32 %0) {"
    , "  %r = call i32 @callee(i32 %0) " <> atSite
    , "  ret i32 %r"
    ]

weakly :: Text
weakly =
  module'
    [ "define weak i32 @callee(i32 %0) {"
    , "  %r = add i32 %0, 1"
    , "  ret i32 %r"
    , "}"
    , "define i32 @asks(i32 %0) {"
    , "  %r = call i32 @callee(i32 %0)"
    , "  ret i32 %r"
    ]

indirect :: Text
indirect =
  module'
    [ "define i32 @asks(ptr %0) {"
    , "  %r = call i32 %0(i32 3)"
    , "  ret i32 %r"
    ]

assembly :: Text
assembly =
  module'
    [ "define i32 @asks(i32 %0) {"
    , "  %r = call i32 asm \"nop\", \"=r,r\"(i32 %0)"
    , "  ret i32 %r"
    ]

bundle :: Text
bundle =
  module'
    [ "declare i32 @callee(i32) memory(none) nounwind willreturn"
    , "define i32 @asks(i32 %0) {"
    , "  %r = call i32 @callee(i32 %0) [ \"deopt\"(i32 %0) ]"
    , "  ret i32 %r"
    ]

-- | The lines of a module, with the last function closed.
module' :: [Text] -> Text
module' ls = T.unlines (ls <> ["}"])
