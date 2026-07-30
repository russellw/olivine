-- | What the target's data layout says, for the two questions that can be
-- answered without parsing it.
--
-- The module's @target datalayout@ line is a string of components separated by
-- @-@ giving pointer widths, alignments, index widths and the byte order.
-- Reading it properly means struct layout with alignment, which is what a pass
-- wanting @sizeof@ or @offsetof@ needs and what nothing here does yet.
--
-- Two things are answerable short of that, and this is where they live.
--
-- __The byte order is one component and stands alone.__  @e@ or @E@, and no
-- other component can be either, so finding it needs no parse of the rest.  It
-- decides which end of a wider value a narrower access at the same address
-- reads, which is the one thing a pass reinterpreting a stored value cannot
-- work out from the types.
--
-- __A scalar's width is decided by the type, not the layout.__  @i17@ is
-- seventeen bits and @double@ is sixty four wherever they are compiled;
-- nothing in the layout string can say otherwise.  A pointer is the opposite
-- case — @p:64:64@ is exactly what the layout is for — so 'scalarBits'
-- declines one, along with everything whose size is a sum over its parts.
module Olivine.Core.Layout
  ( Endianness (..)
  , endiannessOf
  , scalarBits
  ) where

import Data.Text qualified as Text
import Numeric.Natural (Natural)

import Olivine.Core.Program (Entry (..), Program (..))
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Type (FloatKind (..), Type (..))

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
endiannessOf program =
  case [spec | ERetained (Syntax.ETargetDataLayout spec) <- programEntries program] of
    [] -> Nothing
    spec : _ -> lookup' (Text.splitOn "-" spec)
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
