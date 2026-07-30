-- | What the target's data layout says: the byte order, and how big every
-- type is, how it is aligned, and where a struct's fields begin.
--
-- The module's @target datalayout@ line is a string of components separated by
-- @-@ giving the byte order, pointer widths, alignments and index widths.
-- Everything a pass wants to know about memory that is not written in a type
-- is written there, and this is the only place that reads it.
--
-- __The byte order stands alone.__  @e@ or @E@, and no other component can be
-- either, so 'endiannessOf' finds it without parsing the rest and answers for
-- a module whose layout string this module otherwise declines.  It decides
-- which end of a wider value a narrower access at the same address reads,
-- which is the one thing a pass reinterpreting a stored value cannot work out
-- from the types, and it plays no part in any size or offset.  That is why it
-- is a function of the program rather than a field of 'Layout'.
--
-- __A size is a size in a context.__  LLVM has three and they differ, so this
-- has three too: 'sizeInBits' is how many bits the value has, 'storeSize' how
-- many bytes an access to it touches, and 'allocSize' how far apart two of them
-- stand in an array — which is 'storeSize' rounded up to the alignment, and so
-- what a @getelementptr@ strides by.  An @i1@ is one bit, one byte and one
-- byte; an @x86_fp80@ is eighty bits, ten bytes and sixteen.
--
-- __An unreadable component declines the whole string.__  A component this
-- does not recognize could be one that changes where a field lands, so the
-- answer to a module containing one is that there is no layout rather than a
-- layout that ignored it.  Every caller already has to handle a module with no
-- @target datalayout@ line at all — hand written input, and Olivine's own
-- output of it — so declining costs the optimization and not the correctness.
--
-- __The defaults are LLVM's.__  A component the string leaves out is the one
-- LangRef says holds, and those are not all natural: @i64@ is aligned to four
-- bytes unless the target says otherwise, which is why every real
-- @target datalayout@ says @i64:64@.  Guessing sixty four here would put the
-- fields of a struct in the wrong places on a target that meant the default.
module Olivine.Core.Layout
  ( Endianness (..)
  , endiannessOf
  , scalarBits
  , Layout
  , layoutOf
  , sizeInBits
  , storeSize
  , allocSize
  , alignmentOf
  , fieldOffset
  ) where

import Control.Applicative ((<|>))
import Control.Monad (foldM, guard)
import Data.Char (isDigit)
import Data.List (genericDrop, mapAccumL)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Text (Text)
import Data.Text qualified as Text
import Numeric.Natural (Natural)

import Olivine.Core.Program (Entry (..), Program (..), namedTypes)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type
  ( FloatKind (..)
  , Packedness (..)
  , Scalability (..)
  , Type (..)
  , resolveNamed
  )

-- | Which end of a value the byte at its address holds.
data Endianness
  = LittleEndian
  | BigEndian
  deriving (Eq, Show)

-- | The byte order the module was written for, if it says.
--
-- Nothing where there is no @target datalayout@ line or where it omits the
-- component — a module Olivine wrote itself from hand written input is the
-- usual way that happens.  A caller that needs the answer has to decline
-- rather than guess: LLVM has a default, but which one it is is a fact about
-- LLVM's source rather than about the module in hand.
endiannessOf :: Program -> Maybe Endianness
endiannessOf program = lookup' . Text.splitOn "-" =<< specIn program
  where
    lookup' components
      | "e" `elem` components = Just LittleEndian
      | "E" `elem` components = Just BigEndian
      | otherwise = Nothing

-- | How many bits a value of this type is, where that is the type's own
-- business and the same number in a register and in memory.
--
-- Nothing for everything else, which is not only the aggregates: a pointer is
-- as wide as the layout string says, and @x86_fp80@ occupies more bytes in
-- memory than its value has bits, so an access to part of one is a question
-- about padding rather than about the value.  @ppc_fp128@ is a pair of doubles
-- rather than one field of bits and declines for the same reason.
--
-- 'sizeInBits' answers for all of those and this does not, which is the point
-- of it: the caller here is a pass reinterpreting one value as another, and
-- what it needs is that the bits of the type /are/ the value.
scalarBits :: Type -> Maybe Natural
scalarBits (TInteger n) = Just n
scalarBits (TFloat kind) = case kind of
  FHalf -> Just 16
  FBFloat -> Just 16
  FFloat -> Just 32
  FDouble -> Just 64
  FFP128 -> Just 128
  FX86FP80 -> Nothing
  FPPCFP128 -> Nothing
scalarBits _ = Nothing

