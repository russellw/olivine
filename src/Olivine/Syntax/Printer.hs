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
  , renderGlobal
  , renderConstant
  , renderType
  , renderName
  ) where

import Data.Maybe (catMaybes)
import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Syntax.Ast
import Olivine.Syntax.Attribute
import Olivine.Syntax.Constant
import Olivine.Syntax.Function
import Olivine.Syntax.Global
import Olivine.Syntax.Linkage
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
renderEntry (EGlobal g) = renderGlobal g
renderEntry (EDeclare s) = "declare " <> renderSignature s
renderEntry (EOpaque t) = t

renderSignature :: Signature -> Text
renderSignature s =
  T.unwords $
    modifiers
      <> map renderParamAttribute (signatureReturnAttributes s)
      <> [renderType (signatureReturnType s)]
      <> ["@" <> renderName (signatureName s) <> "(" <> parameters <> ")"]
      <> trailing
  where
    modifiers =
      catMaybes
        [ renderLinkage <$> signatureLinkage s
        , renderPreemption <$> signaturePreemption s
        , renderVisibility <$> signatureVisibility s
        , renderDLLStorage <$> signatureDLLStorage s
        , renderCallingConvention <$> signatureCallingConvention s
        ]
    parameters =
      T.intercalate ", " $
        map renderParameter (signatureParameters s)
          <> ["..." | signatureArity s == VariadicArity]
    trailing =
      catMaybes
        [ renderUnnamedAddr <$> signatureUnnamedAddr s
        , (\n -> "addrspace(" <> showText n <> ")") <$> signatureAddrSpace s
        ]
        <> ["#" <> showText n | n <- signatureAttributeGroups s]

renderParameter :: Parameter -> Text
renderParameter p =
  T.unwords $
    renderType (parameterType p)
      : map renderParamAttribute (parameterAttributes p)
      <> foldMap (\n -> ["%" <> renderName n]) (parameterName p)

renderCallingConvention :: CallingConvention -> Text
renderCallingConvention CCC = "ccc"
renderCallingConvention FastCC = "fastcc"
renderCallingConvention ColdCC = "coldcc"
renderCallingConvention GHCCC = "ghccc"
renderCallingConvention TailCC = "tailcc"
renderCallingConvention SwiftCC = "swiftcc"
renderCallingConvention (NumberedCC n) = "cc" <> showText n

renderParamAttribute :: ParamAttribute -> Text
renderParamAttribute PAZeroExt = "zeroext"
renderParamAttribute PASignExt = "signext"
renderParamAttribute PANoExt = "noext"
renderParamAttribute PAInReg = "inreg"
renderParamAttribute PANoAlias = "noalias"
renderParamAttribute PANoCapture = "nocapture"
renderParamAttribute PANoFree = "nofree"
renderParamAttribute PANest = "nest"
renderParamAttribute PAReturned = "returned"
renderParamAttribute PANonNull = "nonnull"
renderParamAttribute PANoUndef = "noundef"
renderParamAttribute PASwiftSelf = "swiftself"
renderParamAttribute PASwiftAsync = "swiftasync"
renderParamAttribute PASwiftError = "swifterror"
renderParamAttribute PAImmArg = "immarg"
renderParamAttribute PAAllocAlign = "allocalign"
renderParamAttribute PAAllocPtr = "allocptr"
renderParamAttribute PAReadNone = "readnone"
renderParamAttribute PAReadOnly = "readonly"
renderParamAttribute PAWriteOnly = "writeonly"
renderParamAttribute PAWritable = "writable"
renderParamAttribute PADeadOnUnwind = "dead_on_unwind"
renderParamAttribute PADeadOnReturn = "dead_on_return"
renderParamAttribute (PAAlign n) = "align " <> showText n
renderParamAttribute (PAAlignStack n) = "alignstack(" <> showText n <> ")"
renderParamAttribute (PADereferenceable n) =
  "dereferenceable(" <> showText n <> ")"
renderParamAttribute (PADereferenceableOrNull n) =
  "dereferenceable_or_null(" <> showText n <> ")"
renderParamAttribute (PAByVal t) = "byval(" <> renderType t <> ")"
renderParamAttribute (PAByRef t) = "byref(" <> renderType t <> ")"
renderParamAttribute (PAPreallocated t) =
  "preallocated(" <> renderType t <> ")"
renderParamAttribute (PAInAlloca t) = "inalloca(" <> renderType t <> ")"
renderParamAttribute (PASRet t) = "sret(" <> renderType t <> ")"
renderParamAttribute (PAElementType t) = "elementtype(" <> renderType t <> ")"
renderParamAttribute (PACaptures raw) = "captures(" <> raw <> ")"
renderParamAttribute (PARange raw) = "range(" <> raw <> ")"
renderParamAttribute (PANoFPClass raw) = "nofpclass(" <> raw <> ")"
renderParamAttribute (PAInitializes raw) = "initializes(" <> raw <> ")"

