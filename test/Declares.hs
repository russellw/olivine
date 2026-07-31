-- | Function declarations and the parameter attribute vocabulary.
--
-- As with the globals, most of this is stated as a line of LLVM that has to
-- survive unchanged, with 'fieldTests' pinning down the readings a printer
-- bug could otherwise hide.
module Declares (declareTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Attribute
import Olivine.Syntax.Function
import Olivine.Syntax.Linkage
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type

-- | Declarations in the spelling LLVM itself emits: every line here was fed
-- to @opt -S@, which echoed it back character for character.
--
-- The lines carrying an attribute group reference were checked differently.
-- LLVM renumbers those groups when it prints, assigning indices from zero in
-- order of first use, so a line lifted out of its module comes back as @#0@
-- whatever it started as.  Those are corpus lines, and they are verified in
-- place instead: @opt -S@ over the whole file reproduces them unchanged,
-- numbering and all.
emitted :: [Text]
emitted =
  [ "declare void @f()"
  , "declare void @f(...)"
  , "declare i32 @f(i32)"
  , -- Return attributes come before the type, parameter attributes after it.
    "declare zeroext i8 @f(i8 signext)"
  , "declare noalias noundef ptr @f(i64 noundef)"
  , "declare void @f(ptr byval(%struct.point))"
  , "declare void @f(ptr sret({ i32, i32 }))"
  , "declare void @f(ptr align 8)"
  , "declare void @f(ptr dereferenceable(16))"
  , "declare void @f(ptr dereferenceable_or_null(16))"
  , "declare void @f(ptr nofree nonnull captures(none))"
  , "declare void @f(ptr captures(address, provenance))"
  , "declare void @f(i32 range(i32 0, 10))"
  , "declare void @f(float nofpclass(nan inf))"
  , "declare void @f(ptr inalloca(i32))"
  , "declare void @f(ptr preallocated(i32))"
  , "declare void @f(ptr byref(i32))"
  , "declare void @f(ptr swiftself)"
  , "declare void @f(ptr dead_on_unwind writable)"
  , "declare void @f(ptr dead_on_return)"
  , "declare void @f(ptr initializes((0, 4)))"
  , "declare void @f(ptr alignstack(8))"
  , "declare void @f(ptr readnone)"
  , "declare void @f(ptr noext)"
  , -- Calling conventions, including the numbered form, which LLVM writes
    -- closed up.
    "declare fastcc void @f()"
  , "declare coldcc void @f()"
  , "declare tailcc void @f()"
  , "declare swiftcc void @f()"
  , "declare cc42 void @f()"
  , "declare hidden void @f()"
  , "declare dllimport void @f()"
  , "declare void @f() unnamed_addr"
  , "declare void @f() local_unnamed_addr #0"
  , -- The shapes clang actually emitted into the corpus.
    "declare i32 @printf(ptr noundef, ...) #1"
  , "declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2"
  , "declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #1"
  , "declare void @free(ptr allocptr noundef captures(none)) local_unnamed_addr #7"
  , "declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #3"
  , "declare void @llvm.va_start.p0(ptr) #10"
  , "declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1"
  , "declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2"
  , -- The header clauses a declaration is allowed: LLVM takes these two and
    -- refuses a personality, which says something about a body.
    "declare void @f() gc \"shadow-stack\""
  , "declare void @f() prefix i32 7"
  ]

-- | Declarations LLVM accepts but writes back differently.  Olivine keeps
-- what was written, so these still round-trip unchanged here; they are
-- separated so that 'emitted' can honestly claim to be LLVM's own output.
accepted :: [Text]
accepted =
  [ -- A declaration's parameter names are dropped on output, having nothing
    -- to name.  Definitions keep theirs, and share this parser.
    "declare i32 @f(i32 %x)"
  , -- LLVM 21 renames this one on the way out.
    "declare void @f(ptr nocapture)"
  , -- An attribute written out on the function is hoisted into a group.
    "declare void @f() nounwind"
  , -- Attributes are reordered into LLVM's canonical order when it prints.
    "declare void @f(ptr writable dead_on_unwind)"
  , "declare void @f() addrspace(1)"
  , "declare void @f(ptr elementtype(i32))"
  ]

-- | Text that must leave the line opaque rather than be parsed as some prefix
-- of itself.  Function attributes written out in full rather than referenced
-- as a group are the boundary of what is modelled.
rejected :: [Text]
rejected =
  [ "declare void @f()) "
  , "declare void @f("
  , "declare @f()" -- the return type is not optional
  , "declare void f()" -- nor is the sigil
  , "declare void @f(ptr captures(none)" -- unbalanced
  ]

declareTests :: TestTree
declareTests =
  testGroup
    "declares"
    [ testGroup
        "round trip"
        [testCase (T.unpack line) (roundTrips line) | line <- emitted <> accepted]
    , testGroup
        "rejected"
        [testCase (T.unpack line) (staysOpaque line) | line <- rejected]
    , fieldTests
    , attachmentTests
    ]

-- | Where a declaration's own metadata attachment stands.
--
-- It is not in 'emitted' because a line carrying one cannot be checked by
-- itself: the node it names has to exist for @llvm-as@ to take the module,
-- and 'roundTrips' reads one entry.  Checked a whole module at a time
-- instead, and by the same rule — @opt -S@ echoes each of these back
-- character for character.  A @!dbg@ was checked separately, since it must
-- name a @DISubprogram@ in a module carrying a compile unit or LLVM discards
-- the debug information rather than echoing it; with one, the @malloc@ line
-- clang writes under @-g@ comes back exactly as clang wrote it.
--
-- The position is the whole of what is being pinned here.  A definition
-- writes its attachments last, after the attribute groups and the clauses; a
-- declaration writes them first, before the return type, and LLVM's parser
-- refuses the other order outright rather than complaining about it.  Every
-- function clang declares under @-g@ carries one, so reading only the
-- definition's position left @malloc@ and @free@ as unread lines in any
-- module compiled with it.
attachmentTests :: TestTree
attachmentTests =
  testGroup
    "a declaration's attachment"
    [ testCase "stands before the return type" $
        module' ["declare !kind !0 void @f()", "", "!0 = !{}"]
    , testCase "before the return attributes as well" $
        module'
          [ "declare !kind !0 noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr"
          , ""
          , "!0 = !{}"
          ]
    , -- The two nodes differ because LLVM uniques metadata: two empty tuples
      -- are one node, and the second attachment would come back naming the
      -- first.
      testCase "more than one of them" $
        module' ["declare !kind !0 !other !1 void @f()", "", "!0 = !{}", "!1 = !{i32 1}"]
    , -- A definition's stay where a definition writes them, which is the
      -- other end of the header.
      testCase "a definition writes its own last" $
        module' ["define void @f() !kind !0 {", "  ret void", "}", "", "!0 = !{}"]
    , -- The order LLVM refuses is a parse error there and an unread line
      -- here, which is this layer's way of saying the same thing.
      testCase "the other order is not read at all" $
        staysOpaque "declare void @f() !kind !0"
    ]

-- | A whole module that must come back exactly as written.
module' :: [Text] -> Assertion
module' written = do
  parsed <- expectParse "<inline>" (T.unlines written)
  renderModule parsed @?= T.unlines written

-- | The declaration itself must come back as written.
--
-- A @; Function Attrs:@ line above it is not part of it.  The printer derives
-- that from the attributes rather than carrying it, which is why it appears
-- here for a declaration whose attributes were written out — LLVM writes the
-- same line — and the rule it is derived by is stated in @test/RoundTrip.hs@.
roundTrips :: Text -> Assertion
roundTrips line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EDeclare _] ->
      filter (not . T.isPrefixOf "; Function Attrs:") (T.lines (renderModule parsed))
        @?= [line]
    entries -> assertFailure ("expected one declaration, got " <> show entries)

