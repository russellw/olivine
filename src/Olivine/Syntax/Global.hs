-- | Global variable and alias definitions.
--
-- Both are here because they are one thing to everything that reads them: a
-- top-level definition of an @\@@ symbol, written with the same vocabulary of
-- modifiers and answering the same questions about who can reach it.  Where
-- they differ they differ in detail, and the detail is below.
--
-- The modifiers between the @=@ and the keyword naming the construct are held
-- as separate fields rather than as a list of tokens.  LLVM's grammar fixes
-- their order, so a record round-trips as faithfully as a list would, and it
-- is what passes actually want: whole-program optimization turns on linkage,
-- since an @internal@ or @private@ symbol is one no other module can reach.
module Olivine.Syntax.Global
  ( Global (..)
  , Alias (..)
  , ThreadLocality (..)
  , Mutability (..)
  , GlobalAttribute (..)
  ) where

import Data.Text (Text)
import Numeric.Natural (Natural)

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
    globalInitializer :: Maybe Value
  , globalAttributes :: [GlobalAttribute]
  }
  deriving (Eq, Show)

-- | @\@a = alias \<T\>, ptr \@g@: a second name for a symbol the module
-- already defines.
--
-- The modifier sequence is a global's, less two.  An alias takes no
-- @addrspace@, because it has no storage of its own to put anywhere, and no
-- @externally_initialized@, because it has no initializer.
--
-- Nor does it take a global's trailing clauses.  @partition@ is the only one
-- LLVM accepts here — @section@, @align@ and @comdat@ are all rejected, an
-- alias having neither storage to place nor a definition to be grouped with —
-- so it is a field of its own rather than a list of 'GlobalAttribute' that
-- would admit three things that cannot occur.
data Alias = Alias
  { aliasName :: Name
  , aliasLinkage :: Maybe Linkage
  , aliasPreemption :: Maybe Preemption
  , aliasVisibility :: Maybe Visibility
  , aliasDLLStorage :: Maybe DLLStorage
  , aliasThreadLocality :: Maybe ThreadLocality
  , aliasUnnamedAddr :: Maybe UnnamedAddr
  , -- | The type the alias gives the symbol, which is the @i32@ of
    -- @\@a = alias i32, ptr \@g@ and need not be the aliasee's own.
    aliasType :: Type
  , -- | The type written before the aliasee, as the @ptr@ of @ptr \@g@.
    --
    -- Absent when the aliasee is a constant expression, which LLVM writes in
    -- this position without one, its own operands carrying their types.  That
    -- is a rule about how the position is written, so following it is what
    -- keeps the round trip exact; and the type cannot simply be assumed to be
    -- @ptr@, since @ptr addrspace(1) \@g@ is written here too.
    aliasAliaseeType :: Maybe Type
  , -- | What the alias resolves to: a symbol, or a constant expression
    -- computing an address from one.
    aliasAliasee :: Value
  , -- | @, partition "..."@.
    aliasPartition :: Maybe Text
  }
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

-- | The comma-separated clauses that follow the initializer.
data GlobalAttribute
  = GASection Text
  | GAPartition Text
  | GAComdat (Maybe Name)
  | GAAlign Natural
  deriving (Eq, Show)
