-- | Judging whether a core program is one LLVM would accept.
--
-- This is the other half of the rule in CLAUDE.md.  A subset that the data
-- does not encode — a constant among operands, a flag among the flags an
-- operation may carry, a field among the fields a struct has — is a predicate
-- applied somewhere, and here is where they are all applied at once.  Every
-- comment in the syntax layer saying that something is a verifier's business
-- means this, and the point of gathering them is that the shape of the data
-- stays simple while nothing goes unchecked.
--
-- __Nothing is thrown.__  'verify' returns what it found, so a caller can
-- report every problem rather than the first, and so the verifier is a pure
-- function like everything else.  An empty list is a program that passes.
--
-- __What it is for is catching Olivine's own bugs.__  A program that arrives
-- broken is worth reporting, but a program that arrives whole and leaves
-- broken is a pass that did something wrong, and the driver runs this after
-- each pass so that the one that did it is named.  That is why the checks are
-- the ones a pass can break — a use of a local nothing defines, an operand
-- whose type stopped matching its definition, a branch to a block that was
-- removed — rather than a reading of the LangRef.
--
-- __Where an assignment stands is not one of the checks.__  The lowering puts
-- the copies a phi becomes on edges of their own, and a block with two
-- successors is no place for one; but an assignment left behind by folding is
-- an ordinary definition, and reconstruction resolves it wherever it stands.
-- Both are 'OAssign' here, so nothing at this distance can tell which was
-- meant.  Only the lowering can, which is where that invariant is asserted.
--
-- __It judges the core and not what is retained beside it.__  A global's
-- initializer, a declaration's attributes, what an @ifunc@ may resolve
-- through: those are judgements about syntax the optimizer does not model and
-- no pass can damage.  So are the names, the block structure and the phis,
-- which the lowering discards on the way in and the raising invents on the way
-- out.  All of them belong to "Olivine.Syntax.Verify", which the driver runs
-- at either end of this one.
module Olivine.Core.Verify
  ( Problem (..)
  , Site (..)
  , Complaint (..)
  , Requirement (..)
  , verify
  , renderProblem
  ) where

import Data.Foldable (toList)
import Data.List (nub, (\\))
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Maybe (fromMaybe)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Numeric.Natural (Natural)

import Olivine.Core.Instruction
import Olivine.Core.Layout (Layout, layoutOf, sizeInBits)
import Olivine.Core.Program

import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function (Parameter (..), Signature (..))
import Olivine.Syntax.Instruction
  ( Alloca (..)
  , Binary (..)
  , BinaryOp (..)
  , Call (..)
  , Compare (..)
  , Convert (..)
  , ExtractElement (..)
  , InsertElement (..)
  , InstructionFlag (..)
  , Load (..)
  , Select (..)
  , ShuffleVector (..)
  , Store (..)
  , Unary (..)
  )
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Printer (renderInstructionFlag, renderName, renderType)
import Olivine.Syntax.Type (Type (..), elementOf, resolveNamed)
import Olivine.Syntax.Value (CastOp (..), TypedValue (..), Value (..), isConstant)
import Olivine.Syntax.Verify (symbolsDefinedBy)

-- | Something wrong, and where it is.
data Problem = Problem
  { problemFunction :: Name
  , problemSite :: Site
  , problemComplaint :: Complaint
  }
  deriving (Eq, Show)

-- | Where in a function a problem is.
--
-- An instruction is named by its position rather than by anything it carries:
-- a core instruction has no identity of its own, and two identical ones in a
-- block are two instructions.
data Site
  = -- | The function as a whole, for what is wrong with none of its blocks in
    -- particular.
    InFunction
  | -- | The nth instruction of a block, counting from zero.
    At Label Int
  | AtTerminator Label
  deriving (Eq, Show)

