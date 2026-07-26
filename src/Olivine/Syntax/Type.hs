-- | LLVM's type grammar.
--
-- Types are the one part of the syntax referenced from nearly everywhere
-- else — globals, function signatures, and eventually every instruction — so
-- they get their own module.
--
-- Widths and lengths are 'Natural' rather than a machine word.  LLVM caps
-- integer widths well below that, but a syntax layer that silently wrapped an
-- absurd width would corrupt the program rather than reject it, and this
-- costs nothing.
module Olivine.Syntax.Type
  ( Type (..)
  , FloatKind (..)
  , Packedness (..)
  , Scalability (..)
  , Arity (..)
  ) where

import Numeric.Natural (Natural)

import Olivine.Syntax.Name (Name)

data Type
  = -- | @void@
    TVoid
  | -- | @iN@
    TInteger Natural
  | TFloat FloatKind
  | -- | @ptr@, or @ptr addrspace(N)@ when an address space is named.
    -- Pointers carry no pointee type: LLVM's are opaque, and so are the ones
    -- in the core representation.
    TPointer (Maybe Natural)
  | -- | @[N x T]@
    TArray Natural Type
  | -- | @<N x T>@ and @<vscale x N x T>@
    TVector Scalability Natural Type
  | -- | @{ T, T }@ and its packed form @<{ T, T }>@
    TStruct Packedness [Type]
  | -- | A reference to a named type, as in @%struct.point@.
    TNamed Name
  | -- | @T (T, T, ...)@
    TFunction Type [Type] Arity
  | -- | A named struct declared without a body.
    TOpaqueStruct
  | TLabel
  | TToken
  | TMetadata
  deriving (Eq, Show)

data FloatKind
  = FHalf
  | FBFloat
  | FFloat
  | FDouble
  | FFP128
  | FX86FP80
  | FPPCFP128
  deriving (Eq, Show)

data Packedness
  = Unpacked
  | Packed
  deriving (Eq, Show)

data Scalability
  = FixedWidth
  | Scalable
  deriving (Eq, Show)

data Arity
  = FixedArity
  | VariadicArity
  deriving (Eq, Show)
