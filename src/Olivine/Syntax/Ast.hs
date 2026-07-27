-- | A faithful syntactic representation of an LLVM @.ll@ module.
--
-- This layer mirrors LLVM's textual form closely, phi nodes and all.  It is
-- deliberately /not/ the representation the optimizer passes work on: those
-- use a separate non-SSA core in which locals have addresses and can be
-- reassigned.  Lowering between the two is its own step, so that a failure in
-- the round trip is never ambiguous between a parsing bug and a lowering bug.
--
-- Every construct starts life as an 'EOpaque' holding its source text
-- verbatim.  That makes the round trip total from the first commit; structure
-- is then added by moving one construct at a time out of 'EOpaque' into a
-- typed constructor, with a matching printer case.  The round-trip test stays
-- green throughout.
module Olivine.Syntax.Ast
  ( Module (..)
  , Entry (..)
  , isComment
  ) where

import Data.List.NonEmpty (NonEmpty)
import Data.Text (Text)
import Data.Text qualified as T
import Numeric.Natural (Natural)

import Olivine.Syntax.Attribute (FunctionAttribute)
import Olivine.Syntax.Function (Definition, Signature)
import Olivine.Syntax.Global (Global)
import Olivine.Syntax.Metadata (Distinctness, MetadataOperand)
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)

-- | A whole translation unit.  Olivine optimizes whole programs, so a
-- complete input is eventually a set of these linked together; for now one
-- module is one file.
newtype Module = Module
  { moduleEntries :: [Entry]
  }
  deriving (Eq, Show)

-- | A single top-level construct.
data Entry
  = -- | @; ModuleID = '...'@.  LLVM writes the module's identifier as a
    -- comment, so no reader ever recovers it and nothing depends on its
    -- value.  It is modelled anyway: it is the first line of every file, and
    -- leaving it opaque would mean the one construct guaranteed to be present
    -- is the one construct never checked.
    EModuleId Text
  | -- | @source_filename = "..."@.
    ESourceFilename Text
  | -- | @target datalayout = "..."@.  The specification is held as its
    -- literal text: nothing needs to interpret it until a pass asks about
    -- pointer widths or alignment, and holding it verbatim keeps the round
    -- trip exact until then.
    ETargetDataLayout Text
  | -- | @target triple = "..."@.
    ETargetTriple Text
  | -- | @%name = type <T>@.  Usually a struct, but LLVM permits any type.
    ETypeDefinition Name Type
  | -- | @\@name = [modifiers] global|constant <T> [initializer] [, ...]@.
    EGlobal Global
  | -- | @declare <signature>@.
    EDeclare Signature
  | -- | @define <signature> { ... }@, the one construct spanning more than
    -- one line.
    EDefine Definition
  | -- | @attributes #N = { ... }@.  LLVM rejects a group with no attributes
    -- in it, so the list cannot be empty here either.
    EAttributeGroup Natural (NonEmpty FunctionAttribute)
  | -- | @!0 = !{...}@, optionally @distinct@.
    EMetadata Natural Distinctness [MetadataOperand]
  | -- | @!llvm.module.flags = !{!0, !1}@.  A named node's operands are
    -- always references to other nodes, never values.
    ENamedMetadata Name [Natural]
  | -- | Source text not yet modelled, retained exactly as written.
    EOpaque Text
  deriving (Eq, Show)

-- | Whether an entry is a comment.
--
-- A comment introduces what follows it rather than standing on its own, which
-- is the one thing anything handling entries has to know about it: the
-- printer puts the blank line above the comment and not between it and what
-- it introduces, and a pass removing a construct has to take the comment
-- introducing it too, or the comment is left saying of the next construct
-- what was true of the one that went.  Clang writes
-- @; Function Attrs: noinline@ above every function, so that is not a corner.
--
-- The module identifier is a comment to LLVM as well, but it is modelled, and
-- nothing follows it that it could be introducing.
isComment :: Entry -> Bool
isComment (EOpaque text) = ";" `T.isPrefixOf` T.stripStart text
isComment _ = False
