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

import Control.Monad (void)
import Data.Char (isDigit, isHexDigit)
import Data.List.NonEmpty (NonEmpty ((:|)))
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Void (Void)
import Numeric.Natural (Natural)
import Text.Megaparsec hiding (ParseError)
import Text.Megaparsec.Char (char, digitChar, eol, hspace, string)

import Olivine.Syntax.Ast
import Olivine.Syntax.Attribute
import Olivine.Syntax.Value
import Olivine.Syntax.Function
import Olivine.Syntax.Global
import Olivine.Syntax.Instruction
import Olivine.Syntax.Linkage
import Olivine.Syntax.Metadata
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
    , try pGlobal
    , try pDeclare
    , try pDefine
    , try pAttributeGroup
    , try pMetadata
    , try pNamedMetadata
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

-- | @\@name = [modifiers] global|constant <T> [initializer] [, ...]@.
pGlobal :: Parser Entry
pGlobal = do
  hspace
  name <- pGlobalName
  symbol "="
  linkage <- optional pLinkage
  preemption <- optional pPreemption
  visibility <- optional pVisibility
  dllStorage <- optional pDLLStorage
  threadLocality <- optional pThreadLocality
  unnamedAddr <- optional pUnnamedAddr
  addrSpace <- optional pAddrSpace
  externallyInitialized <- option False (True <$ keyword "externally_initialized")
  mutability <- pMutability
  t <- pType
  initializer <- optional pValue
  attributes <- many (symbol "," *> pGlobalAttribute)
  endOfLine
  pure $
    EGlobal
      Global
        { globalName = name
        , globalLinkage = linkage
        , globalPreemption = preemption
        , globalVisibility = visibility
        , globalDLLStorage = dllStorage
        , globalThreadLocality = threadLocality
        , globalUnnamedAddr = unnamedAddr
        , globalAddrSpace = addrSpace
        , globalExternallyInitialized = externallyInitialized
        , globalMutability = mutability
        , globalType = t
        , globalInitializer = initializer
        , globalAttributes = attributes
        }

-- The longer spellings need no special ordering here: 'keyword' refuses to
-- match a prefix of a longer identifier, so @linkonce@ cannot swallow the
-- front of @linkonce_odr@.
pLinkage :: Parser Linkage
pLinkage =
  choice
    [ LinkPrivate <$ keyword "private"
    , LinkInternal <$ keyword "internal"
    , LinkAvailableExternally <$ keyword "available_externally"
    , LinkLinkOnce <$ keyword "linkonce"
    , LinkLinkOnceODR <$ keyword "linkonce_odr"
    , LinkWeak <$ keyword "weak"
    , LinkWeakODR <$ keyword "weak_odr"
    , LinkCommon <$ keyword "common"
    , LinkAppending <$ keyword "appending"
    , LinkExternWeak <$ keyword "extern_weak"
    , LinkExternal <$ keyword "external"
    ]

pPreemption :: Parser Preemption
pPreemption =
  (DsoLocal <$ keyword "dso_local")
    <|> (DsoPreemptable <$ keyword "dso_preemptable")

pVisibility :: Parser Visibility
pVisibility =
  choice
    [ VisibilityDefault <$ keyword "default"
    , VisibilityHidden <$ keyword "hidden"
    , VisibilityProtected <$ keyword "protected"
    ]

pDLLStorage :: Parser DLLStorage
pDLLStorage =
  (DLLImport <$ keyword "dllimport") <|> (DLLExport <$ keyword "dllexport")

pThreadLocality :: Parser ThreadLocality
pThreadLocality = do
  keyword "thread_local"
  option GeneralDynamic (symbol "(" *> pMode <* symbol ")")
  where
    pMode =
      choice
        [ LocalDynamic <$ keyword "localdynamic"
        , InitialExec <$ keyword "initialexec"
        , LocalExec <$ keyword "localexec"
        ]

pUnnamedAddr :: Parser UnnamedAddr
pUnnamedAddr =
  (UnnamedAddr <$ keyword "unnamed_addr")
    <|> (LocalUnnamedAddr <$ keyword "local_unnamed_addr")

pAddrSpace :: Parser Natural
pAddrSpace = keyword "addrspace" *> symbol "(" *> pNatural <* symbol ")"

pMutability :: Parser Mutability
pMutability =
  (Mutable <$ keyword "global") <|> (Immutable <$ keyword "constant")

