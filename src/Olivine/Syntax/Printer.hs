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
  , renderValue
  , renderType
  , renderName
  , renderInstructionFlag
  , renderLinkage
  , renderParamAttribute
  ) where

import Data.List.NonEmpty qualified as NE
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (catMaybes)
import Data.Text (Text)
import Data.Text qualified as T
import Numeric.Natural (Natural)

import Olivine.Syntax.Ast
import Olivine.Syntax.Attribute
import Olivine.Syntax.Comdat
import Olivine.Syntax.Value
import Olivine.Syntax.Function
import Olivine.Syntax.Global
import Olivine.Syntax.Instruction
import Olivine.Syntax.Linkage
import Olivine.Syntax.Metadata
import Olivine.Syntax.Name
import Olivine.Syntax.Type

-- | A module, laid out the way LLVM lays one out.
--
-- Blank lines are not carried through the syntax tree, so they are put back
-- here.  LLVM separates one kind of top-level construct from the next with a
-- blank line — the header from the globals, the globals from the functions,
-- the attribute groups from the metadata — and writes one before every
-- function and every comdat whatever precedes it, which is why two @declare@s
-- have a gap between them and two globals do not.
--
-- The @; Function Attrs:@ line above a function is written here rather than by
-- 'renderEntry', because it is not a fact about the entry: it names attributes
-- the entry may only reference, and the group holding them is elsewhere in the
-- module.  It goes below the blank line, being part of what the function
-- prints as.
renderModule :: Module -> Text
renderModule (Module entries) = T.unlines (go Nothing (zip entries (map groupOf entries)))
  where
    go _ [] = []
    go previous ((entry, group) : rest) =
      [T.empty | separated previous group]
        <> functionAttributes groups entry
        <> (renderEntry entry : go (Just group) rest)
    separated Nothing _ = False
    separated (Just before) group =
      before /= group || group == Functions || group == Comdats
    groups = attributeGroupsOf entries

-- | The attributes of each group the module defines.
attributeGroupsOf :: [Entry] -> Map Natural [FunctionAttribute]
attributeGroupsOf entries =
  Map.fromList [(n, NE.toList as) | EAttributeGroup n as <- entries]

-- | The @; Function Attrs:@ line LLVM writes above a function that has any.
--
-- Derived rather than carried, for the same reason as the @; preds =@ comment
-- on a label: it restates the function's attributes, so a pass that changed
-- them would leave a copy saying what used to be true.
--
-- What it lists is every attribute of the function that is not a string one,
-- with the group references expanded in place.  The string attributes are how
-- the front end passes target configuration through — @"target-cpu"="x86-64"@
-- and its dozen neighbours — and LLVM leaves them out of the summary, which is
-- what keeps the summary readable.  A function whose attributes are all
-- strings therefore gets no line at all.
functionAttributes :: Map Natural [FunctionAttribute] -> Entry -> [Text]
functionAttributes groups entry = case entry of
  EDeclare signature -> summary signature
  EDefine d -> summary (definitionSignature d)
  _ -> []
  where
    summary signature =
      case concatMap expand (signatureAttributes signature) of
        [] -> []
        attributes ->
          [ "; Function Attrs: "
              <> T.unwords (map (renderFunctionAttribute OnFunction) attributes)
          ]
    expand (AIGroup n) = filter enumerated (Map.findWithDefault [] n groups)
    expand (AIAttribute a) = [a | enumerated a]
    enumerated FAString{} = False
    enumerated _ = True

-- | The kinds of top-level construct a blank line goes between.
data Group
  = Header
  | Types
  | -- | Written one to a paragraph, as functions are.
    Comdats
  | Globals
  | -- | LLVM writes the aliases after the globals and blank-line separated
    -- from them, rather than in among them, and the ifuncs after those again.
    Aliases
  | IFuncs
  | Functions
  | Attributes
  | NamedNodes
  | Nodes
  | -- | A construct not modelled.
    Unread
  deriving (Eq)

groupOf :: Entry -> Group
groupOf entry = case entry of
  EModuleId _ -> Header
  ESourceFilename _ -> Header
  ETargetDataLayout _ -> Header
  ETargetTriple _ -> Header
  ETypeDefinition _ _ -> Types
  EComdat _ _ -> Comdats
  EGlobal _ -> Globals
  EIndirect s -> case indirectKind s of
    IndirectAlias -> Aliases
    IndirectIFunc -> IFuncs
  EDeclare _ -> Functions
  EDefine _ -> Functions
  EAttributeGroup _ _ -> Attributes
  ENamedMetadata _ _ -> NamedNodes
  EMetadata{} -> Nodes
  EOpaque _ -> Unread

