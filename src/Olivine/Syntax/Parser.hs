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
import Text.Megaparsec.Char (char, eol, hspace, hspace1, string)

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

-- Modelled constructs are tried first, and each is wrapped in 'try' so that
-- anything it does not fully recognize falls through to the opaque line rule
-- rather than failing the parse.  That is what keeps the round trip total
-- while the grammar is incomplete.
pEntry :: Parser Entry
pEntry = try pTarget <|> pOpaqueLine

-- | @target datalayout = "..."@ and @target triple = "..."@.
pTarget :: Parser Entry
pTarget = do
  hspace
  _ <- string "target"
  hspace1
  con <-
    (ETargetDataLayout <$ string "datalayout")
      <|> (ETargetTriple <$ string "triple")
  hspace
  _ <- char '='
  hspace
  spec <- pQuoted
  endOfLine
  pure (con spec)

-- | The contents of an LLVM quoted string, held exactly as written.
--
-- LLVM has no @\\"@ escape — a quote inside a string is written @\\22@ — so a
-- string always ends at the next quote character, and the bytes in between
-- can be carried around without being decoded.
pQuoted :: Parser Text
pQuoted = char '"' *> takeWhileP (Just "string character") (/= '"') <* char '"'

-- Until the grammar grows, anything unrecognized is one line, one entry.
-- Both alternatives consume input, so 'many' above cannot spin.
pOpaqueLine :: Parser Entry
pOpaqueLine =
  EOpaque . T.pack <$> (some (anySingleBut '\n') <* optional eol)
    <|> (EOpaque T.empty <$ eol)

-- | Trailing horizontal space and the line break, if any.
endOfLine :: Parser ()
endOfLine = hspace *> (() <$ eol <|> eof)