pGlobalAttribute :: Parser GlobalAttribute
pGlobalAttribute =
  choice
    [ GASection <$> (keyword "section" *> pQuoted <* hspace)
    , GAPartition <$> (keyword "partition" *> pQuoted <* hspace)
    , -- Comdats have their own sigil rather than sharing the global one.
      GAComdat
        <$> ( keyword "comdat"
                *> optional (symbol "(" *> (char '$' *> pName) <* symbol ")")
            )
    , GAAlign <$> (keyword "align" *> pNatural)
    ]

-- * Functions

-- | @declare <signature>@.
pDeclare :: Parser Entry
pDeclare = do
  hspace
  keyword "declare"
  EDeclare <$> pSignature <* endOfLine

-- | Everything from the linkage to the attribute groups: the whole of a
-- declaration, and the header of a definition once those arrive.
pSignature :: Parser Signature
pSignature = do
  linkage <- optional pLinkage
  preemption <- optional pPreemption
  visibility <- optional pVisibility
  dllStorage <- optional pDLLStorage
  callingConvention <- optional pCallingConvention
  returnAttributes <- many pParamAttribute
  returnType <- pType
  name <- pGlobalName
  (parameters, arity) <- symbol "(" *> pParameters' <* symbol ")"
  unnamedAddr <- optional pUnnamedAddr
  addrSpace <- optional pAddrSpace
  attributes <- many pSignatureAttribute
  pure
    Signature
      { signatureLinkage = linkage
      , signaturePreemption = preemption
      , signatureVisibility = visibility
      , signatureDLLStorage = dllStorage
      , signatureCallingConvention = callingConvention
      , signatureReturnAttributes = returnAttributes
      , signatureReturnType = returnType
      , signatureName = name
      , signatureParameters = parameters
      , signatureArity = arity
      , signatureUnnamedAddr = unnamedAddr
      , signatureAddrSpace = addrSpace
      , signatureAttributes = attributes
      }

pSignatureAttribute :: Parser SignatureAttribute
pSignatureAttribute =
  (SAGroup <$> (char '#' *> pNatural))
    <|> (SAAttribute <$> pFunctionAttribute OnFunction)

-- | @attributes #N = { ... }@.
pAttributeGroup :: Parser Entry
pAttributeGroup = do
  hspace
  keyword "attributes"
  _ <- char '#'
  number <- pNatural
  symbol "="
  symbol "{"
  attributes <- pNonEmpty (pFunctionAttribute InGroup)
  symbol "}"
  endOfLine
  pure (EAttributeGroup number attributes)

pNonEmpty :: Parser a -> Parser (NonEmpty a)
pNonEmpty p = (:|) <$> p <*> many p

