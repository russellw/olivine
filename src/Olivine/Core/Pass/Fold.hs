-- | Working out what a computation comes to.
--
-- Three things can settle that, and the pass asks them in that order.  Every
-- operand may be a constant, and then the answer is a number.  One operand may
-- be the number that makes the operation do nothing — @x + 0@, @x * 1@,
-- @x & -1@ — or the two operands may be the same value, and then the answer is
-- an operand or a constant that has nothing to do with what the operand holds.
-- Or what produced an operand may be known, and then a conversion of a
-- conversion is one conversion or none at all, a conversion cut back and
-- masked is the mask by itself, an aggregate taken apart and put back together
-- is the aggregate it came from, and two operands that are copies of one local
-- are the same value however differently they are spelled.
--
-- A folded instruction becomes an assignment of the value it computes.  The
-- core has assignment and LLVM does not, which is what makes that possible;
-- reconstructing single assignment then carries the value to wherever the
-- local was read, and the dead code pass takes the assignment away.  Nothing
-- new is needed to finish the job.  Looking through a definition is the one
-- case where what comes out is another operation rather than a value, since
-- what a narrowing of a widening comes to is usually a shorter conversion and
-- not a number; the instruction is left computing that instead, reading what
-- the definition it looked through read, and the same collection follows.
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
-- So this looks through a definition only where the instructions run in the
-- order they are written and one execution is one run of each.  Within a block
-- that holds, and a definition is dropped as soon as the local it names or any
-- local it reads is assigned again.  It holds across one boundary as well: a
-- block with exactly one way into it can only have been arrived at through that
-- block's terminator, so what the block above was left holding is what stands
-- here.  See 'sweep'.  Beyond that — two ways in, which would need the two to
-- agree — the walk is "Olivine.Core.Pass.Redundancies"'s availability analysis,
-- which answers a different question and answers it later.
--
-- The one boundary is not a refinement for its own sake.  A front end's cast
-- chains arrive as adjacent instructions and want nothing more than the block,
-- but an aggregate is taken apart where it is tested and put back together
-- where it is used, which for a landing pad is the block below.
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
  , integerOf
  , valueOf
  , widthOf
  ) where

import Control.Applicative ((<|>))
import Control.Monad (guard)
import Data.Bits (complement, shiftL, shiftR, (.&.), (.|.))
import Data.List (isPrefixOf, mapAccumL)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)