renderEntry :: Entry -> Text
renderEntry (EModuleId name) = "; ModuleID = " <> singleQuoted name
renderEntry (ESourceFilename name) = "source_filename = " <> quoted name
renderEntry (ETargetDataLayout spec) = "target datalayout = " <> quoted spec
renderEntry (ETargetTriple spec) = "target triple = " <> quoted spec
renderEntry (ETypeDefinition name t) =
  "%" <> renderName name <> " = type " <> renderType t
renderEntry (EComdat name selection) =
  "$" <> renderName name <> " = comdat " <> renderSelection selection
renderEntry (EGlobal g) = renderGlobal g
renderEntry (EIndirect s) = renderIndirect s
renderEntry (EDeclare s) = "declare " <> renderSignature Leading s
renderEntry (EDefine d) = renderDefinition d
renderEntry (EAttributeGroup n attributes) =
  "attributes #" <> showText n <> " = " <> renderAttributeGroupBody attributes
renderEntry (EMetadata number distinctness operands) =
  "!"
    <> showText number
    <> " = "
    <> (case distinctness of Uniqued -> ""; Distinct -> "distinct ")
    <> renderMetadataTuple operands
renderEntry (ENamedMetadata name operands) =
  "!"
    <> renderName name
    <> " = !{"
    <> T.intercalate ", " ["!" <> showText n | n <- operands]
    <> "}"
renderEntry (EOpaque t) = t

renderDefinition :: Definition -> Text
renderDefinition d =
  T.intercalate "\n" $
    ("define " <> renderSignature Trailing (definitionSignature d) <> " {")
      : concat (zipWith renderBasicBlock [0 :: Int ..] (definitionBlocks d))
      <> ["}"]

renderBasicBlock :: Int -> BasicBlock -> [Text]
renderBasicBlock index block =
  -- Every label but the first in a function is preceded by a blank line.
  ["" | index > 0]
    <> foldMap (pure . renderBlockLabel) (blockLabel block)
    <> concatMap renderInstruction (blockBody block)

-- | An instruction may occupy more than one line, so this yields lines
-- rather than text.  A modelled instruction gets its indentation generated;
-- an opaque one carries its own, having nothing to generate it from.
renderInstruction :: Instruction -> [Text]
renderInstruction (IOpaque raw) = [raw]
renderInstruction (IOperation result operation attachments) =
  case renderOperation operation of
    [] -> []
    first : rest ->
      appendToLast suffix (("  " <> assignment <> first) : map ("  " <>) rest)
  where
    assignment = foldMap (\name -> "%" <> renderName name <> " = ") result
    suffix =
      T.concat
        [ ", !" <> renderName name <> " !" <> showText node
        | MetadataAttachment name node <- attachments
        ]

-- Metadata follows the whole instruction, which for a switch means after its
-- closing bracket rather than on the line the switch begins on.
appendToLast :: Text -> [Text] -> [Text]
appendToLast suffix ls = case reverse ls of
  [] -> []
  final : earlier -> reverse ((final <> suffix) : earlier)

renderOperation :: Operation (TypedValue Name) -> [Text]
renderOperation (ORet Nothing) = ["ret void"]
renderOperation (ORet (Just v)) = ["ret " <> renderTypedValue v]
renderOperation (OBr destination) = ["br " <> renderLabel destination]
renderOperation (OCondBr condition ifTrue ifFalse) =
  [ "br "
      <> renderTypedValue condition
      <> ", "
      <> renderLabel ifTrue
      <> ", "
      <> renderLabel ifFalse
  ]
renderOperation (OSwitch scrutinee defaultDestination cases) =
  ["switch " <> renderTypedValue scrutinee <> ", " <> renderLabel defaultDestination <> " ["]
    <> [ "  " <> renderTypedValue value <> ", " <> renderLabel destination
       | (value, destination) <- cases
       ]
    <> ["]"]
renderOperation (OIndirectBr address destinations) =
  [ "indirectbr "
      <> renderTypedValue address
      <> ", ["
      <> T.intercalate ", " (map renderLabel destinations)
      <> "]"
  ]
renderOperation OUnreachable = ["unreachable"]
renderOperation (OBinary b) =
  [ T.concat
      [ renderBinaryOp (binaryOp b)
      , " "
      , renderFlags (binaryFlags b)
      , renderType (typedValueType (binaryLeft b))
      , " "
      , renderValue (typedValue (binaryLeft b))
      , ", "
      , renderValue (typedValue (binaryRight b))
      ]
  ]
renderOperation (OUnary u) =
  [ T.concat
      [ renderUnaryOp (unaryOp u)
      , " "
      , renderFlags (unaryFlags u)
      , renderType (typedValueType (unaryOperand u))
      , " "
      , renderValue (typedValue (unaryOperand u))
      ]
  ]
