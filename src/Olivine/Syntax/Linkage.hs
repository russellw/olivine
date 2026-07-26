-- | Modifiers shared by everything that defines a symbol.
--
-- Globals and functions draw on the same vocabulary here, which is why it
-- lives apart from either.
module Olivine.Syntax.Linkage
  ( Linkage (..)
  , Preemption (..)
  , Visibility (..)
  , DLLStorage (..)
  , UnnamedAddr (..)
  , CallingConvention (..)
  ) where

import Numeric.Natural (Natural)

data Linkage
  = LinkPrivate
  | LinkInternal
  | LinkAvailableExternally
  | LinkLinkOnce
  | LinkWeak
  | LinkCommon
  | LinkAppending
  | LinkExternWeak
  | LinkLinkOnceODR
  | LinkWeakODR
  | LinkExternal
  deriving (Eq, Show)

data Preemption
  = DsoPreemptable
  | DsoLocal
  deriving (Eq, Show)

data Visibility
  = VisibilityDefault
  | VisibilityHidden
  | VisibilityProtected
  deriving (Eq, Show)

data DLLStorage
  = DLLImport
  | DLLExport
  deriving (Eq, Show)

data UnnamedAddr
  = UnnamedAddr
  | LocalUnnamedAddr
  deriving (Eq, Show)

-- | The named conventions, plus @cc N@ for the rest.  LLVM has a long tail of
-- target-specific numbers, and spelling them out here would be a list to keep
-- in step with no benefit over the number itself.
data CallingConvention
  = CCC
  | FastCC
  | ColdCC
  | GHCCC
  | TailCC
  | SwiftCC
  | NumberedCC Natural
  deriving (Eq, Show)
