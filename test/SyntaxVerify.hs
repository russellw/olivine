-- | The syntax verifier, on modules that pass and on modules that do not.
--
-- The corpus is the first half, at both ends: every module in it must have
-- nothing wrong with it as clang wrote it and nothing wrong with it as Olivine
-- writes it back.  The first direction says the verifier is not simply wrong
-- about what LLVM accepts — a rule stated too strictly shows up here as a
-- complaint about code a real compiler emitted — and the second is the check
-- on the raising, which is where a phi can end up naming the wrong block.
--
-- The second half is written by stating a module and saying what is wrong with
-- it.  Nothing has to be reached into to do that, unlike the core, because
-- this layer reads back whatever was written: a block with no terminator and a
-- branch to nowhere are things the parser will hand over intact, which is the
-- whole reason the invalid case is representable here.
--
-- Every rule below was confirmed against @llvm-as@ before it was written down,
-- in both directions: the broken module is one LLVM rejects, and the module
-- the silence cases hold is one it accepts.
module SyntaxVerify (syntaxVerifyTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (corpusFiles, expectParse, readCorpusFile)
import Olivine.Pipeline (optimize)
import Olivine.Syntax.Attribute (ParamAttribute (..))
import Olivine.Syntax.Linkage (Linkage (..))
import Olivine.Syntax.Name (Name (..), Quoting (..))
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Verify

syntaxVerifyTests :: IO TestTree
syntaxVerifyTests = do
  names <- corpusFiles
  pure $
    testGroup
      "syntax verify"
      [ testGroup
          "the corpus passes at both ends"
          [testCase name (clean name) | name <- names]
      , moduleTests
      , retainedTests
      , structureTests
      , phiTests
      , localTests
      , silenceTests
      ]

-- | Nothing is wrong with a corpus module as it was written, and nothing is
-- wrong with what the optimizer makes of it.
clean :: FilePath -> Assertion
clean name = do
  (_, parsed) <- readCorpusFile name
  assertEqual "as read" [] (found parsed)
  assertEqual "as written" [] (found (optimize parsed))
  where
    found = map (T.unpack . renderProblem) . verify

-- * What the module has one of

moduleTests :: TestTree
moduleTests =
  testGroup
    "the module"
    [ testCase "a module that is right has nothing wrong with it" $
        expect calling []
    , -- LLVM reads a definition of something already declared as a
      -- redefinition rather than as the body it was waiting for.
      testCase "a symbol declared and then defined" $
        expect
          (["declare i32 @f(i32)", ""] <> calling)
          [RedefinedSymbol (Name Bare "f")]
    , testCase "two globals of one name" $
        expect
          ["@g = global i32 0", "@g = global i32 1"]
          [RedefinedSymbol (Name Bare "g")]
    , -- Each of these is a namespace of its own, which is why they are four
      -- complaints and not one: @$g@ and @\@g@ are unrelated names.
      testCase "two types of one name" $
        expect
          ["%t = type i32", "%t = type i64"]
          [RedefinedType (Name Bare "t")]
    , testCase "two comdats of one name" $
        expect
          ["$c = comdat any", "$c = comdat largest"]
          [RedefinedComdat (Name Bare "c")]
    , testCase "two metadata nodes of one number" $
        expect
          ["!0 = !{}", "!0 = !{i32 1}"]
          [RedefinedMetadata 0]
    , testCase "a call to a symbol the module does not have" $
        expect
          (drop 2 calling)
          [UndefinedSymbol (Name Bare "g")]
    , testCase "a comdat clause naming no group" $
        expect
          ["define void @f() comdat($c) {", "  ret void", "}"]
          [UndefinedComdat (Name Bare "c")]
    , -- A clause written bare names the group the symbol's own name spells,
      -- so what is missing is @$f@ although nothing wrote it.
      testCase "a bare comdat clause with no group of that name" $
        expect
          ["define void @f() comdat {", "  ret void", "}"]
          [UndefinedComdat (Name Bare "f")]
    , testCase "a named node pointing at nothing" $
        expect
          ["!llvm.module.flags = !{!3}", "!0 = !{}"]
          [UndefinedMetadata 3]
    , testCase "an attachment naming no node" $
        expect
          ["define void @f() {", "  ret void, !dbg !7", "}"]
          [UndefinedMetadata 7]
    , testCase "a node whose operand is another that is not there" $
        expect
          ["!0 = !{!1}"]
          [UndefinedMetadata 1]
    ]

-- * What is retained beside the code

retainedTests :: TestTree
retainedTests =
  testGroup
    "what is retained"
    [ -- What the type stopped saying when constants stopped being a type of
      -- their own.
      testCase "an initializer that is not a constant" $
        expect ["@g = global i32 %x"] [InitializerNotConstant]
    , testCase "a linkage promising a definition on a declaration" $
        expect ["declare internal i32 @g(i32)"] [LinkageNotForDeclaration LinkInternal]
    , -- The other direction: the one linkage that says there is no definition,
      -- on something that has one.
      testCase "extern_weak on a definition" $
        expect
          ["define extern_weak i32 @f() {", "  ret i32 0", "}"]
          [LinkageNotForDefinition LinkExternWeak]
    , testCase "a global declared external takes no complaint" $
        expect ["@g = external global i32"] []
    , testCase "a linkage an alias may not take" $
        expect
          ["@g = global i32 0", "@a = common alias i32, ptr @g"]
          [LinkageNotForIndirect LinkCommon]
    , -- An alias may stand for an address computed from a symbol; an ifunc
      -- needs a function it can call.
      testCase "an ifunc resolving through a constant expression" $
        expect
          [ "@r = global [2 x ptr] zeroinitializer"
          , "@i = ifunc i32 (), ptr getelementptr ([2 x ptr], ptr @r, i64 0, i64 1)"
          ]
          [ResolverNotSymbol]
    , testCase "the same computed target on an alias is allowed" $
        expect
          [ "@r = global [2 x ptr] zeroinitializer"
          , "@a = alias ptr, ptr getelementptr ([2 x ptr], ptr @r, i64 0, i64 1)"
          ]
          []
    , -- A declaration and the header of a definition are one production, so
      -- the clause is read either way and judged here.
      testCase "a comdat on a declaration" $
        expect
          ["$c = comdat any", "declare void @f() comdat($c)"]
          [ComdatOnDeclaration]
    , testCase "a parameter attribute in the return position" $
        expect
          ["declare byval(i32) ptr @f()"]
          [AttributeNotOnReturn (PAByVal (TInteger 32))]
    , testCase "the same attribute on a parameter is where it belongs" $
        expect ["declare ptr @f(ptr byval(i32) %p)"] []
    ]

-- * What a function is made of

structureTests :: TestTree
structureTests =
  testGroup
    "structure"
    [ testCase "a definition with no blocks" $
        expect ["define void @f() {", "}"] [NoBlocks]
    , testCase "two blocks with one label" $
        expect
          [ "define i32 @f(i1 %c) {"
          , "entry:"
          , "  br i1 %c, label %a, label %b"
          , "a:"
          , "  ret i32 1"
          , "a:"
          , "  ret i32 2"
          , "b:"
          , "  ret i32 3"
          , "}"
          ]
          [DuplicateBlock (Name Bare "a")]
    , testCase "a block that does not end in a terminator" $
        expect
          ["define void @f() {", "entry:", "  %x = add i32 1, 2", "}"]
          [NoTerminator]
    , -- LLVM's parser takes what follows for a block of its own; Olivine reads
      -- it as the one block it is written as.  The two do not agree on what
      -- the function is, which is worth saying however it is resolved.
      testCase "a terminator with instructions after it" $
        expect
          ["define i32 @f() {", "  ret i32 1", "  ret i32 2", "}"]
          [TerminatorNotLast]
    , testCase "a branch to a block that is not there" $
        expect
          ["define void @f() {", "  br label %nowhere", "}"]
          [MissingBlock (Name Bare "nowhere")]
    , testCase "a branch to the entry block" $
        expect
          [ "define i32 @f(i1 %c) {"
          , "entry:"
          , "  br i1 %c, label %entry, label %a"
          , "a:"
          , "  ret i32 0"
          , "}"
          ]
          [BranchToEntry]
    , testCase "a result named for something that produces none" $
        expect
          ["define void @f(ptr %p) {", "  %x = store i32 0, ptr %p", "  ret void", "}"]
          [ResultOfVoid]
    , testCase "a switch case that is not a constant" $
        expect
          [ "define i32 @f(i32 %x) {"
          , "  switch i32 %x, label %d [ i32 %x, label %d ]"
          , "d:"
          , "  ret i32 0"
          , "}"
          ]
          [CaseNotConstant]
    ]

-- * Where a phi stands and what it is entered from

phiTests :: TestTree
phiTests =
  testGroup
    "phis"
    [ testCase "a phi standing after something else" $
        expect
          [ "define i32 @f(i1 %c) {"
          , "entry:"
          , "  br label %a"
          , "a:"
          , "  %y = add i32 1, 2"
          , "  %x = phi i32 [ 1, %entry ]"
          , "  ret i32 %x"
          , "}"
          ]
          [PhiNotFirst]
    , testCase "an edge the phi has no value for" $
        expect
          [ "define i32 @f(i1 %c) {"
          , "entry:"
          , "  br i1 %c, label %a, label %b"
          , "a:"
          , "  br label %b"
          , "b:"
          , "  %x = phi i32 [ 1, %a ]"
          , "  ret i32 %x"
          , "}"
          ]
          [PhiEntryMissing (Name Bare "entry")]
    , testCase "a value from somewhere that does not branch here" $
        expect
          [ "define i32 @f(i1 %c) {"
          , "entry:"
          , "  br i1 %c, label %a, label %b"
          , "a:"
          , "  ret i32 0"
          , "b:"
          , "  %x = phi i32 [ 1, %entry ], [ 2, %a ]"
          , "  ret i32 %x"
          , "}"
          ]
          [PhiEntryUnexpected (Name Bare "a")]
    , -- Two edges to one block are two entries, however they are written, and
      -- LLVM counts them that way.
      testCase "one entry for two edges from one block" $
        expect
          [ "define i32 @f(i32 %x) {"
          , "entry:"
          , "  switch i32 %x, label %d [ i32 1, label %j i32 2, label %j ]"
          , "j:"
          , "  %p = phi i32 [ 5, %entry ]"
          , "  ret i32 %p"
          , "d:"
          , "  ret i32 0"
          , "}"
          ]
          [PhiEntryMissing (Name Bare "entry")]
    , testCase "two entries for two edges from one block" $
        expect
          [ "define i32 @f(i32 %x) {"
          , "entry:"
          , "  switch i32 %x, label %d [ i32 1, label %j i32 2, label %j ]"
          , "j:"
          , "  %p = phi i32 [ 5, %entry ], [ 6, %entry ]"
          , "  ret i32 %p"
          , "d:"
          , "  ret i32 0"
          , "}"
          ]
          []
    ]

-- * What the locals are and where they reach

localTests :: TestTree
localTests =
  testGroup
    "locals"
    [ testCase "a local assigned twice" $
        expect
          [ "define i32 @f() {"
          , "  %x = add i32 1, 2"
          , "  %x = add i32 3, 4"
          , "  ret i32 %x"
          , "}"
          ]
          [DuplicateLocal (Name Bare "x")]
    , testCase "an operand naming a local nothing defines" $
        expect
          ["define i32 @f() {", "  ret i32 %x", "}"]
          [UndefinedLocal (Name Bare "x")]
    , -- Defined, but below where it is read, so there is no path along which
      -- it has been computed.
      testCase "a local read before it is assigned" $
        expect
          [ "define i32 @f() {"
          , "  %y = add i32 %x, 1"
          , "  %x = add i32 1, 2"
          , "  ret i32 %y"
          , "}"
          ]
          [NotDominated (Name Bare "x")]
    , testCase "a local read on a path that does not pass its definition" $
        expect
          [ "define i32 @f(i1 %c) {"
          , "entry:"
          , "  br i1 %c, label %a, label %b"
          , "a:"
          , "  %x = add i32 1, 2"
          , "  br label %b"
          , "b:"
          , "  ret i32 %x"
          , "}"
          ]
          [NotDominated (Name Bare "x")]
    , -- The same value read where every path has passed its definition, which
      -- is the loop the check has to leave alone: the phi reads what the block
      -- below it assigns, along an edge that leaves after the assignment.
      testCase "a value carried round a loop" $
        expect
          [ "define i32 @f(i32 %n) {"
          , "entry:"
          , "  br label %loop"
          , "loop:"
          , "  %i = phi i32 [ 0, %entry ], [ %next, %loop ]"
          , "  %next = add i32 %i, 1"
          , "  %c = icmp slt i32 %next, %n"
          , "  br i1 %c, label %loop, label %done"
          , "done:"
          , "  ret i32 %i"
          , "}"
          ]
          []
    ]

-- * What it declines to judge

silenceTests :: TestTree
silenceTests =
  testGroup
    "silence"
    [ -- An opaque entry is a line the syntax layer cannot read, and what it
      -- holds may define anything.  So a module with one is not asked which
      -- symbols it has, rather than being asked and answering from what
      -- happens to have been understood.
      testCase "no symbol is missing while an entry is unread" $
        expect
          ["@u = i32 0", "", "define void @f() {", "  call void @h()", "  ret void", "}"]
          []
    , -- The specialized debug nodes are not modelled, so a module compiled
      -- with @-g@ is one whose metadata is mostly unread and referred to by
      -- number all through.  A verifier going by the nodes it understood would
      -- report every one of those references.
      testCase "no node is missing while an entry is unread" $
        expect
          [ "!llvm.dbg.cu = !{!0}"
          , "!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1)"
          , "!1 = !DIFile(filename: \"a.c\", directory: \"/\")"
          ]
          []
    , -- The same rule one level down: an unread line may assign anything.
      testCase "no local is missing while a line is unread" $
        expect
          [ "define i32 @f() {"
          , "  %x = extractvalue { i32 } zeroinitializer, 0"
          , "  ret i32 %y"
          , "}"
          ]
          []
    , -- LLVM numbers a result the source did not name, from a counter this
      -- layer does not keep, so a later reference to one is a name that cannot
      -- be looked up rather than a name that is not there.
      testCase "no local is missing while a result is unnamed" $
        expect
          ["declare i32 @g()", "", "define i32 @f() {", "  call i32 @g()", "  ret i32 %1", "}"]
          []
    , -- A block nothing reaches has no path along which a value could be
      -- missing, which is how LLVM reads it too.
      testCase "a value read in a block nothing reaches" $
        expect
          [ "define i32 @f() {"
          , "entry:"
          , "  br label %e"
          , "dead:"
          , "  %y = add i32 %x, 1"
          , "  ret i32 %y"
          , "e:"
          , "  %x = add i32 1, 2"
          , "  ret i32 %x"
          , "}"
          ]
          []
    ]

-- * A module to state

-- | A call to something declared, which is the smallest module with a symbol
-- reference in it.
calling :: [Text]
calling =
  [ "declare i32 @g(i32)"
  , ""
  , "define i32 @f(i32 %a) {"
  , "  %c = call i32 @g(i32 %a)"
  , "  ret i32 %c"
  , "}"
  ]

-- | Parse a module written inline and say what the verifier makes of it.
expect :: [Text] -> [Complaint] -> Assertion
expect source wanted = do
  parsed <- expectParse "<inline>" (T.unlines source)
  let found = verify parsed
  assertEqual
    (unlines (map (T.unpack . renderProblem) found))
    wanted
    (map problemComplaint found)