renderOperation (OSelect s) =
  [ T.concat
      [ "select "
      , renderFlags (selectFlags s)
      , T.intercalate
          ", "
          (map renderTypedValue [selectCondition s, selectTrue s, selectFalse s])
      ]
  ]
renderOperation (OExtractElement e) =
  [ "extractelement "
      <> T.intercalate
        ", "
        (map renderTypedValue [extractElementVector e, extractElementIndex e])
  ]
renderOperation (OInsertElement i) =
  [ "insertelement "
      <> T.intercalate
        ", "
        ( map
            renderTypedValue
            [insertElementVector i, insertElementValue i, insertElementIndex i]
        )
  ]
renderOperation (OExtractValue e) =
  [ "extractvalue "
      <> renderTypedValue (extractValueAggregate e)
      <> renderIndices (extractValueIndices e)
  ]
renderOperation (OInsertValue i) =
  [ "insertvalue "
      <> renderTypedValue (insertValueAggregate i)
      <> ", "
      <> renderTypedValue (insertValueValue i)
      <> renderIndices (insertValueIndices i)
  ]
renderOperation (OShuffleVector v) =
  [ "shufflevector "
      <> T.intercalate
        ", "
        ( map
            renderTypedValue
            [shuffleVectorLeft v, shuffleVectorRight v, shuffleVectorMask v]
        )
  ]
renderOperation (OPhi p) =
  [ T.concat
      [ "phi "
      , renderFlags (phiFlags p)
      , renderType (phiType p)
      , " "
      , T.intercalate
          ", "
          [ "[ " <> renderValue (typedValue value) <> ", %" <> renderName predecessor <> " ]"
          | (value, predecessor) <- phiIncoming p
          ]
      ]
  ]
renderOperation (OCall c) =
  [foldMap ((<> " ") . renderTailKind) (callTail c) <> "call " <> renderCall c]
-- LLVM writes the two destinations on a line of their own, indented ten
-- spaces; the two this adds are the two the caller puts in front of every
-- line but the first.
renderOperation (OInvoke i) =
  [ "invoke " <> renderCall (invokeCall i)
  , T.concat
      [ "        to "
      , renderLabel (invokeNormal i)
      , " unwind "
      , renderLabel (invokeUnwind i)
      ]
  ]
-- The destinations go on a line of their own like an invoke's, the indirect
-- ones between brackets however many there are.  LLVM writes the brackets
-- even when they hold nothing.
renderOperation (OCallBr c) =
  [ "callbr " <> renderCall (callBrCall c)
  , T.concat
      [ "        to "
      , renderLabel (callBrFallthrough c)
      , " ["
      , T.intercalate ", " (map renderLabel (callBrIndirect c))
      , "]"
      ]
  ]
renderOperation (OLandingPad p) =
  ("landingpad " <> renderType (landingPadType p))
    : ["        cleanup" | landingPadCleanup p]
    <> map (("        " <>) . renderClause) (landingPadClauses p)
  where
    renderClause (LPCatch t) = "catch " <> renderTypedValue t
    renderClause (LPFilter t) = "filter " <> renderTypedValue t
renderOperation (OResume value) = ["resume " <> renderTypedValue value]
renderOperation (OConvert c) =
  [ T.concat
      [ renderCastOp (convertOp c)
      , " "
      , renderFlags (convertFlags c)
      , renderTypedValue (convertOperand c)
      , " to "
      , renderType (convertTarget c)
      ]
  ]
renderOperation (OICmp c) = [renderCompare "icmp" renderIntPredicate c]
renderOperation (OFCmp c) = [renderCompare "fcmp" renderFloatPredicate c]
renderOperation (OAlloca a) =
  [ T.concat
      [ "alloca "
      , if allocaInalloca a then "inalloca " else ""
      , renderType (allocaType a)
      , foldMap ((", " <>) . renderTypedValue) (allocaElementCount a)
      , renderAlignment (allocaAlignment a)
      , foldMap (\n -> ", addrspace(" <> showText n <> ")") (allocaAddrSpace a)
      ]
  ]
renderOperation (OLoad l) =
  [ T.concat
      [ "load "
      , if loadVolatile l then "volatile " else ""
      , renderType (loadType l)
      , ", "
      , renderTypedValue (loadPointer l)
      , renderAlignment (loadAlignment l)
      ]
  ]
renderOperation (OStore s) =
  [ T.concat
      [ "store "
      , if storeVolatile s then "volatile " else ""
      , renderTypedValue (storeValue s)
      , ", "
      , renderTypedValue (storePointer s)
      , renderAlignment (storeAlignment s)
      ]
  ]
