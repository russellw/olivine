-- | Function definitions: the header, and the basic blocks inside it.
--
-- Instructions are still opaque lines, so what is under test here is the
-- structure around them — where a block begins, which block owns which lines,
-- and the blank line and padded comment LLVM writes around a label.
module Definitions (definitionTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (corpusFiles, expectParse, readCorpusFile)
import Olivine.Syntax.Ast
import Olivine.Syntax.Function
import Olivine.Syntax.Instruction
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)

-- | Definitions in the spelling LLVM itself emits.  The label padding and the
-- blank line between blocks were taken from @opt -S@ output rather than
-- guessed, including the case of a label too wide to leave room for its
-- comment.
emitted :: [Text]
emitted =
  [ T.unlines
      [ "define void @f() {"
      , "  ret void"
      , "}"
      ]
  , -- A named entry block gets neither a preceding blank line nor a comment.
    T.unlines
      [ "define i32 @f(i1 %c) {"
      , "entry:"
      , "  br i1 %c, label %a, label %b"
      , ""
      , "a:                                                ; preds = %entry"
      , "  ret i32 1"
      , ""
      , "b:                                                ; preds = %entry"
      , "  ret i32 2"
      , "}"
      ]
  , -- An unlabelled entry block, which is how LLVM prints numbered blocks.
    T.unlines
      [ "define i32 @f(i1 %0) {"
      , "  br i1 %0, label %2, label %3"
      , ""
      , "2:                                                ; preds = %1"
      , "  ret i32 1"
      , ""
      , "3:                                                ; preds = %1"
      , "  ret i32 2"
      , "}"
      ]
  , -- A label too wide for the comment column, and a block nothing reaches.
    T.unlines
      [ "define i32 @f() {"
      , "  ret i32 0"
      , ""
      , "this.label.is.deliberately.longer.than.fifty.characters.wide: ; No predecessors!"
      , "  ret i32 1"
      , "}"
      ]
  , -- A switch, which spans several lines and so is several opaque
    -- instructions until terminators are modelled.
    T.unlines
      [ "define void @f(i32 %0) {"
      , "  switch i32 %0, label %2 ["
      , "    i32 0, label %3"
      , "    i32 1, label %3"
      , "  ]"
      , ""
      , "2:                                                ; preds = %1"
      , "  ret void"
      , ""
      , "3:                                                ; preds = %1, %1"
      , "  ret void"
      , "}"
      ]
  ]

-- | Definitions Olivine does not model, which must leave every one of their
-- lines opaque rather than half-parse.  These are the header's trailing
-- clauses: valid LLVM, simply not done yet.
rejected :: [Text]
rejected =
  [ T.unlines ["define void @f() personality ptr @g {", "  ret void", "}"]
  , T.unlines ["define void @f() section \"x\" {", "  ret void", "}"]
  , T.unlines ["define void @f() !dbg !0 {", "  ret void", "}"]
  , T.unlines ["define void @f() align 16 {", "  ret void", "}"]
  , -- No closing brace at all.
    T.unlines ["define void @f() {", "  ret void"]
  ]

definitionTests :: IO TestTree
definitionTests = do
  names <- corpusFiles
  pure $
    testGroup
      "definitions"
      [ testGroup
          "round trip"
          [testCase (summarize line) (roundTrips line) | line <- emitted]
      , testGroup
          "rejected"
          [testCase (summarize line) (staysOpaque line) | line <- rejected]
      , fieldTests
      , testGroup
          "corpus"
          [testCase name (corpusStructure name) | name <- names]
      ]

-- | The first line, which is enough to tell these apart in the test listing.
summarize :: Text -> String
summarize = T.unpack . T.takeWhile (/= '\n')

roundTrips :: Text -> Assertion
roundTrips source = do
  parsed <- expectParse "<inline>" source
  case moduleEntries parsed of
    [EDefine _] -> renderModule parsed @?= source
    entries -> assertFailure ("expected one definition, got " <> show entries)

-- Every line has to stay opaque: a definition Olivine cannot read must not be
-- half-parsed into something it will then print differently.
staysOpaque :: Text -> Assertion
staysOpaque source = do
  parsed <- expectParse "<inline>" source
  let entries = moduleEntries parsed
  assertBool
    ("expected only opaque lines, got " <> show entries)
    (all isOpaqueEntry entries)
  renderModule parsed @?= source
  where
    isOpaqueEntry (EOpaque _) = True
    isOpaqueEntry _ = False

