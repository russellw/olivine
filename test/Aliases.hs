-- | Alias definitions.
--
-- Stated as single lines of LLVM that must survive unchanged, as the globals
-- are and for the same reason: the expected syntax tree written out in full
-- would be longer than the line and no more revealing, so the round trip
-- carries the weight and 'fieldTests' pins down the readings a printer bug
-- could otherwise hide.
module Aliases (aliasTests) where

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
emitted :: [Text]
emitted =
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
  , "@a = alias i32, ptr addrspace(1) @g"
  , "@a = alias i32, getelementptr inbounds ([4 x i32], ptr @arr, i64 0, i64 2)"
  , "@a = alias i32, addrspacecast (ptr addrspace(1) @g to ptr)"
  , "@a = alias [4 x i32], ptr @arr"
  ]

-- | Aliases LLVM accepts but writes back differently, so that 'emitted' can
-- honestly claim to be LLVM's own output.  Olivine keeps what was written, so
-- these have to round-trip here unchanged all the same.
accepted :: [Text]
accepted =
  [ -- External linkage is what an alias has when none is written, so LLVM
    -- drops the word.
    "@a = external alias i32, ptr @g"
  , "@a = dso_preemptable alias i32, ptr @g"
  ]

-- | Text that must leave the line opaque rather than be read as some prefix
-- of itself.  The clauses here are ones a global takes and an alias does not,
-- which is the whole reason an alias does not carry a global's attribute list.
rejected :: [Text]
rejected =
  [ "@a = alias i32 ptr @g" -- the comma is not optional
  , "@a = alias i32, ptr @g, align 8"
  , "@a = alias i32, ptr @g, section \"s\""
  , "@a = alias i32, ptr @g, comdat"
  , "@a = addrspace(1) alias i32, ptr @g"
  , "@a = ifunc i32 (i32), ptr @resolver" -- a construct of its own, not read
  ]

aliasTests :: TestTree
aliasTests =
  testGroup
    "aliases"
    [ testGroup
        "round trip"
        [testCase (T.unpack line) (roundTrips line) | line <- emitted <> accepted]
    , testGroup
        "rejected"
        [testCase (T.unpack line) (staysOpaque line) | line <- rejected]
    , fieldTests
    , layoutTests
    ]

-- | Checks that the parts are read as the things they mean, not merely
-- shuffled from input to output.
fieldTests :: TestTree
fieldTests =
  testGroup
    "fields"
    [ testCase "name" $ field aliasName "@a = alias i32, ptr @g" (Name Bare "a")
    , testCase "linkage" $
        field aliasLinkage "@a = internal alias i32, ptr @g" (Just LinkInternal)
    , testCase "no linkage" $ field aliasLinkage "@a = alias i32, ptr @g" Nothing
    , testCase "visibility" $
        field aliasVisibility "@a = hidden alias i32, ptr @g" (Just VisibilityHidden)
    , testCase "thread locality" $
        field
          aliasThreadLocality
          "@a = thread_local(initialexec) alias i32, ptr @g"
          (Just InitialExec)
    , testCase "unnamed address" $
        field
          aliasUnnamedAddr
          "@a = local_unnamed_addr alias i32, ptr @g"
          (Just LocalUnnamedAddr)
    , -- The type the alias gives the symbol, which is not the aliasee's.
      testCase "type" $
        field aliasType "@a = alias [4 x i32], ptr @arr" (TArray 4 (TInteger 32))
    , testCase "aliasee" $
        field aliasAliasee "@a = alias i32, ptr @g" (VGlobal (Name Bare "g"))
    , testCase "partition" $
        field aliasPartition "@a = alias i32, ptr @g, partition \"p\"" (Just "p")
    , testCase "no partition" $
        field aliasPartition "@a = alias i32, ptr @g" Nothing
    , -- Whether the aliasee's type is written is how LLVM says which of the
      -- two kinds of aliasee this is, so it is read rather than assumed: the
      -- address space would be lost by assuming, and a constant expression has
      -- no type written at all.
      testGroup
        "the aliasee's type"
        [ testCase "a symbol has one" $
            field aliasAliaseeType "@a = alias i32, ptr @g" (Just (TPointer Nothing))
        , testCase "with its address space" $
            field
              aliasAliaseeType
              "@a = alias i32, ptr addrspace(1) @g"
              (Just (TPointer (Just 1)))
        , testCase "a constant expression has none" $
            field
              aliasAliaseeType
              "@a = alias i32, addrspacecast (ptr addrspace(1) @g to ptr)"
              Nothing
        ]
    ]

-- | Where the blank lines go.  LLVM writes the aliases as a block of their
-- own, after the globals and before the functions, so a module with all three
-- has a blank line at each seam.
layoutTests :: TestTree
layoutTests =
  testGroup
    "layout"
    [ testCase "aliases are their own block" $ do
        parsed <-
          expectParse
            "<inline>"
            ( T.unlines
                [ "@g = global i32 0"
                , "@h = global i32 1"
                , "@a1 = alias i32, ptr @g"
                , "@a2 = alias i32, ptr @h"
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
            , "define void @f() {"
            , "  ret void"
            , "}"
            ]
    ]

-- | The line must parse to exactly one alias and print back unchanged.
roundTrips :: Text -> Assertion
roundTrips line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EAlias _] -> renderModule parsed @?= line <> "\n"
    entries -> assertFailure ("expected one alias, got " <> show entries)

staysOpaque :: Text -> Assertion
staysOpaque line = do
  parsed <- expectParse "<inline>" (line <> "\n")
  moduleEntries parsed @?= [EOpaque line]

field :: (Show a, Eq a) => (Alias -> a) -> Text -> a -> Assertion
field get line expected = do
  parsed <- expectParse "<inline>" (line <> "\n")
  case moduleEntries parsed of
    [EAlias a] -> get a @?= expected
    entries -> assertFailure ("expected one alias, got " <> show entries)