renderOperation (OAtomicLoad l) =
  [ T.concat
      [ "load atomic "
      , if atomicLoadVolatile l then "volatile " else ""
      , renderType (atomicLoadType l)
      , ", "
      , renderTypedValue (atomicLoadPointer l)
      , renderSyncScope (atomicLoadScope l)
      , " "
      , renderAtomicOrdering (atomicLoadOrdering l)
      , renderAlignment (atomicLoadAlignment l)
      ]
  ]
renderOperation (OAtomicStore s) =
  [ T.concat
      [ "store atomic "
      , if atomicStoreVolatile s then "volatile " else ""
      , renderTypedValue (atomicStoreValue s)
      , ", "
      , renderTypedValue (atomicStorePointer s)
      , renderSyncScope (atomicStoreScope s)
      , " "
      , renderAtomicOrdering (atomicStoreOrdering s)
      , renderAlignment (atomicStoreAlignment s)
      ]
  ]
renderOperation (OAtomicRmw r) =
  [ T.concat
      [ "atomicrmw "
      , if atomicRmwVolatile r then "volatile " else ""
      , renderRmwOp (atomicRmwOp r)
      , " "
      , renderTypedValue (atomicRmwPointer r)
      , ", "
      , renderTypedValue (atomicRmwValue r)
      , renderSyncScope (atomicRmwScope r)
      , " "
      , renderAtomicOrdering (atomicRmwOrdering r)
      , renderAlignment (atomicRmwAlignment r)
      ]
  ]
renderOperation (OCmpXchg c) =
  [ T.concat
      [ "cmpxchg "
      , if cmpXchgWeak c then "weak " else ""
      , if cmpXchgVolatile c then "volatile " else ""
      , renderTypedValue (cmpXchgPointer c)
      , ", "
      , renderTypedValue (cmpXchgCompare c)
      , ", "
      , renderTypedValue (cmpXchgReplacement c)
      , renderSyncScope (cmpXchgScope c)
      , " "
      , renderAtomicOrdering (cmpXchgSuccess c)
      , " "
      , renderAtomicOrdering (cmpXchgFailure c)
      , renderAlignment (cmpXchgAlignment c)
      ]
  ]
renderOperation (OFence f) =
  [ T.concat
      [ "fence"
      , renderSyncScope (fenceScope f)
      , " "
      , renderAtomicOrdering (fenceOrdering f)
      ]
  ]
renderOperation (OGetElementPtr g) =
  [ T.concat
      [ "getelementptr "
      , T.concat [renderGepFlag f <> " " | f <- gepFlags g]
      , renderType (gepSourceType g)
      , ", "
      , renderTypedValue (gepPointer g)
      , T.concat [", " <> renderTypedValue i | i <- gepIndices g]
      ]
  ]

-- | A call from its flags to its attributes, which is all an @invoke@ shares
-- with a @call@: the keyword and what follows the argument list are each
-- caller's own.
renderCall :: Call (TypedValue Name) -> Text
renderCall c =
  T.concat
    [ renderFlags (callFlags c)
    , foldMap ((<> " ") . renderCallingConvention) (callCallingConvention c)
    , T.concat [renderParamAttribute a <> " " | a <- callReturnAttributes c]
    , foldMap (\n -> "addrspace(" <> showText n <> ") ") (callAddrSpace c)
    , renderType (callType c)
    , " "
    , renderValue (typedValue (callCallee c))
    , "("
    , T.intercalate ", " (map renderArgument (callArguments c))
    , ")"
    , T.concat [" " <> renderAttributeItem a | a <- callAttributes c]
    , renderOperandBundles (callBundles c)
    ]

-- | @ [ "tag"(\<operands\>), "tag"() ]@, or nothing at all when there are none.
--
-- LLVM puts a space inside each bracket and none inside the parentheses, which
-- is what it prints and so what is written back.
renderOperandBundles :: [OperandBundle (TypedValue Name)] -> Text
renderOperandBundles [] = ""
renderOperandBundles bundles =
  " [ " <> T.intercalate ", " (map renderOperandBundle bundles) <> " ]"
  where
    renderOperandBundle b =
      T.concat
        [ "\""
        , bundleTag b
        , "\"("
        , T.intercalate ", " (map renderTypedValue (bundleOperands b))
        , ")"
        ]

renderTailKind :: TailKind -> Text
renderTailKind Tail = "tail"
renderTailKind MustTail = "musttail"
renderTailKind NoTail = "notail"

renderArgument :: Argument (TypedValue Name) -> Text
renderArgument a =
  T.concat
    [ renderType (typedValueType (argumentValue a))
    , " "
    , T.concat [renderParamAttribute x <> " " | x <- argumentAttributes a]
    , renderValue (typedValue (argumentValue a))
    ]

