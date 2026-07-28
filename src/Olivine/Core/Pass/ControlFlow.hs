-- | Simplifying control flow: folding branches that decide nothing, and
-- removing the blocks nothing can then reach.
--
-- This is the other half of constant folding.  Folding works out that a
-- condition is @false@ and stops there, because rewriting @br@ is a change to
-- the shape of the function rather than to a value; this is where that change
-- is made.  What follows is the point of it: a block nothing branches to is a
-- block whose calls are not calls, which is how folding an @icmp@ ends up
-- deleting a function two passes later.
--
-- __Only branches that cannot go two ways.__  A branch on a value this pass
-- cannot read is left alone, including one on @poison@, which LLVM is
-- entitled to treat as unreachable and this is not: undefined behaviour is a
-- promise the program made, and collecting on it is a separate decision from
-- the arithmetic here.
module Olivine.Core.Pass.ControlFlow
  ( simplifyControlFlow
  , foldTerminator
  ) where

import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Blocks (removeForwarding)
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Operation (..))
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

simplifyControlFlow :: Program -> Program
simplifyControlFlow program =
  program {programEntries = map entry (programEntries program)}
  where
    entry (EFunction f) = EFunction (settle f)
    entry retained = retained

-- | Removing one block can leave another unreachable, and can leave the block
-- before it a detour, so this runs until a sweep finds nothing.
settle :: Function -> Function
settle f
  | swept == f = f
  | otherwise = settle swept
  where
    swept = sweep f

sweep :: Function -> Function
sweep f = removeForwarding (prune (decide f))
  where
    decide g = g {functionBlocks = map fold (functionBlocks g)}
    prune g = g {functionBlocks = reachableIn g}
    fold b = b {blockTerminator = foldIn (blockTerminator b)}
    foldIn t =
      maybe t (\operation -> t {terminatorOperation = operation}) $
        foldTerminator (terminatorOperation t)

-- | The blocks control can get to, in the order they were written.
--
-- Reachability is walked from the block the function starts at rather than
-- from every labelled block, which is the whole difference between this and
-- doing nothing: a block is not kept alive by the blocks that branch to it
-- when nothing reaches those either, as a loop nothing enters shows.
--
-- What makes the branches the whole story is that @blockaddress@ is not
-- modelled, so a function taking one holds a line the lowering cannot read
-- and is retained as syntax entire.  Whoever models it has to come back here:
-- the address of a block is a way of reaching it that no terminator mentions,
-- and @indirectbr@ listing every destination is what stands in for that now.
reachableIn :: Function -> [Block]
reachableIn f = [b | b <- blocks, nameOf b `Set.member` reached]
  where
    blocks = functionBlocks f
    nameOf b = fromMaybe (entryName (functionSignature f)) (blockLabel b)
    successors = Map.fromList [(nameOf b, targetsOf (blockTerminator b)) | b <- blocks]
    reached = walk Set.empty [entryLabel f]

    walk :: Set Name -> [Name] -> Set Name
    walk seen [] = seen
    walk seen (name : rest)
      | name `Set.member` seen = walk seen rest
      | otherwise =
          walk (Set.insert name seen) (Map.findWithDefault [] name successors <> rest)

-- | What a branch comes to when only one of its destinations is possible.
--
-- Two things make a destination the only one: a condition this pass can read,
-- and destinations that agree.  The second needs no constant at all — a
-- branch to the same block either way goes there whatever it was branching
-- on, and a @switch@ whose cases all name the default is a @switch@ in name.
foldTerminator :: Syntax.Operation -> Maybe Syntax.Operation
foldTerminator operation = case operation of
  OCondBr condition true false
    | true == false -> Just (OBr true)
    | Just taken <- conditionOf (typedValue condition) ->
        Just (OBr (if taken then true else false))
  OSwitch value target cases
    | all ((== target) . snd) cases -> Just (OBr target)
    | Just chosen <- caseTaken value target cases -> Just (OBr chosen)
  -- An @indirectbr@ names every block its address can hold, so one that names
  -- a single block is a branch to it, whatever address was computed.
  OIndirectBr _ (target : rest)
    | all (== target) rest -> Just (OBr target)
  _ -> Nothing

-- | An @i1@ operand as the branch it decides, when it decides one.
--
-- An @i1@ written as a number rather than as @true@ or @false@ is the same
-- value spelled differently, and the low bit is what it says.
conditionOf :: Value -> Maybe Bool
conditionOf (VBoolean chosen) = Just chosen
conditionOf (VInteger n) = Just (odd n)
conditionOf _ = Nothing

-- | The block a @switch@ goes to, when the value it switches on is known.
--
-- The default is where it goes when no case matches, which is what makes this
-- total once the value is in hand.  LLVM requires the cases to be distinct, so
-- at most one matches; taking the first does not rely on that being true.
caseTaken :: TypedValue -> Name -> [(TypedValue, Name)] -> Maybe Name
caseTaken value target cases = do
  n <- bitsOf value
  pure $ case [label | (c, label) <- cases, bitsOf c == Just n] of
    label : _ -> label
    [] -> target

-- | An integer constant as the bits it stands for.
--
-- Taken modulo the width so that two spellings of one value compare equal:
-- @i8 -1@ and @i8 255@ are the same byte written two ways, and a @switch@ on
-- either takes the case written as the other.
bitsOf :: TypedValue -> Maybe Integer
bitsOf (TypedValue (TInteger width) value) = case value of
  VInteger n -> Just (n `mod` 2 ^ toInteger width)
  VBoolean chosen -> Just (if chosen then 1 else 0)
  _ -> Nothing
bitsOf _ = Nothing