staysOpaque :: Text -> Assertion
staysOpaque line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  moduleEntries parsed @?= [EOpaque line]

fieldTests :: TestTree
fieldTests =
  testGroup
    "fields"
    [ testCase "return type" $
        field signatureReturnType "declare i32 @f()" (TInteger 32)
    , testCase "name" $
        field signatureName "declare void @llvm.va_end.p0(ptr)" (Name Bare "llvm.va_end.p0")
    , testCase "return attributes" $
        field
          signatureReturnAttributes
          "declare noalias noundef ptr @f()"
          [PANoAlias, PANoUndef]
    , testCase "parameters" $
        field
          signatureParameters
          "declare void @f(ptr noalias captures(none), i64)"
          [ Parameter (TPointer Nothing) [PANoAlias, PACaptures "none"] Nothing
          , Parameter (TInteger 64) [] Nothing
          ]
    , testCase "a named parameter" $
        field
          signatureParameters
          "declare void @f(i32 %x)"
          [Parameter (TInteger 32) [] (Just (Name Bare "x"))]
    , testCase "fixed arity" $
        field signatureArity "declare void @f(i32)" FixedArity
    , testCase "variadic" $
        field signatureArity "declare i32 @f(ptr, ...)" VariadicArity
    , testCase "variadic with no fixed parameters" $
        field signatureArity "declare i32 @f(...)" VariadicArity
    , testCase "calling convention" $
        field signatureCallingConvention "declare fastcc void @f()" (Just FastCC)
    , testCase "numbered calling convention" $
        field signatureCallingConvention "declare cc42 void @f()" (Just (NumberedCC 42))
    , testCase "unnamed address" $
        field
          signatureUnnamedAddr
          "declare void @f() local_unnamed_addr"
          (Just LocalUnnamedAddr)
    , testCase "attribute groups" $
        field signatureAttributes "declare void @f() #3" [AIGroup 3]
    , testCase "no attributes" $
        field signatureAttributes "declare void @f()" []
    , -- Group references and attributes written out share one slot, so both
      -- have to survive in the order they were written.
      testCase "attributes written out in full" $
        field
          signatureAttributes
          "declare void @f() nounwind #3 cold"
          [AIAttribute FANoUnwind, AIGroup 3, AIAttribute FACold]
    , -- The interior of an attribute whose argument is its own small
      -- language is carried as written.
      testCase "a nested attribute argument" $
        field
          signatureParameters
          "declare void @f(ptr initializes((0, 4), (8, 12)))"
          [Parameter (TPointer Nothing) [PAInitializes "(0, 4), (8, 12)"] Nothing]
    ]

field :: (Show a, Eq a) => (Signature -> a) -> Text -> a -> Assertion
field get line expected = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EDeclare s] -> get s @?= expected
    entries -> assertFailure ("expected one declaration, got " <> show entries)