renderCompare ::
  Text -> (predicate -> Text) -> Compare predicate (TypedValue Name) -> Text
renderCompare name renderPredicate c =
  T.concat
    [ name
    , " "
    , renderFlags (compareFlags c)
    , renderPredicate (comparePredicate c)
    , " "
    , renderType (typedValueType (compareLeft c))
    , " "
    , renderValue (typedValue (compareLeft c))
    , ", "
    , renderValue (typedValue (compareRight c))
    ]

-- Each flag is followed by a space, so an empty list contributes nothing.
renderFlags :: [InstructionFlag] -> Text
renderFlags flags = T.concat [renderInstructionFlag f <> " " | f <- flags]

renderBinaryOp :: BinaryOp -> Text
renderBinaryOp OpAdd = "add"
renderBinaryOp OpSub = "sub"
renderBinaryOp OpMul = "mul"
renderBinaryOp OpUDiv = "udiv"
renderBinaryOp OpSDiv = "sdiv"
renderBinaryOp OpURem = "urem"
renderBinaryOp OpSRem = "srem"
renderBinaryOp OpShl = "shl"
renderBinaryOp OpLShr = "lshr"
renderBinaryOp OpAShr = "ashr"
renderBinaryOp OpAnd = "and"
renderBinaryOp OpOr = "or"
renderBinaryOp OpXor = "xor"
renderBinaryOp OpFAdd = "fadd"
renderBinaryOp OpFSub = "fsub"
renderBinaryOp OpFMul = "fmul"
renderBinaryOp OpFDiv = "fdiv"
renderBinaryOp OpFRem = "frem"

renderUnaryOp :: UnaryOp -> Text
renderUnaryOp OpFNeg = "fneg"

renderIntPredicate :: IntPredicate -> Text
renderIntPredicate IEq = "eq"
renderIntPredicate INe = "ne"
renderIntPredicate IUgt = "ugt"
renderIntPredicate IUge = "uge"
renderIntPredicate IUlt = "ult"
renderIntPredicate IUle = "ule"
renderIntPredicate ISgt = "sgt"
renderIntPredicate ISge = "sge"
renderIntPredicate ISlt = "slt"
renderIntPredicate ISle = "sle"

renderFloatPredicate :: FloatPredicate -> Text
renderFloatPredicate FFalse = "false"
renderFloatPredicate FOeq = "oeq"
renderFloatPredicate FOgt = "ogt"
renderFloatPredicate FOge = "oge"
renderFloatPredicate FOlt = "olt"
renderFloatPredicate FOle = "ole"
renderFloatPredicate FOne = "one"
renderFloatPredicate FOrd = "ord"
renderFloatPredicate FUeq = "ueq"
renderFloatPredicate FUgt = "ugt"
renderFloatPredicate FUge = "uge"
renderFloatPredicate FUlt = "ult"
renderFloatPredicate FUle = "ule"
renderFloatPredicate FUne = "une"
renderFloatPredicate FUno = "uno"
renderFloatPredicate FTrue = "true"

renderInstructionFlag :: InstructionFlag -> Text
renderInstructionFlag FlagNUW = "nuw"
renderInstructionFlag FlagNSW = "nsw"
renderInstructionFlag FlagExact = "exact"
renderInstructionFlag FlagDisjoint = "disjoint"
renderInstructionFlag FlagSameSign = "samesign"
renderInstructionFlag FlagNNeg = "nneg"
renderInstructionFlag FlagNNaN = "nnan"
renderInstructionFlag FlagNInf = "ninf"
renderInstructionFlag FlagNSZ = "nsz"
renderInstructionFlag FlagARcp = "arcp"
renderInstructionFlag FlagContract = "contract"
renderInstructionFlag FlagAFn = "afn"
renderInstructionFlag FlagReassoc = "reassoc"
renderInstructionFlag FlagFast = "fast"

renderAlignment :: Maybe Natural -> Text
renderAlignment = foldMap (\n -> ", align " <> showText n)

renderLabel :: Name -> Text
renderLabel name = "label %" <> renderName name

-- LLVM pads the label out to 49 columns and then writes a single space, so a
-- comment lands in column 51 unless the label is too wide to allow it.
renderBlockLabel :: BlockLabel -> Text
renderBlockLabel (BlockLabel name Nothing) = renderName name <> ":"
renderBlockLabel (BlockLabel name (Just comment)) =
  T.justifyLeft 49 ' ' (renderName name <> ":") <> " " <> comment

renderMetadataTuple :: [MetadataOperand] -> Text
renderMetadataTuple operands =
  "!{" <> T.intercalate ", " (map renderMetadataOperand operands) <> "}"

