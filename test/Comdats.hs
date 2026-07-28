-- | Comdat group definitions, and the clause that puts a symbol in one.
--
-- Stated as single lines of LLVM that must survive unchanged, as the globals
-- are: the expected syntax tree written out in full would be longer than the
-- line and no more revealing, so the round trip carries the weight and
-- 'fieldTests' pins down the readings a printer bug could otherwise hide.
module Comdats (comdatTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Comdat
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)

-- | Definitions in the spelling LLVM itself emits: every line here was fed to
-- @opt -S@, which echoed it back character for character.
emitted :: [Text]
emitted =
  [ "$c = comdat any"
  , "$c = comdat exactmatch"
  , "$c = comdat largest"
  , "$c = comdat nodeduplicate"
  , "$c = comdat samesize"
  , -- A name needing quotes is written the same way here as anywhere else,
    -- the sigil being the only thing that differs.
    "$\"a b\" = comdat any"
  ]

-- | Text that must leave the line opaque rather than be read as some prefix
-- of itself.
rejected :: [Text]
rejected =
  [ "$c = comdat" -- the selection kind is not optional
  , "$c = comdat anything"
  , "$c = any"
  , "$ = comdat any"
  ]

comdatTests :: TestTree
comdatTests =
  testGroup
    "comdats"
    [ testGroup
        "round trip"
        [testCase (T.unpack line) (roundTrips line) | line <- emitted]
    , testGroup
        "rejected"
        [testCase (T.unpack line) (staysOpaque line) | line <- rejected]
    , fieldTests
    , membershipTests
    , layoutTests
    ]

fieldTests :: TestTree
fieldTests =
  testGroup
    "fields"
    [ testCase "name" $ field fst "$c = comdat any" (Name Bare "c")
    , testCase "quoted name" $ field fst "$\"a b\" = comdat any" (Name Quoted "a b")
    , testCase "any" $ field snd "$c = comdat any" SelectAny
    , testCase "exactmatch" $ field snd "$c = comdat exactmatch" SelectExactMatch
    , testCase "largest" $ field snd "$c = comdat largest" SelectLargest
    , testCase "nodeduplicate" $
        field snd "$c = comdat nodeduplicate" SelectNoDeduplicate
    , testCase "samesize" $ field snd "$c = comdat samesize" SelectSameSize
    ]

-- | The clause putting a symbol in a group, which a function carries as
-- readily as a global variable does and writes without the commas.
membershipTests :: TestTree
membershipTests =
  testGroup
    "membership"
    [ testCase label (linesRoundTrip body)
    | (label, body) <-
        [ ("a global", ["@g = global i32 0, section \"s\", comdat($c), align 4"])
        , ("a definition", ["define void @f() comdat($c) {", "  ret void", "}"])
        , ("naming no group", ["define void @f() comdat {", "  ret void", "}"])
        , -- The clauses come after the attribute slot and in the order a
          -- global writes them in, which is what says they are one production
          -- read by one rule.
          ( "among the other clauses"
          , ["define void @f() #0 section \"s\" comdat($c) align 16 {", "  ret void", "}"]
          )
        , -- LLVM rejects a comdat on a declaration, a declaration defining
          -- nothing to put in a group; the other three it accepts.
          ("a declaration", ["declare void @f() section \"s\" partition \"p\" align 8"])
        ]
    ]

-- | Where the blank lines go.  LLVM writes each comdat as a paragraph of its
-- own between the type definitions and the globals, the way it writes each
-- function as one.
layoutTests :: TestTree
layoutTests =
  testGroup
    "layout"
    [ testCase "one paragraph each" $ do
        parsed <-
          expectParse
            "<inline>"
            ( T.unlines
                [ "%struct.s = type { i32 }"
                , "$c = comdat any"
                , "$d = comdat largest"
                , "@g = global i32 0, comdat($c)"
                ]
            )
        renderModule parsed
          @?= T.unlines
            [ "%struct.s = type { i32 }"
            , ""
            , "$c = comdat any"
            , ""
            , "$d = comdat largest"
            , ""
            , "@g = global i32 0, comdat($c)"
            ]
    ]

-- | The line must parse to exactly one comdat and print back unchanged.
roundTrips :: Text -> Assertion
roundTrips line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EComdat _ _] -> renderModule parsed @?= line <> "\n"
    entries -> assertFailure ("expected one comdat, got " <> show entries)

-- | The lines must print back unchanged, with nothing left opaque.
linesRoundTrip :: [Text] -> Assertion
linesRoundTrip body = do
  let source = T.unlines body
  parsed <- expectParse "<inline>" source
  let entries = moduleEntries parsed
  assertBool
    ("expected nothing opaque, got " <> show entries)
    (not (any isOpaque entries))
  renderModule parsed @?= source
  where
    isOpaque (EOpaque _) = True
    isOpaque _ = False

staysOpaque :: Text -> Assertion
staysOpaque line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  moduleEntries parsed @?= [EOpaque line]

field :: (Show a, Eq a) => ((Name, Selection) -> a) -> Text -> a -> Assertion
field get line expected = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EComdat name selection] -> get (name, selection) @?= expected
    entries -> assertFailure ("expected one comdat, got " <> show entries)
