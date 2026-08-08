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

-- | What a body's own access comes to: it may be anywhere, since nothing here
-- works out that what a function reaches through a parameter is only what its
-- caller handed it.  Only a promise written down says otherwise.
anywhere :: Behaviour
anywhere = nothing {behaviourReach = Anywhere}

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
              >>= (@?= anywhere {readsMemory = True})
        , testCase "a global written" $
            behaviourIn (asking "store i32 %0, ptr @counter" "ret i32 %0")
              >>= (@?= anywhere {writesMemory = True})
        , testCase "a pointer it was handed written through" $
            behaviourIn (asking' "ptr" "store i32 3, ptr %0" "ret i32 0")
              >>= (@?= anywhere {writesMemory = True})
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
              >>= (@?= anywhere {writesMemory = True})
        , -- A volatile access is a side effect however narrow the storage.
          testCase "a volatile read of its own storage" $
            behaviourIn
              ( asking
                  ( T.unlines
                      ["  %s = alloca i32", "  %r = load volatile i32, ptr %s"]
                  )
                  "ret i32 %r"
              )
              >>= (@?= anywhere {readsMemory = True, writesMemory = True})
        , -- An ordering is where another thread's writes become visible.
          testCase "an atomic read" $
            behaviourIn (asking "%r = load atomic i32, ptr @counter monotonic, align 4" "ret i32 %r")
              >>= (@?= anywhere {readsMemory = True, writesMemory = True})
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
        , -- The C spelling.  The language promises progress for a loop whose
          -- controlling expression is not a constant rather than for every
          -- loop a function has, so the promise is written a loop at a time:
          -- on the branch that closes it, as a node naming the node the marker
          -- is in.
          testCase "a loop promising progress on its own back edge" $
            (mayNotReturn <$> behaviourIn (promising "llvm.loop.mustprogress")) >>= (@?= False)
        , -- The node is where the unrolling hints are written too, and reading
          -- one of those as a promise would be reading any node as any promise.
          testCase "a loop whose node says something else" $
            (mayNotReturn <$> behaviourIn (promising "llvm.loop.unroll.disable")) >>= (@?= True)
        , testCase "a loop that writes, promising progress on its back edge" $
            (mayNotReturn <$> behaviourIn (promisingWhileWriting "llvm.loop.mustprogress"))
              >>= (@?= True)
        , -- A branch that is not a way round the loop says nothing about
          -- whether it ends, and a reader that took any attachment in the body
          -- for the loop's own would believe an inner loop's promise about an
          -- outer loop.
          testCase "the promise on the branch into the loop" $
            (mayNotReturn <$> behaviourIn (promisingElsewhere "llvm.loop.mustprogress"))
              >>= (@?= True)
        , -- Which is not a hypothetical: every branch of an inner loop is a
          -- branch of the loop around it, so the promise the inner one carries
          -- is inside the outer one's body and belongs to neither the outer
          -- loop nor the question being asked about it.
          testCase "an inner loop promising, inside one that does not" $
            (mayNotReturn <$> behaviourIn (nested attached "")) >>= (@?= True)
        , testCase "both of them promising" $
            (mayNotReturn <$> behaviourIn (nested attached attached)) >>= (@?= False)
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
              >>= (@?= anywhere {readsMemory = True})
        , -- Where the promise is about is read as well as what it promises: a
          -- callee that touches only what its arguments point into cannot
          -- disturb storage it was never handed.
          testCase "memory(argmem: read)" $
            behaviourIn (declaring "memory(argmem: read) nounwind willreturn" "")
              >>= (@?= nothing {readsMemory = True, behaviourReach = OnlyArguments})
        , -- The bare access is the one for every location not named, so this
          -- reads everything except the arguments and reaches anywhere.
          testCase "memory(read, argmem: none)" $
            behaviourIn (declaring "memory(read, argmem: none) nounwind willreturn" "")
              >>= (@?= anywhere {readsMemory = True})
        , testCase "memory(argmem: write)" $
            behaviourIn (declaring "memory(argmem: write) nounwind willreturn" "")
              >>= (@?= nothing {writesMemory = True, behaviourReach = OnlyArguments})
        , -- Storage nothing in the module can address: it writes, which is why
          -- the dead code pass keeps it, and no access written here can alias
          -- it, which is why nothing has to be given up at it.
          testCase "memory(inaccessiblemem: write)" $
            behaviourIn (declaring "memory(inaccessiblemem: write) nounwind willreturn" "")
              >>= (@?= nothing {writesMemory = True, behaviourReach = Unaddressable})
        , testCase "memory(argmem: readwrite, inaccessiblemem: readwrite)" $
            behaviourIn
              (declaring "memory(argmem: readwrite, inaccessiblemem: readwrite) nounwind willreturn" "")
              >>= ( @?=
                      nothing
                        { readsMemory = True
                        , writesMemory = True
                        , behaviourReach = OnlyArguments
                        }
                  )
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
counting attributes = looping attributes step "" "" []

spinning :: Text -> Text
spinning attributes = looping attributes (T.unlines [written, step]) "" "" []

-- | The counting loop with the promise written where C writes it: a node the
-- branch closing the loop names, holding a node that holds the marker.
promising :: Text -> Text
promising marker = looping "" step "" attached (nodes marker)

-- | The same promise, on the branch into the loop rather than the one that
-- closes it.  Nothing is promised about a loop by a branch that is not a way
-- round it.
promisingElsewhere :: Text -> Text
promisingElsewhere marker = looping "" step attached "" (nodes marker)

-- | And on the closing branch of a loop that writes every time round, where
-- what is promised is not that it ends.
promisingWhileWriting :: Text -> Text
promisingWhileWriting marker =
  looping "" (T.unlines [written, step]) "" attached (nodes marker)

-- | A loop inside a loop, with whatever each of them promises on its own back
-- edge.  Both count the same way, so what is being read is which branch the
-- promise is written on rather than what the loop does.
nested :: Text -> Text -> Text
nested inner outer =
  module''
    [ "define internal i32 @callee(i32 %0) {"
    , "entry:"
    , "  br label %outer"
    , "outer:"
    , "  %n = phi i32 [ 0, %entry ], [ %s, %next ]"
    , "  br label %inner"
    , "inner:"
    , "  %m = phi i32 [ 0, %outer ], [ %t, %inner ]"
    , "  %t = add i32 %m, 1"
    , "  %ic = icmp slt i32 %t, %0"
    , "  br i1 %ic, label %inner, label %next" <> inner
    , "next:"
    , "  %s = add i32 %n, 1"
    , "  %c = icmp slt i32 %s, %0"
    , "  br i1 %c, label %outer, label %done" <> outer
    , "done:"
    , "  ret i32 %n"
    , "}"
    , "define i32 @asks(i32 %0) {"
    , "  %r = call i32 @callee(i32 %0)"
    , "  ret i32 %r"
    ]
    (nodes "llvm.loop.mustprogress")

step :: Text
step = "  %s = add i32 %n, 1"

written :: Text
written = "  store i32 %n, ptr @counter"

attached :: Text
attached = ", !llvm.loop !0"

nodes :: Text -> [Text]
nodes marker = ["!0 = distinct !{!0, !1}", "!1 = !{!\"" <> marker <> "\"}"]

looping :: Text -> Text -> Text -> Text -> [Text] -> Text
looping attributes work entering closing trailing =
  module''
    [ "@counter = global i32 0"
    , "define internal i32 @callee(i32 %0) " <> attributes <> " {"
    , "entry:"
    , "  br label %head" <> entering
    , "head:"
    , "  %n = phi i32 [ 0, %entry ], [ %s, %head ]"
    , work
    , "  %c = icmp slt i32 %s, %0"
    , "  br i1 %c, label %head, label %done" <> closing
    , "done:"
    , "  ret i32 %n"
    , "}"
    , "define i32 @asks(i32 %0) {"
    , "  %r = call i32 @callee(i32 %0)"
    , "  ret i32 %r"
    ]
    trailing

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
module' ls = module'' ls []

-- | The same, with metadata nodes written after it.
module'' :: [Text] -> [Text] -> Text
module'' ls trailing = T.unlines (ls <> ["}"] <> trailing)
