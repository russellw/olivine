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
  , resolveNamed
  , elementOf
  , insideOf
  ) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
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

-- | What a named type stands for, given the module's type definitions.
--
-- A name is a reference into that table, so anything asking what a type
-- actually is — which fields a struct has, whether something is a vector —
-- has to look it up, and what it finds may be another name.  A type that is
-- not a name, or one the table does not have, stands for itself.
--
-- The bound is against a definition that names itself: LLVM rejects one, and
-- nothing that resolves a type should hang on a module that has it.
resolveNamed :: Map Name Type -> Type -> Type
resolveNamed types = go (Map.size types)
  where
    go 0 t = t
    go n (TNamed name) = maybe (TNamed name) (go (n - 1 :: Int)) (Map.lookup name types)
    go _ t = t

-- | What a vector holds, or the type itself when it is not one.
--
-- The answer for something that is not a vector is what makes this usable
-- where an operation reads either — an addition of two vectors adds their
-- elements, and one of two integers adds the integers.
elementOf :: Map Name Type -> Type -> Type
elementOf types t = case resolveNamed types t of
  TVector _ _ element -> element
  _ -> t

-- | What stands at a path of indices into an aggregate.
--
-- The walk @extractvalue@ and @insertvalue@ are written in terms of: each
-- index picks a field of a struct or an element of an array, and the next one
-- is read against what that arrived at.  An array's indices all pick the same
-- type and a struct's each pick their own, which is why this is a walk rather
-- than a lookup.
--
-- A path that does not fit the type — an index past the last field, a step
-- into something that is not an aggregate — stops and gives back what it
-- reached.  That the path fits is a verifier's business, and answering
-- something here lets everything that asks what an instruction produces stay
-- total.
insideOf :: Map Name Type -> Type -> [Natural] -> Type
insideOf types = foldl step
  where
    step t index = case resolveNamed types t of
      TStruct _ fields
        | (field : _) <- drop (fromIntegral index) fields -> field
      TArray _ element -> element
      _ -> t
