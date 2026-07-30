-- | Whether a write through one pointer can change what a read through
-- another sees.
--
-- Every question a pass asks about memory comes down to this one.  A load
-- reads what the last write to its address left there, so knowing that an
-- earlier load or store already settled it means knowing that nothing in
-- between could have written the same place — and \"the same place\" is what a
-- pointer does not say, two pointers being the same address or different ones
-- for reasons written elsewhere in the function.
--
-- __It answers by object, not by address.__  The pointer is followed back
-- through the steps and copies that derived it until something says what
-- storage it points into: an @alloca@, or a symbol.  Two pointers into
-- different objects cannot overlap however they were computed, and that is
-- the whole of what is claimed here.  Where within an object each one lands is
-- not compared, because comparing them needs sizes and the core has no data
-- layout: without one, @%p@ and @%p + 1@ are ranges of unknown length starting
-- at a known distance apart, which says nothing.  So a store to one field of a
-- struct is taken to write every field of it.  Distinguishing steps of equal
-- stride by their constant index is the refinement to make when it is worth
-- one, and it is sound without a layout — two whole elements of the same array
-- are disjoint whatever an element measures — but it is not made yet.
--
-- __What escapes decides what a stranger can reach.__  A pointer this cannot
-- follow back to an object may point anywhere a pointer got to, and that is
-- everywhere except a slot whose address never went anywhere: if the only
-- places a local's address was ever written are the address positions of loads,
-- stores and steps, then nothing else in the function and nothing any callee
-- can do has a way to name that storage.  This is the one fact here that is
-- not local to the instruction being asked about, and the one that makes
-- knowledge of a slot survive a call.
--
-- __Two globals are not distinguished.__  Distinct @alloca@s are distinct
-- objects, and no symbol names stack storage, so those cases are settled.  Two
-- global names are not: an alias gives a second name to one object, and two
-- declarations can be one symbol once the linker has been over them.  Reading
-- the module to find which names are aliases of what would buy the cases where
-- one global is written and another read, and is left for when they turn up.
--
-- __It lives outside the passes that use it.__  Redundant loads are the first
-- caller and not the last: hoisting a load out of a loop is the same question
-- asked of a whole loop body rather than of the instructions between two
-- accesses.  Nothing here is about either transformation.
module Olivine.Core.Alias
  ( Object (..)
  , Objects
  , objectsIn
  , objectOf
  , mayAlias
  , reachableByCall
  ) where

import Data.Foldable (toList)
import Data.List (delete)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set

import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Instruction (Alloca (..), Convert (..), Load (..), Store (..))
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Value (CastOp (..), TypedValue (..), Value (..))

-- | The storage a pointer points into.
--
-- Only the two kinds whose identity is written in the program.  Storage a
-- function was handed — through a parameter, out of a call, read back from
-- memory — is no object here but the absence of one, which is what makes
-- 'objectOf' partial.
data Object
  = -- | What an @alloca@ made, named by the local the allocation assigns to.
    --
    -- The local rather than the instruction, since that is what the allocation
    -- is identified by everywhere else, and two allocations never share one.
    OnStack Local
  | -- | What a symbol names.
    InGlobal Name
  deriving (Eq, Show)

-- | What a function says about its own pointers.
--
-- Worked out once for the function and then asked about pointer after
-- pointer, which is why it is a value rather than a pass over the blocks per
-- question.
data Objects = Objects
  { -- | What each local assigned in exactly one place is assigned by.
    --
    -- One place, because following a pointer back through a local written in
    -- two would be following it to whichever of them ran, and the answer has
    -- to hold on every path.  A local assigned twice therefore says nothing
    -- here, and 'leaking' is what keeps that from being mistaken for saying
    -- nothing can reach it.
    definedBy :: Map Local (Operation (TypedValue Local))
  , -- | The locals whose value reaches somewhere this cannot follow it to.
    leaking :: Set Local
  }