renderMetadataOperand :: MetadataOperand -> Text
renderMetadataOperand (MDRef n) = "!" <> showText n
renderMetadataOperand (MDString s) = "!" <> quoted s
renderMetadataOperand (MDValue v) = renderTypedValue v
renderMetadataOperand MDNull = "null"
renderMetadataOperand (MDTuple operands) = renderMetadataTuple operands

-- LLVM spaces the braces off from the attributes.
renderAttributeGroupBody :: NE.NonEmpty FunctionAttribute -> Text
renderAttributeGroupBody attributes =
  "{ "
    <> T.unwords (map (renderFunctionAttribute InGroup) (NE.toList attributes))
    <> " }"

renderAttributeItem :: AttributeItem -> Text
renderAttributeItem (AIGroup n) = "#" <> showText n
renderAttributeItem (AIAttribute a) = renderFunctionAttribute OnFunction a

renderSignature :: AttachmentPosition -> Signature -> Text
renderSignature position s =
  T.unwords $
    leading
      <> modifiers
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
        <> map renderAttributeItem (signatureAttributes s)
        -- The clauses a global writes commas between, a function does not.
        <> map renderGlobalAttribute (signatureClauses s)
        <> map renderFunctionClause (signatureFunctionClauses s)
        <> trailingAttachments
    (leading, trailingAttachments) = case position of
      Leading -> (attachments, [])
      Trailing -> ([], attachments)
    attachments =
      [ "!" <> renderName name <> " !" <> showText node
      | MetadataAttachment name node <- signatureMetadata s
      ]

renderFunctionClause :: FunctionClause -> Text
renderFunctionClause (FCGarbageCollector name) = "gc \"" <> name <> "\""
renderFunctionClause (FCPrefix value) = "prefix " <> renderTypedValue value
renderFunctionClause (FCPrologue value) = "prologue " <> renderTypedValue value
renderFunctionClause (FCPersonality value) =
  "personality " <> renderTypedValue value

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
    <> T.concat
      [ ", !" <> renderName name <> " !" <> showText node
      | MetadataAttachment name node <- globalMetadata g
      ]
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
        <> foldMap (pure . renderValue) (globalInitializer g)
    guarded b = if b then Just () else Nothing

-- | The target's type is written when it was: LLVM omits it exactly where the
-- target is a constant expression, and 'indirectTargetType' is absent exactly
-- there, so the rule needs stating in neither place twice.
--
-- The modifiers are written back whichever keyword this is, although LLVM
-- keeps fewer of them for an ifunc than for an alias: it accepts
-- @unnamed_addr@, @thread_local@ and @dllexport@ on one and then drops them,
-- having nowhere in its model of an ifunc to put them.  Olivine writes back
-- what it read, here as everywhere.
renderIndirect :: IndirectSymbol -> Text
renderIndirect s =
  T.unwords (["@" <> renderName (indirectName s), "="] <> modifiers <> body)
    <> foldMap (\p -> ", partition " <> quoted p) (indirectPartition s)
  where
    modifiers =
      catMaybes
        [ renderLinkage <$> indirectLinkage s
        , renderPreemption <$> indirectPreemption s
        , renderVisibility <$> indirectVisibility s
        , renderDLLStorage <$> indirectDLLStorage s
        , renderThreadLocality <$> indirectThreadLocality s
        , renderUnnamedAddr <$> indirectUnnamedAddr s
        ]
    body =
      [renderIndirectKind (indirectKind s), renderType (indirectType s) <> ","]
        <> foldMap (pure . renderType) (indirectTargetType s)
        <> [renderValue (indirectTarget s)]

renderIndirectKind :: IndirectKind -> Text
renderIndirectKind IndirectAlias = "alias"
renderIndirectKind IndirectIFunc = "ifunc"

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

renderSelection :: Selection -> Text
renderSelection SelectAny = "any"
renderSelection SelectExactMatch = "exactmatch"
renderSelection SelectLargest = "largest"
renderSelection SelectNoDeduplicate = "nodeduplicate"
renderSelection SelectSameSize = "samesize"

renderGlobalAttribute :: GlobalAttribute -> Text
renderGlobalAttribute (GASection name) = "section " <> quoted name
renderGlobalAttribute (GAPartition name) = "partition " <> quoted name
renderGlobalAttribute (GAComdat Nothing) = "comdat"
renderGlobalAttribute (GAComdat (Just name)) =
  "comdat($" <> renderName name <> ")"
renderGlobalAttribute (GAAlign n) = "align " <> showText n