fieldTests :: TestTree
fieldTests =
  testGroup
    "fields"
    [ testCase "the signature is the one declarations use" $ do
        d <- definition "define void @f() {\n  ret void\n}\n"
        signatureName (definitionSignature d) @?= Name Bare "f"
    , testCase "an unlabelled entry block" $ do
        d <- definition "define void @f() {\n  ret void\n}\n"
        map blockLabel (definitionBlocks d) @?= [Nothing]
    , testCase "a named entry block" $ do
        d <- definition "define void @f() {\nentry:\n  ret void\n}\n"
        map (fmap blockLabelName . blockLabel) (definitionBlocks d)
          @?= [Just (Name Bare "entry")]
    , testCase "blocks are separated at their labels" $ do
        d <-
          definition $
            T.unlines
              [ "define void @f() {"
              , "  br label %a"
              , ""
              , "a:                                                ; preds = %1"
              , "  br label %b"
              , ""
              , "b:                                                ; preds = %a"
              , "  ret void"
              , "}"
              ]
        map (length . blockBody) (definitionBlocks d) @?= [1, 1, 1]
        map (fmap blockLabelName . blockLabel) (definitionBlocks d)
          @?= [Nothing, Just (Name Bare "a"), Just (Name Bare "b")]
    , testCase "the label comment is kept" $ do
        d <-
          definition $
            T.unlines
              [ "define void @f() {"
              , "  br label %a"
              , ""
              , "a:                                                ; preds = %1"
              , "  ret void"
              , "}"
              ]
        map (blockLabel >=> blockLabelComment) (definitionBlocks d)
          @?= [Nothing, Just "; preds = %1"]
    , -- Indentation travels with the text, since an opaque instruction has no
      -- structure from which it could be regenerated.
      testCase "instructions keep their text and indentation" $ do
        d <-
          definition $
            T.unlines
              [ "define void @f(i32 %0) {"
              , "  switch i32 %0, label %2 ["
              , "    i32 0, label %2"
              , "  ]"
              , ""
              , "2:                                                ; preds = %1, %1"
              , "  ret void"
              , "}"
              ]
        concatMap blockBody (definitionBlocks d)
          @?= [ IOpaque "  switch i32 %0, label %2 ["
              , IOpaque "    i32 0, label %2"
              , IOpaque "  ]"
              , IOpaque "  ret void"
              ]
    ]
  where
    m >=> f = \x -> m x >>= f

-- | Every definition in the file must be parsed as one, with every body line
-- accounted for.  Byte-identical output alone would not show this: it holds
-- just as well when a definition falls back to a run of opaque lines.
corpusStructure :: FilePath -> Assertion
corpusStructure name = do
  (source, parsed) <- readCorpusFile name
  let entries = moduleEntries parsed
      definitions = [d | EDefine d <- entries]
      blocks = concatMap definitionBlocks definitions
      sourceLines = T.lines source
  assertEqual
    "definitions parsed"
    (length (filter ("define" `T.isPrefixOf`) sourceLines))
    (length definitions)
  assertEqual
    "labelled blocks"
    (length (filter isLabelLine sourceLines))
    (length (filter (/= Nothing) (map blockLabel blocks)))
  assertEqual
    "instruction lines"
    (length (bodyLines sourceLines))
    (length (concatMap blockBody blocks))

-- A label line is one starting in the first column and running to a colon,
-- which no instruction does.
isLabelLine :: Text -> Bool
isLabelLine line = case T.uncons line of
  Just (c, _) -> isIdentifierChar c && T.isInfixOf ":" (T.takeWhile (/= ' ') line)
  Nothing -> False

-- The lines between a header and its closing brace that are neither blank nor
-- a label.
bodyLines :: [Text] -> [Text]
bodyLines = go False
  where
    go _ [] = []
    go inside (l : ls)
      | "define" `T.isPrefixOf` l = go True ls
      | l == "}" = go False ls
      | inside && not (T.null l) && not (isLabelLine l) = l : go inside ls
      | otherwise = go inside ls

definition :: Text -> IO Definition
definition source = do
  parsed <- expectParse "<inline>" source
  case moduleEntries parsed of
    [EDefine d] -> pure d
    entries -> assertFailure ("expected one definition, got " <> show entries)