-- | What is wrong.
--
-- Structured rather than a message, so that a test can say which problem it
-- expects without matching on English, and so that the wording lives in one
-- place.
data Complaint
  = -- | A definition with nothing in it, which is a declaration written wrong.
    NoBlocks
  | -- | Two blocks with the same label.  A label is the whole of a block's
    -- identity, so two blocks sharing one are not two blocks.
    DuplicateBlock Label
  | -- | The signature's parameters and the ones the body names, in that
    -- order.  The body refers to its parameters by position, so a count that
    -- disagrees means some parameter is either unnameable or invented.
    ParameterCountDiffers Int Int
  | -- | A branch to a block the function does not have.
    MissingBlock Label
  | -- | A branch to the entry block, which LLVM rejects: the entry block is
    -- the one block that may not be a destination, and the raising leaves its
    -- label unwritten because nothing can name it.
    BranchToEntry
  | -- | An operand naming a local nothing in the function defines.
    UndefinedLocal Local
  | -- | An operand naming a symbol the program does not have.
    --
    -- The one check here that reads the whole program rather than one
    -- function, and the one that dead symbol elimination can break: a symbol
    -- it removed while something still called it leaves exactly this.
    UndefinedGlobal Name
  | -- | A result named for an operation that produces no value.
    ResultOfVoid
  | -- | A value produced and assigned to nothing, and its type.
    --
    -- LLVM tolerates this in isolation and numbers the result itself, which is
    -- exactly the trouble: the raising issues the numbering, so a value it did
    -- not number leaves every number after it one out.
    ResultMissing Type
  | -- | A local, the type it is defined at, and the type it has here.
    --
    -- The core does not write down what type a local has — the operand carries
    -- it at each use — so nothing but this notices when a pass rewrites one
    -- side and not the other.
    LocalTypeDiffers Local Type Type
  | -- | Two operands that must have the same type and do not.
    Mismatched Type Type
  | -- | What was needed here, and what was found.
    Expected Requirement Type
  | -- | The function's return type and what the @ret@ gives back, in that
    -- order.  'TVoid' on either side is a @ret@ with a value where none was
    -- promised, or none where one was.
    ReturnDiffers Type Type
  | -- | A @switch@ case that is not a compile-time constant.
    CaseNotConstant
  | -- | A struct and a field number it does not have.
    FieldOutOfRange Type Natural
  | -- | A @bitcast@ between two types that are not the same number of bits,
    -- in the order written.
    --
    -- Reported only where the module states a layout both sizes can be read
    -- from: what an @i17@ or a @double@ measures is the type's own business,
    -- but what a pointer or a struct measures is the target's.
    SizeDiffers Type Type
  | -- | A flag on an operation that may not carry it.
    FlagNotAllowed InstructionFlag
  deriving (Eq, Show)

-- | What an operand had to be.
--
-- A vector satisfies whatever its elements do, which is how LLVM reads these:
-- @add@ takes integers or a vector of them, and there is no separate
-- elementwise opcode to distinguish.
data Requirement
  = AnInteger
  | AFloat
  | APointer
  | -- | @i1@, which is what a condition is.
    ABoolean
  | -- | Something to compare with @icmp@, which LLVM allows to be a pointer as
    -- readily as an integer.
    AnIntegerOrPointer
  | AVector
  | AStruct
  deriving (Eq, Show)

-- | Every problem in a program, function by function in the order written.
verify :: Program -> [Problem]
verify program =
  concatMap
    (verifyFunction (namedTypes program) (layoutOf program) symbols)
    (functionsIn program)
  where
    symbols = definedSymbols program

-- | Every symbol the program defines, when it can be said which those are.
--
-- 'Nothing' if any entry is still opaque.  An opaque entry is source the
-- syntax layer has not learned to read, and what it holds may define a symbol
-- as readily as not, so a program with one in it cannot be asked which
-- symbols it has — and a verifier that guessed would report every reference
-- to whatever is in there as a reference to nothing.
definedSymbols :: Program -> Maybe (Set Name)
definedSymbols program
  | any opaque entries = Nothing
  | otherwise = Just (Set.fromList (concatMap defines entries))
  where
    entries = programEntries program

    opaque (ERetained (Syntax.EOpaque _)) = True
    opaque _ = False

    -- What a retained entry defines is asked of the syntax layer rather than
    -- answered again here: it is a fact about that grammar, and a second copy
    -- would be a second place to forget a construct.
    defines entry = case entry of
      EFunction f -> [signatureName (functionSignature f)]
      ERetained retained -> symbolsDefinedBy retained

