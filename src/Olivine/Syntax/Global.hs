-- | Global variable definitions.
--
-- The modifiers between the @=@ and the @global@ or @constant@ keyword are
-- held as separate fields rather than as a list of tokens.  LLVM's grammar
-- fixes their order, so a record round-trips as faithfully as a list would,
-- and it is what passes actually want: whole-program optimization turns on
-- linkage, since an @internal@ or @private@ global is one no other module can
-- reach.
module Olivine.Syntax.Global
  ( Global (..)
  , ThreadLocality (..)
  , Mutability (..)
  , GlobalAttribute (..)
  ) where

import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Syntax.Constant (Constant)
import Olivine.Syntax.Linkage
import Olivine.Syntax.Name (Name)
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
    globalInitializer :: Maybe Constant
  , globalAttributes :: [GlobalAttribute]
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
