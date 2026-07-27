-- | The operands of an operation.
--
-- Nothing needed this while instructions were only read back and printed.
-- Reconstructing single assignment is the first thing that has to substitute
-- one value for another throughout an instruction, and every pass after it
-- will want the same.
--
-- Everything here comes from one traversal, so reading the operands and
-- rewriting them cannot disagree: an operand missed by one is missed by both,
-- and a single test finds it.
module Olivine.Syntax.Operands
  ( traverseOperands
  , mapOperands
  , operandsOf
  , localsUsedBy
  , globalsUsedBy
  ) where

import Data.Functor.Const (Const (..))
import Data.Functor.Identity (Identity (..))

import Olivine.Syntax.Instruction
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Value

-- | Visit every operand of an operation.
--
-- Block labels are not operands and are left alone: rewriting control flow is
-- a separate matter from rewriting values.  Some operands are written without
-- a type of their own, the operation having named it once for all of them;
-- those are handed over with that type supplied, and it is dropped again
-- after, so that a caller sees one shape everywhere.
traverseOperands ::
  Applicative f => (TypedValue -> f TypedValue) -> Operation -> f Operation
traverseOperands f = go
  where
    bare t x = typedValue <$> f (TypedValue t x)
    go (ORet operand) = ORet <$> traverse f operand
    go (OBr target) = pure (OBr target)
    go (OCondBr c a b) = (\x -> OCondBr x a b) <$> f c
    go (OSwitch s d cases) =
      OSwitch <$> f s <*> pure d <*> traverse (\(x, l) -> (,l) <$> f x) cases
    go (OIndirectBr address targets) =
      OIndirectBr <$> f address <*> pure targets
    go OUnreachable = pure OUnreachable
    go (OBinary b) =
      (\l r -> OBinary b {binaryLeft = l, binaryRight = r})
        <$> bare (binaryType b) (binaryLeft b)
        <*> bare (binaryType b) (binaryRight b)
    go (OUnary u) =
      (\x -> OUnary u {unaryOperand = x}) <$> bare (unaryType u) (unaryOperand u)
    go (OICmp c) = OICmp <$> comparison c
    go (OFCmp c) = OFCmp <$> comparison c
    go (OConvert c) =
      (\x -> OConvert c {convertOperand = x}) <$> f (convertOperand c)
    go (OCall c) =
      (\callee arguments -> OCall c {callCallee = callee, callArguments = arguments})
        <$> bare (callType c) (callCallee c)
        <*> traverse argument (callArguments c)
    go (OPhi p) =
      (\incoming -> OPhi p {phiIncoming = incoming})
        <$> traverse (\(x, l) -> (,l) <$> bare (phiType p) x) (phiIncoming p)
    go (OSelect s) =
      (\c t e -> OSelect s {selectCondition = c, selectTrue = t, selectFalse = e})
        <$> f (selectCondition s)
        <*> f (selectTrue s)
        <*> f (selectFalse s)
    go (OExtractElement e) =
      (\vec i -> OExtractElement e {extractElementVector = vec, extractElementIndex = i})
        <$> f (extractElementVector e)
        <*> f (extractElementIndex e)
    go (OInsertElement i) =
      (\vec x n -> OInsertElement i {insertElementVector = vec, insertElementValue = x, insertElementIndex = n})
        <$> f (insertElementVector i)
        <*> f (insertElementValue i)
        <*> f (insertElementIndex i)
    go (OShuffleVector s) =
      (\l r m -> OShuffleVector s {shuffleVectorLeft = l, shuffleVectorRight = r, shuffleVectorMask = m})
        <$> f (shuffleVectorLeft s)
        <*> f (shuffleVectorRight s)
        <*> f (shuffleVectorMask s)
    go (OAlloca a) =
      (\n -> OAlloca a {allocaElementCount = n}) <$> traverse f (allocaElementCount a)
    go (OLoad l) = (\p -> OLoad l {loadPointer = p}) <$> f (loadPointer l)
    go (OStore s) =
      (\x p -> OStore s {storeValue = x, storePointer = p})
        <$> f (storeValue s)
        <*> f (storePointer s)
    go (OGetElementPtr g) =
      (\p i -> OGetElementPtr g {gepPointer = p, gepIndices = i})
        <$> f (gepPointer g)
        <*> traverse f (gepIndices g)
    comparison c =
      (\l r -> c {compareLeft = l, compareRight = r})
        <$> bare (compareType c) (compareLeft c)
        <*> bare (compareType c) (compareRight c)
    argument a =
      (\x -> a {argumentValue = x}) <$> bare (argumentType a) (argumentValue a)

mapOperands :: (TypedValue -> TypedValue) -> Operation -> Operation
mapOperands f = runIdentity . traverseOperands (Identity . f)

operandsOf :: Operation -> [TypedValue]
operandsOf = getConst . traverseOperands (\x -> Const [x])

-- | The locals an operation reads.
localsUsedBy :: Operation -> [Name]
localsUsedBy operation = [n | VLocal n <- map typedValue (operandsOf operation)]

-- | The globals an operation names, including from inside its constants.
--
-- The callee of a call is an operand like any other, so a call names what it
-- calls here without this having to know what a call is.
globalsUsedBy :: Operation -> [Name]
globalsUsedBy = concatMap (globalsIn . typedValue) . operandsOf