-- | Everything the module says about how values are laid out.
--
-- The parsed @target datalayout@ string and the module's type definitions,
-- together because neither answers anything alone: a size is a question about
-- a type, and a named type is only a body once the module's definitions have
-- been looked in.
--
-- Alignments here are in bytes, having been checked on the way in to be whole
-- ones; sizes are in bits, as they are written.
data Layout = Layout
  { -- | What a pointer in each address space is, by address space.  Address
    -- space zero is always present, since the layout has a default for it.
    layoutPointers :: Map Natural Pointer
  , -- | The alignment of an integer of each width the string mentions.
    layoutIntegers :: Map Natural Natural
  , layoutFloats :: Map Natural Natural
  , layoutVectors :: Map Natural Natural
  , -- | What an aggregate is aligned to beyond what its members demand.  Zero
    -- by default, which is to say nothing beyond them.
    layoutAggregate :: Natural
  , layoutTypes :: Map Name Type
  }
  deriving (Eq, Show)

-- | How wide a pointer is and what it is aligned to.
--
-- The index width a pointer spec may also carry is not here: it says how wide
-- the integer doing arithmetic on the pointer is, which changes no size and no
-- offset, and a pass that wraps an index would want it stated rather than
-- inferred.
data Pointer = Pointer
  { pointerBits :: Natural
  , pointerAlign :: Natural
  }
  deriving (Eq, Show)

-- | Read the module's layout, or decline.
--
-- Nothing where the module has no @target datalayout@ line, or where it has
-- one this cannot read all of.
layoutOf :: Program -> Maybe Layout
layoutOf program = do
  spec <- specIn program
  foldM component (defaultLayout (namedTypes program)) (Text.splitOn "-" spec)

specIn :: Program -> Maybe Text
specIn program =
  listToMaybe [spec | ERetained (Syntax.ETargetDataLayout spec) <- programEntries program]

-- | What holds where the string does not say, which is LangRef's list.
defaultLayout :: Map Name Type -> Layout
defaultLayout types =
  Layout
    { layoutPointers = Map.singleton 0 (Pointer 64 8)
    , layoutIntegers = Map.fromList [(1, 1), (8, 1), (16, 2), (32, 4), (64, 4)]
    , layoutFloats = Map.fromList [(16, 2), (32, 4), (64, 8), (128, 16)]
    , layoutVectors = Map.fromList [(64, 8), (128, 16)]
    , layoutAggregate = 0
    , layoutTypes = types
    }

-- * Reading the string

-- | One component of the layout string, or Nothing if it is not one this
-- knows.
--
-- The ones that change nothing here are recognized and dropped rather than
-- passed over unread, so that the string as a whole is declined exactly when
-- it holds something unaccounted for.  Those are the byte order, which
-- 'endiannessOf' answers; the stack, function and global address space
-- components, which say nothing about a type; and the native integer widths,
-- which say what the target does quickly rather than what it does at all.
component :: Layout -> Text -> Maybe Layout
component layout text = case Text.splitOn ":" text of
  [""] -> Just layout
  [single] -> unkeyed single
  key : arguments -> keyed key arguments
  [] -> Just layout
  where
    unkeyed t
      | t `elem` ["e", "E"] = Just layout
      | Just rest <- prefixed ["S", "G", "P", "A", "n", "Fi", "Fn"] t
      , digits rest =
          Just layout
      | otherwise = Nothing

    keyed key arguments
      -- The name mangling, and the address spaces holding pointers an integer
      -- cannot be made from.  Neither is a size.
      | key == "m", [_] <- arguments = Just layout
      | key == "ni", all digits arguments = Just layout
      | Just rest <- Text.stripPrefix "n" key, digits rest, all digits arguments =
          Just layout
      | Just rest <- Text.stripPrefix "p" key = do
          space <- if Text.null rest then Just 0 else natural rest
          (size, abi) <- twoOrMore arguments
          bits <- natural size
          align <- alignment abi
          guard (bits > 0)
          pure layout {layoutPointers = Map.insert space (Pointer bits align) (layoutPointers layout)}
      | Just rest <- Text.stripPrefix "i" key = scalar rest arguments integers
      | Just rest <- Text.stripPrefix "f" key = scalar rest arguments floats
      | Just rest <- Text.stripPrefix "v" key = scalar rest arguments vectors
      -- @a:@ names no width, and an older spelling puts a zero where the width
      -- would go.  Its alignment may be zero, unlike every other one here:
      -- that is what says an aggregate is aligned by its members alone.
      | Just rest <- Text.stripPrefix "a" key
      , Text.null rest || rest == "0" = do
          (abi, _) <- oneOrMore arguments
          align <- alignmentOrNone abi
          pure layout {layoutAggregate = align}
      | otherwise = Nothing

    scalar width arguments insert = do
      bits <- natural width
      (abi, _) <- oneOrMore arguments
      align <- alignment abi
      guard (bits > 0)
      pure (insert bits align)

    integers bits align = layout {layoutIntegers = Map.insert bits align (layoutIntegers layout)}
    floats bits align = layout {layoutFloats = Map.insert bits align (layoutFloats layout)}
    vectors bits align = layout {layoutVectors = Map.insert bits align (layoutVectors layout)}

    -- A component may carry a preferred alignment and an index width after the
    -- ones read here.  Nothing asks what a preferred alignment is — it is what
    -- a target would rather have, not what its ABI requires — so the trailing
    -- fields are checked to be numbers and dropped.
    oneOrMore (first : rest) | all digits rest = Just (first, rest)
    oneOrMore _ = Nothing

    twoOrMore (first : second : rest) | all digits rest = Just (first, second)
    twoOrMore _ = Nothing

    prefixed keys t = listToMaybe [rest | key <- keys, Just rest <- [Text.stripPrefix key t]]

