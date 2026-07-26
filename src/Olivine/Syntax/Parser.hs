-- | Parser for LLVM's textual @.ll@ form.
module Olivine.Syntax.Parser
  ( parseModule
  , ParseError
  , renderParseError
  ) where

import Data.Text (Text)
import Data.Text qualified as T
import Data.Void (Void)
import Text.Megaparsec hiding (ParseError)
import Text.Megaparsec.Char (eol)

import Olivine.Syntax.Ast

type Parser = Parsec Void Text

type ParseError = ParseErrorBundle Text Void

-- | Parse a module.  The 'FilePath' is used only for error messages.
parseModule :: FilePath -> Text -> Either ParseError Module
parseModule = runParser pModule

renderParseError :: ParseError -> String
renderParseError = errorBundlePretty

pModule :: Parser Module
pModule = Module <$> many pEntry <* eof

-- Until the grammar grows, one line is one entry.  Both alternatives consume
-- input, so 'many' above cannot spin.
pEntry :: Parser Entry
pEntry =
  EOpaque . T.pack <$> (some (anySingleBut '\n') <* optional eol)
    <|> (EOpaque T.empty <$ eol)