import Olivine.Core.Blocks (predecessorsOf, reversePostorder)
import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Instruction
  ( Binary (..)
  , BinaryOp (..)
  , Compare (..)
  , Convert (..)
  , ExtractValue (..)
  , InsertValue (..)
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
    blocks = functionBlocks f
    byLabel = Map.fromList [(blockLabel b, b) | b <- blocks]

    -- The definitions in hand are the folded ones and are carried along the
    -- block, so a chain settles as far as the block runs in one sweep rather
    -- than one link per sweep.  The terminator is read against what the last
    -- instruction left, which is where it stands.
    rewrite b =
      let (leaving, instructions) =
            fromMaybe
              (mapAccumL instruction Map.empty (blockInstructions b))
              (Map.lookup (blockLabel b) walked)
       in b
            { blockInstructions = instructions
            , blockTerminator =
                (blockTerminator b)
                  { terminatorTransfer =
                      fmap (resolve leaving) (terminatorTransfer (blockTerminator b))
                  }
            }

    -- Every block a walk arrives at, walked once: what it was left holding and
    -- what it turned into.
    --
    -- __The order is what makes it one walk rather than a chain of them.__  A
    -- block reads what the block above it was left holding, and in reverse
    -- postorder the block above has already been walked — the one edge into it
    -- cannot be a back edge, since a back edge is one whose target was reached
    -- before its source and the only way to reach this block is along it.  A
    -- block nothing reaches is not here at all, and 'rewrite' walks one of those
    -- from nothing.
    walked = foldl step Map.empty (reversePostorder f)
      where
        step done label = case Map.lookup label byLabel of
          Nothing -> done
          Just b ->
            Map.insert
              label
              (mapAccumL instruction (entering done label) (blockInstructions b))
              done

    -- What is in hand where a block begins: nothing, unless there is exactly
    -- one way into it, and then whatever the block above was left holding.
    --
    -- __One predecessor is the whole of the argument.__  Control reaching here
    -- can only have come through that block's terminator, so every instruction
    -- in it has just run, in order, and nothing has run since.  That is the same
    -- sentence that licenses the walk within a block, said of a pair of them,
    -- and it needs no dominance and no question about back edges: a loop around
    -- this block comes back through the one predecessor like everything else.
    -- Two ways in would need the two to agree, which is the availability walk in
    -- "Olivine.Core.Pass.Redundancies" and not this.
    --
    -- The terminator's own result is dropped, an @invoke@ and a @callbr@ being
    -- calls that assign where a branch stands: what the block left in that local
    -- is not what stands in it here.  Nothing else the terminator does can
    -- unsettle a definition, every rule reading this map being about a value
    -- worked out from operands rather than from memory.
    --
    -- __What is carried over is the definitions and not the constants.__  An
    -- assignment of a constant is dropped at the boundary, so this widens what
    -- 'foldThrough' can look through and leaves 'resolve' reading the block it
    -- stands in.  Carrying the constants too would be whole-function constant
    -- propagation, which is worth two instructions over the corpus and costs
    -- more than that: folding the address arithmetic in a loop's preheader
    -- shortens it, and a preheader that no longer ends the way the loop's own
    -- arms do is one "Olivine.Core.Pass.Sink" can take a shorter run from.  A
    -- constant that holds throughout is 'knownValues', which 'resolve' already
    -- asks, and where that cannot answer it is because promotion assigned the
    -- local twice — in which case what a block above settled is not what holds
    -- here anyway.
    entering done label
      | [above] <- predecessorsOf blocks label
      , Just (leaving, _) <- Map.lookup above done
      , Just previous <- Map.lookup above byLabel =
          Map.filter (not . isConstantAssignment)
            (forgetting (resultOf (blockTerminator previous)) leaving)
      | otherwise = Map.empty

    isConstantAssignment (OAssign value) = isConstant (typedValue value)
    isConstantAssignment _ = False

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
        remaining = forgetting (Just result) inHand

    -- What survives an assignment to a local, whatever made it: the definition
    -- held in that local described something else, and every definition reading
    -- it means something else now.
    forgetting Nothing inHand = inHand
    forgetting (Just result) inHand =
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
-- Integer conversions, and what may stand between two of them.  A widening
-- followed by a narrowing is the shape a front end writes whenever a value
-- passes through a type on its way to another — @i1@ through @i8@ back to @i1@
-- is what a C @_Bool@ costs — and a narrowing with a mask on it and a widening
-- back is what reading a bit field comes to once the slot holding it is
-- promoted.
foldThrough ::
  Eq local =>
  Producer local ->
  Operation (TypedValue local) ->
  Maybe (Operation (TypedValue local))
foldThrough produced operation =
  throughConversion produced operation
    <|> throughMask produced operation
    <|> throughAggregate produced operation
    <|> throughCopies produced operation

-- | An operation on two operands that are copies of one local, which the rules
-- for two operands that are the same value then answer.
--
-- Those rules ask whether the operands are equal, and after promotion they
-- rarely are however plainly the source said so: @b - b@ arrives as two loads
-- of one slot, which promotion makes two copies of one local, and two copies
-- are two locals.  This is that gap and nothing wider — the operands are made
-- to agree only where knowing they are one value settles the operation, so an
-- operation that would merely have its operand respelled is left alone.
--
-- Only the operand is rewritten and never the operand list at large, which is
-- the same line 'sweep' draws: resolving copy chains into operands would be a
-- second place that has to keep them right, and "Olivine.Core.Ssa" takes every
-- copy away on the way out.
throughCopies ::
  Eq local =>
  Producer local ->
  Operation (TypedValue local) ->
  Maybe (Operation (TypedValue local))
throughCopies produced operation = do
  equalized <- case operation of
    OBinary b -> do
      right <- agreed (binaryLeft b) (binaryRight b)
      pure (OBinary b {binaryRight = right})
    OICmp c -> do
      right <- agreed (compareLeft c) (compareRight c)
      pure (OICmp c {compareRight = right})
    _ -> Nothing
  OAssign <$> foldOperation equalized
  where
    -- The left operand written in place of the right, where the two name one
    -- value by way of the copies between them.
    agreed left right = do
      VLocal l <- Just (typedValue left)
      VLocal r <- Just (typedValue right)
      if l /= r && origin l == origin r then Just left else Nothing

    -- What a local ultimately names: a copy is what it copies.  The walk
    -- terminates for the reason 'producing''s does, being the same walk read
    -- for the name it ends at rather than the operation.
    origin name = case produced name of
      Just (OAssign (TypedValue _ (VLocal copied))) -> origin copied
      _ -> name

-- | A conversion of a conversion, which is one conversion in whichever
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
throughConversion ::
  Producer local ->
  Operation (TypedValue local) ->
  Maybe (Operation (TypedValue local))
throughConversion produced operation = do
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

-- | An aggregate value taken apart and put back together, which is the
-- aggregate it was taken from; and a field read out of an aggregate the field
-- was just written into, which is the value written.
--
-- The two rules are one another's inverse, and both arise the same way: an
-- aggregate small enough to travel in registers is passed about a field at a
-- time, so any pass that takes one apart hands the next one a chain to put back
-- together.  A landing pad is the case a front end writes without being asked —
-- the pad's pair is unpacked to test the selector and repacked to @resume@ —
-- and taking a struct out of a slot will be the other, since a whole-aggregate
-- load becomes a load per field and a chain that assembles them.
--
-- __The chain must cover every field and come from one aggregate.__  Rebuilding
-- from field 0 alone says nothing about field 1, so what is required is that
-- each of the fields is written exactly once, that each is @extractvalue@ of one
-- and the same value at that same field, and that the chain starts from
-- @poison@ or @undef@ — a chain built on something else keeps whatever that held
-- wherever it was not written, and a chain covering every field never reads it.
--
-- __Top level indices only.__  A path that goes further in writes part of a
-- field, and part of a field is not a field: knowing where @a.b.c@ came from
-- says nothing about the rest of @a.b@.  Nothing writes an aggregate that way
-- in any case, a front end assembling one field at a time.
--
-- __A named aggregate type is declined__, because the count of its fields is in
-- the module's type table and this pass reads nothing but the function.  LLVM
-- writes a literal type wherever an aggregate travels as a value — the corpus
-- has 108 of these instructions and not one names a type — so what that costs
-- is nothing, and the alternative is threading the table through folding for
-- one rule.
throughAggregate ::
  Eq local =>
  Producer local ->
  Operation (TypedValue local) ->
  Maybe (Operation (TypedValue local))
throughAggregate produced operation =
  readingBack operation <|> puttingBack operation
  where
    -- A field read out of an aggregate an insert had just written.  Where the
    -- paths are the same the answer is the value that was written; where
    -- neither path is a prefix of the other the insert wrote somewhere else
    -- entirely and the read goes past it, to the aggregate it wrote into.  A
    -- path that is a prefix of the other reads part of what was written, or
    -- writes part of what is read, and neither of those is settled here.
    readingBack o = do
      OExtractValue reading <- Just o
      VLocal name <- Just (typedValue (extractValueAggregate reading))
      OInsertValue written <- producing produced name
      let there = insertValueIndices written
          here = extractValueIndices reading
      if there == here
        then Just (OAssign (insertValueValue written))
        else do
          guard (not (there `isPrefixOf` here || here `isPrefixOf` there))
          Just (OExtractValue reading {extractValueAggregate = insertValueAggregate written})

    -- An aggregate assembled out of the fields of another one.
    puttingBack o = do
      OInsertValue outermost <- Just o
      let aggregate = typedValueType (insertValueAggregate outermost)
      fields <- fieldsIn aggregate
      guard (fields > 0)
      (base, written) <- chain Map.empty (OInsertValue outermost)
      guard (Map.keys written == [0 .. fromIntegral fields - 1])
      taken <- traverse fieldTaken (Map.toList written)
      -- One aggregate, and the same one the chain is building: a pair of
      -- doubles assembled out of another pair is that pair, and out of the
      -- first two fields of something wider it is not.
      (source : rest) <- Just taken
      guard (all (== source) rest)
      guard (typedValueType source == aggregate)
      guard (base == VUndef || base == VPoison)
      Just (OAssign source)
      where
        -- Each field of the chain must be read from its own place in the
        -- aggregate it is read from, or the chain is a permutation of one and
        -- not a copy.
        fieldTaken (index, value) = do
          VLocal name <- Just (typedValue value)
          OExtractValue reading <- producing produced name
          guard (extractValueIndices reading == [index])
          Just (extractValueAggregate reading)

    -- The whole chain of inserts, from the outermost inward: what each field
    -- was last written with, and the value the chain was built on.  Written
    -- outermost first, so a field written twice keeps the write that stands
    -- last in the program.
    chain written o = case o of
      OInsertValue i
        | [index] <- insertValueIndices i
        , VLocal name <- typedValue (insertValueAggregate i) ->
            chain (Map.insertWith (\_ old -> old) index (insertValueValue i) written)
              =<< producing produced name
        | [index] <- insertValueIndices i ->
            Just
              ( typedValue (insertValueAggregate i)
              , Map.insertWith (\_ old -> old) index (insertValueValue i) written
              )
      _ -> Nothing

    -- How many fields an aggregate has at its top level.
    fieldsIn t = case t of
      TStruct _ fields -> Just (length fields)
      TArray n _ -> Just (fromIntegral n)
      _ -> Nothing

-- | A value cut down, masked, and zeroed back to the width it came from, which
-- is the mask alone at the width it started at.
--
-- Cutting to @middle@ takes away every bit above that width and putting zeroes
-- back leaves them away, so the whole chain keeps only the bits the mask keeps
-- — and the mask, being a constant of the narrow type, has nothing above
-- @middle@ to keep.  Masking the original value with the same number is
-- therefore the same value, and the two conversions have nothing left to do.
--
-- Only @and@, and only back to the width it came from.  With @or@ or @xor@ the
-- bits the cut took away come back set or unset by the constant rather than
-- staying away, so the mask is still needed and the chain is no shorter; with
-- any other final width a conversion is left standing beside the mask, which
-- is what "Olivine.Core.Pass.Fold.throughConversion" already says about the
-- same shape without the mask in it.
--
-- The mask is read unsigned at the narrow width, which is what makes @and i16
-- %x, -9@ come out as @and i32 %y, 65527@: the bits above @middle@ are the
-- ones the chain cleared, and a constant written as a negative number at the
-- narrow type has them set.
--
-- This is what a C bit field read costs once "Olivine.Core.Pass.Promote" has
-- taken the slot away.  The load at a narrower type than the slot was stored
-- at becomes the cut, the shifting and masking clang wrote is the mask, and
-- the widening back to @int@ is the conversion outside it.
throughMask ::
  Producer local ->
  Operation (TypedValue local) ->
  Maybe (Operation (TypedValue local))
throughMask produced operation = do
  OConvert outer <- Just operation
  CastZExt <- Just (convertOp outer)
  VLocal name <- Just (typedValue (convertOperand outer))
  OBinary masking <- producing produced name
  OpAnd <- Just (binaryOp masking)
  middle <- widthOf (typedValueType (binaryLeft masking))
  to <- widthOf (convertTarget outer)
  let target = convertTarget outer
      -- One side is the value being cut down and the other the mask; which is
      -- which is not settled, so both readings are tried.
      through cut kept = do
        mask <- integerOf (typedValueType kept) (typedValue kept)
        VLocal narrowed <- Just (typedValue cut)
        OConvert narrowing <- producing produced narrowed
        CastTrunc <- Just (convertOp narrowing)
        let source = convertOperand narrowing
        from <- widthOf (typedValueType source)
        guard (from == to)
        pure
          ( OBinary
              masking
                { binaryLeft = source
                , binaryRight = TypedValue target (valueOf target (unsigned middle mask))
                }
          )
  through (binaryLeft masking) (binaryRight masking)
    <|> through (binaryRight masking) (binaryLeft masking)

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
