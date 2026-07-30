-- | Working out what a computation comes to.
--
-- Three things can settle that, and the pass asks them in that order.  Every
-- operand may be a constant, and then the answer is a number.  One operand may
-- be the number that makes the operation do nothing — @x + 0@, @x * 1@,
-- @x & -1@ — or the two operands may be the same value, and then the answer is
-- an operand or a constant that has nothing to do with what the operand holds.
-- Or what produced an operand may be known, and then a conversion of a
-- conversion is one conversion or none at all.
--
-- A folded instruction becomes an assignment of the value it computes.  The
-- core has assignment and LLVM does not, which is what makes that possible;
-- reconstructing single assignment then carries the value to wherever the
-- local was read, and the dead code pass takes the assignment away.  Nothing
-- new is needed to finish the job.  A chain of conversions is the one case
-- where what comes out is another operation rather than a value, since what a
-- narrowing of a widening comes to is usually a shorter conversion and not a
-- number; the instruction is left computing that instead, reading what the
-- conversion it looked through read, and the same collection follows.
--
-- __An answer may be more defined than the operation, and never less.__  @mul
-- x, 0@ is poison where @x@ is poison, and folding it to zero replaces poison
-- with a number.  That is allowed: poison stands for any value the target
-- likes, so producing one particular value where LLVM promised nothing is a
-- program that still does what the source asked for.  Going the other way —
-- giving an operation a value where LLVM promised one and spreading poison to
-- where there was none — is what would be wrong, and nothing here does it.
-- Where the answer is poison outright the pass still declines rather than
-- naming a number, which the rule above permits either way; see 'binary'.
--
-- __Looking through a definition is a question about where, not only what.__
-- In single assignment form the operation that produced an operand is a lookup
-- on its name.  Here a local can be reassigned, so knowing that @%b@ was
-- assigned @zext %a@ somewhere is not knowing that @%b@ holds a widened @%a@
-- /here/: the assignment may not have run, and @%a@ may have been assigned
-- since — in which case the widened value @%b@ holds is of a number @%a@ no
-- longer has.  Both go wrong across a back edge, where an instruction can read
-- what the previous time round the loop left.
--
-- So this looks through a definition only within the block that made it, where
-- the instructions run in the order they are written and one execution of the
-- block is one run of each.  A definition is dropped as soon as the local it
-- names or any local it reads is assigned again.  That is the whole of what a
-- front end's cast chains need, which arrive as adjacent instructions; a chain
-- spread across blocks is left alone, and the availability walk that would
-- reach it is "Olivine.Core.Pass.Redundancies"'s, which answers a different
-- question and answers it later.
--
-- That same walk is what lets a constant reach an operand at all in the
-- commonest case there is.  'knownValues' says what a local holds throughout
-- the function, and can only say it of a local assigned once; promotion
-- assigns a slot's local twice over — poison before the first store, the
-- stored value after it — so a value that arrived through memory is settled
-- nowhere by that rule and everywhere by this one.  Without it @x = 1; y = 2;
-- return x + y@ leaves an addition of two constants standing in the core.
--
-- __No floating point.__  Float literals are held as the text they were
-- written in, so that nothing decodes and re-encodes them and no literal is
-- ever quietly rounded.  Folding one would mean doing exactly that, and
-- getting it right would mean implementing the rounding LLVM's target uses.
-- Integers only, where the answer is the answer.
module Olivine.Core.Pass.Fold
  ( foldOperations
  , foldOperation
  , foldThrough
  , Producer
  ) where

import Control.Applicative ((<|>))
import Data.Bits (complement, shiftL, shiftR, (.&.), (.|.))
import Data.List (mapAccumL)
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