-- | Read a function's pointers.
objectsIn :: Function -> Objects
objectsIn f = Objects definitions (leakingIn f definitions)
  where
    definitions = definitionsIn f

-- | What each local assigned in exactly one place is assigned by.
--
-- Parameters are left out however they are assigned to: one arrives holding
-- what the caller passed, so an assignment to a parameter is never the only
-- thing that put a value there.
definitionsIn :: Function -> Map Local (Operation (TypedValue Local))
definitionsIn f =
  Map.withoutKeys
    (Map.mapMaybe only (Map.fromListWith (<>) assignments))
    (Set.fromList (functionParameters f))
  where
    assignments =
      [ (result, [instructionOperation i])
      | i <- instructionsIn f
      , Just result <- [instructionResult i]
      ]
    only [operation] = Just operation
    only _ = Nothing

-- | The locals whose value gets somewhere this cannot follow it to.
--
-- A least fixed point over two rules.  An instruction lets out of sight
-- everything it reads other than as an address: a call argument, a returned
-- value, the value half of a store, an operand of anything that computes with
-- a pointer rather than dereferencing it.  And a step whose result gets out of
-- sight lets out what it stepped from, since a pointer into an object is as
-- good as the object to anything holding it.
leakingIn :: Function -> Map Local (Operation (TypedValue Local)) -> Set Local
leakingIn f definitions = settle (Set.fromList (concatMap directly instructions <> transferred))
  where
    instructions = instructionsIn f

    -- A terminator reads no address in the sense above, so everything one names
    -- is let out of sight.  Nothing after a @ret@ runs, so this changes no
    -- answer that matters; it is here so that saying which answers matter is
    -- not a thing anyone has to work out.
    transferred =
      [ named
      | b <- functionBlocks f
      , named <- localsUsedBy (terminatorTransfer (blockTerminator b))
      ]

    settle seen
      | next == seen = seen
      | otherwise = settle next
      where
        next = seen <> Set.fromList (concatMap (carriedBy seen) instructions)

    directly i = case instructionResult i of
      -- @inalloca@ storage is how an argument is passed rather than something
      -- the function owns, so the caller reaches it without the address going
      -- anywhere from here.
      Just result
        | OAlloca a <- instructionOperation i
        , allocaInalloca a ->
            result : elsewhere
      -- A local assigned in more than one place is one 'objectOf' will not
      -- follow, so a store through it would appear to reach nothing.  What it
      -- was derived from has to be given up on here instead.
      Just result | not (Map.member result definitions) -> everything
      _ -> elsewhere
      where
        everything = localsUsedBy (instructionOperation i)

        -- Written as a difference rather than by case so that a local
        -- appearing twice in one instruction is counted twice:
        -- @store ptr %a, ptr %a@ writes a slot's own address into it, and the
        -- value operand lets it out although the pointer operand does not.
        elsewhere = foldr delete everything (addressPositions (instructionOperation i))

    carriedBy seen i = case instructionResult i of
      Just result
        | Set.member result seen ->
            foldMap toList (derivedFrom (instructionOperation i))
      _ -> []

    -- Where a pointer is used and not let out of sight: dereferenced, or handed
    -- on to a local this can follow it through.
    addressPositions operation =
      dereferenced operation <> foldMap local (derivedFrom operation)

    dereferenced operation = case operation of
      OLoad l -> local (loadPointer l)
      OStore s -> local (storePointer s)
      -- A catch-all, unlike the enumerations a pass decides by, because the
      -- answer it gives for an operation added later is that the operation lets
      -- its operands out of sight — which is the cautious answer and stays
      -- right until someone wants better.
      _ -> []

    local (TypedValue _ (VLocal n)) = [n]
    local _ = []

