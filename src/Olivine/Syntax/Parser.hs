-- | Parser for LLVM's textual @.ll@ form.
--
-- Whitespace handling is horizontal only.  Every construct modelled so far
-- occupies a single line, and never consuming a line break is what lets an
-- unrecognized construct fall back to 'pOpaqueLine' without the recovery
-- point drifting into the middle of the next line.
module Olivine.Syntax.Parser
  ( parseModule
  , ParseError
  , renderParseError
  ) where

import Data.Text (Text)
import Data.Text qualified as T
import Data.Void (Void)
import Numeric.Natural (Natural)
import Text.Megaparsec hiding (ParseError)
import Text.Megaparsec.Char (char, digitChar, eol, hspace, string)

import Olivine.Syntax.Ast
import Olivine.Syntax.Name
import Olivine.Syntax.Type

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
pEntry =
  choice
    [ try pModuleId
    , try pSourceFilename
    , try pTarget
    , try pTypeDefinition
    , pOpaqueLine
    ]

-- | @; ModuleID = '...'@.
--
-- This is a comment as far as LLVM is concerned, so an identifier containing
-- a quote would not be escaped and could not be read back unambiguously.  In
-- that case the trailing 'endOfLine' fails, the enclosing 'try' backtracks,
-- and the line stays opaque — which is the right outcome for something no
-- reader consumes anyway.
pModuleId :: Parser Entry
pModuleId = do
  hspace
  _ <- char ';'
  hspace
  keyword "ModuleID"
  EModuleId <$> pAssigned pSingleQuoted

-- | @source_filename = "..."@.
pSourceFilename :: Parser Entry
pSourceFilename = do
  hspace
  keyword "source_filename"
  ESourceFilename <$> pAssigned pQuoted

-- | @target datalayout = "..."@ and @target triple = "..."@.
pTarget :: Parser Entry
pTarget = do
  hspace
  keyword "target"
  con <-
    (ETargetDataLayout <$ keyword "datalayout")
      <|> (ETargetTriple <$ keyword "triple")
  con <$> pAssigned pQuoted

-- | @%name = type <T>@.
pTypeDefinition :: Parser Entry
pTypeDefinition = do
  hspace
  name <- pLocalName
  ETypeDefinition name <$> pAssigned (keyword "type" *> pType)

-- | The @= <value>@ tail shared by the top-level definitions, through to the
-- end of the line.
pAssigned :: Parser a -> Parser a
pAssigned value = symbol "=" *> value <* endOfLine

-- Until the grammar grows, anything unrecognized is one line, one entry.
-- Both alternatives consume input, so 'many' above cannot spin.
pOpaqueLine :: Parser Entry
pOpaqueLine =
  EOpaque . T.pack <$> (some (anySingleBut '\n') <* optional eol)
    <|> (EOpaque T.empty <$ eol)

-- * Types

pType :: Parser Type
pType = pTypeAtom >>= functionSuffixes

-- A type followed by a parameter list is a function type.  LLVM rejects a
-- function returning a function during verification rather than during
-- parsing, so the loop here is deliberately more permissive than the
-- language: the syntax layer's job is to read back what was written.
functionSuffixes :: Type -> Parser Type
functionSuffixes result =
  ( do
      (params, arity) <- pParameterList
      functionSuffixes (TFunction result params arity)
  )
    <|> pure result

pParameterList :: Parser ([Type], Arity)
pParameterList = symbol "(" *> pParameters <* symbol ")"

pParameters :: Parser ([Type], Arity)
pParameters =
  (([], VariadicArity) <$ symbol "...")
    <|> ( do
            t <- pType
            (ts, arity) <- (symbol "," *> pParameters) <|> pure ([], FixedArity)
            pure (t : ts, arity)
        )
    <|> pure ([], FixedArity)

pTypeAtom :: Parser Type
pTypeAtom =
  choice
    [ TVoid <$ keyword "void"
    , TLabel <$ keyword "label"
    , TToken <$ keyword "token"
    , TMetadata <$ keyword "metadata"
    , TOpaqueStruct <$ keyword "opaque"
    , TFloat FHalf <$ keyword "half"
    , TFloat FBFloat <$ keyword "bfloat"
    , TFloat FFloat <$ keyword "float"
    , TFloat FDouble <$ keyword "double"
    , TFloat FFP128 <$ keyword "fp128"
    , TFloat FX86FP80 <$ keyword "x86_fp80"
    , TFloat FPPCFP128 <$ keyword "ppc_fp128"
    , pPointerType
    , pIntegerType
    , pArrayType
    , pAngleType
    , pStructType Unpacked
    , TNamed <$> pLocalName
    ]

pPointerType :: Parser Type
pPointerType = do
  keyword "ptr"
  TPointer
    <$> optional (keyword "addrspace" *> symbol "(" *> pNatural <* symbol ")")

-- The boundary check has to happen before trailing space is consumed, or
-- @i32@ would be rejected wherever an identifier legitimately follows it.
pIntegerType :: Parser Type
pIntegerType = try $ do
  _ <- char 'i'
  digits <- some digitChar
  notFollowedBy (satisfy isIdentifierChar)
  hspace
  pure (TInteger (read digits))

pArrayType :: Parser Type
pArrayType = do
  symbol "["
  len <- pNatural
  keyword "x"
  element <- pType
  symbol "]"
  pure (TArray len element)

-- An opening angle bracket starts either a vector or a packed struct; only
-- the next token tells them apart.
pAngleType :: Parser Type
pAngleType = do
  symbol "<"
  t <- pStructType Packed <|> pVectorType
  symbol ">"
  pure t

pVectorType :: Parser Type
pVectorType = do
  scalability <-
    option FixedWidth (Scalable <$ try (keyword "vscale" *> keyword "x"))
  len <- pNatural
  keyword "x"
  element <- pType
  pure (TVector scalability len element)

pStructType :: Packedness -> Parser Type
pStructType packedness = do
  symbol "{"
  fields <- pType `sepBy` symbol ","
  symbol "}"
  pure (TStruct packedness fields)

-- * Identifiers and literals

pLocalName :: Parser Name
pLocalName = char '%' *> pName

pName :: Parser Name
pName =
  lexeme $
    (Name Quoted <$> pQuoted)
      <|> (Name Bare <$> takeWhile1P (Just "identifier character") isIdentifierChar)

-- | The contents of an LLVM quoted string, held exactly as written.
--
-- LLVM has no @\\"@ escape — a quote inside a string is written @\\22@ — so a
-- string always ends at the next quote character, and the bytes in between
-- can be carried around without being decoded.
pQuoted :: Parser Text
pQuoted = char '"' *> takeWhileP (Just "string character") (/= '"') <* char '"'

pSingleQuoted :: Parser Text
pSingleQuoted =
  char '\'' *> takeWhileP (Just "identifier character") (/= '\'') <* char '\''

pNatural :: Parser Natural
pNatural = lexeme (read <$> some digitChar)

-- * Lexical helpers

-- | A keyword, which must not be the prefix of a longer identifier.
keyword :: Text -> Parser ()
keyword kw =
  try (() <$ string kw <* notFollowedBy (satisfy isIdentifierChar)) <* hspace

-- | Punctuation, which has no such restriction.
symbol :: Text -> Parser ()
symbol s = () <$ string s <* hspace

lexeme :: Parser a -> Parser a
lexeme p = p <* hspace

-- | Trailing horizontal space and the line break, if any.
endOfLine :: Parser ()
endOfLine = hspace *> (() <$ eol <|> eof)
