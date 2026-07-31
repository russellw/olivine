-- | Global variable, alias and ifunc definitions.
--
-- All three are here because they are one thing to everything that reads them:
-- a top-level definition of an @\@@ symbol, written with the same vocabulary
-- of modifiers and answering the same questions about who can reach it.  Where
-- they differ they differ in detail, and the detail is below.
--
-- The modifiers between the @=@ and the keyword naming the construct are held
-- as separate fields rather than as a list of tokens.  LLVM's grammar fixes
-- their order, so a record round-trips as faithfully as a list would, and it
-- is what passes actually want: whole-program optimization turns on linkage,
-- since an @internal@ or @private@ symbol is one no other module can reach.
module Olivine.Syntax.Global
  ( Global (..)
  , IndirectSymbol (..)
  , IndirectKind (..)
  , ThreadLocality (..)
  , Mutability (..)
  ) where

import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Syntax.Instruction (MetadataAttachment)
import Olivine.Syntax.Linkage
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Value (Value)
import Olivine.Syntax.Type (Type)

data Global = Global
  { globalName :: Name
  , globalLinkage :: Maybe Linkage
  , globalPreemption :: Maybe Preemption
  , globalVisibility :: Maybe Visibility
  , globalDLLStorage :: Maybe DLLStorage
  , globalThreadLocality :: Maybe ThreadLocality
  , globalUnnamedAddr :: Maybe UnnamedAddr
  , globalAddrSpace :: Maybe Natural
  , globalExternallyInitialized :: Bool
  , globalMutability :: Mutability
  , globalType :: Type
  , -- | Absent for a declaration, as in @\@g = external global i32@.
    globalInitializer :: Maybe (Value Name)
  , -- | The clauses following the initializer, written with commas between
    -- them.
    globalAttributes :: [GlobalAttribute]
  , -- | The metadata attached to the global itself, @!dbg !0@ and its
    -- relatives.  A global compiled with @-g@ carries one naming a
    -- @DIGlobalVariableExpression@, and every global in such a module does.
    --
    -- It stands in the same comma-separated list as 'globalAttributes' and is
    -- held apart from it because it is a different construct — the third
    -- place LLVM allows an attachment, after an instruction and a function.
    -- LLVM writes the attachments after the clauses whichever order they were
    -- read in, so they are written back that way rather than where they
    -- stood.
    globalMetadata :: [MetadataAttachment]
  }
  deriving (Eq, Show)

-- | A symbol defined as standing for something else:
-- @\@a = alias \<T\>, ptr \@g@ and @\@i = ifunc \<T\>, ptr \@resolver@.
--
-- One type for both, because they are one piece of grammar.  LLVM reads them
-- with a single rule and differs only on the keyword; the modifier sequence,
-- the @\<T\>, \<target\>@ body and the one trailing clause are the same, and
-- so is every restriction on them.  Both take exactly the linkages that say a
-- definition is present — @available_externally@, @common@, @appending@ and
-- @extern_weak@ are rejected for both — and neither takes @addrspace@.  Two
-- records would be one shape written twice and every function over it written
-- twice after that, to record a difference the 'indirectKind' field already
-- records.  LLVM itself derived them from a common @GlobalIndirectSymbol@ for
-- most of their history.
--
-- The modifier sequence is a global's, less two.  Neither takes @addrspace@,
-- having no storage of its own to put anywhere, nor @externally_initialized@,
-- having no initializer.
--
-- Nor do they take a global's trailing clauses.  @partition@ is the only one
-- LLVM accepts here — @section@, @align@ and @comdat@ are all rejected, these
-- having neither storage to place nor a definition to be grouped with — so it
-- is a field of its own rather than a list of 'GlobalAttribute' that would
-- admit three things which cannot occur.
data IndirectSymbol = IndirectSymbol
  { indirectKind :: IndirectKind
  , indirectName :: Name
  , indirectLinkage :: Maybe Linkage
  , indirectPreemption :: Maybe Preemption
  , indirectVisibility :: Maybe Visibility
  , indirectDLLStorage :: Maybe DLLStorage
  , indirectThreadLocality :: Maybe ThreadLocality
  , indirectUnnamedAddr :: Maybe UnnamedAddr
  , -- | The type the symbol is given, which is the @i32@ of
    -- @\@a = alias i32, ptr \@g@ and need not be the target's own.
    indirectType :: Type
  , -- | The type written before the target, as the @ptr@ of @ptr \@g@.
    --
    -- Absent when the target is a constant expression, which LLVM writes in
    -- this position without one, its own operands carrying their types.  That
    -- is a rule about how the position is written, so following it is what
    -- keeps the round trip exact; and the type cannot simply be assumed to be
    -- @ptr@, since @ptr addrspace(1) \@g@ is written here too.
    indirectTargetType :: Maybe Type
  , -- | What the symbol stands for: the aliasee of an alias, the resolver of
    -- an ifunc.  A symbol, or a constant expression computing an address from
    -- one — which LLVM's verifier allows only for an alias, an ifunc needing
    -- a function it can call.  That is a judgement on a program rather than a
    -- fact about the grammar, so it belongs to a verifier and not here.
    indirectTarget :: Value Name
  , -- | @, partition "..."@.
    indirectPartition :: Maybe Text
  }
  deriving (Eq, Show)

-- | Which keyword the symbol was written with, and so what resolves it: the
-- linker, or a call at load time to the function named.
data IndirectKind
  = IndirectAlias
  | IndirectIFunc
  deriving (Eq, Show)

data ThreadLocality
  = GeneralDynamic
  | LocalDynamic
  | InitialExec
  | LocalExec
  deriving (Eq, Show)

-- | Whether the global was written @global@ or @constant@.
data Mutability
  = Mutable
  | Immutable
  deriving (Eq, Show)