-- | The operand an operation's result is a pointer into the same storage as.
--
-- The two steps, the copies, and the casts that change a pointer's type without
-- changing what it points at.  One answer serving three questions, which is
-- what keeps them agreeing: 'objectOf' follows these back, a pointer in one of
-- these positions is passed on rather than let out of sight, and a result let
-- out of sight lets out whatever it was derived from.  A position left out of
-- here is only followed less far; one wrongly put in would be a pointer
-- 'objectOf' claims to have followed and a leak nothing recorded.
derivedFrom :: Operation operand -> Maybe operand
derivedFrom operation = case operation of
  OAssign value -> Just value
  OOffset o -> Just (offsetPointer o)
  OField x -> Just (fieldPointer x)
  -- A pointer has no pointee type to change since LLVM made them opaque, so
  -- the first of these is rare; the second is how one address space names
  -- storage in another.
  OConvert c
    | convertOp c `elem` [CastBitcast, CastAddrSpaceCast] -> Just (convertOperand c)
  _ -> Nothing

instructionsIn :: Function -> [Instruction]
instructionsIn f = [i | b <- functionBlocks f, i <- blockInstructions b]

-- | What storage a pointer points into, where the function says.
--
-- Followed back through whatever passed it along, by 'derivedFrom'.  Anything
-- else — a pointer read out of memory, arrived through a parameter, computed
-- from an integer, chosen by a @select@ — is where this stops, and stopping is
-- reported rather than guessed at.
--
-- The locals already visited are carried so that a chain of copies that closes
-- on itself is answered rather than followed forever.  Nothing well formed
-- writes one, and this is not the place that says so.
objectOf :: Objects -> Value Local -> Maybe Object
objectOf objects = go Set.empty
  where
    go seen value = case value of
      VGlobal name -> Just (InGlobal name)
      VLocal n
        | Set.member n seen -> Nothing
        | otherwise -> case Map.lookup n (definedBy objects) of
            Just (OAlloca _) -> Just (OnStack n)
            Just operation ->
              go (Set.insert n seen) . typedValue =<< derivedFrom operation
            Nothing -> Nothing
      VCast op operand _
        | op `elem` [CastBitcast, CastAddrSpaceCast] -> go seen (typedValue operand)
      -- A constant address computed from a symbol: the indices move within the
      -- object and the first operand is what they move within.
      VGetElementPtr _ _ (base : _) -> go seen (typedValue base)
      _ -> Nothing

-- | Whether writing through one pointer can change what reading through the
-- other sees.
--
-- The two ways to answer no: both point into objects, and the objects are
-- different ones; or one of them points into a slot no stranger can name, and
-- the other is a stranger.
mayAlias :: Objects -> Value Local -> Value Local -> Bool
mayAlias objects p q = case (objectOf objects p, objectOf objects q) of
  (Just a, Just b) -> not (distinct a b)
  (Just a, Nothing) -> escaped objects a
  (Nothing, Just b) -> escaped objects b
  (Nothing, Nothing) -> True
  where
    distinct (OnStack a) (OnStack b) = a /= b
    -- No symbol names stack storage and nothing on the stack is a symbol.
    distinct (OnStack _) (InGlobal _) = True
    distinct (InGlobal _) (OnStack _) = True
    -- Two names, possibly one object.  See the module: an alias is a second
    -- name for storage that already had one.
    distinct (InGlobal _) (InGlobal _) = False

-- | Whether a call can reach the storage a pointer points into.
--
-- A call may do anything, so the question is only what it has a way to name.
-- Everything with a symbol, everything it was handed, and everything reachable
-- from either — which is everything except a slot whose address stayed in the
-- address positions of this function's own accesses.
reachableByCall :: Objects -> Value Local -> Bool
reachableByCall objects = maybe True (escaped objects) . objectOf objects

-- | Whether storage can be reached other than through a pointer this can
-- follow back to it.
escaped :: Objects -> Object -> Bool
escaped objects object = case object of
  OnStack slot -> Set.member slot (leaking objects)
  -- The program's interface to everything outside it is exactly its symbols.
  InGlobal _ -> True
