-- | The operands of an operation, for the one question that needs them.
--
-- Reading the locals off an operation and renaming them are the derived
-- instances now — 'Data.Foldable.toList' and 'fmap' — because what a local is
-- called is the type parameter and nothing else is.  A global's name is not a
-- parameter and never will be, since it is the program's interface to
-- everything outside it and must survive exactly as written; so asking which
-- globals an operation names is the one question the derived instances cannot
-- answer, and this walk is what answers it.
--
-- The counterpart over the core's own grammar is
-- 'Olivine.Core.Instruction.valuesIn'.  Two grammars cost two walks, and this
-- is the whole of that cost.
module Olivine.Syntax.Operands
  ( valuesIn
  , globalsUsedBy
  ) where

import Data.Foldable (toList)

import Olivine.Syntax.Instruction
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Value

-- | Every operand an operation is written with.
--
-- Some are written without a type of their own, the operation having named it
-- once for all of them; nothing here needs the type, so they are handed over
-- as they are rather than being dressed in one.
valuesIn :: Operation local -> [Value local]
valuesIn operation = case operation of
  ORet value -> map typedValue (toList value)
  OBr _ -> []
  OCondBr condition _ _ -> [typedValue condition]
  OSwitch value _ cases -> map typedValue (value : map fst cases)
  OIndirectBr address _ -> [typedValue address]
  OUnreachable -> []
  OBinary b -> [binaryLeft b, binaryRight b]
  OUnary u -> [unaryOperand u]
  OICmp c -> [compareLeft c, compareRight c]
  OFCmp c -> [compareLeft c, compareRight c]
  OConvert c -> [typedValue (convertOperand c)]
  OSelect s -> map typedValue [selectCondition s, selectTrue s, selectFalse s]
  OExtractElement e ->
    map typedValue [extractElementVector e, extractElementIndex e]
  OInsertElement i ->
    map typedValue [insertElementVector i, insertElementValue i, insertElementIndex i]
  OShuffleVector s ->
    map typedValue [shuffleVectorLeft s, shuffleVectorRight s, shuffleVectorMask s]
  OPhi p -> map fst (phiIncoming p)
  OCall c -> callCallee c : map argumentValue (callArguments c)
  OAlloca a -> map typedValue (toList (allocaElementCount a))
  OLoad l -> [typedValue (loadPointer l)]
  OStore s -> map typedValue [storeValue s, storePointer s]
  OGetElementPtr g -> map typedValue (gepPointer g : gepIndices g)

-- | The globals an operation names, including from inside its constants.
--
-- The callee of a call is an operand like any other, so a call names what it
-- calls here without this having to know what a call is.
globalsUsedBy :: Operation local -> [Name]
globalsUsedBy = concatMap globalsIn . valuesIn
