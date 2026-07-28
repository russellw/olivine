-- | Alias and ifunc definitions.
--
-- Stated as single lines of LLVM that must survive unchanged, as the globals
-- are and for the same reason: the expected syntax tree written out in full
-- would be longer than the line and no more revealing, so the round trip
-- carries the weight and 'fieldTests' pins down the readings a printer bug
-- could otherwise hide.
--
-- The two are one construct in the syntax layer, so the lists below are what
-- says they are not being confused: every spelling is checked to come back as
-- the kind it was written with.
module Indirects (indirectTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Global
import Olivine.Syntax.Linkage
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type
import Olivine.Syntax.Value

-- | Aliases in the spelling LLVM itself emits: every line here was fed to
-- @opt -S@, which echoed it back character for character.
emittedAliases :: [Text]
emittedAliases =
  [ "@a = alias i32, ptr @g"
  , -- The linkages an alias may carry.  LLVM rejects the rest outright:
    -- available_externally, common, appending and extern_weak are all errors
    -- here, an alias being a definition that owns no storage.
    "@a = private alias i32, ptr @g"
  , "@a = internal alias i32, ptr @g"
  , "@a = weak alias i32, ptr @g"
  , "@a = weak_odr alias i32, ptr @g"
  , "@a = linkonce alias i32, ptr @g"
  , "@a = linkonce_odr alias i32, ptr @g"
  , -- The rest of the modifier sequence, in LLVM's order.
    "@a = dso_local alias i32, ptr @g"
  , "@a = hidden alias i32, ptr @g"
  , "@a = protected alias i32, ptr @g"
  , "@a = dllexport alias i32, ptr @g"
  , "@a = thread_local alias i32, ptr @g"
  , "@a = thread_local(localdynamic) alias i32, ptr @g"
  , "@a = thread_local(initialexec) alias i32, ptr @g"
  , "@a = unnamed_addr alias i32, ptr @g"
  , "@a = local_unnamed_addr alias i32, ptr @g"
  , "@a = hidden thread_local alias i32, ptr @g"
  , "@a = weak_odr protected dllexport thread_local(localexec) local_unnamed_addr alias i32, ptr @g"
  , -- The one trailing clause an alias takes.
    "@a = alias i32, ptr @g, partition \"p\""
  , -- What is aliased: a function as readily as a variable, another alias,
    -- and an address computed from one.
    "@a = alias i32 (i32), ptr @f"
  , "@a = alias i32, ptr @other"
  , "@a = alias i32, ptr addrspace(1) @gs"
  , "@a = alias i32, getelementptr inbounds ([4 x i32], ptr @arr, i64 0, i64 2)"
  , "@a = alias i32, addrspacecast (ptr addrspace(1) @gs to ptr)"
  , "@a = alias [4 x i32], ptr @arr"
  ]

-- | The same for ifuncs, whose grammar is an alias's with the other keyword.
emittedIFuncs :: [Text]
emittedIFuncs =
  [ "@i = ifunc i32 (i32), ptr @res"
  , "@i = private ifunc i32 (i32), ptr @res"
  , "@i = internal ifunc i32 (i32), ptr @res"
  , "@i = weak ifunc i32 (i32), ptr @res"
  , "@i = weak_odr ifunc i32 (i32), ptr @res"
  , "@i = linkonce ifunc i32 (i32), ptr @res"
  , "@i = linkonce_odr ifunc i32 (i32), ptr @res"
  , "@i = dso_local ifunc i32 (i32), ptr @res"
  , "@i = hidden ifunc i32 (i32), ptr @res"
  , "@i = protected ifunc i32 (i32), ptr @res"
  , "@i = ifunc i32 (i32), ptr @res, partition \"p\""
  , "@i = ifunc i32 (i32), ptr addrspace(1) @res1"
  , "@i = weak_odr protected ifunc i32 (i32), ptr @res"
  ]

-- | Accepted, but written back differently, so that the lists above can
-- honestly claim to be LLVM's own output.  Olivine keeps what was written, so
-- these have to round-trip here unchanged all the same.
accepted :: [Text]
accepted =
  [ -- External linkage is what these have when none is written, so LLVM drops
    -- the word.
    "@a = external alias i32, ptr @g"
  , "@i = external ifunc i32 (i32), ptr @res"
  , "@a = dso_preemptable alias i32, ptr @g"
  , -- LLVM parses these on an ifunc and then drops them, having nowhere in
    -- its model of one to put them — where on an alias it keeps all three.
    "@i = dllexport ifunc i32 (i32), ptr @res"
  , "@i = thread_local ifunc i32 (i32), ptr @res"
  , "@i = unnamed_addr ifunc i32 (i32), ptr @res"
  , "@i = local_unnamed_addr ifunc i32 (i32), ptr @res"
  ]

-- | Text that must leave the line opaque rather than be read as some prefix
-- of itself.  The clauses here are ones a global takes and these do not,
-- which is the whole reason they carry no attribute list.
rejected :: [Text]
rejected =
  [ "@a = alias i32 ptr @g" -- the comma is not optional
  , "@a = alias i32, ptr @g, align 8"
  , "@a = alias i32, ptr @g, section \"s\""
  , "@a = alias i32, ptr @g, comdat"
  , "@a = addrspace(1) alias i32, ptr @g"
  , "@i = ifunc i32 (i32), ptr @res, align 8"
  , "@i = ifunc i32 (i32), ptr @res, comdat"
  , "@i = addrspace(1) ifunc i32 (i32), ptr @res"
  , "@i = ifunc i32 (i32) ptr @res"
  ]

indirectTests :: TestTree
indirectTests =
  testGroup
    "aliases and ifuncs"
    [ testGroup
        "round trip"
        [ testCase (T.unpack line) (roundTrips line)
        | line <- emittedAliases <> emittedIFuncs <> accepted
        ]
    , testGroup
        "rejected"
        [testCase (T.unpack line) (staysOpaque line) | line <- rejected]
    , -- The one thing the shared representation could get wrong that two
      -- types could not.
      testGroup
        "the keyword says which kind it is"
        [ testCase "alias" $
            field indirectKind "@a = alias i32, ptr @g" IndirectAlias
        , testCase "ifunc" $
            field indirectKind "@i = ifunc i32 (i32), ptr @res" IndirectIFunc
        , testCase "and modifiers do not confuse it" $
            field
              indirectKind
              "@i = weak_odr protected ifunc i32 (i32), ptr @res"
              IndirectIFunc
        ]
    , fieldTests
    , layoutTests
    ]

-- | Checks that the parts are read as the things they mean, not merely
-- shuffled from input to output.
fieldTests :: TestTree
fieldTests =
  testGroup
    "fields"
    [ testCase "name" $ field indirectName "@a = alias i32, ptr @g" (Name Bare "a")
    , testCase "linkage" $
        field indirectLinkage "@a = internal alias i32, ptr @g" (Just LinkInternal)
    , testCase "no linkage" $ field indirectLinkage "@a = alias i32, ptr @g" Nothing
    , testCase "visibility" $
        field indirectVisibility "@a = hidden alias i32, ptr @g" (Just VisibilityHidden)
    , testCase "thread locality" $
        field
          indirectThreadLocality
          "@a = thread_local(initialexec) alias i32, ptr @g"
          (Just InitialExec)
    , testCase "unnamed address" $
        field
          indirectUnnamedAddr
          "@a = local_unnamed_addr alias i32, ptr @g"
          (Just LocalUnnamedAddr)
    , -- The type the symbol is given, which is not the target's.
      testCase "type" $
        field indirectType "@a = alias [4 x i32], ptr @arr" (TArray 4 (TInteger 32))
    , testCase "aliasee" $
        field indirectTarget "@a = alias i32, ptr @g" (VGlobal (Name Bare "g"))
    , testCase "resolver" $
        field indirectTarget "@i = ifunc i32 (i32), ptr @res" (VGlobal (Name Bare "res"))
    , testCase "partition" $
        field indirectPartition "@a = alias i32, ptr @g, partition \"p\"" (Just "p")
    , testCase "no partition" $
        field indirectPartition "@a = alias i32, ptr @g" Nothing
    , -- Whether the target's type is written is how LLVM says which of the two
      -- kinds of target this is, so it is read rather than assumed: the
      -- address space would be lost by assuming, and a constant expression has
      -- no type written at all.
      testGroup
        "the target's type"
        [ testCase "a symbol has one" $
            field indirectTargetType "@a = alias i32, ptr @g" (Just (TPointer Nothing))
        , testCase "with its address space" $
            field
              indirectTargetType
              "@a = alias i32, ptr addrspace(1) @gs"
              (Just (TPointer (Just 1)))
        , testCase "a constant expression has none" $
            field
              indirectTargetType
              "@a = alias i32, addrspacecast (ptr addrspace(1) @gs to ptr)"
              Nothing
        , -- LLVM's verifier wants a function here and would reject this, which
          -- is a judgement on the program rather than on the grammar, so the
          -- syntax layer reads it back the way it reads back every other thing
          -- a verifier would refuse.
          testCase "an ifunc is read the same way" $
            field
              indirectTargetType
              "@i = ifunc i32 (i32), getelementptr inbounds ([4 x ptr], ptr @t, i64 0, i64 1)"
              Nothing
        ]
    ]

-- | Where the blank lines go.  LLVM writes the aliases as a block of their
-- own after the globals, and the ifuncs as another after those, so a module
-- with all four kinds has a blank line at each seam.
layoutTests :: TestTree
layoutTests =
  testGroup
    "layout"
    [ testCase "each kind is its own block" $ do
        parsed <-
          expectParse
            "<inline>"
            ( T.unlines
                [ "@g = global i32 0"
                , "@h = global i32 1"
                , "@a1 = alias i32, ptr @g"
                , "@a2 = alias i32, ptr @h"
                , "@i1 = ifunc i32 (i32), ptr @res"
                , "define void @f() {"
                , "  ret void"
                , "}"
                ]
            )
        renderModule parsed
          @?= T.unlines
            [ "@g = global i32 0"
            , "@h = global i32 1"
            , ""
            , "@a1 = alias i32, ptr @g"
            , "@a2 = alias i32, ptr @h"
            , ""
            , "@i1 = ifunc i32 (i32), ptr @res"
            , ""
            , "define void @f() {"
            , "  ret void"
            , "}"
            ]
    ]

-- | The line must parse to exactly one of these and print back unchanged.
roundTrips :: Text -> Assertion
roundTrips line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EIndirect _] -> renderModule parsed @?= line <> "\n"
    entries -> assertFailure ("expected one alias or ifunc, got " <> show entries)

staysOpaque :: Text -> Assertion
staysOpaque line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  moduleEntries parsed @?= [EOpaque line]

field :: (Show a, Eq a) => (IndirectSymbol -> a) -> Text -> a -> Assertion
field get line expected = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EIndirect s] -> get s @?= expected
    entries -> assertFailure ("expected one alias or ifunc, got " <> show entries)