-- | An alignment written in bits, as a whole number of bytes.
--
-- LLVM writes alignments in bits and requires them to be whole bytes, so one
-- that is not is a string this cannot read rather than a fraction to round.
alignment :: Text -> Maybe Natural
alignment text = do
  bits <- alignmentOrNone text
  guard (bits > 0)
  pure bits

alignmentOrNone :: Text -> Maybe Natural
alignmentOrNone text = do
  bits <- natural text
  guard (bits `mod` 8 == 0)
  pure (bits `div` 8)

natural :: Text -> Maybe Natural
natural text
  | digits text = Just (Text.foldl' (\n c -> 10 * n + fromIntegral (fromEnum c - fromEnum '0')) 0 text)
  | otherwise = Nothing

digits :: Text -> Bool
digits text = not (Text.null text) && Text.all isDigit text

-- * Measuring a type

-- | What one walk of a type finds out about it.
--
-- Size, alignment and field offsets together because they are one recursion: a
-- struct's size is where its last field ends, which is where the ones before
-- it ended and how each of them is aligned.  Asking the three separately would
-- walk the struct three times and, worse, would let the three walks disagree.
data Measured = Measured
  { -- | As LLVM's @getTypeSizeInBits@: the bits the value has, with no padding.
    measuredBits :: Natural
  , -- | The ABI alignment, in bytes.  Never zero.
    measuredAlign :: Natural
  , -- | Where each field begins, in bytes, for a struct; empty for everything
    -- else, which is what makes 'fieldOffset' decline a type that has none.
    measuredFields :: [Natural]
  }
  deriving (Eq, Show)

-- | Everything about a type, or Nothing where it has no size.
--
-- The ones with no size are the types no storage holds: @void@, a label, a
-- token, metadata, a function, a struct declared without a body.  A scalable
-- vector declines too — its size is a multiple of something the target chooses
-- at run time, so there is no number here to give.
--
-- The bound is against a cycle through the named types.  A struct cannot
-- contain itself directly, but @%a = type { %b }@ and @%b = type { %a }@ can be
-- written, and nothing measuring a type should hang on a module that has them.
-- Only a step through a name spends fuel, since a type written out is finite
-- however deeply nested.
measure :: Layout -> Type -> Maybe Measured
measure layout = go (Map.size (layoutTypes layout))
  where
    go fuel written = case written of
      TNamed _ | fuel <= 0 -> Nothing
      _ -> case resolveNamed (layoutTypes layout) written of
        TInteger bits -> do
          align <- integerAlign bits
          pure (Measured bits align [])
        TFloat kind -> do
          let bits = floatBits kind
          pure (Measured bits (floatAlign bits) [])
        TPointer space -> do
          pointer <- pointerFor space
          pure (Measured (pointerBits pointer) (pointerAlign pointer) [])
        -- An array is its elements one after another, so each of them stands
        -- where a whole one fits — and the array is aligned as one element is,
        -- which is already enough for every element after the first.
        TArray count element -> do
          each <- go inner element
          pure (Measured (8 * count * allocOf each) (measuredAlign each) [])
        -- A vector is its elements packed with no padding at all: eight @i1@s
        -- are eight bits and one byte, not eight bytes.
        TVector FixedWidth count element -> do
          each <- go inner element
          let bits = count * measuredBits each
          pure (Measured bits (vectorAlign bits) [])
        TStruct packed fields -> layOut packed <$> traverse (go inner) fields
        _ -> Nothing
      where
        inner = case written of
          TNamed _ -> fuel - 1
          _ -> fuel

    -- Each field where the next whole one fits after the last, and the whole
    -- padded out so that an array of these has every element aligned.  A packed
    -- struct aligns nothing, so every field lands where the one before it
    -- ended, and the layout string's word on aggregates does not reach it —
    -- that is the whole of what packing means.
    layOut packed fields = Measured (8 * roundUp size align) align offsets
      where
        ((size, align), offsets) = mapAccumL place (0, floor') fields

        floor' = case packed of
          Packed -> 1
          -- What the members demand or what the string asks of aggregates,
          -- whichever is more.  It is a floor under the alignment rather than
          -- something applied afterwards, since the size is rounded to the
          -- same number the struct is aligned to.
          Unpacked -> max 1 (layoutAggregate layout)

        place (at, sofar) field = ((start + allocOf field, max sofar demanded), start)
          where
            demanded = case packed of
              Packed -> 1
              Unpacked -> measuredAlign field
            start = roundUp at demanded

    -- No exact match takes the alignment of the next wider integer, and a width
    -- wider than any of them takes the widest.  That is LLVM's rule, and the
    -- one @i128@ on a target that names none is decided by.
    integerAlign bits =
      snd <$> (Map.lookupGE bits (layoutIntegers layout) <|> Map.lookupMax (layoutIntegers layout))

    -- Floating point and vectors have no such rule: a width the string does not
    -- name is aligned naturally, which is what LLVM falls back to and what a
    -- target that cared would have written down.
    floatAlign bits = Map.findWithDefault (naturalAlign bits) bits (layoutFloats layout)
    vectorAlign bits = Map.findWithDefault (naturalAlign bits) bits (layoutVectors layout)

    -- An address space the string says nothing about is laid out as address
    -- space zero is, which the layout always has an answer for.
    pointerFor space =
      Map.lookup (fromMaybe 0 space) (layoutPointers layout)
        <|> Map.lookup 0 (layoutPointers layout)

-- | The first power of two at least as big as the value's bytes.
naturalAlign :: Natural -> Natural
naturalAlign bits = until (>= max 1 (byteCeiling bits)) (* 2) 1

floatBits :: FloatKind -> Natural
floatBits kind = case kind of
  FHalf -> 16
  FBFloat -> 16
  FFloat -> 32
  FDouble -> 64
  FFP128 -> 128
  -- Eighty bits of value in sixteen bytes of storage on the one target that
  -- has it, which is exactly the difference between 'sizeInBits' and
  -- 'allocSize' and why they are separate questions.
  FX86FP80 -> 80
  FPPCFP128 -> 128

byteCeiling :: Natural -> Natural
byteCeiling bits = (bits + 7) `div` 8

roundUp :: Natural -> Natural -> Natural
roundUp n align = ((n + align - 1) `div` align) * align

storeOf :: Measured -> Natural
storeOf = byteCeiling . measuredBits

allocOf :: Measured -> Natural
allocOf m = roundUp (storeOf m) (measuredAlign m)

-- * What a pass asks

-- | How many bits the value of this type has, with no padding.
sizeInBits :: Layout -> Type -> Maybe Natural
sizeInBits layout t = measuredBits <$> measure layout t

-- | How many bytes an access at this type reads or writes.
--
-- What one access touches and so what two of them have to overlap in to be the
-- same bytes, which is the question "Olivine.Core.Alias" asks.  An @i17@ store
-- writes three bytes; what it leaves in the seven bits above is not defined,
-- but they are bytes it wrote.
storeSize :: Layout -> Type -> Maybe Natural
storeSize layout t = storeOf <$> measure layout t

-- | How far apart two of these stand in an array.
--
-- 'storeSize' rounded up to the alignment, which is what @getelementptr@
-- strides by and what a struct's next field is placed after.
allocSize :: Layout -> Type -> Maybe Natural
allocSize layout t = allocOf <$> measure layout t

-- | What an object of this type is aligned to, in bytes.
alignmentOf :: Layout -> Type -> Maybe Natural
alignmentOf layout t = measuredAlign <$> measure layout t

-- | Where a struct's field begins, in bytes from the start of the struct.
--
-- Nothing where the type is not a struct, where it has no such field, or where
-- something in it has no size.  This is the fact that a @getelementptr@ into a
-- struct needs and that a stride cannot give, fields not being all one size.
fieldOffset :: Layout -> Type -> Natural -> Maybe Natural
fieldOffset layout t index = do
  measured <- measure layout t
  listToMaybe (genericDrop index (measuredFields measured))
