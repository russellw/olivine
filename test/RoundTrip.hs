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
          "no blank line or comment reaches the syntax tree"
          [testCase name (noLayoutEntries name) | name <- names]
      , testGroup
          "the layout written is LLVM's own"
          [testCase name (layoutMatches name) | name <- names]
      , layoutTests
      , attributeCommentTests
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
    , -- The attribute comment belongs to the function below it, so the gap
      -- goes above the comment and not between it and its declaration.
      laidOut
        "the blank line goes above a function's attribute comment"
        ["@a = global i32 0", "declare void @b() nounwind"]
        [ "@a = global i32 0"
        , ""
        , "; Function Attrs: nounwind"
        , "declare void @b() nounwind"
        ]
    , laidOut
        "and nothing is written above the first construct"
        ["declare void @a()"]
        ["declare void @a()"]
    ]
  where
    laidOut name written expected = testCase name $ do
      parsed <- expectParse "<inline>" (T.unlines written)
      renderModule parsed @?= T.unlines expected

-- | The @; Function Attrs:@ line, stated as the rule that derives it.
--
-- Every line expected here was confirmed by feeding the input to @opt -S@ and
-- reading back what LLVM wrote above the function.  What it lists is the
-- function's attributes with the string ones left out, group references
-- expanded where they stand; a function whose attributes are all strings gets
-- no line, and neither does one with none.
attributeCommentTests :: TestTree
attributeCommentTests =
  testGroup
    "the attribute comment is derived from the attributes"
    [ summarized
        "a group reference is expanded"
        ["declare void @f() #0", "attributes #0 = { nounwind uwtable }"]
        ["; Function Attrs: nounwind uwtable"]
    , summarized
        "an attribute written out is listed where it stands"
        ["declare void @f() nounwind"]
        ["; Function Attrs: nounwind"]
    , summarized
        "a definition gets one as well"
        ["define void @f() #0 {", "  ret void", "}", "attributes #0 = { noinline }"]
        ["; Function Attrs: noinline"]
    , -- The string attributes are how the front end passes target
      -- configuration through, and LLVM leaves them out of the summary.
      summarized
        "string attributes are left out"
        [ "declare void @f() #0"
        , "attributes #0 = { nounwind \"target-cpu\"=\"x86-64\" }"
        ]
        ["; Function Attrs: nounwind"]
    , summarized
        "and a function with nothing else gets no line at all"
        ["declare void @f() #0", "attributes #0 = { \"target-cpu\"=\"x86-64\" }"]
        []
    , summarized
        "nor does one with no attributes"
        ["declare void @f()"]
        []
    , -- LLVM spells stack alignment alignstack=16 inside a group and
      -- alignstack(16) on a function, and the comment is the second of those.
      summarized
        "an attribute spelled one way in a group is spelled the other here"
        ["declare void @f() #0", "attributes #0 = { alignstack=16 }"]
        ["; Function Attrs: alignstack(16)"]
    ]
  where
    summarized name written expected = testCase name $ do
      parsed <- expectParse "<inline>" (T.unlines written)
      filter ("; Function Attrs:" `T.isPrefixOf`) (T.lines (renderModule parsed))
        @?= expected

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

-- | Vertical whitespace is layout, comments restate what is already held, and
-- the tree holds constructs.
--
-- A blank line surviving as an entry is what would make every pass step
-- around one, and what would leave a gap behind wherever a pass removed a
-- construct that stood between two of them.  A comment surviving is worse: it
-- would go on saying what was true of the construct it was written above
-- after a pass had changed it, or after the construct was gone entirely.
noLayoutEntries :: FilePath -> Assertion
noLayoutEntries name = do
  parsed <- parseCorpusFile name
  assertEqual
    "blank lines and comments among the entries"
    []
    [ t
    | EOpaque t <- moduleEntries parsed
    , T.null (T.strip t) || ";" `T.isPrefixOf` T.stripStart t
    ]

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