verifyFunction ::
  Map Name Type -> Maybe Layout -> Maybe (Set Name) -> Function -> [Problem]
verifyFunction types layout symbols f =
  [ Problem (signatureName signature) site complaint
  | (site, complaint) <- whole <> concatMap inBlock blocks
  ]
  where
    signature = functionSignature f
    blocks = functionBlocks f

    whole =
      map
        ((,) InFunction)
        ( [NoBlocks | null blocks]
            <> [DuplicateBlock label | label <- repeated (map blockLabel blocks)]
            <> [ ParameterCountDiffers declared named
               | let declared = length (signatureParameters signature)
               , let named = length (functionParameters f)
               , declared /= named
               ]
        )

    inBlock b =
      concat (zipWith (instruction b) [0 ..] (blockInstructions b))
        <> terminator b

    instruction b index i =
      map
        ((,) (At (blockLabel b) index))
        ( operands operation
            <> [ResultOfVoid | Just _ <- [result], produced == TVoid]
            <> [ResultMissing produced | Nothing <- [result], produced /= TVoid]
            <> [ LocalTypeDiffers local defined produced
               | Just local <- [result]
               , produced /= TVoid
               , Just defined <- [definitionOf local]
               , defined /= produced
               ]
            <> shape types layout operation
            <> flagged types produced operation
        )
      where
        operation = instructionOperation i
        result = instructionResult i
        produced = resultType types operation

    terminator b =
      map
        ((,) (AtTerminator (blockLabel b)))
        ( operands transfer
            <> [MissingBlock target | target <- targetsOf t, target `notElem` labels]
            <> [ BranchToEntry
               | Just entry <- [entryLabel f]
               , entry `elem` targetsOf t
               ]
            <> control types (signatureReturnType signature) transfer
        )
      where
        t = blockTerminator b
        transfer = terminatorTransfer t

    labels = map blockLabel blocks

    -- What is wrong with what something reads: a local nothing defines, a
    -- symbol the program does not have, or a type disagreeing with the one the
    -- local was defined at.  An operation and a terminator are both 'Foldable'
    -- over their operands, so this is written once and asks nothing about
    -- which of them it was handed.
    operands :: Foldable f => f (TypedValue Local) -> [Complaint]
    operands thing =
      [UndefinedLocal local | local <- localsUsedBy thing, not (Map.member local definitions)]
        <> [ UndefinedGlobal name
           | Just defined <- [symbols]
           , name <- globalsUsedBy thing
           , not (Set.member name defined)
           ]
        <> [ LocalTypeDiffers local defined used
           | TypedValue used (VLocal local) <- toList thing
           , Just defined <- [definitionOf local]
           , defined /= used
           ]

    definitionOf local = Map.lookup local definitions

    -- The type each local holds, taken from where it is first defined.
    --
    -- A local may be assigned more than once here, which is the whole point of
    -- the core; what it may not do is change type between one assignment and
    -- the next, and taking the first definition is what makes the rest of them
    -- checkable against something.
    definitions :: Map Local Type
    definitions =
      Map.fromListWith
        (\_ first -> first)
        ( zip (functionParameters f) (map parameterType (signatureParameters signature))
            <> [ (local, produced)
               | b <- blocks
               , i <- blockInstructions b
               , Just local <- [instructionResult i]
               , let produced = resultType types (instructionOperation i)
               , produced /= TVoid
               ]
        )

