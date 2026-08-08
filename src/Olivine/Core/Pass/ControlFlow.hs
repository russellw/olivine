-- | Simplifying control flow: folding branches that decide nothing, and
-- removing the blocks nothing can then reach.
--
-- This is the other half of "Olivine.Core.Pass.Fold".  Folding works out that a
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
--
-- __An @indirectbr@ is read the same way, and reading it needs the block.__
-- Where a branch reads a condition an address is computed, so what says where
-- a computed jump goes is the instruction above it rather than an operand of
-- the transfer: @goto *(c ? &&x : &&y)@ is a conditional branch written the
-- long way, and this is where it becomes one.  That is why the folding here
-- is handed what the block says about the addresses in it — 'aimsIn' — where
-- everything else it does is a fact about the terminator alone.
--
-- __An @invoke@ that cannot throw is one of those branches__, and 'plainCalls'
-- is where it stops being a branch at all.  The edge it cannot take leads to a
-- landing pad, so what folding it away leaves for the sweep below to collect is
-- a whole block and everything in it, which is the largest thing this pass does
-- on a program with exceptions in it.  Two things make it unlike the rest:
-- what it rewrites is the block and not only the terminator — a call that does
-- not end its block is an instruction — and it is the first thing here to want
-- an analysis, since whether a callee throws is 'Olivine.Core.Effects'
-- answering rather than arithmetic on an operand.
module Olivine.Core.Pass.ControlFlow
  ( simplifyControlFlow
  , foldTerminator
  ) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Blocks (mergeBlocks, removeForwarding)