pFunctionAttribute :: AttributeContext -> Parser FunctionAttribute
pFunctionAttribute context =
  choice
    [ FAAlwaysInline <$ keyword "alwaysinline"
    , FABuiltin <$ keyword "builtin"
    , FACold <$ keyword "cold"
    , FAConvergent <$ keyword "convergent"
    , FADisableSanitizerInstrumentation
        <$ keyword "disable_sanitizer_instrumentation"
    , FAFnRetThunkExtern <$ keyword "fn_ret_thunk_extern"
    , FAHot <$ keyword "hot"
    , FAInlineHint <$ keyword "inlinehint"
    , FAJumpTable <$ keyword "jumptable"
    , FAMinSize <$ keyword "minsize"
    , FAMustProgress <$ keyword "mustprogress"
    , FANaked <$ keyword "naked"
    , FANoBuiltin <$ keyword "nobuiltin"
    , FANoCallback <$ keyword "nocallback"
    , FANoCfCheck <$ keyword "nocf_check"
    , FANoDuplicate <$ keyword "noduplicate"
    , FANoFree <$ keyword "nofree"
    , FANoImplicitFloat <$ keyword "noimplicitfloat"
    , FANoInline <$ keyword "noinline"
    , FANoMerge <$ keyword "nomerge"
    , FANonLazyBind <$ keyword "nonlazybind"
    , FANoProfile <$ keyword "noprofile"
    , FANoRecurse <$ keyword "norecurse"
    , FANoRedZone <$ keyword "noredzone"
    , FANoReturn <$ keyword "noreturn"
    , FANoSanitizeBounds <$ keyword "nosanitize_bounds"
    , FANoSanitizeCoverage <$ keyword "nosanitize_coverage"
    , FANoSync <$ keyword "nosync"
    , FANoUnwind <$ keyword "nounwind"
    , FANullPointerIsValid <$ keyword "null_pointer_is_valid"
    , FAOptDebug <$ keyword "optdebug"
    , FAOptForFuzzing <$ keyword "optforfuzzing"
    , FAOptNone <$ keyword "optnone"
    , FAOptSize <$ keyword "optsize"
    , FAPreSplitCoroutine <$ keyword "presplitcoroutine"
    , FAReturnsTwice <$ keyword "returns_twice"
    , FASafeStack <$ keyword "safestack"
    , FASanitizeAddress <$ keyword "sanitize_address"
    , FASanitizeHwAddress <$ keyword "sanitize_hwaddress"
    , FASanitizeMemTag <$ keyword "sanitize_memtag"
    , FASanitizeMemory <$ keyword "sanitize_memory"
    , FASanitizeRealtime <$ keyword "sanitize_realtime"
    , FASanitizeThread <$ keyword "sanitize_thread"
    , FASanitizeType <$ keyword "sanitize_type"
    , FAShadowCallStack <$ keyword "shadowcallstack"
    , FASpeculatable <$ keyword "speculatable"
    , FASpeculativeLoadHardening <$ keyword "speculative_load_hardening"
    , FAStrictFP <$ keyword "strictfp"
    , FASspReq <$ keyword "sspreq"
    , FASspStrong <$ keyword "sspstrong"
    , FASsp <$ keyword "ssp"
    , FAWillReturn <$ keyword "willreturn"
    , FAAlignStack <$> (keyword "alignstack" *> pAlignStackArgument)
    , FAAllocKind <$> (keyword "allockind" *> pParenthesized (pQuoted <* hspace))
    , FAAllocSize <$> (keyword "allocsize" *> symbol "(" *> pNatural) <*> pSecond
    , FAVScaleRange <$> (keyword "vscale_range" *> symbol "(" *> pNatural) <*> pSecond
    , FAUwTable <$> (keyword "uwtable" *> optional pRawParenthesized)
    , FAMemory <$> (keyword "memory" *> pRawParenthesized)
    , pStringAttribute
    ]
  where
    -- The optional second number of allocsize and vscale_range, through to
    -- the closing parenthesis they share.
    pSecond = optional (symbol "," *> pNatural) <* symbol ")"
    pAlignStackArgument = case context of
      InGroup -> symbol "=" *> pNatural
      OnFunction -> pParenthesized pNatural

-- | @"key"@ or @"key"="value"@.  This is the one attribute kind that cannot
-- be enumerated: the front end uses it to pass target configuration through.
pStringAttribute :: Parser FunctionAttribute
pStringAttribute = do
  key <- pQuoted
  hspace
  value <- optional (symbol "=" *> pQuoted <* hspace)
  pure (FAString key value)