renderGlobal :: Global -> Text
renderGlobal g =
  T.unwords (["@" <> renderName (globalName g), "="] <> modifiers <> body)
    <> T.concat [", " <> renderGlobalAttribute a | a <- globalAttributes g]
  where
    modifiers =
      catMaybes
        [ renderLinkage <$> globalLinkage g
        , renderPreemption <$> globalPreemption g
        , renderVisibility <$> globalVisibility g
        , renderDLLStorage <$> globalDLLStorage g
        , renderThreadLocality <$> globalThreadLocality g
        , renderUnnamedAddr <$> globalUnnamedAddr g
        , (\n -> "addrspace(" <> showText n <> ")") <$> globalAddrSpace g
        , "externally_initialized" <$ guarded (globalExternallyInitialized g)
        ]
    body =
      [renderMutability (globalMutability g), renderType (globalType g)]
        <> foldMap (pure . renderConstant) (globalInitializer g)
    guarded b = if b then Just () else Nothing

renderLinkage :: Linkage -> Text
renderLinkage LinkPrivate = "private"
renderLinkage LinkInternal = "internal"
renderLinkage LinkAvailableExternally = "available_externally"
renderLinkage LinkLinkOnce = "linkonce"
renderLinkage LinkWeak = "weak"
renderLinkage LinkCommon = "common"
renderLinkage LinkAppending = "appending"
renderLinkage LinkExternWeak = "extern_weak"
renderLinkage LinkLinkOnceODR = "linkonce_odr"
renderLinkage LinkWeakODR = "weak_odr"
renderLinkage LinkExternal = "external"

renderPreemption :: Preemption -> Text
renderPreemption DsoPreemptable = "dso_preemptable"
renderPreemption DsoLocal = "dso_local"

renderVisibility :: Visibility -> Text
renderVisibility VisibilityDefault = "default"
renderVisibility VisibilityHidden = "hidden"
renderVisibility VisibilityProtected = "protected"

renderDLLStorage :: DLLStorage -> Text
renderDLLStorage DLLImport = "dllimport"
renderDLLStorage DLLExport = "dllexport"

renderThreadLocality :: ThreadLocality -> Text
renderThreadLocality GeneralDynamic = "thread_local"
renderThreadLocality LocalDynamic = "thread_local(localdynamic)"
renderThreadLocality InitialExec = "thread_local(initialexec)"
renderThreadLocality LocalExec = "thread_local(localexec)"

renderUnnamedAddr :: UnnamedAddr -> Text
renderUnnamedAddr UnnamedAddr = "unnamed_addr"
renderUnnamedAddr LocalUnnamedAddr = "local_unnamed_addr"

renderMutability :: Mutability -> Text
renderMutability Mutable = "global"
renderMutability Immutable = "constant"

renderGlobalAttribute :: GlobalAttribute -> Text
renderGlobalAttribute (GASection name) = "section " <> quoted name
renderGlobalAttribute (GAPartition name) = "partition " <> quoted name
renderGlobalAttribute (GAComdat Nothing) = "comdat"
renderGlobalAttribute (GAComdat (Just name)) =
  "comdat($" <> renderName name <> ")"
renderGlobalAttribute (GAAlign n) = "align " <> showText n

renderConstant :: Constant -> Text
renderConstant (CInteger n) = showText n
renderConstant (CBoolean True) = "true"
renderConstant (CBoolean False) = "false"
renderConstant (CFloat raw) = raw
renderConstant CNull = "null"
renderConstant CNone = "none"
renderConstant CUndef = "undef"
renderConstant CPoison = "poison"
renderConstant CZeroInitializer = "zeroinitializer"
renderConstant (CString s) = "c" <> quoted s
renderConstant (CArray elements) = "[" <> renderElements elements <> "]"
renderConstant (CVector elements) = "<" <> renderElements elements <> ">"
renderConstant (CStruct Unpacked fields) = renderStructFields fields
renderConstant (CStruct Packed fields) =
  "<" <> renderStructFields fields <> ">"
renderConstant (CGlobal name) = "@" <> renderName name
renderConstant (CCast op value target) =
  renderCastOp op
    <> " ("
    <> renderTypedConstant value
    <> " to "
    <> renderType target
    <> ")"
renderConstant (CGetElementPtr flags element operands) =
  T.concat
    [ "getelementptr"
    , T.concat [" " <> renderGepFlag f | f <- flags]
    , " ("
    , T.intercalate ", " (renderType element : map renderTypedConstant operands)
    , ")"
    ]

renderTypedConstant :: TypedConstant -> Text
renderTypedConstant (TypedConstant t c) =
  renderType t <> " " <> renderConstant c

-- LLVM writes array and vector constants without spaces inside the brackets,
-- but struct constants with them, matching how it writes the types.
renderElements :: [TypedConstant] -> Text
renderElements = T.intercalate ", " . map renderTypedConstant

renderStructFields :: [TypedConstant] -> Text
renderStructFields [] = "{}"
renderStructFields fields = "{ " <> renderElements fields <> " }"

renderCastOp :: CastOp -> Text
renderCastOp CastTrunc = "trunc"
renderCastOp CastPtrToInt = "ptrtoint"
renderCastOp CastIntToPtr = "inttoptr"
renderCastOp CastBitcast = "bitcast"
renderCastOp CastAddrSpaceCast = "addrspacecast"

renderGepFlag :: GepFlag -> Text
renderGepFlag GepInbounds = "inbounds"
renderGepFlag GepNusw = "nusw"
renderGepFlag GepNuw = "nuw"

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