-- | What an operation demands of its operands.
--
-- The checks are the ones LLVM makes and no more: that operands which have to
-- agree do, that each is of the kind the opcode reads, that a field selection
-- picks a field that is there, and that a @bitcast@ is between two types of
-- one size.  That last is the one that needs the module's layout, and is
-- passed over where there is none or where either type has no size there.
--
-- Whether a @trunc@ actually narrows is not checked, and could be: the widths
-- are the types' own.  It is left out because no pass here writes one whose
-- widths it did not choose, and a check nothing can fail is a check nobody
-- maintains.
shape :: Map Name Type -> Maybe Layout -> Operation (TypedValue local) -> [Complaint]
shape types layout operation = case operation of
  OAssign _ -> []
  OBinary b ->
    agree (binaryLeft b) (binaryRight b)
      <> needs (kindOf (binaryOp b)) (binaryLeft b)
  OUnary u -> needs AFloat (unaryOperand u)
  OICmp c ->
    agree (compareLeft c) (compareRight c)
      <> needs AnIntegerOrPointer (compareLeft c)
  OFCmp c ->
    agree (compareLeft c) (compareRight c)
      <> needs AFloat (compareLeft c)
  OConvert c -> conversion types layout c
  OSelect s ->
    needs ABoolean (selectCondition s)
      <> agree (selectTrue s) (selectFalse s)
  OExtractElement e ->
    needs AVector (extractElementVector e)
      <> needs AnInteger (extractElementIndex e)
  OInsertElement i ->
    needs AVector (insertElementVector i)
      <> needs AnInteger (insertElementIndex i)
      <> [ Mismatched wanted given
         | TVector _ _ wanted <- [resolveNamed types (typedValueType (insertElementVector i))]
         , let given = typedValueType (insertElementValue i)
         , wanted /= given
         ]
  OShuffleVector s ->
    needs AVector (shuffleVectorLeft s)
      <> needs AVector (shuffleVectorRight s)
      <> needs AVector (shuffleVectorMask s)
      <> agree (shuffleVectorLeft s) (shuffleVectorRight s)
  -- Nothing is said about the arguments: what they must be is the callee's
  -- signature, and the callee is an operand here — a pointer, which since
  -- LLVM made pointers opaque says nothing about what it points at.
  OCall c -> needs APointer (callCallee c)
  OAlloca a -> foldMap (needs AnInteger) (allocaElementCount a)
  OLoad l -> needs APointer (loadPointer l)
  OStore s -> needs APointer (storePointer s)
  OOffset o ->
    needs APointer (offsetPointer o)
      <> needs AnInteger (offsetIndex o)
  OField field ->
    needs APointer (fieldPointer field)
      <> case resolveNamed types (fieldStructType field) of
        TStruct _ fields
          -- Counted in 'Natural', which is what an index is: a number too big
          -- for an 'Int' is out of range rather than wrapped into it.
          | fieldIndex field < fromIntegral (length fields) -> []
          | otherwise -> [FieldOutOfRange (fieldStructType field) (fieldIndex field)]
        t -> [Expected AStruct t]
  where
    needs requirement = require types requirement . typedValueType

-- | What a conversion reads and what it writes.
conversion ::
  Map Name Type -> Maybe Layout -> Convert (TypedValue local) -> [Complaint]
conversion types layout c =
  from source <> to target <> [SizeDiffers source target | resized]
  where
    source = typedValueType (convertOperand c)
    target = convertTarget c

    -- The one conversion that has to preserve the bits, which is what makes it
    -- a way of speaking about a value rather than something a machine does.
    resized = convertOp c == CastBitcast && fromMaybe False (differs <$> layout)

    differs measure =
      case (sizeInBits measure source, sizeInBits measure target) of
        (Just a, Just b) -> a /= b
        _ -> False

    (from, to) = case convertOp c of
      CastTrunc -> (integer, integer)
      CastZExt -> (integer, integer)
      CastSExt -> (integer, integer)
      CastFPTrunc -> (float, float)
      CastFPExt -> (float, float)
      CastFPToUI -> (float, integer)
      CastFPToSI -> (float, integer)
      CastUIToFP -> (integer, float)
      CastSIToFP -> (integer, float)
      CastPtrToInt -> (pointer, integer)
      CastIntToPtr -> (integer, pointer)
      -- A bitcast reinterprets whatever it is given; that the two are the same
      -- size is checked above, where the layout can say what a size is.
      CastBitcast -> (anything, anything)
      CastAddrSpaceCast -> (pointer, pointer)

    integer = require types AnInteger
    float = require types AFloat
    pointer = require types APointer
    anything = const []

