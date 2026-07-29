-- | Working out what a computation comes to when its operands are known.
--
-- A folded instruction becomes an assignment of the value it computes.  The
-- core has assignment and LLVM does not, which is what makes that possible;
-- reconstructing single assignment then carries the value to wherever the
-- local was read, and the dead code pass takes the assignment away.  Nothing
-- new is needed to finish the job.
--
-- __No floating point.__  Float literals are held as the text they were
-- written in, so that nothing decodes and re-encodes them and no literal is
-- ever quietly rounded.  Folding one would mean doing exactly that, and
-- getting it right would mean implementing the rounding LLVM's target uses.
-- Integers only, where the answer is the answer.
module Olivine.Core.Pass.ConstantFold
  ( foldConstants
  , foldOperation
  ) where

import Data.Bits (complement, shiftL, shiftR, (.&.), (.|.))
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)

import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Instruction
  ( Binary (..)
  , BinaryOp (..)
  , Compare (..)
  , Convert (..)
  , InstructionFlag (..)
  , IntPredicate (..)
  , Select (..)
  )
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value

foldConstants :: Program -> Program
foldConstants program =
  program {programEntries = map entry (programEntries program)}
  where
    entry (EFunction f) = EFunction (settle f)
    entry retained = retained

-- | Folding an instruction makes its result known, which may let the next one
-- fold, so this runs until a sweep changes nothing.
settle :: Function -> Function
settle f
  | swept == f = f
  | otherwise = settle swept
  where
    swept = sweep f

sweep :: Function -> Function
sweep f = f {functionBlocks = map rewrite (functionBlocks f)}
  where
    known = knownValues f
    substitute :: Functor g => g (TypedValue Local) -> g (TypedValue Local)
    substitute = fmap (\(TypedValue t x) -> TypedValue t (resolve x))
    resolve (VLocal n) = fromMaybe (VLocal n) (Map.lookup n known)
    resolve x = x
    rewrite b =
      b
        { blockInstructions = map instruction (blockInstructions b)
        , blockTerminator =
            (blockTerminator b)
              { terminatorTransfer = substitute (terminatorTransfer (blockTerminator b))
              }
        }
    instruction i =
      let folded = substitute (instructionOperation i)
       in i {instructionOperation = maybe folded OAssign (foldOperation folded)}

-- | The locals whose value is known throughout the function.
--
-- A local assigned once, to a constant, is that constant everywhere it is
-- read: the assignment stands where the instruction it replaced stood, so it
-- reaches every use that instruction reached.  A local assigned more than
-- once is one a phi became, and holds different things on different paths.
knownValues :: Function -> Map Local (Value Local)
knownValues f =
  Map.fromList
    [ (name, value)
    | (name, value) <- assignments
    , length [() | (other, _) <- assignments, other == name] == 1
    , isConstant value
    ]
  where
    assignments =
      [ (name, typedValue value)
      | b <- functionBlocks f
      , Instruction (Just name) (OAssign value) _ <- blockInstructions b
      ]

-- | What an operation comes to, when it comes to anything.
foldOperation :: Operation (TypedValue local) -> Maybe (TypedValue local)
foldOperation operation = case operation of
  OBinary b -> do
    let t = typedValueType (binaryLeft b)
    left <- integerOf t (typedValue (binaryLeft b))
    right <- integerOf t (typedValue (binaryRight b))
    width <- widthOf t
    result <- binary (binaryOp b) (binaryFlags b) width left right
    pure (TypedValue t (valueOf t result))
  OICmp c -> do
    let t = typedValueType (compareLeft c)
    left <- integerOf t (typedValue (compareLeft c))
    right <- integerOf t (typedValue (compareRight c))
    width <- widthOf t
    pure (TypedValue (TInteger 1) (VBoolean (comparison (comparePredicate c) width left right)))
  OConvert c -> do
    from <- widthOf (typedValueType (convertOperand c))
    value <- integerOf (typedValueType (convertOperand c)) (typedValue (convertOperand c))
    to <- widthOf (convertTarget c)
    result <- conversion (convertOp c) from to value
    pure (TypedValue (convertTarget c) (valueOf (convertTarget c) result))
  OSelect s -> case typedValue (selectCondition s) of
    VBoolean chosen -> Just (if chosen then selectTrue s else selectFalse s)
    _ -> Nothing
  -- A step that moves the pointer nowhere is the pointer it started from.
  -- Taking a @getelementptr@ apart leaves these behind wherever LLVM wrote an
  -- index of zero, which it does whenever it walks into an aggregate without
  -- subscripting it.
  OOffset o | zero (offsetIndex o) -> Just (offsetPointer o)
  -- The same thing for the other kind of step, and true whatever the data
  -- layout says: a struct's first field begins where the struct does.
  OField f | fieldIndex f == 0 -> Just (fieldPointer f)
  _ -> Nothing
  where
    zero (TypedValue _ (VInteger 0)) = True
    zero _ = False

