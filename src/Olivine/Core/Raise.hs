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

import Olivine.Core.Blocks (removeForwarding)
import Olivine.Core.Program
import Olivine.Core.Ssa (reconstruct)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name
import Olivine.Syntax.Operands (mapOperands)
import Olivine.Syntax.Printer (renderName)

raise :: Program -> Syntax.Module
raise = Syntax.Module . map raiseEntry . programEntries

raiseEntry :: Entry -> Syntax.Entry
raiseEntry (ERetained entry) = entry
raiseEntry (EFunction f) =
  Syntax.EDefine
    Syntax.Definition
      { Syntax.definitionSignature = numberedSignature numbering
      , Syntax.definitionBlocks = map (raiseBlock numbering single) (functionBlocks single)
      }
  where
    -- Reconstruction is what empties the blocks put on split edges: the
    -- assignments in them become phi operands, leaving a branch and nothing
    -- else.  Taking them out again is what makes the trip through the core
    -- leave the control flow graph as it found it.
    single = removeForwarding (reconstruct f)
    numbering = number single

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
-- before anything in it, and then every instruction that assigns.  There is
-- no test for whether something was named, because nothing in the core is:
-- what LLVM calls an unnamed value is all the core has.
number :: Function -> Numbering
number f =
  Numbering
    { numberedSignature = signature {Syntax.signatureParameters = parameters}
    , numberedLocals = Map.fromList (parameterNames <> resultNames)
    , numberedBlocks = Map.fromList blockNames
    }
  where
    signature = functionSignature f

    (afterParameters, parameters, parameterNames) =
      foldl' takeParameter (0 :: Int, [], []) $
        zip (functionParameters f) (Syntax.signatureParameters signature)
    takeParameter (n, done, names) (local, p) =
      ( n + 1
      , done <> [p {Syntax.parameterName = Just (numberName n)}]
      , names <> [(local, numberName n)]
      )

    (_, blockNames, resultNames) =
      foldl' takeBlock (afterParameters, [], []) (functionBlocks f)
    takeBlock (n, names, results) b =
      let (n', results') = foldl' takeResult (n + 1, results) (blockInstructions b)
       in (n', names <> [(blockLabel b, numberName n)], results')
    takeResult (n, results) i = case instructionResult i of
      Just local -> (n + 1, results <> [(local, numberName n)])
      Nothing -> (n, results)

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

raiseBlock :: Numbering -> Function -> Block -> Syntax.BasicBlock
raiseBlock numbering f block =
  Syntax.BasicBlock
    { Syntax.blockLabel = label
    , Syntax.blockBody =
        map (raiseInstruction numbering) (blockInstructions block) <> [terminator]
    }
  where
    -- The entry block's number is spent but not written: nothing may branch
    -- to it, so LLVM leaves the label off and so does this.
    label
      | Just (blockLabel block) == entryLabel f = Nothing
      | otherwise =
          Just
            Syntax.BlockLabel
              { Syntax.blockLabelName = blockLabelName numbering (blockLabel block)
              , Syntax.blockLabelComment = predecessorComment numbering f (blockLabel block)
              }
    terminator =
      Syntax.IOperation
        Nothing
        (raiseOperation numbering (terminatorOperation (blockTerminator block)))
        (terminatorMetadata (blockTerminator block))

-- | One core instruction.
--
-- No assignment survives reconstruction: each assigned value was carried to
-- where it is read, and a phi put wherever several of them meet.
raiseInstruction :: Numbering -> Instruction -> Syntax.Instruction
raiseInstruction numbering i = case instructionOperation i of
  Perform operation ->
    Syntax.IOperation
      (localName numbering <$> instructionResult i)
      (raiseOperation numbering operation)
      (instructionMetadata i)
  Assign _ ->
    error "Olivine.Core.Raise: an assignment survived reconstruction"

-- | Give an operation the names the numbering settled on.
--
-- Two substitutions that cannot be confused with one another: the labels are
-- what the operation is parameterized by, so 'fmap' reaches exactly those,
-- and the locals are its operands, which is what 'mapOperands' reaches.
raiseOperation ::
  Numbering -> Syntax.Operation Local Label -> Syntax.Operation Name Name
raiseOperation numbering =
  fmap (blockLabelName numbering) . mapOperands (fmap (localName numbering))

-- | The @; preds = %a, %b@ comment LLVM writes after a label.
--
-- Derived from the control flow graph rather than carried, which is what
-- having structural terminators buys: the comment states which blocks reach
-- this one, so a pass that changes control flow cannot leave it stale.
--
-- LLVM lists predecessors in reverse order of where the blocks appear, once
-- per edge rather than once per block, and writes @; No predecessors!@ for a
-- block nothing reaches.
predecessorComment :: Numbering -> Function -> Label -> Maybe Text
predecessorComment numbering f label
  | null predecessors = Just "; No predecessors!"
  | otherwise = Just ("; preds = " <> T.intercalate ", " (map reference predecessors))
  where
    predecessors =
      concat
        [ [blockLabel b | target <- targetsOf (blockTerminator b), target == label]
        | b <- reverse (functionBlocks f)
        ]
    reference = ("%" <>) . renderName . blockLabelName numbering
