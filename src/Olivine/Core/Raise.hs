-- | Core to syntax.
--
-- The core lets a local be assigned as often as it likes and LLVM does not,
-- so "Olivine.Core.Ssa" puts the function back into single assignment form
-- first.  After that every instruction has an LLVM spelling and what is left
-- is translation, plus the one thing translation cannot avoid deciding: what
-- everything is called.
--
-- __The numbering is issued here, not carried.__  LLVM numbers whatever was
-- written without a name — parameters, blocks, results — from one counter per
-- function, and those numbers stop being true the moment a pass removes an
-- instruction or moves code between blocks.  So none of them are kept: the
-- core says which block is which with a 'Label' that means nothing outside
-- it, and the sequence is generated from scratch on the way out, by the rule
-- LLVM itself uses.  A module that no pass changed comes back numbered as it
-- arrived, because the rule is the same rule.
module Olivine.Core.Raise
  ( raise
  ) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Core.Instruction
import Olivine.Core.Phi (Joined (..), PhiNode (..), inWrittenOrder, removeForwarding)
import Olivine.Core.Program
import Olivine.Core.Ssa (reconstruct)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderName)
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

raise :: Program -> Syntax.Module
raise = Syntax.Module . map raiseEntry . programEntries

raiseEntry :: Entry -> Syntax.Entry
raiseEntry (ERetained entry) = entry
raiseEntry (EFunction f) =
  Syntax.EDefine
    Syntax.Definition
      { Syntax.definitionSignature = numberedSignature numbering
      , Syntax.definitionBlocks = map (raiseBlock numbering single) single
      }
  where
    -- Reconstruction is what empties the blocks put on split edges: the
    -- assignments in them become phi operands, leaving a branch and nothing
    -- else.  Taking them out again is what makes the trip through the core
    -- leave the control flow graph as it found it.
    --
    -- And ordering the phi operands afterwards is what makes it leave the same
    -- graph the second time as the first: removing a detour renames the block an
    -- operand arrives from, which is what leaves the order to be settled here
    -- rather than where the operands were made.
    single = inWrittenOrder (removeForwarding (reconstruct f))
    numbering = number (functionSignature f) (functionParameters f) single

-- * Numbering

-- | What everything unnamed is to be called.
--
-- One counter runs over the whole function, so a block and a value cannot
-- both be @%3@: LLVM draws them from the same sequence and so does this.
data Numbering = Numbering
  { numberedSignature :: Syntax.Signature
  , -- | Every local, since every local in the core is a number waiting for
    -- one.
    numberedLocals :: Map Local Name
  , numberedBlocks :: Map Label Name
  }

-- | Walk a function in the order LLVM numbers it.
--
-- Parameters first, then each block in turn: the block itself takes a number
-- before anything in it, then its phis, which stand at its head, and then
-- every instruction that assigns.  There is no test for whether something was
-- named, because nothing in the core is: what LLVM calls an unnamed value is
-- all the core has.
number :: Syntax.Signature -> [Local] -> [Joined] -> Numbering
number signature written blocks =
  Numbering
    { numberedSignature = signature {Syntax.signatureParameters = parameters}
    , numberedLocals = Map.fromList (parameterNames <> resultNames)
    , numberedBlocks = Map.fromList blockNames
    }
  where
    (afterParameters, parameters, parameterNames) =
      foldl' takeParameter (0 :: Int, [], []) $
        zip written (Syntax.signatureParameters signature)
    takeParameter (n, done, names) (local, p) =
      ( n + 1
      , done <> [p {Syntax.parameterName = Just (numberName n)}]
      , names <> [(local, numberName n)]
      )

    (_, blockNames, resultNames) =
      foldl' takeBlock (afterParameters, [], []) blocks
    -- The terminator's result is last because the terminator is: an invoke or
    -- a callbr assigns where it stands, and LLVM numbers what a function
    -- leaves unnamed in the order it is written.
    takeBlock (n, names, results) b =
      let assigned =
            map phiLocal (joinedPhis b)
              <> assigning (joinedInstructions b)
              <> maybe [] pure (resultOf (joinedTerminator b))
          (n', results') = foldl' takeResult (n + 1, results) assigned
       in (n', names <> [(joinedLabel b, numberName n)], results')
    assigning instructions = [local | i <- instructions, Just local <- [instructionResult i]]
    takeResult (n, results) local = (n + 1, results <> [(local, numberName n)])

