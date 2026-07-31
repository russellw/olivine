-- | Discarding debug information.
--
-- Each case is a whole module, because that is what the operation is about:
-- what goes is decided by what refers to what, and a line on its own cannot
-- state that.  The expected output was checked against @opt --strip-debug@,
-- which does the same thing to the same input — the module flags it leaves
-- behind included.
--
-- It differs in one way that is not about debug information: LLVM renumbers
-- metadata densely when it prints, so its output has the surviving nodes
-- starting from @!0@ where these keep the numbers they were read under.
-- Olivine writes back what it read, here as everywhere.
module Debug (debugTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Debug (stripDebugInfo)
import Olivine.Syntax.Printer (renderModule)

debugTests :: TestTree
debugTests =
  testGroup
    "debug information"
    [ testGroup
        "what goes"
        [ testCase "a location attached to an instruction" $
            stripped
              ["define void @f() {", "  ret void, !dbg !0", "}", "", "!0 = !DILocation(line: 1, column: 2, scope: !1)", "!1 = distinct !DISubprogram(name: \"f\")"]
              ["define void @f() {", "  ret void", "}"]
        , testCase "the subprogram a definition names" $
            stripped
              ["define void @f() !dbg !0 {", "  ret void", "}", "", "!0 = distinct !DISubprogram(name: \"f\")"]
              ["define void @f() {", "  ret void", "}"]
        , -- The position a declaration writes it in, which is the one clang
          -- uses for every function a -g module declares.
          testCase "the subprogram a declaration names" $
            stripped
              ["declare !dbg !0 void @f()", "", "!0 = distinct !DISubprogram(name: \"f\")"]
              ["declare void @f()"]
        , testCase "the variable a global names" $
            stripped
              ["@g = global i32 0, align 4, !dbg !0", "", "!0 = !DIGlobalVariableExpression(var: !1)", "!1 = distinct !DIGlobalVariable(name: \"g\")"]
              ["@g = global i32 0, align 4"]
        , -- Assignment tracking puts this one in the attachment list beside
          -- !tbaa, so a rule about attachment names rather than about the
          -- node named would have kept it.
          testCase "an assignment identity attached to a store" $
            stripped
              ["define void @f(ptr %p) {", "  store i32 0, ptr %p, !DIAssignID !0", "  ret void", "}", "", "!0 = distinct !DIAssignID()"]
              ["define void @f(ptr %p) {", "  store i32 0, ptr %p", "  ret void", "}"]
        , testCase "the list of compile units" $
            stripped
              ["!llvm.dbg.cu = !{!0}", "", "!0 = distinct !DICompileUnit(language: DW_LANG_C11)"]
              []
        , -- A type list is an ordinary tuple.  Nothing but the debug node
          -- referred to it, and a node nothing refers to is not part of the
          -- program.
          testCase "a plain tuple only a debug node referred to" $
            stripped
              ["declare !dbg !0 void @f()", "", "!0 = distinct !DISubprogram(type: !1)", "!1 = !{null}"]
              ["declare void @f()"]
        ]
    , testGroup
        "what stays"
        [ -- The one that matters: TBAA is what tells the aliasing that a
          -- float store cannot clobber an int load.
          testCase "the type-based aliasing beside a location" $
            stripped
              ["define void @f(ptr %p) {", "  store i32 0, ptr %p, !dbg !0, !tbaa !2", "  ret void", "}", "", "!0 = !DILocation(line: 1, scope: !1)", "!1 = distinct !DISubprogram(name: \"f\")", "!2 = !{!3, !3, i64 0}", "!3 = !{!\"int\"}"]
              ["define void @f(ptr %p) {", "  store i32 0, ptr %p, !tbaa !2", "  ret void", "}", "", "!2 = !{!3, !3, i64 0}", "!3 = !{!\"int\"}"]
        , -- A loop node holds the loop's start and end locations among its
          -- properties, so this one is a rewrite rather than a removal.  It
          -- names itself, which is what the properties are told apart from.
          testCase "a loop's properties, without the loop's locations" $
            stripped
              ["define void @f() {", "  br label %1, !llvm.loop !0", "", "1:", "  ret void", "}", "", "!0 = distinct !{!0, !1, !2, !3}", "!1 = !DILocation(line: 1, scope: !4)", "!2 = !DILocation(line: 9, scope: !4)", "!3 = !{!\"llvm.loop.mustprogress\"}", "!4 = distinct !DISubprogram(name: \"f\")"]
              ["define void @f() {", "  br label %1, !llvm.loop !0", "", "1:", "  ret void", "}", "", "!0 = distinct !{!0, !3}", "!3 = !{!\"llvm.loop.mustprogress\"}"]
        , -- LLVM's own strip leaves these, and a flag describing debug
          -- information that is no longer there says nothing to anybody.
          testCase "the module flags naming a debug format" $
            stripped
              ["!llvm.module.flags = !{!0, !1}", "", "!0 = !{i32 7, !\"Dwarf Version\", i32 5}", "!1 = !{i32 2, !\"Debug Info Version\", i32 3}"]
              ["!llvm.module.flags = !{!0, !1}", "", "!0 = !{i32 7, !\"Dwarf Version\", i32 5}", "!1 = !{i32 2, !\"Debug Info Version\", i32 3}"]
        , -- A construct this layer has not read can name a node as readily
          -- as a construct it has, so its text is asked what it refers to.
          testCase "a node an unread line refers to" $
            stripped
              ["@g = appending global [1 x ptr] zeroinitializer, !unread !0", "!0 = !{i32 1}"]
              ["@g = appending global [1 x ptr] zeroinitializer, !unread !0", "", "!0 = !{i32 1}"]
        , testCase "a module with no debug information at all" $
            stripped
              ["define void @f(ptr %p) {", "  store i32 0, ptr %p, !tbaa !0", "  ret void", "}", "", "!0 = !{!1, !1, i64 0}", "!1 = !{!\"int\"}"]
              ["define void @f(ptr %p) {", "  store i32 0, ptr %p, !tbaa !0", "  ret void", "}", "", "!0 = !{!1, !1, i64 0}", "!1 = !{!\"int\"}"]
        ]
    ]

-- | Strip a module and say what it must come back as.
stripped :: [Text] -> [Text] -> Assertion
stripped written expected = do
  parsed <- expectParse "<inline>" (T.unlines written)
  renderModule (stripDebugInfo parsed) @?= T.unlines expected