renderValue :: Value Name -> Text
renderValue (VLocal name) = "%" <> renderName name
renderValue (VInteger n) = showText n
renderValue (VBoolean True) = "true"
renderValue (VBoolean False) = "false"
renderValue (VFloat raw) = raw
renderValue VNull = "null"
renderValue VNone = "none"
renderValue VUndef = "undef"
renderValue VPoison = "poison"
renderValue VZeroInitializer = "zeroinitializer"
renderValue (VString s) = "c" <> quoted s
renderValue (VArray elements) = "[" <> renderElements elements <> "]"
renderValue (VVector elements) = "<" <> renderElements elements <> ">"
renderValue (VSplat element) = "splat (" <> renderTypedValue element <> ")"
renderValue (VStruct Unpacked fields) = renderStructFields fields
renderValue (VStruct Packed fields) =
  "<" <> renderStructFields fields <> ">"
renderValue (VGlobal name) = "@" <> renderName name
renderValue (VBlockAddress function block) =
  "blockaddress(@" <> renderName function <> ", %" <> renderName block <> ")"
renderValue (VAsm a) =
  T.concat
    [ "asm"
    , word " sideeffect" (asmSideEffect a)
    , word " alignstack" (asmAlignStack a)
    , word " inteldialect" (asmIntelDialect a)
    , word " unwind" (asmUnwind a)
    , " "
    , quoted (asmTemplate a)
    , ", "
    , quoted (asmConstraints a)
    ]
  where
    word text present = if present then text else ""
renderValue (VCast op value target) =
  renderCastOp op
    <> " ("
    <> renderTypedValue value
    <> " to "
    <> renderType target
    <> ")"
renderValue (VGetElementPtr flags element operands) =
  T.concat
    [ "getelementptr"
    , T.concat [" " <> renderGepFlag f | f <- flags]
    , " ("
    , T.intercalate ", " (renderType element : map renderTypedValue operands)
    , ")"
    ]

-- | The scope an ordering is against, with the space that precedes it, since
-- it stands between two things and is written only when it is there.
renderSyncScope :: Maybe Text -> Text
renderSyncScope = foldMap (\scope -> " syncscope(" <> quoted scope <> ")")

renderAtomicOrdering :: AtomicOrdering -> Text
renderAtomicOrdering ordering = case ordering of
  Unordered -> "unordered"
  Monotonic -> "monotonic"
  Acquire -> "acquire"
  Release -> "release"
  AcquireRelease -> "acq_rel"
  SequentiallyConsistent -> "seq_cst"

renderRmwOp :: RmwOp -> Text
renderRmwOp op = case op of
  RmwXchg -> "xchg"
  RmwAdd -> "add"
  RmwSub -> "sub"
  RmwAnd -> "and"
  RmwNand -> "nand"
  RmwOr -> "or"
  RmwXor -> "xor"
  RmwMax -> "max"
  RmwMin -> "min"
  RmwUMax -> "umax"
  RmwUMin -> "umin"
  RmwFAdd -> "fadd"
  RmwFSub -> "fsub"
  RmwFMax -> "fmax"
  RmwFMin -> "fmin"
  RmwFMaximum -> "fmaximum"
  RmwFMinimum -> "fminimum"
  RmwUIncWrap -> "uinc_wrap"
  RmwUDecWrap -> "udec_wrap"
  RmwUSubCond -> "usub_cond"
  RmwUSubSat -> "usub_sat"

-- | The path an aggregate operation reads, each index after its own comma.
renderIndices :: [Natural] -> Text
renderIndices indices = T.concat [", " <> showText i | i <- indices]

renderTypedValue :: TypedValue Name -> Text
renderTypedValue (TypedValue t c) =
  renderType t <> " " <> renderValue c

-- LLVM writes array and vector constants without spaces inside the brackets,
-- but struct constants with them, matching how it writes the types.
renderElements :: [TypedValue Name] -> Text
renderElements = T.intercalate ", " . map renderTypedValue

renderStructFields :: [TypedValue Name] -> Text
renderStructFields [] = "{}"
renderStructFields fields = "{ " <> renderElements fields <> " }"

renderCastOp :: CastOp -> Text
renderCastOp CastTrunc = "trunc"
renderCastOp CastZExt = "zext"
renderCastOp CastSExt = "sext"
renderCastOp CastFPTrunc = "fptrunc"
renderCastOp CastFPExt = "fpext"
renderCastOp CastFPToUI = "fptoui"
renderCastOp CastFPToSI = "fptosi"
renderCastOp CastUIToFP = "uitofp"
renderCastOp CastSIToFP = "sitofp"
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

renderFunctionAttribute :: AttributeContext -> FunctionAttribute -> Text
renderFunctionAttribute _ FAAlwaysInline = "alwaysinline"
renderFunctionAttribute _ FABuiltin = "builtin"
renderFunctionAttribute _ FACold = "cold"
renderFunctionAttribute _ FAConvergent = "convergent"
renderFunctionAttribute _ FADisableSanitizerInstrumentation =
  "disable_sanitizer_instrumentation"