foldOperations :: Program -> Program
foldOperations program =
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

    -- The definitions in hand are the folded ones and are carried along the
    -- block, so a chain settles as far as the block runs in one sweep rather
    -- than one link per sweep.  The terminator is read against what the last
    -- instruction left, which is where it stands.
    rewrite b =
      let (leaving, instructions) = mapAccumL instruction Map.empty (blockInstructions b)
       in b
            { blockInstructions = instructions
            , blockTerminator =
                (blockTerminator b)
                  { terminatorTransfer =
                      fmap (resolve leaving) (terminatorTransfer (blockTerminator b))
                  }
            }

    instruction inHand i =
      ( recording (instructionResult i) folded inHand
      , i {instructionOperation = folded}
      )
      where
        operation = fmap (resolve inHand) (instructionOperation i)
        folded =
          fromMaybe operation $
            (OAssign <$> foldOperation operation)
              <|> foldThrough (`Map.lookup` inHand) operation

    -- An operand naming a local that holds a constant, written as the constant
    -- it holds.  What the block has settled is asked before what holds
    -- throughout the function, being the more precise of the two: a local
    -- assigned in two places is not settled anywhere by 'knownValues', and
    -- promotion writes exactly that — a slot is poison before its first store
    -- and the stored value after it.
    --
    -- Only a constant is written back.  A local standing for another local is a
    -- copy chain, and resolving one into the operands here would be a second
    -- place that has to keep it right; "Olivine.Core.Ssa" takes every copy away
    -- on the way out, which is where that belongs.  Reading /through/ the
    -- copies to find the constant is a different thing, and is what promotion
    -- leaves no choice about.
    resolve inHand (TypedValue t x) = TypedValue t (value x)
      where
        value (VLocal n) =
          fromMaybe (VLocal n) (settled n <|> Map.lookup n known)
        value constant = constant
        settled n = case producing (`Map.lookup` inHand) n of
          Just (OAssign (TypedValue _ held)) | isConstant held -> Just held
          _ -> Nothing

    -- What an instruction leaves worth knowing: the operation it turned out to
    -- be, under the local it assigns to.  Assigning to a local takes away the
    -- definition held in it, which describes something else now, and every
    -- definition that reads it, which means something else now.  An operation
    -- reading the local it assigns to is both of those at once, so it is
    -- recorded as neither.
    recording Nothing _ inHand = inHand
    recording (Just result) operation inHand
      | result `elem` localsUsedBy operation = remaining
      | otherwise = Map.insert result operation remaining
      where
        remaining =
          Map.filterWithKey
            (\name op -> name /= result && result `notElem` localsUsedBy op)
            inHand

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

-- | What an operation comes to, when its own operands say.
--
-- Either every operand is known and the answer is worked out, or one of them
-- makes the operation do nothing and the answer is the other, or the two are
-- the same value and the answer follows from that alone.
foldOperation :: Eq local => Operation (TypedValue local) -> Maybe (TypedValue local)
foldOperation operation = case operation of
  OBinary b -> constantBinary b <|> identity b
  OICmp c -> constantCompare c <|> reflexive c
  OConvert c -> constantConvert c
  OSelect s -> case typedValue (selectCondition s) of
    VBoolean chosen -> Just (if chosen then selectTrue s else selectFalse s)
    -- Both arms the same value is that value however the condition comes out,
    -- and the condition need not be known or even be a single one: an
    -- elementwise select between two copies of a vector chooses between equals
    -- lane by lane.
    _ | selectTrue s == selectFalse s -> Just (selectTrue s)
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

constantBinary :: Binary (TypedValue local) -> Maybe (TypedValue local)
constantBinary b = do
  let t = typedValueType (binaryLeft b)
  left <- integerOf t (typedValue (binaryLeft b))
  right <- integerOf t (typedValue (binaryRight b))
  width <- widthOf t
  result <- binary (binaryOp b) (binaryFlags b) width left right
  pure (TypedValue t (valueOf t result))

constantCompare :: Compare IntPredicate (TypedValue local) -> Maybe (TypedValue local)
constantCompare c = do
  let t = typedValueType (compareLeft c)
  left <- integerOf t (typedValue (compareLeft c))
  right <- integerOf t (typedValue (compareRight c))
  width <- widthOf t
  pure (TypedValue (TInteger 1) (VBoolean (comparison (comparePredicate c) width left right)))

constantConvert :: Convert (TypedValue local) -> Maybe (TypedValue local)
constantConvert c = do
  from <- widthOf (typedValueType (convertOperand c))
  value <- integerOf (typedValueType (convertOperand c)) (typedValue (convertOperand c))
  to <- widthOf (convertTarget c)
  result <- conversion (convertOp c) from to value
  pure (TypedValue (convertTarget c) (valueOf (convertTarget c) result))