-- As with a function type's parameters, @...@ may stand alone or close the
-- list, so the recursion carries the arity back out rather than trying to
-- separate the two cases up front.
pParameters' :: Parser ([Parameter], Arity)
pParameters' =
  (([], VariadicArity) <$ symbol "...")
    <|> ( do
            p <- pParameter
            (ps, arity) <- (symbol "," *> pParameters') <|> pure ([], FixedArity)
            pure (p : ps, arity)
        )
    <|> pure ([], FixedArity)

pParameter :: Parser Parameter
pParameter =
  Parameter <$> pType <*> many pParamAttribute <*> optional pLocalName

pCallingConvention :: Parser CallingConvention
pCallingConvention =
  choice
    [ CCC <$ keyword "ccc"
    , FastCC <$ keyword "fastcc"
    , ColdCC <$ keyword "coldcc"
    , GHCCC <$ keyword "ghccc"
    , TailCC <$ keyword "tailcc"
    , SwiftCC <$ keyword "swiftcc"
    , -- LLVM writes the numbered conventions closed up, as @cc42@, so this
      -- one cannot go through 'keyword': the digit is an identifier
      -- character and the boundary check would reject it.
      NumberedCC <$> try (string "cc" *> pNatural)
    ]

pParamAttribute :: Parser ParamAttribute
pParamAttribute =
  choice
    [ PAZeroExt <$ keyword "zeroext"
    , PASignExt <$ keyword "signext"
    , PANoExt <$ keyword "noext"
    , PAInReg <$ keyword "inreg"
    , PANoAlias <$ keyword "noalias"
    , PANoCapture <$ keyword "nocapture"
    , PANoFree <$ keyword "nofree"
    , PANest <$ keyword "nest"
    , PAReturned <$ keyword "returned"
    , PANonNull <$ keyword "nonnull"
    , PANoUndef <$ keyword "noundef"
    , PASwiftSelf <$ keyword "swiftself"
    , PASwiftAsync <$ keyword "swiftasync"
    , PASwiftError <$ keyword "swifterror"
    , PAImmArg <$ keyword "immarg"
    , PAAllocAlign <$ keyword "allocalign"
    , PAAllocPtr <$ keyword "allocptr"
    , PAReadNone <$ keyword "readnone"
    , PAReadOnly <$ keyword "readonly"
    , PAWriteOnly <$ keyword "writeonly"
    , PAWritable <$ keyword "writable"
    , PADeadOnUnwind <$ keyword "dead_on_unwind"
    , PADeadOnReturn <$ keyword "dead_on_return"
    , PAAlignStack <$> (keyword "alignstack" *> pParenthesized pNatural)
    , -- Alignment is written without parentheses when it applies to a
      -- parameter, but LLVM accepts both spellings.
      PAAlign <$> (keyword "align" *> (pParenthesized pNatural <|> pNatural))
    , PADereferenceable <$> (keyword "dereferenceable" *> pParenthesized pNatural)
    , PADereferenceableOrNull
        <$> (keyword "dereferenceable_or_null" *> pParenthesized pNatural)
    , PAByVal <$> (keyword "byval" *> pParenthesized pType)
    , PAByRef <$> (keyword "byref" *> pParenthesized pType)
    , PAPreallocated <$> (keyword "preallocated" *> pParenthesized pType)
    , PAInAlloca <$> (keyword "inalloca" *> pParenthesized pType)
    , PASRet <$> (keyword "sret" *> pParenthesized pType)
    , PAElementType <$> (keyword "elementtype" *> pParenthesized pType)
    , PACaptures <$> (keyword "captures" *> pRawParenthesized)
    , PARange <$> (keyword "range" *> pRawParenthesized)
    , PANoFPClass <$> (keyword "nofpclass" *> pRawParenthesized)
    , PAInitializes <$> (keyword "initializes" *> pRawParenthesized)
    ]

pParenthesized :: Parser a -> Parser a
pParenthesized p = symbol "(" *> p <* symbol ")"

-- | The text between a matched pair of parentheses, kept as written.
pRawParenthesized :: Parser Text
pRawParenthesized = do
  _ <- char '('
  raw <- go 0
  hspace
  pure raw
  where
    -- Newlines are excluded so that an unbalanced parenthesis fails at the
    -- end of the line rather than swallowing the rest of the file.
    go :: Int -> Parser Text
    go depth = do
      text <- takeWhileP (Just "attribute argument") (`notElem` ("()\n" :: String))
      c <- oneOf ("()" :: String)
      case c of
        ')' | depth == 0 -> pure text
        ')' -> (\rest -> text <> ")" <> rest) <$> go (depth - 1)
        _ -> (\rest -> text <> "(" <> rest) <$> go (depth + 1)

-- | @define <signature> { ... }@.
--
-- The only construct that spans more than one line.  If any of it fails to
-- parse the enclosing 'try' backtracks and the header becomes an opaque line
-- like any other, leaving the body lines to be picked up individually — so a
-- definition Olivine cannot read still survives the round trip intact.
pDefine :: Parser Entry
pDefine = do
  hspace
  keyword "define"
  signature <- pSignature
  symbol "{"
  endOfLine
  blocks <- pBasicBlocks
  hspace
  _ <- char '}'
  endOfLine
  pure (EDefine (Definition signature blocks))

-- An entry block written without a label has nothing to introduce it, so it
-- is whatever instructions precede the first label.  A function whose entry
-- block is named has none, and contributes no empty block here.
pBasicBlocks :: Parser [BasicBlock]
pBasicBlocks = do
  entry <- many pInstruction
  labelled <- many (try pLabelledBlock)
  pure ([BasicBlock Nothing entry | not (null entry)] <> labelled)

pLabelledBlock :: Parser BasicBlock
pLabelledBlock = do
  -- LLVM writes a blank line before every label but the first in a function.
  _ <- optional (try pBlankLine)
  header <- pBlockLabel
  BasicBlock (Just header) <$> many pInstruction

pBlockLabel :: Parser BlockLabel
pBlockLabel = do
  hspace
  name <- pName
  _ <- char ':'
  hspace
  comment <- optional pComment
  endOfLine
  pure (BlockLabel name comment)

-- | A comment, from its semicolon to the end of the line.
pComment :: Parser Text
pComment = T.cons <$> char ';' <*> takeWhileP (Just "comment") (/= '\n')

pBlankLine :: Parser ()
pBlankLine = hspace *> (() <$ eol)

pInstruction :: Parser Instruction
pInstruction = try pOperationInstruction <|> pOpaqueInstruction

pOperationInstruction :: Parser Instruction
pOperationInstruction = try $ do
  hspace
  result <- optional (try (pLocalName <* symbol "="))
  operation <- pOperation
  attachments <- many (try (symbol "," *> pMetadataAttachment))
  endOfLine
  pure (IOperation result operation attachments)

-- Anything in a body that is not the closing brace, a blank line or a label.
-- The text is kept with its indentation: only a modelled instruction could
-- have its indentation regenerated.
pOpaqueInstruction :: Parser Instruction
pOpaqueInstruction = try $ do
  notFollowedBy (hspace *> char '}')
  notFollowedBy pBlankLine
  notFollowedBy pBlockLabel
  IOpaque <$> takeWhile1P (Just "instruction") (/= '\n') <* optional eol

pOperation :: Parser Operation
pOperation =
  choice
    [ pRet
    , pBr
    , pSwitch
    , pIndirectBr
    , OUnreachable <$ keyword "unreachable"
    , pBinary
    , pUnary
    , pConvert
    , pICmp
    , pFCmp
    , pAlloca
    , pLoad
    , pStore
    , pGetElementPtr
    ]

-- * Arithmetic and comparisons

pBinary :: Parser Operation
pBinary = do
  op <- pBinaryOp
  flags <- many pInstructionFlag
  t <- pType
  left <- pValue
  symbol ","
  right <- pValue
  pure $
    OBinary
      Binary
        { binaryOp = op
        , binaryFlags = flags
        , binaryType = t
        , binaryLeft = left
        , binaryRight = right
        }

pUnary :: Parser Operation
pUnary = do
  op <- OpFNeg <$ keyword "fneg"
  flags <- many pInstructionFlag
  t <- pType
  operand <- pValue
  pure $
    OUnary
      Unary
        { unaryOp = op
        , unaryFlags = flags
        , unaryType = t
        , unaryOperand = operand
        }

-- The constant expression of the same shape accepts only the opcodes LLVM
-- still allows there, which is why 'pCastValue' has its own shorter list.
pConvert :: Parser Operation
pConvert = do
  op <- pCastOp
  flags <- many pInstructionFlag
  operand <- pTypedValue
  keyword "to"
  target <- pType
  pure $
    OConvert
      Convert
        { convertOp = op
        , convertFlags = flags
        , convertOperand = operand
        , convertTarget = target
        }

pCastOp :: Parser CastOp
pCastOp =
  choice
    [ CastTrunc <$ keyword "trunc"
    , CastZExt <$ keyword "zext"
    , CastSExt <$ keyword "sext"
    , CastFPTrunc <$ keyword "fptrunc"
    , CastFPExt <$ keyword "fpext"
    , CastFPToUI <$ keyword "fptoui"
    , CastFPToSI <$ keyword "fptosi"
    , CastUIToFP <$ keyword "uitofp"
    , CastSIToFP <$ keyword "sitofp"
    , CastPtrToInt <$ keyword "ptrtoint"
    , CastIntToPtr <$ keyword "inttoptr"
    , CastBitcast <$ keyword "bitcast"
    , CastAddrSpaceCast <$ keyword "addrspacecast"
    ]

pICmp :: Parser Operation
pICmp = keyword "icmp" *> (OICmp <$> pCompare pIntPredicate)

pFCmp :: Parser Operation
pFCmp = keyword "fcmp" *> (OFCmp <$> pCompare pFloatPredicate)

-- The flags come before the predicate, as in @icmp samesign ugt i32 %a, %b@.
pCompare :: Parser predicate -> Parser (Compare predicate)
pCompare pPredicate = do
  flags <- many pInstructionFlag
  predicate <- pPredicate
  t <- pType
  left <- pValue
  symbol ","
  right <- pValue
  pure
    Compare
      { compareFlags = flags
      , comparePredicate = predicate
      , compareType = t
      , compareLeft = left
      , compareRight = right
      }

pBinaryOp :: Parser BinaryOp
pBinaryOp =
  choice
    [ OpAdd <$ keyword "add"
    , OpSub <$ keyword "sub"
    , OpMul <$ keyword "mul"
    , OpUDiv <$ keyword "udiv"
    , OpSDiv <$ keyword "sdiv"
    , OpURem <$ keyword "urem"
    , OpSRem <$ keyword "srem"
    , OpShl <$ keyword "shl"
    , OpLShr <$ keyword "lshr"
    , OpAShr <$ keyword "ashr"
    , OpAnd <$ keyword "and"
    , OpOr <$ keyword "or"
    , OpXor <$ keyword "xor"
    , OpFAdd <$ keyword "fadd"
    , OpFSub <$ keyword "fsub"
    , OpFMul <$ keyword "fmul"
    , OpFDiv <$ keyword "fdiv"
    , OpFRem <$ keyword "frem"
    ]

pIntPredicate :: Parser IntPredicate
pIntPredicate =
  choice
    [ IEq <$ keyword "eq"
    , INe <$ keyword "ne"
    , IUgt <$ keyword "ugt"
    , IUge <$ keyword "uge"
    , IUlt <$ keyword "ult"
    , IUle <$ keyword "ule"
    , ISgt <$ keyword "sgt"
    , ISge <$ keyword "sge"
    , ISlt <$ keyword "slt"
    , ISle <$ keyword "sle"
    ]

pFloatPredicate :: Parser FloatPredicate
pFloatPredicate =
  choice
    [ FFalse <$ keyword "false"
    , FOeq <$ keyword "oeq"
    , FOgt <$ keyword "ogt"
    , FOge <$ keyword "oge"
    , FOlt <$ keyword "olt"
    , FOle <$ keyword "ole"
    , FOne <$ keyword "one"
    , FOrd <$ keyword "ord"
    , FUeq <$ keyword "ueq"
    , FUgt <$ keyword "ugt"
    , FUge <$ keyword "uge"
    , FUlt <$ keyword "ult"
    , FUle <$ keyword "ule"
    , FUne <$ keyword "une"
    , FUno <$ keyword "uno"
    , FTrue <$ keyword "true"
    ]

pInstructionFlag :: Parser InstructionFlag
pInstructionFlag =
  choice
    [ FlagNUW <$ keyword "nuw"
    , FlagNSW <$ keyword "nsw"
    , FlagExact <$ keyword "exact"
    , FlagDisjoint <$ keyword "disjoint"
    , FlagSameSign <$ keyword "samesign"
    , FlagNNeg <$ keyword "nneg"
    , FlagNNaN <$ keyword "nnan"
    , FlagNInf <$ keyword "ninf"
    , FlagNSZ <$ keyword "nsz"
    , FlagARcp <$ keyword "arcp"
    , FlagContract <$ keyword "contract"
    , FlagAFn <$ keyword "afn"
    , FlagReassoc <$ keyword "reassoc"
    , FlagFast <$ keyword "fast"
    ]

-- * Memory

pAlloca :: Parser Operation
pAlloca = do
  keyword "alloca"
  inalloca <- option False (True <$ keyword "inalloca")
  t <- pType
  elementCount <- optional (try (symbol "," *> pTypedValue))
  alignment <- optional (try pAlignmentClause)
  addrSpace <- optional (try (symbol "," *> pAddrSpace))
  pure $
    OAlloca
      Alloca
        { allocaInalloca = inalloca
        , allocaType = t
        , allocaElementCount = elementCount
        , allocaAlignment = alignment
        , allocaAddrSpace = addrSpace
        }

-- The atomic form is not modelled, and fails here at its ordering keyword
-- rather than being half-read.
pLoad :: Parser Operation
pLoad = do
  keyword "load"
  volatile <- option False (True <$ keyword "volatile")
  t <- pType
  symbol ","
  pointer <- pTypedValue
  alignment <- optional (try pAlignmentClause)
  pure $
    OLoad
      Load
        { loadVolatile = volatile
        , loadType = t
        , loadPointer = pointer
        , loadAlignment = alignment
        }

pStore :: Parser Operation
pStore = do
  keyword "store"
  volatile <- option False (True <$ keyword "volatile")
  value <- pTypedValue
  symbol ","
  pointer <- pTypedValue
  alignment <- optional (try pAlignmentClause)
  pure $
    OStore
      Store
        { storeVolatile = volatile
        , storeValue = value
        , storePointer = pointer
        , storeAlignment = alignment
        }

pGetElementPtr :: Parser Operation
pGetElementPtr = do
  keyword "getelementptr"
  flags <- many pGepFlag
  sourceType <- pType
  symbol ","
  pointer <- pTypedValue
  indices <- many (try (symbol "," *> pTypedValue))
  pure $
    OGetElementPtr
      GetElementPtr
        { gepFlags = flags
        , gepSourceType = sourceType
        , gepPointer = pointer
        , gepIndices = indices
        }

-- | @, align N@, which every memory operation may end with.
pAlignmentClause :: Parser Natural
pAlignmentClause = symbol "," *> keyword "align" *> pNatural

pRet :: Parser Operation
pRet = do
  keyword "ret"
  ORet <$> ((Nothing <$ keyword "void") <|> (Just <$> pTypedValue))

-- The unconditional form starts with the label keyword and the conditional
-- with a type, so one look is enough to tell them apart.
pBr :: Parser Operation
pBr = do
  keyword "br"
  (OBr <$> pLabelOperand) <|> pConditional
  where
    pConditional = do
      condition <- pTypedValue
      symbol ","
      ifTrue <- pLabelOperand
      symbol ","
      OCondBr condition ifTrue <$> pLabelOperand

-- The one terminator written across several lines.  Its cases sit between a
-- bracket pair that spans line breaks, so this is the only place the parser
-- steps over a newline within a construct.
pSwitch :: Parser Operation
pSwitch = do
  keyword "switch"
  scrutinee <- pTypedValue
  symbol ","
  defaultDestination <- pLabelOperand
  symbol "["
  cases <- many (try (verticalSpace *> pSwitchCase))
  verticalSpace
  _ <- char ']'
  hspace
  pure (OSwitch scrutinee defaultDestination cases)
  where
    pSwitchCase = do
      value <- pTypedValue
      symbol ","
      (,) value <$> pLabelOperand

pIndirectBr :: Parser Operation
pIndirectBr = do
  keyword "indirectbr"
  address <- pTypedValue
  symbol ","
  symbol "["
  destinations <- pLabelOperand `sepBy` symbol ","
  symbol "]"
  pure (OIndirectBr address destinations)

pGepFlag :: Parser GepFlag
pGepFlag =
  choice
    [ GepInbounds <$ keyword "inbounds"
    , GepNusw <$ keyword "nusw"
    , GepNuw <$ keyword "nuw"
    ]

pLabelOperand :: Parser Name
pLabelOperand = keyword "label" *> pLocalName

-- | @!llvm.loop !6@, following an instruction.
pMetadataAttachment :: Parser MetadataAttachment
pMetadataAttachment = do
  _ <- char '!'
  name <- pName
  MetadataAttachment name <$> pMetadataRef

-- Horizontal space and line breaks together, for the inside of a switch.
verticalSpace :: Parser ()
verticalSpace = skipMany (void (satisfy horizontal) <|> void eol)
  where
    horizontal c = c == ' ' || c == '\t'

-- * Metadata

-- | @!0 = !{...}@, optionally @distinct@.
pMetadata :: Parser Entry
pMetadata = do
  hspace
  _ <- char '!'
  number <- pNatural
  symbol "="
  distinctness <- option Uniqued (Distinct <$ keyword "distinct")
  operands <- pMetadataTuple
  endOfLine
  pure (EMetadata number distinctness operands)

-- | @!llvm.module.flags = !{!0, !1}@.
--
-- The name may not begin with a digit, which is what keeps this rule off the
-- numbered nodes: digits are identifier characters, so without the check a
-- name would happily match @0@.
pNamedMetadata :: Parser Entry
pNamedMetadata = do
  hspace
  _ <- char '!'
  notFollowedBy digitChar
  name <- pName
  symbol "="
  _ <- char '!'
  symbol "{"
  operands <- pMetadataRef `sepBy` symbol ","
  symbol "}"
  endOfLine
  pure (ENamedMetadata name operands)

pMetadataTuple :: Parser [MetadataOperand]
pMetadataTuple =
  char '!' *> symbol "{" *> (pMetadataOperand `sepBy` symbol ",") <* symbol "}"

pMetadataRef :: Parser Natural
pMetadataRef = char '!' *> pNatural

-- Each alternative beginning with @!@ has to be tried, since they are told
-- apart only by what follows it.
pMetadataOperand :: Parser MetadataOperand
pMetadataOperand =
  choice
    [ MDNull <$ keyword "null"
    , try (MDString <$> (char '!' *> pQuoted <* hspace))
    , try (MDRef <$> pMetadataRef)
    , MDTuple <$> pMetadataTuple
    , MDValue <$> pTypedValue
    ]

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

-- * Operands

pValue :: Parser Value
pValue =
  choice
    [ VLocal <$> pLocalName
    , VZeroInitializer <$ keyword "zeroinitializer"
    , VNull <$ keyword "null"
    , VNone <$ keyword "none"
    , VUndef <$ keyword "undef"
    , VPoison <$ keyword "poison"
    , VBoolean True <$ keyword "true"
    , VBoolean False <$ keyword "false"
    , pStringValue
    , pGetElementPtrValue
    , pCastValue
    , VGlobal <$> pGlobalName
    , pArrayValue
    , pAngleValue
    , pStructValue Unpacked
    , pNumericValue
    ]

-- | An operand written with its type, as in the elements of an aggregate.
pTypedValue :: Parser TypedValue
pTypedValue = TypedValue <$> pType <*> pValue

pStringValue :: Parser Value
pStringValue = VString <$> try (char 'c' *> pQuoted) <* hspace

pArrayValue :: Parser Value
pArrayValue =
  VArray <$> (symbol "[" *> pTypedValue `sepBy` symbol "," <* symbol "]")

-- As in the type grammar, an opening angle bracket starts either a vector or
-- a packed struct.
pAngleValue :: Parser Value
pAngleValue = do
  symbol "<"
  c <- pStructValue Packed <|> (VVector <$> pTypedValue `sepBy` symbol ",")
  symbol ">"
  pure c

pStructValue :: Packedness -> Parser Value
pStructValue packedness =
  VStruct packedness
    <$> (symbol "{" *> pTypedValue `sepBy` symbol "," <* symbol "}")

pCastValue :: Parser Value
pCastValue = do
  op <-
    choice
      [ CastTrunc <$ keyword "trunc"
      , CastPtrToInt <$ keyword "ptrtoint"
      , CastIntToPtr <$ keyword "inttoptr"
      , CastBitcast <$ keyword "bitcast"
      , CastAddrSpaceCast <$ keyword "addrspacecast"
      ]
  symbol "("
  value <- pTypedValue
  keyword "to"
  target <- pType
  symbol ")"
  pure (VCast op value target)

-- | @getelementptr inbounds nuw (i8, ptr \@g, i64 8)@.  The first item inside
-- the parentheses is the source element type, not an operand.
pGetElementPtrValue :: Parser Value
pGetElementPtrValue = do
  keyword "getelementptr"
  flags <- many pGepFlag
  symbol "("
  element <- pType
  symbol ","
  operands <- pTypedValue `sepBy1` symbol ","
  symbol ")"
  pure (VGetElementPtr flags element operands)

-- | An integer or a floating point literal.
--
-- LLVM writes integers only in decimal, so a @0x@ prefix is unambiguously a
-- float; otherwise a decimal point or an exponent is what distinguishes the
-- two.  Floats are kept as text — see 'VFloat'.
pNumericValue :: Parser Value
pNumericValue = try (VFloat <$> pHexFloat) <|> try pDecimalNumber

pHexFloat :: Parser Text
pHexFloat = do
  prefix <- string "0x"
  -- The letter selects the format: half, bfloat, x86_fp80, fp128, ppc_fp128.
  kind <- option "" (T.singleton <$> oneOf ("KLMHR" :: String))
  digits <- takeWhile1P (Just "hexadecimal digit") isHexDigit
  hspace
  pure (prefix <> kind <> digits)

pDecimalNumber :: Parser Value
pDecimalNumber = do
  sign <- option "" (T.singleton <$> char '-')
  whole <- takeWhile1P (Just "digit") isDigit
  fractional <- optional (T.cons <$> char '.' <*> takeWhileP (Just "digit") isDigit)
  exponent' <- optional pExponent
  notFollowedBy (satisfy isIdentifierChar)
  hspace
  pure $ case (fractional, exponent') of
    (Nothing, Nothing) -> VInteger (read (T.unpack (sign <> whole)))
    _ ->
      VFloat
        ( sign
            <> whole
            <> fromMaybe T.empty fractional
            <> fromMaybe T.empty exponent'
        )
  where
    pExponent = do
      e <- oneOf ("eE" :: String)
      s <- option "" (T.singleton <$> oneOf ("+-" :: String))
      digits <- takeWhile1P (Just "digit") isDigit
      pure (T.cons e (s <> digits))

-- * Identifiers and literals

pLocalName :: Parser Name
pLocalName = char '%' *> pName

pGlobalName :: Parser Name
pGlobalName = char '@' *> pName

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
