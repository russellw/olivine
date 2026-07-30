-- | Function definitions: the header, and the basic blocks inside it.
--
-- What is under test here is the structure around the instructions — where a
-- block begins, which block owns which lines, and the blank line and padded
-- comment LLVM writes around a label.  The instructions themselves are tested
-- in "Terminators" and, while they remain unmodelled, only for being carried
-- through unchanged.
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
import Olivine.Syntax.Value (TypedValue)

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
  , -- The header's trailing clauses, which a function shares with a global.
    T.unlines
      [ "define void @f() section \"x\" align 16 {"
      , "  ret void"
      , "}"
      ]
  , -- And the ones only a function has, in the order LLVM writes them.
    T.unlines
      [ "define void @f() gc \"shadow-stack\" prefix i32 7 prologue i32 8 personality ptr null !kind !0 {"
      , "  ret void"
      , "}"
      ]
  , T.unlines
      [ "define void @f() personality ptr @__gxx_personality_v0 !dbg !10 {"
      , "  ret void"
      , "}"
      ]
  , -- A switch, the one terminator spanning several lines.
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
-- lines opaque rather than half-parse.
rejected :: [Text]
rejected =
  [ -- No closing brace at all.
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
      , layoutTests
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
      -- structure from which it could be regenerated.  A modelled terminator
      -- in the same block has its indentation generated instead.
      --
      -- The opaque lines here are deliberately not LLVM.  Naming a real
      -- instruction would make this test fail every time that family is
      -- modelled, which has already happened twice and says nothing about
      -- what is being checked.
      testCase "opaque instructions keep their text and indentation" $ do
        d <-
          definition $
            T.unlines
              [ "define void @f() {"
              , "    not.an.instruction i32 %0, 1"
              , "  neither.is.this"
              , "  ret void"
              , "}"
              ]
        concatMap blockBody (definitionBlocks d)
          @?= [ IOpaque "    not.an.instruction i32 %0, 1"
              , IOpaque "  neither.is.this"
              , IOperation Nothing (ORet Nothing) []
              ]
    ]
  where
    m >=> f = \x -> m x >>= f

-- | Blank lines and comments inside a body, which are layout there as much as
-- they are between constructs.
--
-- LLVM writes both, and someone writing @.ll@ by hand writes them anywhere at
-- all.  None may reach the tree, and none may cost the definition around it its
-- structure: the lowering reads a definition whole, so a single line left as
-- text keeps the whole function out of the core.
layoutTests :: TestTree
layoutTests =
  testGroup
    "layout in a body"
    [ testCase "a comment on a line of its own is not an instruction" $ do
        d <-
          definition $
            T.unlines
              [ "define void @f() {"
              , "  ; a note somebody wrote"
              , "  ret void"
              , "}"
              ]
        concatMap blockBody (definitionBlocks d)
          @?= [IOperation Nothing (ORet Nothing) []]
    , -- The instruction is what the line says; the comment says nothing the
      -- tree does not already hold.
      testCase "a comment ending an instruction is dropped" $ do
        d <- definition "define void @f() {\n  ret void ; done\n}\n"
        concatMap blockBody (definitionBlocks d)
          @?= [IOperation Nothing (ORet Nothing) []]
    , -- A blank line was read only where LLVM writes one, before a label, so
      -- one anywhere else failed the whole define and left every line opaque.
      testCase "a blank line inside a block does not end it" $ do
        d <-
          definition $
            T.unlines
              [ "define void @f() {"
              , "  %p = alloca i32"
              , ""
              , "  ret void"
              , "}"
              ]
        map (length . blockBody) (definitionBlocks d) @?= [2]
    , testCase "a comment between two blocks joins neither" $ do
        d <-
          definition $
            T.unlines
              [ "define void @f() {"
              , "  br label %a"
              , ""
              , "; what a is for"
              , "a:"
              , "  ret void"
              , "}"
              ]
        map (length . blockBody) (definitionBlocks d) @?= [1, 1]
        map (fmap blockLabelName . blockLabel) (definitionBlocks d)
          @?= [Nothing, Just (Name Bare "a")]
    , testCase "a comment before the closing brace" $ do
        d <- definition "define void @f() {\n  ret void\n  ; that was that\n}\n"
        concatMap blockBody (definitionBlocks d)
          @?= [IOperation Nothing (ORet Nothing) []]
    , -- The one instruction written across several lines, where a comment can
      -- stand between the cases as well as at the end of one.
      testCase "a comment among the cases of a switch" $ do
        d <-
          definition $
            T.unlines
              [ "define void @f(i32 %0) {"
              , "  switch i32 %0, label %2 ["
              , "    i32 0, label %2 ; zero"
              , "    ; and one"
              , "    i32 1, label %2"
              , "  ]"
              , ""
              , "2:                                                ; preds = %1, %1, %1"
              , "  ret void"
              , "}"
              ]
        let switches =
              [ length cases
              | IOperation _ (OSwitch _ _ cases) _ <-
                  concatMap blockBody (definitionBlocks d)
              ]
        switches @?= [2]
    , -- A line Olivine cannot read keeps every character of itself, the comment
      -- included: there is nothing left for either to be regenerated from.
      testCase "an unread line keeps the comment ending it" $ do
        d <-
          definition $
            T.unlines
              [ "define void @f() {"
              , "  not.an.instruction ; with a note"
              , "  ret void"
              , "}"
              ]
        concatMap blockBody (definitionBlocks d)
          @?= [ IOpaque "  not.an.instruction ; with a note"
              , IOperation Nothing (ORet Nothing) []
              ]
    ]

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
  -- A switch absorbs several lines, so body lines and instructions no longer
  -- correspond one to one.  What must hold is that every line beginning with
  -- a terminator keyword became one, and that none was left behind.
  assertEqual
    "terminators parsed"
    (length (filter startsWithTerminator (bodyLines sourceLines)))
    (length [op | IOperation _ op _ <- concatMap blockBody blocks, isTerminator op])
  assertEqual
    "memory operations parsed"
    (length (filter isMemoryLine (bodyLines sourceLines)))
    (length [op | IOperation _ op _ <- concatMap blockBody blocks, isMemory op])
  assertEqual
    "arithmetic and comparisons parsed"
    (length (filter isArithmeticLine (bodyLines sourceLines)))
    (length [op | IOperation _ op _ <- concatMap blockBody blocks, isArithmetic op])
  -- Every instruction in the corpus is now modelled, which is a stronger
  -- statement than any of the checks above and subsumes their opaque halves.
  assertEqual
    "instructions left opaque"
    []
    [raw | IOpaque raw <- concatMap blockBody blocks]

