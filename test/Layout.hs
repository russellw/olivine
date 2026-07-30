-- | Reading @target datalayout@, and what it says about a type.
--
-- Every number here was confirmed against LLVM rather than against the
-- LangRef: a module stating the layout under test, with one function per
-- question written as the @ptrtoint (getelementptr T, ptr null, i32 1)@ idiom
-- for a size and @getelementptr {i8, T}, ptr null, i32 0, i32 1@ for an
-- alignment, put through @opt -passes=instcombine@ so that its own data layout
-- folds them.  @llc@ will not do: it lays the module out for the target it was
-- given and ignores what the module says, which is exactly the difference
-- these tests are about.
--
-- The defaults are worth the most care.  A string that omits a component means
-- LLVM's answer for it, and LLVM's are not all the natural ones — an @i64@ is
-- aligned to four bytes unless the target says otherwise, which is why every
-- real layout string says @i64:64@ — so a plausible guess here would put the
-- fields of a struct in the wrong places on a target that meant the default.
module Layout (layoutTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Numeric.Natural (Natural)
import Test.Tasty
import Test.Tasty.HUnit

import Olivine.Core.Layout
import Olivine.Core.Lower (lower)
import Olivine.Syntax.Name
import Olivine.Syntax.Parser (parseModule, renderParseError)
import Olivine.Syntax.Type

layoutTests :: TestTree
layoutTests =
  testGroup
    "layout"
    [ testGroup
        "what a scalar is"
        [ testCase "an integer is as wide as it says" $ do
            measures x86 (TInteger 32) @?>= (32, 4, 4, 4)
        , -- Three bytes of value in four bytes of storage, and the difference
          -- between them is the whole reason there are three sizes.
          testCase "an odd width is rounded up to bytes and to its alignment" $ do
            measures x86 (TInteger 17) @?>= (17, 3, 4, 4)
        , testCase "an integer wider than any the string names" $ do
            -- @i128:128@ is in the corpus string; without it the answer would
            -- be the widest one named, which is what the bare module below
            -- checks.
            measures x86 (TInteger 128) @?>= (128, 16, 16, 16)
        , testCase "a double" $ measures x86 (TFloat FDouble) @?>= (64, 8, 8, 8)
        , -- Eighty bits of value in sixteen bytes of storage on the one target
          -- that has it, which @f80:128@ is what says.
          testCase "x86_fp80" $ measures x86 (TFloat FX86FP80) @?>= (80, 10, 16, 16)
        , testCase "a pointer is as wide as the layout says" $ do
            measures x86 (TPointer Nothing) @?>= (64, 8, 8, 8)
        , -- @p270:32:32@, one of the segment address spaces x86 names.
          testCase "a pointer in another address space" $ do
            measures x86 (TPointer (Just 270)) @?>= (32, 4, 4, 4)
        , testCase "and one the string says nothing about" $ do
            measures x86 (TPointer (Just 9)) @?>= (64, 8, 8, 8)
        ]
    , testGroup
        "what an aggregate is"
        [ -- Bit packed, unlike an array: eight @i1@s are eight bits and one
          -- byte, not eight bytes.
          testCase "a vector is its elements with no padding" $ do
            measures x86 (TVector FixedWidth 8 (TInteger 1)) @?>= (8, 1, 1, 1)
        , -- Twelve bytes of value, aligned to sixteen because the string names
          -- no vector that size and the fallback is the next power of two.
          testCase "a vector of a width the string does not name" $ do
            measures x86 (TVector FixedWidth 3 (TInteger 32)) @?>= (96, 12, 16, 16)
        , testCase "an array is as aligned as one element" $ do
            measures x86 (TArray 3 (TInteger 8)) @?>= (24, 3, 3, 1)
        , testCase "and strides by the whole of one" $ do
            measures x86 (TArray 3 (TFloat FX86FP80)) @?>= (384, 48, 48, 16)
        , testCase "a struct is padded to what its members want" $ do
            measures x86 (TStruct Unpacked [TInteger 8, TInteger 32, TInteger 16])
              @?>= (96, 12, 12, 4)
        , testCase "and a packed one is not padded at all" $ do
            measures x86 (TStruct Packed [TInteger 8, TInteger 32, TInteger 16])
              @?>= (56, 7, 7, 1)
        , testCase "a named type is what it stands for" $ do
            measures x86 (TNamed (Name Bare "pair")) @?>= (64, 8, 8, 4)
        , testCase "and a nested one is measured where it lands" $ do
            measures x86 (TNamed (Name Bare "outer")) @?>= (192, 24, 24, 8)
        , -- A struct cannot hold itself, but two definitions can name each
          -- other, and measuring one must answer rather than run forever.
          testCase "a cycle through the named types is declined" $ do
            measures x86 (TNamed (Name Bare "loop")) @?= Nothing
        , testCase "a type nothing holds has no size" $ do
            measures x86 TVoid @?= Nothing
            measures x86 (TNamed (Name Bare "opaque")) @?= Nothing
            measures x86 (TVector Scalable 4 (TInteger 32)) @?= Nothing
        ]
    , testGroup
        "where a field begins"
        [ testCase "after the padding the one before it wanted" $ do
            offsets x86 (TStruct Unpacked [TInteger 8, TInteger 32, TInteger 16])
              @?= [Just 0, Just 4, Just 8, Nothing]
        , testCase "and immediately, where the struct is packed" $ do
            offsets x86 (TStruct Packed [TInteger 8, TInteger 32, TInteger 16])
              @?= [Just 0, Just 1, Just 5, Nothing]
        , testCase "in a struct holding a struct" $ do
            offsets x86 (TNamed (Name Bare "outer")) @?= [Just 0, Just 4, Just 16, Nothing]
        , testCase "nothing that is not a struct has one" $ do
            offsets x86 (TArray 4 (TInteger 32)) @?= [Nothing, Nothing, Nothing, Nothing]
        ]
    , testGroup
        "what the string leaves out"
        [ -- The default that would be guessed wrong: LLVM aligns an @i64@ to
          -- four bytes unless the target says otherwise.
          testCase "an i64 is aligned to four bytes" $ do
            measures bare (TInteger 64) @?>= (64, 8, 8, 4)
        , testCase "so a struct holding one is smaller than on x86" $ do
            offsets bare (TStruct Unpacked [TInteger 8, TInteger 64])
              @?= [Just 0, Just 4, Nothing, Nothing]
            measures bare (TStruct Unpacked [TInteger 8, TInteger 64]) @?>= (96, 12, 12, 4)
        , -- A double is aligned to eight by default, an i64 is not: they are
          -- separate components and only one of them was left out of the list
          -- of natural answers.
          testCase "a double is aligned to eight" $ do
            measures bare (TFloat FDouble) @?>= (64, 8, 8, 8)
        , testCase "an integer wider than any named takes the widest" $ do
            measures bare (TInteger 128) @?>= (128, 16, 16, 4)
        , testCase "a pointer is sixty four bits" $ do
            measures bare (TPointer Nothing) @?>= (64, 8, 8, 8)
        ]
    , testGroup
        "what else the string can say"
        [ -- @a:@ is a floor under every aggregate's alignment, and the size is
          -- rounded to the same number the struct is aligned to — so a struct
          -- holding one byte is eight bytes here, padding and all.
          testCase "an alignment asked of every aggregate" $ do
            measures aggregate (TStruct Unpacked [TInteger 8]) @?>= (64, 8, 8, 8)
            measures aggregate (TStruct Unpacked [TInteger 8, TInteger 32, TInteger 16])
              @?>= (128, 16, 16, 8)
        , testCase "which a packed struct is not subject to" $ do
            measures aggregate (TStruct Packed [TInteger 8]) @?>= (8, 1, 1, 1)
        , testCase "an array of them is not either" $ do
            measures aggregate (TArray 4 (TInteger 8)) @?>= (32, 4, 4, 1)
        ]
    , testGroup
        "what is not read"
        [ testCase "a module with no layout line" $ do
            layoutIn (T.unlines ["define void @f() {", "entry:", "  ret void", "}"])
              @?= Nothing
        , -- A component this does not know could be one that moves a field, so
          -- the answer to a string holding one is that there is no layout
          -- rather than a layout that passed over it.
          testCase "a component that is not one of these" $ do
            layoutIn (module' "e-i64:64-wat:3" "") @?= Nothing
        , testCase "an alignment that is not a whole number of bytes" $ do
            layoutIn (module' "e-i64:12" "") @?= Nothing
        , -- The components that say nothing about a type are recognized and
          -- dropped, which is what lets the one above be told from them.
          testCase "and the ones that say nothing about a type" $ do
            fmap (const ()) (layoutIn (module' corpusSpec "")) @?= Just ()
        ]
    ]
  where
    x86 = module' corpusSpec types
    bare = module' "e" types
    aggregate = module' "e-a:64:64" types

    types =
      T.unlines
        [ "%pair = type { i32, i32 }"
        , "%outer = type { i8, %pair, double }"
        , "%loop = type { %knot }"
        , "%knot = type { %loop }"
        , "%opaque = type opaque"
        ]

-- | The layout string every corpus file states, which is what clang writes for
-- @x86_64-unknown-linux-gnu@.
corpusSpec :: Text
corpusSpec =
  "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

module' :: Text -> Text -> Text
module' spec types =
  T.unlines
    [ "target datalayout = \"" <> spec <> "\""
    , types
    , "define void @f() {"
    , "entry:"
    , "  ret void"
    , "}"
    ]

-- | Everything about a type at once: the bits it has, the bytes an access to
-- it touches, the bytes one of them takes in an array, and what it is aligned
-- to.
--
-- Asked together because a mistake in one is usually a mistake in another —
-- an alignment read wrongly moves the stride and not the size — and reading
-- all four says which.
measures :: Text -> Type -> Maybe (Natural, Natural, Natural, Natural)
measures source t = do
  layout <- layoutIn source
  bits <- sizeInBits layout t
  store <- storeSize layout t
  alloc <- allocSize layout t
  align <- alignmentOf layout t
  pure (bits, store, alloc, align)

-- | Where each of the first three fields begins, and then one field past the
-- end, which nothing has.
offsets :: Text -> Type -> [Maybe Natural]
offsets source t = [layoutIn source >>= \layout -> fieldOffset layout t k | k <- [0 .. 3]]

-- | The layout of a module written out here.
--
-- Pure, unlike the corpus tests, so that a table of expected numbers reads as
-- one.  A module that does not parse raises rather than answering Nothing:
-- half of these ask for Nothing, and a typo in the source would otherwise be
-- indistinguishable from the answer they want.
layoutIn :: Text -> Maybe Layout
layoutIn source =
  layoutOf (either (error . renderParseError) lower (parseModule "<inline>" source))

infix 1 @?>=

-- | As '@?=', for the four numbers, so that a failure names the type.
(@?>=) :: Maybe (Natural, Natural, Natural, Natural) -> (Natural, Natural, Natural, Natural) -> Assertion
actual @?>= expected = actual @?= Just expected
