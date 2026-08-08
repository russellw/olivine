-- | Block addresses: the one name the core keeps, and what keeps it true.
--
-- A @blockaddress@ names a block of a function, almost always from outside
-- that function — the table a computed @goto@ jumps through is a global.  The
-- core numbers a function's blocks afresh on the way out, so the whole
-- construct turns on two things holding at once: the block has to survive the
-- passes, and whatever names it has to be told what it is called now.
--
-- Both are checked here by asking what comes out, and the syntax verifier is
-- the third check on every case: it now knows that a @blockaddress@ must name
-- a block the function has, which is exactly what goes wrong when a label is
-- carried through unchanged while the blocks around it are renumbered.
module Addresses (addressTests) where

import Data.Foldable (toList)
import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Lower (lower)
import Olivine.Core.Pass.Inline (inlineCalls)
import Olivine.Core.Program
import Olivine.Pipeline (optimize)
import Olivine.Syntax.Ast (Entry (..), Module (..))
import Olivine.Syntax.Function (BasicBlock (..), Definition (..))
import Olivine.Syntax.Global (Global (..))
import Olivine.Syntax.Instruction (Instruction (..), Operation (..))
import Olivine.Syntax.Name (Name (..), Quoting (..))
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Value (TypedValue (..), Value (..), blockAddressesIn)
import Olivine.Syntax.Verify qualified as Syntax

addressTests :: TestTree
addressTests =
  testGroup
    "block addresses"
    [ testGroup
        "what the numbering leaves true"
        [ -- The table names three blocks and the jump lists three
          -- destinations.  They are the same three, whatever the blocks are
          -- called after a trip through the core, and being the same three is
          -- the whole of what makes the program work.
          testCase "a table names the blocks the jump lists" $ do
            m <- optimized threaded
            assertEqual "the table is the destinations" (destinationsIn m) (tableIn m)
        , testCase "and the module comes back well formed" $ acceptable threaded
        , -- The address in a body rather than a global, which is the same
          -- construct with the operand somewhere else.
          testCase "an address written as an operand" $ acceptable held
        ]
    , testGroup
        "what stays put"
        [ -- Both blocks do nothing but branch on, which is what forwarding
          -- removes and merging absorbs.  Neither may happen: something can
          -- still arrive at each without any branch here saying so.
          testCase "a block whose address is taken is not merged away" $ do
            m <- optimized threaded
            assertEqual "three blocks named, three blocks present" 3 (length (tableIn m))
        ]
    , testGroup
        "what folds"
        [ -- @goto *p@ where @p@ was decided a line earlier is the branch the
          -- source meant, and once it is one the addresses are named by
          -- nothing, the blocks stop being pinned and the whole thing
          -- collapses.
          testCase "a jump to one of two addresses becomes a branch" $ do
            m <- optimized eitherWay
            assertEqual "nothing takes an address any more" [] (tableIn m)
        , testCase "and what is left is one block" $ do
            m <- optimized eitherWay
            assertEqual "the branch went with the blocks" 1 (blockCountIn m)
        , testCase "and it is still well formed" $ acceptable eitherWay
        , -- The address of a block of another function is not this function's
          -- to branch to, whatever it holds.
          testCase "a jump to another function's block is left alone" $ do
            m <- optimized elsewhere
            assertBool "the jump is still indirect" (not (null (tableIn m)))
        ]
    , testGroup
        "what is refused"
        [ -- Copying the body would be a second block with the same claim to
          -- the one address.
          testCase "a body whose block address is taken is not inlined" $
            notInlined threaded
        ]
    , testGroup
        "what the verifier says"
        [ testCase "an address of a block that is not there" $ do
            problems <- verified stale
            assertEqual
              "one complaint, naming the block"
              [Syntax.MissingBlockAddress (name "f") (name "nowhere")]
              (map Syntax.problemComplaint problems)
        ]
    ]

optimized :: Text -> IO Module
optimized source = optimize <$> expectParse "<inline>" source

acceptable :: Text -> Assertion
acceptable source = do
  m <- optimized source
  let problems = Syntax.verify m
  assertEqual
    (T.unpack (renderModule m <> T.unlines (map Syntax.renderProblem problems)))
    []
    problems

verified :: Text -> IO [Syntax.Problem]
verified source = Syntax.verify <$> expectParse "<inline>" source

-- | That inlining copies nothing, which is what a callee with a pinned block
-- has to leave true.
notInlined :: Text -> Assertion
notInlined source = do
  program <- lower <$> expectParse "<inline>" source
  assertBool "expected a function" (not (null (functionsIn program)))
  assertEqual "unchanged" program (inlineCalls program)