numberName :: Int -> Name
numberName = Name Bare . T.pack . show

-- | What a local is called once it is written down.
--
-- Every local the function assigns has a number waiting for it, so a local
-- with none is one nothing defines — which the lowering will not build and no
-- pass can introduce, since a pass wanting a new local assigns to it.
localName :: Numbering -> Local -> Name
localName numbering local =
  Map.findWithDefault (error "Olivine.Core.Raise: a use of no local") local $
    numberedLocals numbering

-- | What a block is called once it is written down.
--
-- A label the numbering never saw would be a branch to a block that is not
-- there, which the lowering refuses to produce; nothing else can construct a
-- core function, so the map is total in practice and this says so loudly
-- rather than inventing a destination.
blockLabelName :: Numbering -> Label -> Name
blockLabelName numbering label =
  Map.findWithDefault (error "Olivine.Core.Raise: a branch to no block") label $
    numberedBlocks numbering

-- * Translation

raiseBlock :: Numbering -> [Joined] -> Joined -> Syntax.BasicBlock
raiseBlock numbering blocks block =
  Syntax.BasicBlock
    { Syntax.blockLabel = label
    , Syntax.blockBody =
        map (raisePhi numbering) (joinedPhis block)
          <> map (raiseInstruction numbering) (joinedInstructions block)
          <> [terminator]
    }
  where
    -- The entry block's number is spent but not written: nothing may branch
    -- to it, so LLVM leaves the label off and so does this.
    label
      | Just (joinedLabel block) == entryOf blocks = Nothing
      | otherwise =
          Just
            Syntax.BlockLabel
              { Syntax.blockLabelName = blockLabelName numbering (joinedLabel block)
              , Syntax.blockLabelComment =
                  predecessorComment numbering blocks (joinedLabel block)
              }
    terminator =
      Syntax.IOperation
        (localName numbering <$> resultOf (joinedTerminator block))
        (raiseTransfer numbering (terminatorTransfer (joinedTerminator block)))
        (terminatorMetadata (joinedTerminator block))

-- | The block a function starts at, which is the first one written.
entryOf :: [Joined] -> Maybe Label
entryOf blocks = case blocks of
  block : _ -> Just (joinedLabel block)
  [] -> Nothing

-- | One phi, written the way LLVM writes it.
--
-- The flags are empty because the core has nowhere to have kept them: nothing
-- between the two boundaries reads a phi's fast-math flags, so nothing carries
-- them, and inventing some here would be inventing them.
raisePhi :: Numbering -> PhiNode -> Syntax.Instruction
raisePhi numbering p =
  Syntax.IOperation
    (Just (localName numbering (phiLocal p)))
    ( Syntax.OPhi
        Syntax.Phi
          { Syntax.phiFlags = []
          , Syntax.phiType = phiType p
          , Syntax.phiIncoming =
              [ ( TypedValue (phiType p) (localName numbering <$> value)
                , blockLabelName numbering from
                )
              | (value, from) <- phiIncoming p
              ]
          }
    )
    []

-- | One core instruction.
raiseInstruction :: Numbering -> Instruction -> Syntax.Instruction
raiseInstruction numbering i =
  Syntax.IOperation
    (localName numbering <$> instructionResult i)
    (raiseOperation numbering (instructionOperation i))
    (instructionMetadata i)

-- | One operation, on the other side of the boundary.
--
-- Giving the locals the names the numbering settled on comes first and is the
-- derived map; what is left is the arm for each operation.  An assignment has
-- no LLVM spelling and needs none — reconstruction carried each assigned
-- value to wherever the local is read — so reaching one here is a bug in
-- reconstruction rather than a program this cannot write.
raiseOperation ::
  Numbering ->
  Operation (TypedValue Local) ->
  Syntax.Operation (TypedValue Name)