import Olivine.Core.Effects (Behaviour (..), behaviourOf, effectsOf)
import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Function (Signature (..))
import Olivine.Syntax.Instruction (Call, Select (..))
import Olivine.Syntax.Type (Type (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

simplifyControlFlow :: Program -> Program
simplifyControlFlow program =
  program {programEntries = map entry (programEntries program)}
  where
    -- Read once for the whole program, and still true at the end of it: what
    -- this pass does to a function is remove work, and nothing it removes is
    -- something a caller could have been relying on the callee to do.  So no
    -- answer here goes stale as the sweeps go round.
    made = behaviourOf (effectsOf program)
    entry (EFunction f) = EFunction (settle made f)
    entry retained = retained

-- | What a call may do, as this pass is handed it.
type Made = Call (TypedValue Local) -> Behaviour

-- | Removing one block can leave another unreachable, and can leave the block
-- before it a detour, so this runs until a sweep finds nothing.
settle :: Made -> Function -> Function
settle made f
  | swept == f = f
  | otherwise = settle made swept
  where
    swept = sweep made f

-- | Fold what can be folded, drop what that leaves unreachable, and put back
-- together the blocks the CFG no longer has a reason to keep apart.
--
-- Merging comes last because the other three make work for it and it makes
-- none for them: a block stops having a second predecessor when the branch
-- that was the other one folds away, or when the block it was in is dropped.
--
-- Making the invokes plain comes first for the same reason from the other end:
-- it is the one step that makes work for all three and takes none from any of
-- them.  An invoke that becomes a call is a block whose landing pad nothing now
-- reaches, so pruning has something to drop; and it is a block ending in an
-- unconditional branch, so merging has two blocks to join where it had a call
-- standing between them.
sweep :: Made -> Function -> Function
sweep made f = mergeBlocks (removeForwarding (prune (decide (plainCalls made f))))
  where
    decide g = g {functionBlocks = map (fold g) (functionBlocks g)}
    prune g = g {functionBlocks = reachableIn g}
    fold g b = b {blockTerminator = foldIn (aimsIn g b) (blockTerminator b)}
    foldIn aims t =
      maybe t (\transfer -> t {terminatorTransfer = transfer}) $
        foldTerminator aims (terminatorTransfer t)

-- | An @invoke@ whose callee cannot throw, written as the call it is.
--
-- The unwind edge of such an invoke is a branch that can never be taken, so
-- this is 'foldTerminator' by another name — and it is here rather than there
-- because the answer is not a transfer.  A call that returns to the next
-- instruction /is/ an instruction, so what comes back is the block with the
-- call at the end of its instructions and an unconditional branch to where the
-- invoke went when it returned.
--
-- __The result is the same local and it is now readable everywhere.__  An
-- invoke's result arrives only along the normal edge, which is what the
-- verifier's @ResultOnUnwind@ says; an instruction's result is in hand for the
-- rest of the block and below.  That is a widening of where it may be read and
-- so takes nothing away from anything already written.
--
-- __Nothing moves.__  The call ends up where the invoke was, after every
-- instruction of the block and before control leaves it, so the copies a phi
-- left on the normal edge still run where they ran.  That is why this needs no
-- question asked about the block: an invoke is already the last thing in it.
--
-- The metadata goes on the call rather than on the branch.  An attachment on an
-- invoke is about the call it makes — what it may return, which callees it may
-- resolve to — and the branch this leaves behind decides nothing for a branch
-- weight to be about.
plainCalls :: Made -> Function -> Function
plainCalls made f = f {functionBlocks = map plainly (functionBlocks f)}
  where
    plainly b = case terminatorTransfer (blockTerminator b) of
      Invoke result call normal _
        | not (mayUnwind (made call)) ->
            b
              { blockInstructions =
                  blockInstructions b
                    <> [ Instruction
                          { instructionResult = result
                          , instructionOperation = OCall call
                          , instructionMetadata = terminatorMetadata (blockTerminator b)
                          }
                       ]
              , blockTerminator = Terminator (Br normal) []
              }
      _ -> b

-- | The blocks control can get to, in the order they were written.
--
-- Reachability is walked from the block the function starts at rather than
-- from every labelled block, which is the whole difference between this and
-- doing nothing: a block is not kept alive by the blocks that branch to it
-- when nothing reaches those either, as a loop nothing enters shows.
--
-- The branches are not quite the whole story, and the exception is
-- @blockaddress@: the address of a block is a way of reaching it that no
-- terminator here mentions, and the table it is written into may be read by
-- another function entirely.  So the walk starts from those blocks as well as
-- from the entry, which is 'Olivine.Core.Program.pinnedIn' — an @indirectbr@
-- in this function listing every destination says the same thing about the
-- ones it lists, and says nothing about the rest.
reachableIn :: Function -> [Block]
reachableIn f = [b | b <- blocks, blockLabel b `Set.member` reached]
  where
    blocks = functionBlocks f
    successors = Map.fromList [(blockLabel b, targetsOf (blockTerminator b)) | b <- blocks]
    reached = walk Set.empty (maybe [] pure (entryLabel f) <> Set.toList (pinnedIn f))

    walk :: Set Label -> [Label] -> Set Label
    walk seen [] = seen
    walk seen (label : rest)
      | label `Set.member` seen = walk seen rest
      | otherwise =
          walk (Set.insert label seen) (Map.findWithDefault [] label successors <> rest)

-- | What a branch comes to when only one of its destinations is possible.
--
-- Two things make a destination the only one: a condition this pass can read,
-- and destinations that agree.  The second needs no constant at all — a
-- branch to the same block either way goes there whatever it was branching
-- on, and a @switch@ whose cases all name the default is a @switch@ in name.
foldTerminator ::
  Map Local Aim ->
  Transfer (TypedValue Local) ->
  Maybe (Transfer (TypedValue Local))
foldTerminator aims transfer = case transfer of
  CondBr condition true false
    | true == false -> Just (Br true)
    | Just taken <- conditionOf (typedValue condition) ->
        Just (Br (if taken then true else false))
  Switch value target cases
    | all ((== target) . snd) cases -> Just (Br target)
    | Just chosen <- caseTaken value target cases -> Just (Br chosen)
  -- An @indirectbr@ names every block its address can hold, so one that names
  -- a single block is a branch to it, whatever address was computed.
  IndirectBr _ (target : rest)
    | all (== target) rest -> Just (Br target)
  -- And one whose address this block computed is a branch to what it
  -- computed.  A @goto *p@ where @p@ was decided a line earlier is what a
  -- front end writes for @goto@ into a label held in a variable, and reading
  -- it is what turns the jump table back into the branch the source meant.
  IndirectBr address targets
    | Just aim <- reaching aims address -> case aim of
        AtOne target | target `elem` targets -> Just (Br target)
        AtEither condition true false
          | true `elem` targets, false `elem` targets ->
              Just (CondBr condition true false)
        _ -> Nothing
  _ -> Nothing

-- * Where a computed jump goes

-- | Where the address a local holds may land.
data Aim
  = -- | One block, because the local holds that block's address.
    AtOne Label
  | -- | One of two, decided by a condition: the local was assigned a
    -- @select@ between two block addresses.
    AtEither (TypedValue Local) Label Label

-- | Where each local this block computes an address into may land.
--
-- Read block-locally, and for the reason "Olivine.Core.Pass.Fold" reads what
-- produced an operand block-locally: a local here may be assigned twice, so
-- knowing that it /was/ assigned a block's address somewhere is not knowing
-- that it holds one here.  Within a block the instructions run in order and
-- one execution is one run of each, so what the last assignment above the
-- terminator left is what the terminator reads.  A local assigned again loses
-- what was known about it, and so does an aim whose condition is assigned
-- again — the branch this becomes reads that condition where the terminator
-- stands, not where the @select@ did.
--
-- The address has to name a block of this function.  Jumping to a block of
-- another one is undefined however the address was got, so an address from
-- elsewhere is not something to fold into a branch to a block that is not
-- here.
aimsIn :: Function -> Block -> Map Local Aim
aimsIn f b = foldl step Map.empty (blockInstructions b)
  where
    here = functionAddressed f
    ours = signatureName (functionSignature f)

    step aims i = case (instructionResult i, instructionOperation i) of
      (Just result, operation) ->
        Map.alter (const (aimOf aims operation)) result (dropping result aims)
      (Nothing, _) -> aims

    -- An aim whose condition has just been assigned is no longer an aim: what
    -- the condition holds at the terminator is not what the select read.
    dropping written =
      Map.filter (\aim -> written `notElem` conditionOf' aim)
      where
        conditionOf' (AtEither condition _ _) = localsUsedBy [condition]
        conditionOf' (AtOne _) = []

    aimOf aims operation = case operation of
      OAssign operand -> reaching aims operand
      OSelect s -> do
        true <- reaching aims (selectTrue s)
        false <- reaching aims (selectFalse s)
        case (true, false) of
          (AtOne a, AtOne c) -> Just (AtEither (selectCondition s) a c)
          _ -> Nothing
      _ -> Nothing

    labelOf function block
      | function == ours = Map.lookup block here
      | otherwise = Nothing

    reaching aims operand = case typedValue operand of
      VBlockAddress function block -> AtOne <$> labelOf function block
      VLocal local -> Map.lookup local aims
      _ -> Nothing

-- | Where an operand's address lands, where the block above says.
reaching :: Map Local Aim -> TypedValue Local -> Maybe Aim
reaching aims operand = case typedValue operand of
  VLocal local -> Map.lookup local aims
  _ -> Nothing

-- | An @i1@ operand as the branch it decides, when it decides one.
--
-- An @i1@ written as a number rather than as @true@ or @false@ is the same
-- value spelled differently, and the low bit is what it says.
conditionOf :: Value local -> Maybe Bool
conditionOf (VBoolean chosen) = Just chosen
conditionOf (VInteger n) = Just (odd n)
conditionOf _ = Nothing

-- | The block a @switch@ goes to, when the value it switches on is known.
--
-- The default is where it goes when no case matches, which is what makes this
-- total once the value is in hand.  LLVM requires the cases to be distinct, so
-- at most one matches; taking the first does not rely on that being true.
caseTaken :: TypedValue local -> Label -> [(TypedValue local, Label)] -> Maybe Label
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
bitsOf :: TypedValue local -> Maybe Integer
bitsOf (TypedValue (TInteger width) value) = case value of
  VInteger n -> Just (n `mod` 2 ^ toInteger width)
  VBoolean chosen -> Just (if chosen then 1 else 0)
  _ -> Nothing
bitsOf _ = Nothing