renderFunctionAttribute _ FAFnRetThunkExtern = "fn_ret_thunk_extern"
renderFunctionAttribute _ FAHot = "hot"
renderFunctionAttribute _ FAInlineHint = "inlinehint"
renderFunctionAttribute _ FAJumpTable = "jumptable"
renderFunctionAttribute _ FAMinSize = "minsize"
renderFunctionAttribute _ FAMustProgress = "mustprogress"
renderFunctionAttribute _ FANaked = "naked"
renderFunctionAttribute _ FANoBuiltin = "nobuiltin"
renderFunctionAttribute _ FANoCallback = "nocallback"
renderFunctionAttribute _ FANoCfCheck = "nocf_check"
renderFunctionAttribute _ FANoDuplicate = "noduplicate"
renderFunctionAttribute _ FANoFree = "nofree"
renderFunctionAttribute _ FANoImplicitFloat = "noimplicitfloat"
renderFunctionAttribute _ FANoInline = "noinline"
renderFunctionAttribute _ FANoMerge = "nomerge"
renderFunctionAttribute _ FANonLazyBind = "nonlazybind"
renderFunctionAttribute _ FANoProfile = "noprofile"
renderFunctionAttribute _ FANoRecurse = "norecurse"
renderFunctionAttribute _ FANoRedZone = "noredzone"
renderFunctionAttribute _ FANoReturn = "noreturn"
renderFunctionAttribute _ FANoSanitizeBounds = "nosanitize_bounds"
renderFunctionAttribute _ FANoSanitizeCoverage = "nosanitize_coverage"
renderFunctionAttribute _ FANoSync = "nosync"
renderFunctionAttribute _ FANoUnwind = "nounwind"
renderFunctionAttribute _ FANullPointerIsValid = "null_pointer_is_valid"
renderFunctionAttribute _ FAOptDebug = "optdebug"
renderFunctionAttribute _ FAOptForFuzzing = "optforfuzzing"
renderFunctionAttribute _ FAOptNone = "optnone"
renderFunctionAttribute _ FAOptSize = "optsize"
renderFunctionAttribute _ FAPreSplitCoroutine = "presplitcoroutine"
renderFunctionAttribute _ FAReturnsTwice = "returns_twice"
renderFunctionAttribute _ FASafeStack = "safestack"
renderFunctionAttribute _ FASanitizeAddress = "sanitize_address"
renderFunctionAttribute _ FASanitizeHwAddress = "sanitize_hwaddress"
renderFunctionAttribute _ FASanitizeMemTag = "sanitize_memtag"
renderFunctionAttribute _ FASanitizeMemory = "sanitize_memory"
renderFunctionAttribute _ FASanitizeRealtime = "sanitize_realtime"
renderFunctionAttribute _ FASanitizeThread = "sanitize_thread"
renderFunctionAttribute _ FASanitizeType = "sanitize_type"
renderFunctionAttribute _ FAShadowCallStack = "shadowcallstack"
renderFunctionAttribute _ FASpeculatable = "speculatable"
renderFunctionAttribute _ FASpeculativeLoadHardening =
  "speculative_load_hardening"
renderFunctionAttribute _ FAStrictFP = "strictfp"
renderFunctionAttribute _ FASsp = "ssp"
renderFunctionAttribute _ FASspReq = "sspreq"
renderFunctionAttribute _ FASspStrong = "sspstrong"
renderFunctionAttribute _ FAWillReturn = "willreturn"
renderFunctionAttribute InGroup (FAAlignStack n) = "alignstack=" <> showText n
renderFunctionAttribute OnFunction (FAAlignStack n) =
  "alignstack(" <> showText n <> ")"
renderFunctionAttribute _ (FAAllocKind kind) =
  "allockind(" <> quoted kind <> ")"
renderFunctionAttribute _ (FAAllocSize a b) = withOptional "allocsize" a b
renderFunctionAttribute _ (FAVScaleRange a b) = withOptional "vscale_range" a b
renderFunctionAttribute _ (FAUwTable Nothing) = "uwtable"
renderFunctionAttribute _ (FAUwTable (Just kind)) = "uwtable(" <> kind <> ")"
renderFunctionAttribute _ (FAMemory effects) = "memory(" <> effects <> ")"
renderFunctionAttribute _ (FAString key Nothing) = quoted key
renderFunctionAttribute _ (FAString key (Just value)) =
  quoted key <> "=" <> quoted value

-- LLVM writes the two-argument attributes closed up, with no space after the
-- comma, unlike everywhere else it separates a list.
withOptional :: Text -> Natural -> Maybe Natural -> Text
withOptional name a b =
  name <> "(" <> showText a <> foldMap (("," <>) . showText) b <> ")"
