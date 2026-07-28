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

import Data.Char (isDigit)
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
import Olivine.Syntax.Value (TypedValue (..), Value (..))

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
  , -- | Only the locals that had numbers.  A local with a name keeps it.
    numberedLocals :: Map Name Name
  , numberedBlocks :: Map Label Name
  }

-- | Walk a function in the order LLVM numbers it.
--
-- Parameters first, then each block in turn: the block itself takes a number
-- before anything in it, and then every instruction whose result was written
-- without a name.  An instruction that names its result, or has none, takes
-- nothing.
number :: Function -> Numbering
number f =
  Numbering
    { numberedSignature = signature {Syntax.signatureParameters = parameters}
    , numberedLocals = Map.fromList (parameterRenames <> resultRenames)
    , numberedBlocks = Map.fromList blockNames
    }
  where
    signature = functionSignature f

    (afterParameters, parameters, parameterRenames) =
      foldl' takeParameter (0 :: Int, [], []) (Syntax.signatureParameters signature)
    takeParameter (n, done, renames) p = case Syntax.parameterName p of
      Just name
        | numbered name ->
            ( n + 1
            , done <> [p {Syntax.parameterName = Just (numberName n)}]
            , renames <> [(name, numberName n)]
            )
        | otherwise -> (n, done <> [p], renames)
      -- A parameter written as a bare type is unnamed too, and LLVM numbers
      -- it; there is simply nothing to rename, since nothing can refer to it.
      Nothing -> (n + 1, done <> [p], renames)

    (_, blockNames, resultRenames) =
      foldl' takeBlock (afterParameters, [], []) (functionBlocks f)
    takeBlock (n, names, renames) b =
      let (n', renames') = foldl' takeResult (n + 1, renames) (blockInstructions b)
       in (n', names <> [(blockLabel b, numberName n)], renames')
    takeResult (n, renames) i = case instructionResult i of
      Just name | numbered name -> (n + 1, renames <> [(name, numberName n)])
      _ -> (n, renames)

-- | Whether a name is a number LLVM issued rather than a name somebody chose.
--
-- Written bare and all digits is the whole test, because that is the only way
-- to write one: a local a source really wanted to call @3@ has to be quoted,
-- and quoting is remembered.
numbered :: Name -> Bool
numbered (Name Bare text) = not (T.null text) && T.all isDigit text
numbered _ = False

numberName :: Int -> Name
numberName = Name Bare . T.pack . show

localName :: Numbering -> Name -> Name
localName numbering name = Map.findWithDefault name name (numberedLocals numbering)

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
raiseOperation :: Numbering -> Syntax.Operation Label -> Syntax.Operation Name
raiseOperation numbering =
  fmap (blockLabelName numbering) . mapOperands renameLocal
  where
    renameLocal (TypedValue t (VLocal n)) = TypedValue t (VLocal (localName numbering n))
    renameLocal operand = operand

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
