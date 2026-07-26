-- | Printer for LLVM's textual @.ll@ form.
--
-- The printer is the exact inverse of "Olivine.Syntax.Parser": every
-- constructor added there needs a case here, and the round-trip test in
-- @test/RoundTrip.hs@ is what keeps the two honest.
--
-- Where LLVM's own printer has a house style — the spaces inside struct
-- braces, @{}@ for the empty struct — this follows it, so that output stays
-- comparable to the input by eye and by diff.
module Olivine.Syntax.Printer
  ( renderModule
  , renderEntry
  , renderType
  , renderName
  ) where

import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Syntax.Ast
import Olivine.Syntax.Name
import Olivine.Syntax.Type

renderModule :: Module -> Text
renderModule = T.unlines . map renderEntry . moduleEntries

renderEntry :: Entry -> Text
renderEntry (EModuleId name) = "; ModuleID = " <> singleQuoted name
renderEntry (ESourceFilename name) = "source_filename = " <> quoted name
renderEntry (ETargetDataLayout spec) = "target datalayout = " <> quoted spec
renderEntry (ETargetTriple spec) = "target triple = " <> quoted spec
renderEntry (ETypeDefinition name t) =
  "%" <> renderName name <> " = type " <> renderType t
renderEntry (EOpaque t) = t

renderType :: Type -> Text
renderType TVoid = "void"
renderType (TInteger width) = "i" <> showText width
renderType (TFloat kind) = renderFloatKind kind
renderType (TPointer Nothing) = "ptr"
renderType (TPointer (Just space)) =
  "ptr addrspace(" <> showText space <> ")"
renderType (TArray len element) =
  "[" <> showText len <> " x " <> renderType element <> "]"
renderType (TVector scalability len element) =
  "<" <> vscale <> showText len <> " x " <> renderType element <> ">"
  where
    vscale = case scalability of
      FixedWidth -> ""
      Scalable -> "vscale x "
renderType (TStruct Unpacked fields) = renderFields fields
renderType (TStruct Packed fields) = "<" <> renderFields fields <> ">"
renderType (TNamed name) = "%" <> renderName name
renderType (TFunction result params arity) =
  renderType result <> " (" <> T.intercalate ", " parts <> ")"
  where
    parts = map renderType params <> ["..." | arity == VariadicArity]
renderType TOpaqueStruct = "opaque"
renderType TLabel = "label"
renderType TToken = "token"
renderType TMetadata = "metadata"

renderFloatKind :: FloatKind -> Text
renderFloatKind FHalf = "half"
renderFloatKind FBFloat = "bfloat"
renderFloatKind FFloat = "float"
renderFloatKind FDouble = "double"
renderFloatKind FFP128 = "fp128"
renderFloatKind FX86FP80 = "x86_fp80"
renderFloatKind FPPCFP128 = "ppc_fp128"

-- LLVM writes the empty struct without the interior spaces.
renderFields :: [Type] -> Text
renderFields [] = "{}"
renderFields fields = "{ " <> T.intercalate ", " (map renderType fields) <> " }"

renderName :: Name -> Text
renderName (Name Bare t) = t
renderName (Name Quoted t) = quoted t

quoted :: Text -> Text
quoted t = "\"" <> t <> "\""

singleQuoted :: Text -> Text
singleQuoted t = "'" <> t <> "'"

showText :: Show a => a -> Text
showText = T.pack . show
