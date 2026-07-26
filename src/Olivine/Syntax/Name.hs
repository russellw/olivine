-- | LLVM identifiers.
module Olivine.Syntax.Name
  ( Name (..)
  , Quoting (..)
  , isIdentifierChar
  ) where

import Data.Text (Text)

-- | An identifier with its sigil (@%@, @\@@, @!@) removed.
--
-- Whether it was quoted is remembered rather than recomputed from the
-- characters: a name that needs no quotes may still have been written with
-- them, and reprinting it bare would be a change nobody asked for.
data Name = Name
  { nameQuoting :: Quoting
  , nameText :: Text
  }
  deriving (Eq, Ord, Show)

data Quoting
  = Bare
  | Quoted
  deriving (Eq, Ord, Show)

-- | The characters an unquoted identifier may contain, per LLVM's lexer.
-- Note that @-@ is among them, so this is wider than it first looks.
isIdentifierChar :: Char -> Bool
isIdentifierChar c =
  (c >= 'a' && c <= 'z')
    || (c >= 'A' && c <= 'Z')
    || (c >= '0' && c <= '9')
    || c == '-'
    || c == '$'
    || c == '.'
    || c == '_'