-- A label line is one starting in the first column and running to a colon,
-- which no instruction does.
isLabelLine :: Text -> Bool
isLabelLine line = case T.uncons line of
  Just (c, _) -> isIdentifierChar c && T.isInfixOf ":" (T.takeWhile (/= ' ') line)
  Nothing -> False

isArithmetic :: Operation (TypedValue Name) -> Bool
isArithmetic (OBinary _) = True
isArithmetic (OUnary _) = True
isArithmetic (OICmp _) = True
isArithmetic (OFCmp _) = True
isArithmetic (OConvert _) = True
isArithmetic (OCall _) = True
isArithmetic (OPhi _) = True
isArithmetic (OSelect _) = True
isArithmetic (OExtractElement _) = True
isArithmetic (OInsertElement _) = True
isArithmetic (OShuffleVector _) = True
isArithmetic _ = False

isArithmeticLine :: Text -> Bool
isArithmeticLine = operationKeyword `startsWithAny` keywords
  where
    keywords =
      [ "add ", "sub ", "mul ", "udiv ", "sdiv ", "urem ", "srem "
      , "shl ", "lshr ", "ashr ", "and ", "or ", "xor "
      , "fadd ", "fsub ", "fmul ", "fdiv ", "frem ", "fneg "
      , "icmp ", "fcmp "
      , "trunc ", "zext ", "sext ", "fptrunc ", "fpext ", "fptoui "
      , "fptosi ", "uitofp ", "sitofp ", "ptrtoint ", "inttoptr "
      , "bitcast ", "addrspacecast "
      , "call ", "tail call ", "musttail call ", "notail call "
      , "phi ", "select ", "extractelement ", "insertelement "
      , "shufflevector "
      ]

isMemory :: Operation (TypedValue Name) -> Bool
isMemory (OAlloca _) = True
isMemory (OLoad _) = True
isMemory (OStore _) = True
isMemory (OGetElementPtr _) = True
-- The atomic accesses are memory operations too, and a fence is counted among
-- them although it names no address: what this asks is that a line of the
-- kind became an operation of the kind, not that the kind is tidy.
isMemory (OAtomicLoad _) = True
isMemory (OAtomicStore _) = True
isMemory (OAtomicRmw _) = True
isMemory (OCmpXchg _) = True
isMemory (OFence _) = True
isMemory _ = False

-- An operation either starts the line, as store does, or follows the name it
-- assigns to.
operationKeyword :: Text -> Text
operationKeyword line
  | "%" `T.isPrefixOf` stripped, (_, rest) <- T.breakOn " = " stripped, not (T.null rest) =
      T.drop 3 rest
  | otherwise = stripped
  where
    stripped = T.stripStart line

startsWithAny :: (Text -> Text) -> [Text] -> Text -> Bool
startsWithAny extract keywords line =
  any (`T.isPrefixOf` extract line) keywords

isMemoryLine :: Text -> Bool
isMemoryLine =
  operationKeyword
    `startsWithAny` [ "alloca"
                    , "load "
                    , "store "
                    , "getelementptr "
                    , "atomicrmw "
                    , "cmpxchg "
                    , "fence "
                    ]

-- An invoke is the one terminator that names a result, so this reads through
-- the assignment the way the memory and arithmetic lines are read.
startsWithTerminator :: Text -> Bool
startsWithTerminator =
  operationKeyword
    `startsWithAny` [ "ret "
                    , "ret\n"
                    , "br "
                    , "switch "
                    , "indirectbr "
                    , "unreachable"
                    , "invoke "
                    , "resume "
                    ]

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