-- | What a terminator demands, given what the function promised to return.
control ::
  Map Name Type -> Type -> Transfer (TypedValue local) -> [Complaint]
control types returns transfer = case transfer of
  Ret Nothing -> [ReturnDiffers returns TVoid | returns /= TVoid]
  Ret (Just value) ->
    [ReturnDiffers returns given | let given = typedValueType value, returns /= given]
  Br _ -> []
  CondBr condition _ _ -> needs ABoolean condition
  Switch value _ cases ->
    needs AnInteger value
      <> concat
        [ [CaseNotConstant | not (isConstant (typedValue x))] <> agree x value
        | (x, _) <- cases
        ]
  IndirectBr address _ -> needs APointer address
  Unreachable -> []
  where
    needs requirement = require types requirement . typedValueType

-- | Which flags an operation may carry.
--
-- The wrapping flags belong to the arithmetic that can wrap, @exact@ to the
-- division and shifts that can lose a bit, @disjoint@ to @or@, @samesign@ to
-- @icmp@, @nneg@ to the two conversions that can be told an operand is not
-- negative, and the fast-math set to floating point — including a @select@ or
-- a @call@ whose result is floating point, which is the one case where what
-- may be carried depends on a type rather than on the opcode.
flagged ::
  Map Name Type -> Type -> Operation (TypedValue local) -> [Complaint]
flagged types produced operation =
  [FlagNotAllowed flag | flag <- flags, flag `notElem` allowed]
  where
    flags = case operation of
      OBinary b -> binaryFlags b
      OUnary u -> unaryFlags u
      OICmp c -> compareFlags c
      OFCmp c -> compareFlags c
      OConvert c -> convertFlags c
      OSelect s -> selectFlags s
      OCall c -> callFlags c
      _ -> []

    allowed = case operation of
      OBinary b -> case binaryOp b of
        OpAdd -> wrapping
        OpSub -> wrapping
        OpMul -> wrapping
        OpShl -> wrapping
        OpUDiv -> [FlagExact]
        OpSDiv -> [FlagExact]
        OpLShr -> [FlagExact]
        OpAShr -> [FlagExact]
        OpOr -> [FlagDisjoint]
        OpAnd -> []
        OpXor -> []
        OpURem -> []
        OpSRem -> []
        OpFAdd -> fastMath
        OpFSub -> fastMath
        OpFMul -> fastMath
        OpFDiv -> fastMath
        OpFRem -> fastMath
      -- @fneg@ is the only one, and it is floating point.
      OUnary _ -> fastMath
      OICmp _ -> [FlagSameSign]
      OFCmp _ -> fastMath
      OConvert c -> case convertOp c of
        CastTrunc -> wrapping
        CastZExt -> [FlagNNeg]
        CastUIToFP -> [FlagNNeg]
        _ -> []
      OSelect _ -> onlyIfFloating
      OCall _ -> onlyIfFloating
      _ -> []

    onlyIfFloating
      | satisfies types AFloat produced = fastMath
      | otherwise = []

    wrapping = [FlagNUW, FlagNSW]
    fastMath =
      [ FlagNNaN
      , FlagNInf
      , FlagNSZ
      , FlagARcp
      , FlagContract
      , FlagAFn
      , FlagReassoc
      , FlagFast
      ]

-- * Asking about types

agree :: TypedValue local -> TypedValue local -> [Complaint]
agree a b =
  [ Mismatched left right
  | let left = typedValueType a
  , let right = typedValueType b
  , left /= right
  ]

require :: Map Name Type -> Requirement -> Type -> [Complaint]
require types requirement given
  | satisfies types requirement given = []
  | otherwise = [Expected requirement given]