-- | Every block named by a @blockaddress@ anywhere in the module.
tableIn :: Module -> [Name]
tableIn (Module entries) = concatMap fromEntry entries
  where
    fromEntry (EGlobal g) = map snd (foldMap blockAddressesIn (globalInitializer g))
    fromEntry (EDefine d) =
      [ block
      | b <- definitionBlocks d
      , operand <- operandsOf b
      , (_, block) <- blockAddressesIn (typedValue operand)
      ]
    fromEntry _ = []

-- | Every block an @indirectbr@ in the module lists, in the order listed.
destinationsIn :: Module -> [Name]
destinationsIn (Module entries) =
  [ destination
  | EDefine d <- entries
  , b <- definitionBlocks d
  , IOperation _ (OIndirectBr _ destinations) _ <- blockBody b
  , destination <- destinations
  ]

blockCountIn :: Module -> Int
blockCountIn (Module entries) =
  sum [length (definitionBlocks d) | EDefine d <- entries]

operandsOf :: BasicBlock -> [TypedValue Name]
operandsOf b =
  [ operand
  | IOperation _ operation _ <- blockBody b
  , operand <- toList operation
  ]

name :: Text -> Name
name = Name Bare

-- | A dispatch loop: a static table of three block addresses, and a jump
-- through it.  Each arm does nothing but go round again, so every one of them
-- is a block the graph would otherwise fold away.
threaded :: Text
threaded =
  T.unlines
    [ "@ops = internal constant [3 x ptr] [ptr blockaddress(@run, %a), ptr blockaddress(@run, %b), ptr blockaddress(@run, %c)]"
    , "define i32 @run(ptr %code, i32 %n) {"
    , "entry:"
    , "  %t = getelementptr inbounds ptr, ptr @ops, i64 0"
    , "  %p = load ptr, ptr %t, align 8"
    , "  indirectbr ptr %p, [label %a, label %b, label %c]"
    , "a:"
    , "  br label %out"
    , "b:"
    , "  br label %out"
    , "c:"
    , "  br label %out"
    , "out:"
    , "  ret i32 %n"
    , "}"
    , "define i32 @caller(ptr %code, i32 %n) {"
    , "entry:"
    , "  %r = call i32 @run(ptr %code, i32 %n)"
    , "  ret i32 %r"
    , "}"
    ]

-- | The address taken into a local and jumped through, with no table at all.
held :: Text
held =
  T.unlines
    [ "define i32 @f(ptr %q) {"
    , "entry:"
    , "  store ptr blockaddress(@f, %there), ptr %q, align 8"
    , "  %p = load ptr, ptr %q, align 8"
    , "  indirectbr ptr %p, [label %there, label %elsewhere]"
    , "there:"
    , "  ret i32 1"
    , "elsewhere:"
    , "  ret i32 2"
    , "}"
    ]

-- | @goto *(c ? &&x : &&y)@, which is a conditional branch written the long
-- way.
eitherWay :: Text
eitherWay =
  T.unlines
    [ "define i32 @f(i1 %c) {"
    , "entry:"
    , "  %p = select i1 %c, ptr blockaddress(@f, %high), ptr blockaddress(@f, %low)"
    , "  indirectbr ptr %p, [label %high, label %low]"
    , "high:"
    , "  br label %out"
    , "low:"
    , "  br label %out"
    , "out:"
    , "  %r = phi i32 [ 1, %high ], [ -1, %low ]"
    , "  ret i32 %r"
    , "}"
    ]

-- | An address of a block of another function.  Jumping there is undefined
-- however it was got, so nothing here reads it as a destination.
elsewhere :: Text
elsewhere =
  T.unlines
    [ "define i32 @g(i32 %n) {"
    , "entry:"
    , "  br label %up"
    , "up:"
    , "  ret i32 %n"
    , "down:"
    , "  ret i32 0"
    , "}"
    , "define i32 @f(i1 %c) {"
    , "entry:"
    , "  %p = select i1 %c, ptr blockaddress(@g, %up), ptr blockaddress(@g, %down)"
    , "  indirectbr ptr %p, [label %here, label %there]"
    , "here:"
    , "  ret i32 1"
    , "there:"
    , "  ret i32 2"
    , "}"
    ]

-- | An address naming a block the function does not have, which is what a
-- label carried through a renumbering comes to.
stale :: Text
stale =
  T.unlines
    [ "@t = internal constant [1 x ptr] [ptr blockaddress(@f, %nowhere)]"
    , "define i32 @f() {"
    , "entry:"
    , "  ret i32 0"
    , "}"
    ]