widthOf :: Type -> Maybe Integer
widthOf (TInteger w) = Just (fromIntegral w)
widthOf _ = Nothing

-- | An integer constant, as the number it stands for.
integerOf :: Type -> Value local -> Maybe Integer
integerOf (TInteger _) (VInteger n) = Just n
integerOf (TInteger _) (VBoolean b) = Just (if b then 1 else 0)
integerOf _ _ = Nothing

-- | A number as an integer constant of the given type, wrapped to fit.
valueOf :: Type -> Integer -> Value local
valueOf (TInteger 1) n = VBoolean (odd n)
valueOf (TInteger w) n = VInteger (signed (fromIntegral w) n)
valueOf _ n = VInteger n

-- | The two's complement reading of a number in a given width.
signed :: Integer -> Integer -> Integer
signed width n
  | wrapped >= half = wrapped - 2 ^ width
  | otherwise = wrapped
  where
    wrapped = n `mod` 2 ^ width
    half = 2 ^ (width - 1)

unsigned :: Integer -> Integer -> Integer
unsigned width n = n `mod` 2 ^ width

-- | An operation on two known integers.
--
-- Nothing is returned where LLVM's answer is poison rather than a number: a
-- division by zero, a shift past the width, an inexact division marked exact,
-- or a result that overflows a wrapping flag which says it does not.  Folding
-- those to some number would be inventing one.
binary :: BinaryOp -> [InstructionFlag] -> Integer -> Integer -> Integer -> Maybe Integer
binary op flags width left right = case op of
  OpAdd -> checked (+)
  OpSub -> checked (-)
  OpMul -> checked (*)
  OpUDiv -> divides (unsigned width left `quot` unsigned width right)
  OpSDiv
    | right == -1 && left == negate (2 ^ (width - 1)) -> Nothing
    | otherwise -> divides (left `quot` right)
  OpURem -> guarded (right /= 0) (unsigned width left `rem` unsigned width right)
  OpSRem -> guarded (right /= 0) (left `rem` right)
  OpShl -> if shiftable then checked (\a _ -> a `shiftL` fromIntegral right) else Nothing
  OpLShr -> shifted (unsigned width left `shiftR` fromIntegral right)
  OpAShr -> shifted (left `shiftR` fromIntegral right)
  OpAnd -> Just (left .&. right)
  OpOr -> guarded (not (has FlagDisjoint) || (left .&. right) == 0) (left .|. right)
  OpXor -> Just (xor' left right)
  _ -> Nothing
  where
    has flag = flag `elem` flags
    shiftable = right >= 0 && right < width
    guarded condition result = if condition then Just result else Nothing
    -- A flag promising no overflow is a promise the caller made, and a broken
    -- promise gives poison rather than a wrapped answer.
    --
    -- The two flags are promises about different arithmetic and have to be
    -- checked on it.  The operands are one set of bits; nsw is about reading
    -- them as signed and nuw as unsigned, and @add nuw i32 -1, 1@ overflows
    -- although the signed sum is nothing but zero.
    checked f =
      guarded
        ( (not (has FlagNSW) || signed width signedResult == signedResult)
            && (not (has FlagNUW) || (unsignedResult >= 0 && unsignedResult < 2 ^ width))
        )
        signedResult
      where
        signedResult = f left right
        unsignedResult = f (unsigned width left) (unsigned width right)
    divides result =
      guarded
        (right /= 0 && (not (has FlagExact) || left == result * right))
        result
    shifted result =
      guarded
        (shiftable && (not (has FlagExact) || (result `shiftL` fromIntegral right) == left))
        result

-- Data.Bits has xor, but the name is taken by the Value constructor set; this
-- keeps the import list to what is unambiguous.
xor' :: Integer -> Integer -> Integer
xor' a b = (a .|. b) .&. complement (a .&. b)

comparison :: IntPredicate -> Integer -> Integer -> Integer -> Bool
comparison predicate width left right = case predicate of
  IEq -> left == right
  INe -> left /= right
  ISgt -> left > right
  ISge -> left >= right
  ISlt -> left < right
  ISle -> left <= right
  IUgt -> u left > u right
  IUge -> u left >= u right
  IUlt -> u left < u right
  IUle -> u left <= u right
  where
    u = unsigned width

conversion :: CastOp -> Integer -> Integer -> Integer -> Maybe Integer
conversion op from to value = case op of
  CastTrunc -> guarded (to <= from) value
  CastZExt -> guarded (to >= from) (unsigned from value)
  CastSExt -> guarded (to >= from) (signed from value)
  _ -> Nothing
  where
    guarded condition result = if condition then Just result else Nothing