-- | What an operation comes to when an operand makes it do nothing, or when
-- both operands are the same value.
--
-- The flags are not consulted, and need not be.  A flag says the operation
-- will not overflow and is poison where it does; every case here either gives
-- back an operand of an operation that cannot overflow at that operand — @x +
-- 0@ and @x * 1@ overflow at nothing — or gives a constant, and a constant
-- where LLVM allowed poison is the direction that is allowed.
identity :: Eq local => Binary (TypedValue local) -> Maybe (TypedValue local)
identity b = case binaryOp b of
  OpAdd | is 0 right -> Just left
  OpAdd | is 0 left -> Just right
  OpSub | is 0 right -> Just left
  OpSub | same -> constant 0
  OpMul | is 1 right -> Just left
  OpMul | is 1 left -> Just right
  OpMul | is 0 right || is 0 left -> constant 0
  OpUDiv | is 1 right -> Just left
  OpSDiv | is 1 right -> Just left
  OpURem | is 1 right -> constant 0
  OpSRem | is 1 right -> constant 0
  OpAnd | same || is (-1) right -> Just left
  OpAnd | is (-1) left -> Just right
  OpAnd | is 0 right || is 0 left -> constant 0
  OpOr | same || is 0 right -> Just left
  OpOr | is 0 left -> Just right
  OpOr | is (-1) right || is (-1) left -> constant (-1)
  OpXor | same -> constant 0
  OpXor | is 0 right -> Just left
  OpXor | is 0 left -> Just right
  -- Shifting by nothing leaves the value; shifting nothing leaves nothing,
  -- whatever the amount, including the amounts that would be poison.  A shift
  -- of all ones is the same story for the one that keeps the sign.
  OpShl | is 0 right -> Just left
  OpLShr | is 0 right -> Just left
  OpAShr | is 0 right -> Just left
  OpShl | is 0 left -> constant 0
  OpLShr | is 0 left -> constant 0
  OpAShr | is 0 left -> constant 0
  OpAShr | is (-1) left -> constant (-1)
  _ -> Nothing
  where
    left = binaryLeft b
    right = binaryRight b
    t = typedValueType left
    same = left == right

    -- Whether an operand is a particular number, read at the width the
    -- operation works at, so that all ones is @-1@ at every width and @true@
    -- at @i1@.
    is n operand = case (widthOf t, integerOf t (typedValue operand)) of
      (Just width, Just value) -> unsigned width value == unsigned width n
      _ -> False

    -- A number as an operand of the type the operation works at.  Nothing at a
    -- vector type, where a constant is written as an aggregate or a splat
    -- rather than as a number — the identities that give back an operand hold
    -- there anyway, and are the ones written without this.
    constant n = do
      _ <- widthOf t
      pure (TypedValue t (valueOf t n))

-- | What a comparison of a value with itself comes to.
--
-- The answer does not depend on the value, so it is settled even where the
-- value is poison: naming @true@ where LLVM allowed anything is the direction
-- that is allowed.  Only at a scalar type, since a comparison of vectors is a
-- vector of answers and a single 'VBoolean' is not one.
reflexive :: Eq local => Compare IntPredicate (TypedValue local) -> Maybe (TypedValue local)
reflexive c
  | compareLeft c /= compareRight c = Nothing
  | otherwise = case typedValueType (compareLeft c) of
      TInteger _ -> answer
      TPointer _ -> answer
      _ -> Nothing
  where
    answer = Just (TypedValue (TInteger 1) (VBoolean (holds (comparePredicate c))))
    holds predicate = case predicate of
      IEq -> True
      INe -> False
      IUge -> True
      IUle -> True
      ISge -> True
      ISle -> True
      IUgt -> False
      IUlt -> False
      ISgt -> False
      ISlt -> False

-- | What produced a local, where what it produced is still what the local
-- holds at the point the question is asked.
--
-- A function rather than a map because what a caller can establish is a fact
-- about a place: 'sweep' answers it for the definitions its walk of the block
-- has not yet had to drop.
--
-- A copy is followed to what it copies, so what a caller answers has to point
-- backwards — a local may name one assigned before it and never one assigned
-- after.  Dropping every definition that reads a local when that local is
-- assigned is what makes that so, and is required of an answer for the same
-- reason it is required for the answer to be true.
type Producer local = local -> Maybe (Operation (TypedValue local))