-- | Whether a type is of the kind wanted.
--
-- A vector answers for its elements throughout, except where being a vector
-- is itself the question.
satisfies :: Map Name Type -> Requirement -> Type -> Bool
satisfies types requirement t = case requirement of
  AnInteger -> case scalar of
    TInteger _ -> True
    _ -> False
  ABoolean -> scalar == TInteger 1
  AFloat -> case scalar of
    TFloat _ -> True
    _ -> False
  APointer -> case scalar of
    TPointer _ -> True
    _ -> False
  AnIntegerOrPointer -> case scalar of
    TInteger _ -> True
    TPointer _ -> True
    _ -> False
  AVector -> case resolved of
    TVector{} -> True
    _ -> False
  AStruct -> case resolved of
    TStruct{} -> True
    _ -> False
  where
    resolved = resolveNamed types t
    scalar = elementOf types t

-- | What kind of operands an arithmetic opcode reads.
kindOf :: BinaryOp -> Requirement
kindOf op = case op of
  OpFAdd -> AFloat
  OpFSub -> AFloat
  OpFMul -> AFloat
  OpFDiv -> AFloat
  OpFRem -> AFloat
  _ -> AnInteger

repeated :: Eq a => [a] -> [a]
repeated xs = nub (xs \\ nub xs)

-- * Saying what was found

-- | One problem, as a line for whoever is reading.
renderProblem :: Problem -> Text
renderProblem p =
  "@"
    <> renderName (problemFunction p)
    <> site (problemSite p)
    <> ": "
    <> renderComplaint (problemComplaint p)
  where
    site InFunction = T.empty
    site (At label index) = ", " <> renderLabel label <> ", instruction " <> number index
    site (AtTerminator label) = ", " <> renderLabel label <> ", terminator"

renderComplaint :: Complaint -> Text
renderComplaint complaint = case complaint of
  NoBlocks -> "a definition with no blocks in it"
  DuplicateBlock label -> "two blocks are both " <> renderLabel label
  ParameterCountDiffers declared named ->
    "the signature has "
      <> number declared
      <> " parameters and the body names "
      <> number named
  MissingBlock label -> "a branch to " <> renderLabel label <> ", which is not there"
  BranchToEntry -> "a branch to the entry block, which may not be a destination"
  UndefinedLocal local -> renderLocal local <> " is defined nowhere"
  UndefinedGlobal name -> "@" <> renderName name <> " is defined nowhere in the program"
  ResultOfVoid -> "a result named for an operation that produces no value"
  ResultMissing t -> "a value of type " <> renderType t <> " assigned to nothing"
  LocalTypeDiffers local defined used ->
    renderLocal local
      <> " is "
      <> renderType defined
      <> " where it is defined and "
      <> renderType used
      <> " here"
  Mismatched left right ->
    "operands of type "
      <> renderType left
      <> " and "
      <> renderType right
      <> ", which must agree"
  Expected requirement given ->
    "expected " <> renderRequirement requirement <> ", found " <> renderType given
  ReturnDiffers returns given ->
    "the function returns " <> renderType returns <> " and this gives back " <> renderType given
  CaseNotConstant -> "a switch case that is not a constant"
  FieldOutOfRange t index ->
    renderType t <> " has no field " <> T.pack (show index)
  FlagNotAllowed flag ->
    renderInstructionFlag flag <> ", which this operation may not carry"
  SizeDiffers source target ->
    "a bitcast from "
      <> renderType source
      <> " to "
      <> renderType target
      <> ", which is a different number of bits"

renderRequirement :: Requirement -> Text
renderRequirement requirement = case requirement of
  AnInteger -> "an integer"
  AFloat -> "a floating point type"
  APointer -> "a pointer"
  ABoolean -> "i1"
  AnIntegerOrPointer -> "an integer or a pointer"
  AVector -> "a vector"
  AStruct -> "a struct"

-- | A local and a block are numbers with no spelling of their own, so they are
-- written as what they are rather than as @%3@, which would look like a name
-- LLVM will see and is not one: the raising issues those afresh.
renderLocal :: Local -> Text
renderLocal (Local n) = "local " <> number n

renderLabel :: Label -> Text
renderLabel (Label n) = "block " <> number n

number :: Int -> Text
number = T.pack . show
