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
  , GlobalAttribute (..)
  ) where

import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Syntax.Name (Name)

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

-- | The clauses written after a definition rather than before it: @section@,
-- @partition@, @comdat@ and @align@.
--
-- LLVM gives these to every global object, and a function is one as much as a
-- global variable is — the same four clauses in the same order, differing
-- only in that a global writes commas between them and a function does not.
-- A comdat clause with no group named means the group the symbol's own name
-- spells, which is why it is a @Maybe@ and not simply absent.
data GlobalAttribute
  = GASection Text
  | GAPartition Text
  | GAComdat (Maybe Name)
  | GAAlign Natural
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
