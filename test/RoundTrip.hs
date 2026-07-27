-- | The load-bearing test for the ingest/egress layer.
module RoundTrip (roundTripTests) where

import Control.Monad (unless)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (corpusFiles, expectParse, parseCorpusFile, readCorpusFile)
import Olivine.Syntax.Ast (Entry (..), Module (..))
import Olivine.Syntax.Printer (renderModule)

roundTripTests :: IO TestTree
roundTripTests = do
  names <- corpusFiles
  pure $
    testGroup
      "round trip"
      [ testGroup
          "reparsing gives the same syntax tree"
          [testCase name (roundTrip name) | name <- names]
      , testGroup
          "no blank line reaches the syntax tree"
          [testCase name (noBlankEntries name) | name <- names]
      , testGroup
          "the layout written is LLVM's own"
          [testCase name (layoutMatches name) | name <- names]
      , layoutTests
      ]

-- | The layout rule stated on its own, independent of what the corpus
-- happens to contain.
--
-- Each case is written without any blank line at all, so what the printer
-- puts back is what the rule says and not what was carried.
layoutTests :: TestTree
layoutTests =
  testGroup
    "blank lines are put back by rule"
    [ laidOut
        "one kind of construct is separated from the next"
        ["target triple = \"x86_64-pc-linux-gnu\"", "@a = global i32 0"]
        ["target triple = \"x86_64-pc-linux-gnu\"", "", "@a = global i32 0"]
    , laidOut
        "globals run together"
        ["@a = global i32 0", "@b = global i32 1"]
        ["@a = global i32 0", "@b = global i32 1"]
    , laidOut
        "so do metadata nodes"
        ["!0 = !{i32 0}", "!1 = !{i32 1}"]
        ["!0 = !{i32 0}", "!1 = !{i32 1}"]
    , -- LLVM writes a newline before every function, which is why two
      -- declarations have a gap between them and two globals do not.
      laidOut
        "every function is preceded by a blank line"
        ["declare void @a()", "declare void @b()"]
        ["declare void @a()", "", "declare void @b()"]
    , -- A comment introduces what follows it, so the gap goes above the
      -- comment and not between it and its function.
      laidOut
        "a comment keeps the function it introduces"
        ["@a = global i32 0", "; Function Attrs: nounwind", "declare void @b()"]
        ["@a = global i32 0", "", "; Function Attrs: nounwind", "declare void @b()"]
    , laidOut
        "and nothing is written above the first construct"
        ["declare void @a()"]
        ["declare void @a()"]
    ]
  where
    laidOut name written expected = testCase name $ do
      parsed <- expectParse "<inline>" (T.unlines written)
      renderModule parsed @?= T.unlines expected

-- | Parsing, printing and reparsing must reach a fixed point.  Byte-exact
-- output is deliberately not required of an arbitrary input: the printer
-- normalizes the spacing within a line, and it is the abstract syntax that
-- passes have to preserve.
roundTrip :: FilePath -> Assertion
roundTrip name = do
  parsed <- parseCorpusFile name
  reparsed <- expectParse (name <> " (reprinted)") (renderModule parsed)
  unless (parsed == reparsed) $
    assertFailure "reparsing the printed module gave a different syntax tree"

-- | Vertical whitespace is layout, and the tree holds constructs.
--
-- A blank line surviving as an entry is what would make every pass step
-- around one, and what would leave a gap behind wherever a pass removed a
-- construct that stood between two of them.
noBlankEntries :: FilePath -> Assertion
noBlankEntries name = do
  parsed <- parseCorpusFile name
  assertEqual
    "blank lines among the entries"
    []
    [t | EOpaque t <- moduleEntries parsed, T.null (T.strip t)]

-- | The corpus is LLVM's own output, so printing it back must reproduce it to
-- the byte — including the blank lines, which are now regenerated rather than
-- carried.
--
-- This is what checks that the layout rule is LLVM's and not one invented
-- here.  Nothing else can: the round trip above compares syntax trees, and
-- the trees no longer contain the answer.
layoutMatches :: FilePath -> Assertion
layoutMatches name = do
  (source, parsed) <- readCorpusFile name
  unless (renderModule parsed == source) $
    assertFailure (T.unpack (firstDifference source (renderModule parsed)))

-- | Where two renderings first disagree, as a line of each.
firstDifference :: T.Text -> T.Text -> T.Text
firstDifference expected actual =
  case [(n, e, a) | (n, e, a) <- zip3 [1 :: Int ..] left right, e /= a] of
    (n, e, a) : _ ->
      "line " <> T.pack (show n) <> "\nexpected: " <> e <> "\n but got: " <> a
    [] ->
      "one is longer: "
        <> T.pack (show (length left))
        <> " lines against "
        <> T.pack (show (length right))
  where
    left = T.lines expected
    right = T.lines actual