-- | The same, reading a local that is a copy as what it is a copy of, as far
-- back as the copies go.
--
-- Which is what makes the answer worth anything.  A value that passed through
-- a slot arrives with promotion's assignment between it and whatever reads it,
-- and that is the shape a front end writes; two computations are only adjacent
-- in code that never touched memory.
--
-- The walk terminates because a copy is recorded under a local assigned after
-- the one it names, and recording an assignment to a local drops every
-- definition that reads it, so nothing can point forwards.
producing :: Producer local -> Producer local
producing produced = go
  where
    go name = case produced name of
      Just (OAssign (TypedValue _ (VLocal copied))) -> go copied
      other -> other

-- | What an operation comes to when what produced an operand is known.
--
-- Conversions only, and integer conversions at that.  A widening followed by a
-- narrowing is the shape a front end writes whenever a value passes through a
-- type on its way to another — @i1@ through @i8@ back to @i1@ is what a C
-- @_Bool@ costs — and what it comes to is one conversion in whichever
-- direction the two widths ask for, or the original value where they cancel.
--
-- What comes out reads what the conversion looked through read, so the
-- instruction between them is left computing something nothing needs, which
-- the dead code pass collects.
--
-- The flags of the conversion that stood here are dropped rather than carried.
-- A flag on a narrowing says which bits it promises are already gone, and that
-- is a promise about the narrowing, not about the widening that comes out in
-- its place; dropping one can only make the result defined where it was
-- poison, which is the direction that is allowed.
foldThrough ::
  Producer local ->
  Operation (TypedValue local) ->
  Maybe (Operation (TypedValue local))
foldThrough produced operation = do
  OConvert outer <- Just operation
  VLocal name <- Just (typedValue (convertOperand outer))
  OConvert inner <- producing produced name
  from <- widthOf (typedValueType (convertOperand inner))
  middle <- widthOf (convertTarget inner)
  to <- widthOf (convertTarget outer)
  let source = convertOperand inner
      -- The same conversion, over what the one it looked through converted.
      instead op =
        OConvert outer {convertOp = op, convertFlags = [], convertOperand = source}
      -- Extending to @middle@ and cutting back to @to@, where the extension is
      -- the one named: the value is carried from @from@ to @to@ by whichever
      -- single step spans them, and by no step at all where they are the same
      -- width.
      narrowed extension
        | to == from = OAssign source
        | to > from = instead extension
        | otherwise = instead CastTrunc
  case (convertOp inner, convertOp outer) of
    -- Extending and then cutting back: the bits below the width it is cut to
    -- are the ones that were always there, so what is left is a step from the
    -- original width to the final one, in whichever direction that is.
    (CastZExt, CastTrunc) -> Just (narrowed CastZExt)
    (CastSExt, CastTrunc) -> Just (narrowed CastSExt)
    -- Two steps the same way are one step.
    (CastZExt, CastZExt) -> Just (instead CastZExt)
    (CastSExt, CastSExt) -> Just (instead CastSExt)
    (CastTrunc, CastTrunc) -> Just (instead CastTrunc)
    -- A zero extension leaves the top bit of what it produced clear, since it
    -- widened something narrower, so sign extending it copies a zero.
    (CastZExt, CastSExt) -> Just (instead CastZExt)
    -- Cutting a value down and putting zeroes back where it came from is that
    -- value with the bits that were cut taken out, which is a mask.  Only back
    -- to the width it started at: any other width leaves a conversion as well
    -- as the mask, which is no fewer instructions than there were.
    (CastTrunc, CastZExt)
      | to == from ->
          Just
            ( OBinary
                Binary
                  { binaryOp = OpAnd
                  , binaryFlags = []
                  , binaryLeft = source
                  , binaryRight =
                      TypedValue (convertTarget outer) (valueOf (convertTarget outer) (2 ^ middle - 1))
                  }
            )
    _ -> Nothing

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