raiseOperation numbering written = case fmap (localName numbering) <$> written of
  OBinary b -> Syntax.OBinary b
  OUnary u -> Syntax.OUnary u
  OICmp c -> Syntax.OICmp c
  OFCmp c -> Syntax.OFCmp c
  OConvert c -> Syntax.OConvert c
  OSelect s -> Syntax.OSelect s
  OExtractElement e -> Syntax.OExtractElement e
  OInsertElement i -> Syntax.OInsertElement i
  OShuffleVector s -> Syntax.OShuffleVector s
  OExtractValue e -> Syntax.OExtractValue e
  OInsertValue i -> Syntax.OInsertValue i
  OCall c -> Syntax.OCall c
  OAlloca a -> Syntax.OAlloca a
  OLoad l -> Syntax.OLoad l
  OStore s -> Syntax.OStore s
  OAtomicLoad l -> Syntax.OAtomicLoad l
  OAtomicStore s -> Syntax.OAtomicStore s
  OAtomicRmw r -> Syntax.OAtomicRmw r
  OCmpXchg c -> Syntax.OCmpXchg c
  OFence f -> Syntax.OFence f
  OOffset o ->
    Syntax.OGetElementPtr
      Syntax.GetElementPtr
        { Syntax.gepFlags = offsetFlags o
        , Syntax.gepSourceType = offsetElementType o
        , Syntax.gepPointer = offsetPointer o
        , Syntax.gepIndices = [offsetIndex o]
        }
  -- A struct field is two indices in LLVM whatever it is here: one to arrive
  -- at the struct and one to pick the field.  The first is the zero stride
  -- that lowering drops on the way in, put back because there is no way to
  -- write the second without it.
  OField f ->
    Syntax.OGetElementPtr
      Syntax.GetElementPtr
        { Syntax.gepFlags = fieldFlags f
        , Syntax.gepSourceType = fieldStructType f
        , Syntax.gepPointer = fieldPointer f
        , Syntax.gepIndices = [index 0, index (toInteger (fieldIndex f))]
        }
    where
      index = TypedValue (TInteger 32) . VInteger
  OLandingPad p -> Syntax.OLandingPad p
  OAssign _ -> error "Olivine.Core.Raise: an assignment survived reconstruction"

-- | One terminator, on the other side of the boundary.
raiseTransfer ::
  Numbering ->
  Transfer (TypedValue Local) ->
  Syntax.Operation (TypedValue Name)
raiseTransfer numbering written = case fmap (localName numbering) <$> written of
  Ret value -> Syntax.ORet value
  Br target -> Syntax.OBr (label target)
  CondBr condition true false ->
    Syntax.OCondBr condition (label true) (label false)
  Switch value target cases ->
    Syntax.OSwitch value (label target) [(x, label l) | (x, l) <- cases]
  IndirectBr address targets -> Syntax.OIndirectBr address (map label targets)
  Unreachable -> Syntax.OUnreachable
  -- The result is not written here: it is the name on the instruction, which
  -- 'raiseBlock' takes from 'resultOf' the way it takes an instruction's from
  -- 'instructionResult'.
  Invoke _ call normal unwind ->
    Syntax.OInvoke (Syntax.Invoke call (label normal) (label unwind))
  CallBr _ call fallthrough indirect ->
    Syntax.OCallBr (Syntax.CallBr call (label fallthrough) (map label indirect))
  Resume value -> Syntax.OResume value
  where
    label = blockLabelName numbering

-- | The @; preds = %a, %b@ comment LLVM writes after a label.
--
-- Derived from the control flow graph rather than carried, which is what
-- having structural terminators buys: the comment states which blocks reach
-- this one, so a pass that changes control flow cannot leave it stale.
--
-- LLVM lists predecessors in reverse order of where the blocks appear, once
-- per edge rather than once per block, and writes @; No predecessors!@ for a
-- block nothing reaches.
predecessorComment :: Numbering -> [Joined] -> Label -> Maybe Text
predecessorComment numbering blocks label
  | null predecessors = Just "; No predecessors!"
  | otherwise = Just ("; preds = " <> T.intercalate ", " (map reference predecessors))
  where
    predecessors =
      concat
        [ [joinedLabel b | target <- targetsOf (joinedTerminator b), target == label]
        | b <- reverse blocks
        ]
    reference = ("%" <>) . renderName . blockLabelName numbering
