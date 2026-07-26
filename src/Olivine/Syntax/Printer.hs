-- | Printer for LLVM's textual @.ll@ form.
--
-- The printer is the exact inverse of "Olivine.Syntax.Parser": every
-- constructor added there needs a case here, and the round-trip test in
-- @test/RoundTrip.hs@ is what keeps the two honest.
module Olivine.Syntax.Printer
  ( renderModule
  , renderEntry
  ) where

import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Syntax.Ast

renderModule :: Module -> Text
renderModule = T.unlines . map renderEntry . moduleEntries

renderEntry :: Entry -> Text
renderEntry (EModuleId name) = "; ModuleID = " <> singleQuoted name
renderEntry (ESourceFilename name) = "source_filename = " <> quoted name
renderEntry (ETargetDataLayout spec) = "target datalayout = " <> quoted spec
renderEntry (ETargetTriple spec) = "target triple = " <> quoted spec
renderEntry (EOpaque t) = t

quoted :: Text -> Text
quoted t = "\"" <> t <> "\""

singleQuoted :: Text -> Text
singleQuoted t = "'" <> t <> "'"
