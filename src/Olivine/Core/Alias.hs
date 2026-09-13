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
-- __It answers by object, and then by the bytes touched.__  The pointer is
-- followed back through the steps and copies that derived it until something
-- says what storage it points into: an @alloca@, or a symbol.  Two pointers
-- into different objects cannot overlap however they were computed, and that
-- settles most of the questions asked here.
--
-- Where both are measured from the /same/ thing the walk has also added up
-- what it stepped over on the way, so each access is a byte at which it starts
-- and a number of bytes it covers, and two that do not meet are two places.
-- That is what tells one field of a struct from another.  Both halves of it
-- come from "Olivine.Core.Layout" — the stride of a step, the offset of a
-- field, the size of an access — so a module whose @target datalayout@ this
-- cannot read answers by object alone, as everything here did before there was
-- a layout.
--
-- __The same thing need not be an object.__  A front end writes two fields of
-- a struct the function was handed far more often than two fields of one it
-- made, and where the pointer came from is then a question about the caller.
-- But both accesses are still so many bytes past one parameter, and a
-- parameter the function never assigns to holds one value throughout it, so
-- the distance between them is known although the address is not.  A local a
-- call left a pointer in is the same case one step further on — a buffer the
-- function allocated for itself is written field by field exactly as a
-- handed-in one is — and it holds one value the same way, being assigned in
-- one place.  That is what 'Base' is: an object, or a local to measure from.
--
-- An offset is known or it is not.  A step by an index nothing settles, a
-- pointer arriving as a constant expression, a type with no size: any of them
-- and the accumulated offset is dropped, leaving the base and no offset, which
-- is the same as saying the access could be anywhere in it.
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
-- __What a parameter points at is partly the caller's business.__  Two of the
-- answers here are not about anything written in the body: an argument was
-- computed before the call began, so it cannot point into storage this call
-- allocated; and a parameter written @noalias@ — which is where a @restrict@
-- in the source ends up — is promised not to reach what anything else in the
-- function reaches.  Both are read off the signature rather than the
-- instructions, and both were settled by asking LLVM what it concludes about
-- the same pairs rather than by reading the LangRef's definition of \"based
-- on\".
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
  , Access (..)
  , objectsIn
  , objectOf
  , mayAlias
  , mustAlias
  , reachableByCall
  , reachableByArguments
  ) where

import Data.Foldable (toList)
import Data.List (delete)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Set (Set)
import Data.Set qualified as Set
import Numeric.Natural (Natural)

import Olivine.Core.Instruction
import Olivine.Core.Layout (Layout, allocSize, fieldOffset, storeSize)
import Olivine.Core.Program
import Olivine.Syntax.Attribute (ParamAttribute (..))
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction (Alloca (..), Convert (..), Load (..), Store (..))
import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Type)
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

-- | Where a pointer points: what it is measured from, and how far along that
-- it stands if that is known.
--
-- The offset is in bytes and may be negative, a step being free to go
-- backwards; Nothing where the walk passed something it could not measure.
data Region = Region
  { regionBase :: Base
  , regionOffset :: Maybe Integer
  }

-- | What a pointer is measured from.
--
-- Storage, where the function says which; and otherwise a local the walk
-- stopped at, which says nothing about where the pointer points but does say
-- that two pointers measured from it are that far apart.  That is what tells
-- one field of a handed-in struct from another, which is the shape a front end
-- writes far more often than it writes two fields of a local one.
--
-- __A local it can measure from is one holding a single value.__  A local
-- assigned in more than one place is a different value at different points, so
-- two pointers measured from it are two distances from two addresses, and it is
-- no base at all.  Everything else is: a parameter, which holds what the caller
-- passed for the whole of the call, and a local assigned exactly once, which
-- holds what its one assignment left there at every point that assignment
-- reaches.  A local assigned once by a derivation is one the walk goes
-- /through/ rather than stopping at; what stops it is an assignment that says
-- nothing about where the pointer points — a call, a load, a @select@ between
-- two pointers — and the local is then the far end of the walk.
--
-- __The two are one fact for the offsets and two for everything else.__  Both
-- say the same thing about two pointers measured from one of them, which is why
-- 'overlapping' asks only whether the bases are equal.  They part company over
-- what such a pointer may /meet/: what a parameter can point at is the caller's
-- business and is answered from the signature and from when the argument was
-- computed, and none of that reasoning holds for a pointer this function made.
-- A callee handed a slot's address can hand it straight back, so the value a
-- call left in a local may well point into this frame, where an argument to
-- that same call cannot.  Keeping them apart here is what stops 'handedIn'
-- being asked about a local that never came from a caller.
data Base
  = InObject Object
  | -- | A parameter the function never assigns to.
    AtParameter Local
  | -- | A local assigned once by something the walk cannot see through.
    AtLocal Local
  deriving (Eq)

-- | One access to memory: where it is and how much of it there is.
--
-- The type is what the access is made at rather than the type of the pointer,
-- which is @ptr@ and says nothing.  It is here because how far an access
-- reaches is the other half of whether two of them are the same bytes — a
-- store of an @i8@ and a store of an @i64@ four bytes along are two places, and
-- the same two stores the other way round are one.
data Access = Access
  { accessPointer :: Value Local
  , accessType :: Type
  }

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
  , -- | The parameters the function never assigns to, which are the locals
    -- that hold one value everywhere in it and so the only ones a distance can
    -- be measured from.  See 'Base'.
    fixed :: Set Local
  , -- | The parameters written @noalias@, which is @restrict@ where a front
    -- end put it.
    --
    -- The one thing here the function's own body does not say: what a
    -- parameter may point at is a fact about every caller, and this is the
    -- caller's promise about it written down where the callee can read it.
    apart :: Set Local
  , -- | How to measure a step and an access, where the module says.
    --
    -- Nothing is not a special case anywhere below: it makes every offset and
    -- every extent unknown, which is what the answers by object alone are
    -- already written in terms of.
    measuring :: Maybe Layout
  }

-- | Read a function's pointers.
objectsIn :: Maybe Layout -> Function -> Objects
objectsIn layout f =
  Objects definitions (leakingIn f definitions) unassigned promised layout
  where
    definitions = definitionsIn f

    unassigned =
      Set.fromList (functionParameters f)
        `Set.difference` Set.fromList
          [result | i <- instructionsIn f, Just result <- [instructionResult i]]

    -- The signature keeps its parameters in the order written and so does
    -- 'functionParameters', which is what lets one be read by the other: the
    -- attributes are in the signature and the local the body calls it by is
    -- not.
    promised =
      Set.fromList
        [ local
        | (local, p) <-
            zip
              (functionParameters f)
              (Syntax.signatureParameters (functionSignature f))
        , PANoAlias `elem` Syntax.parameterAttributes p
        ]

-- | What each local assigned in exactly one place is assigned by.
--
-- Parameters are left out however they are assigned to: one arrives holding
-- what the caller passed, so an assignment to a parameter is never the only
-- thing that put a value there.
--
-- __An assignment of poison is not one of the places.__  Promotion writes one
-- where the allocation was and the store's assignment after it, so the slot a
-- front end passed a pointer through is a local written twice and every
-- pointer read out of one would stop here.  Passing over it is not a special
-- case for that pass: a local holding poison is one that cannot be
-- dereferenced at all, so what this claims about it — where it points, what it
-- may overlap — is claimed only about accesses that are already undefined.
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
      , not (poison (instructionOperation i))
      ]
    only [operation] = Just operation
    only _ = Nothing

    poison (OAssign (TypedValue _ VPoison)) = True
    poison _ = False

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
            foldMap (toList . fst) (derivedFrom (instructionOperation i))
      _ -> []

    -- Where a pointer is used and not let out of sight: dereferenced, or handed
    -- on to a local this can follow it through.
    addressPositions operation =
      dereferenced operation <> foldMap (local . fst) (derivedFrom operation)

    dereferenced operation = case operation of
      OLoad l -> local (loadPointer l)
      OStore s -> local (storePointer s)
      -- Not dereferenced at all, but in the same position for this purpose: a
      -- lifetime marker is handed an address it neither follows nor keeps, so
      -- the storage behind it is no more reachable from elsewhere afterwards
      -- than before.  Promotion takes these away where it can; what is left
      -- here is the slots it could not promote, which are the aggregates and
      -- the arrays, and those are exactly the ones with anything to gain from
      -- being known unreached by a call.
      _ | Just marked <- lifetimeMarked operation -> [marked]
      -- A catch-all, unlike the enumerations a pass decides by, because the
      -- answer it gives for an operation added later is that the operation lets
      -- its operands out of sight — which is the cautious answer and stays
      -- right until someone wants better.
      _ -> []

    local (TypedValue _ (VLocal n)) = [n]
    local _ = []

-- | The operand an operation's result is a pointer into the same storage as,
-- and how far along from it the result stands.
--
-- The two steps, the copies, and the casts that change a pointer's type without
-- changing what it points at.  One answer serving three questions, which is
-- what keeps them agreeing: 'regionOf' follows these back, a pointer in one of
-- these positions is passed on rather than let out of sight, and a result let
-- out of sight lets out whatever it was derived from.  A position left out of
-- here is only followed less far; one wrongly put in would be a pointer
-- 'objectOf' claims to have followed and a leak nothing recorded.
--
-- The step comes back with the operand rather than being read off the
-- operation again elsewhere, so that an operation added here has to say how far
-- it moves and cannot be taken for one that moves nothing.
derivedFrom :: Operation operand -> Maybe (operand, Step operand)
derivedFrom operation = case operation of
  OAssign value -> Just (value, Nowhere)
  OOffset o -> Just (offsetPointer o, Strides (offsetElementType o) (offsetIndex o))
  OField x -> Just (fieldPointer x, Into (fieldStructType x) (fieldIndex x))
  -- A pointer has no pointee type to change since LLVM made them opaque, so
  -- the first of these is rare; the second is how one address space names
  -- storage in another.
  OConvert c
    | convertOp c `elem` [CastBitcast, CastAddrSpaceCast] ->
        Just (convertOperand c, Nowhere)
  _ -> Nothing

-- | How far one pointer stands past the one it was derived from.
--
-- Said in the terms the instruction is written in rather than in bytes,
-- because bytes are what the layout answers and 'derivedFrom' has no layout to
-- ask.  'regionOf' is where the two meet.
data Step operand
  = -- | The same address said another way.
    Nowhere
  | -- | So many of these, where the index says how many.
    Strides Type operand
  | -- | The field of this struct at this index.
    Into Type Natural

instructionsIn :: Function -> [Instruction]
instructionsIn f = [i | b <- functionBlocks f, i <- blockInstructions b]

-- | What storage a pointer points into, where the function says.
--
-- Followed back through whatever passed it along, by 'derivedFrom'.  Anything
-- else — a pointer read out of memory, arrived through a parameter, computed
-- from an integer, chosen by a @select@ — is where this stops, and stopping is
-- reported rather than guessed at.
objectOf :: Objects -> Value Local -> Maybe Object
objectOf objects value = case regionOf objects value of
  Just (Region (InObject object) _) -> Just object
  _ -> Nothing

-- | What storage a pointer points into and where in it, where the function
-- says.
--
-- The offset is added up on the way back: each step passed through says how
-- far along it went, and one that cannot say leaves the rest of the walk
-- looking for the object alone.
--
-- The locals already visited are carried so that a chain of copies that closes
-- on itself is answered rather than followed forever.  Nothing well formed
-- writes one, and this is not the place that says so.
regionOf :: Objects -> Value Local -> Maybe Region
regionOf objects = go Set.empty (Just 0)
  where
    go seen at value = case value of
      VGlobal name -> Just (Region (InObject (InGlobal name)) at)
      VLocal n
        | Set.member n seen -> Nothing
        | otherwise -> case Map.lookup n (definedBy objects) of
            Just (OAlloca _) -> Just (Region (InObject (OnStack n)) at)
            Just operation -> case derivedFrom operation of
              Just (from, step) ->
                go (Set.insert n seen) ((+) <$> at <*> distance step) (typedValue from)
              -- Assigned once by something that is no derivation, so this is as
              -- far back as the pointer can be followed.  Where it points is not
              -- said here and nothing below claims it is; what the walk stopping
              -- here buys over its giving up is the one answer a base gives,
              -- that two pointers measured from this local stand a known
              -- distance apart.  See 'Base'.
              Nothing -> Just (Region (AtLocal n) at)
            -- Not something the function assigned once: a parameter, or a local
            -- written in more than one place.  The first is a base to measure
            -- from and the second is nothing at all.
            Nothing
              | Set.member n (fixed objects) -> Just (Region (AtParameter n) at)
              | otherwise -> Nothing
      VCast op operand _
        | op `elem` [CastBitcast, CastAddrSpaceCast] -> go seen at (typedValue operand)
      -- A constant address computed from a symbol: the indices move within the
      -- object and the first operand is what they move within.  How far they
      -- move is not worked out — the walk over a list of indices is
      -- "Olivine.Core.Lower"'s, and a second copy of it here to serve a
      -- constant is a copy to keep right — so this says the object and no
      -- more.
      VGetElementPtr _ _ (base : _) -> go seen Nothing (typedValue base)
      _ -> Nothing

    -- A step in bytes.  Nothing where the module has no layout to measure it
    -- with, or where the index is not one the program has settled: an
    -- array subscript is usually a variable, and where it is, this is the walk
    -- giving up on the offset and keeping the object.
    distance step = case step of
      Nowhere -> Just 0
      Strides element index -> do
        layout <- measuring objects
        n <- constantIn index
        stride <- allocSize layout element
        pure (n * toInteger stride)
      Into struct index -> do
        layout <- measuring objects
        toInteger <$> fieldOffset layout struct index

    constantIn (TypedValue _ (VInteger n)) = Just n
    constantIn _ = Nothing

-- | Whether writing through one access can change what reading through the
-- other sees.
--
-- The ways to answer no: the two are measured from one base and touch bytes
-- that do not meet; they are in objects the program keeps apart; or one of them
-- is in a slot no stranger can name, and the other is a stranger.
mayAlias :: Objects -> Access -> Access -> Bool
mayAlias objects p q =
  case (regionOf objects (accessPointer p), regionOf objects (accessPointer q)) of
    (Just a, Just b) -> compared a b
    (Just a, Nothing) -> strange a
    (Nothing, Just b) -> strange b
    (Nothing, Nothing) -> True
  where
    compared a b = case (regionBase a, regionBase b) of
      -- One base, whatever it is, so how far along it each stands is the whole
      -- question.
      (x, y) | x == y -> overlapping a b
      -- A local this function computed and cannot place says nothing about
      -- where it points, which is what a pointer the walk gave up on says, so
      -- it meets what such a pointer meets.  The line above is the whole of
      -- what measuring from it buys.
      (AtLocal _, _) -> strange b
      (_, AtLocal _) -> strange a
      (InObject x, InObject y) -> not (distinct x y)
      -- A parameter points at what the caller had, and what that can be is
      -- decided by when it was computed and by what the caller promised.
      (InObject x, AtParameter n) -> handedIn objects n x
      (AtParameter n, InObject y) -> handedIn objects n y
      (AtParameter n, AtParameter m) -> not (promisedApart objects n m)

    -- What a region measured from a pointer this could not follow can be:
    -- anything, unless the other one is storage nothing outside these accesses
    -- has a way to name.
    --
    -- A @noalias@ promise says nothing here, although LLVM's own answer to the
    -- same pair is that it does.  The promise is about pointers not /based on/
    -- the parameter, and what this walk stopped at may be based on it: a
    -- @select@ between it and something else, or a local two branches assign,
    -- is exactly a pointer the promise covers rather than one it excludes.
    -- Telling those from a pointer read out of memory is the walk being able
    -- to say why it stopped, which it cannot.
    strange a = case regionBase a of
      InObject object -> escaped objects object
      AtParameter _ -> True
      AtLocal _ -> True

    distinct (OnStack x) (OnStack y) = x /= y
    -- No symbol names stack storage and nothing on the stack is a symbol.
    distinct (OnStack _) (InGlobal _) = True
    distinct (InGlobal _) (OnStack _) = True
    -- Two names, possibly one object, and possibly at an offset from each
    -- other: an alias is a second name for storage that already had one, and
    -- what it names may be part way into it.  So this is where the offsets say
    -- nothing, unlike the same name twice.
    distinct (InGlobal _) (InGlobal _) = False

    -- Whether the bytes one touches can be the bytes the other touches, which
    -- is a question only asked of two accesses measured from one base.
    -- Anything not known — either offset, either extent — and the answer is
    -- that they can.
    overlapping a b =
      fromMaybe True $ do
        here <- regionOffset a
        there <- regionOffset b
        layout <- measuring objects
        mine <- toInteger <$> storeSize layout (accessType p)
        theirs <- toInteger <$> storeSize layout (accessType q)
        pure (here < there + theirs && there < here + mine)

-- | Whether writing through one access covers exactly the bytes the other
-- names.
--
-- The other side of 'mayAlias', and not its negation: that one says two
-- accesses /can/ be the same place and this says they /are/ the same place, so
-- both answer no wherever the walk could not follow a pointer.  What wants it
-- is a store answered by a later store, where the later one has to write over
-- the whole of what the earlier one wrote — writing some of it leaves the rest
-- readable, and the earlier store has to stay for it.
--
-- One base and one offset make the addresses the same, whatever the base is:
-- an object, or a local this function measures from.  The extent is the other
-- half, and where the two are accessed at the same type it is settled without
-- a layout to measure with, which is the case a front end writes: a slot
-- written twice is written at its own type twice.
--
-- __The copies are what this is really for.__  Promotion leaves a value that
-- travelled through a slot as a local assigned from another local, and a front
-- end reloads a pointer parameter at every use, so two stores through \"the
-- same pointer\" arrive here naming two different locals.  'regionOf' walks
-- both back to what they are measured from, which is the whole reason this is
-- asked of "Olivine.Core.Alias" rather than by comparing two operands.
mustAlias :: Objects -> Access -> Access -> Bool
mustAlias objects p q = fromMaybe False $ do
  here <- regionOf objects (accessPointer p)
  there <- regionOf objects (accessPointer q)
  at <- regionOffset here
  also <- regionOffset there
  pure (regionBase here == regionBase there && at == also && extending)
  where
    extending
      | accessType p == accessType q = True
      | otherwise = fromMaybe False $ do
          layout <- measuring objects
          mine <- storeSize layout (accessType p)
          theirs <- storeSize layout (accessType q)
          pure (mine == theirs)

-- | Whether a pointer handed to this function can point into this storage.
--
-- An argument is computed by the caller before the call begins, so it cannot
-- point into storage this call allocated however far that storage's address
-- afterwards travels: a recursive call is handed a pointer into the frame that
-- made it, and this function's own @alloca@ belongs to this frame.  The
-- exception is @inalloca@, which is not storage the function owns but the
-- memory the caller built the arguments in, and which the caller therefore
-- names already.
--
-- A symbol is the other way round.  Everything outside the function can name
-- one, so an ordinary parameter may well point at it, and it takes the
-- @noalias@ promise to say otherwise — the promise being that what is reached
-- through the parameter is not reached any other way, and a symbol written by
-- name is another way.
handedIn :: Objects -> Local -> Object -> Bool
handedIn objects parameter object = case object of
  OnStack slot -> case Map.lookup slot (definedBy objects) of
    Just (OAlloca a) -> allocaInalloca a
    -- Not something this can look at, so not something to claim about.
    _ -> True
  InGlobal _ -> not (Set.member parameter (apart objects))

-- | Whether two parameters are promised to point into different storage.
--
-- One @noalias@ is enough: the promise is that nothing reached through this
-- parameter is reached other than through it, and the other parameter is
-- another way to reach it whether or not it carries a promise of its own.
--
-- Two accesses measured from /one/ parameter are of course the same storage,
-- and are settled by the offsets before this is asked.  It says so again
-- because the alternative is a soundness bug that depends on the order of the
-- cases above.
promisedApart :: Objects -> Local -> Local -> Bool
promisedApart objects p q =
  p /= q
    && (Set.member p (apart objects) || Set.member q (apart objects))

-- | Whether a call can reach the storage a pointer points into.
--
-- A call may do anything, so the question is only what it has a way to name.
-- Everything with a symbol, everything it was handed, and everything reachable
-- from either — which is everything except a slot whose address stayed in the
-- address positions of this function's own accesses.
reachableByCall :: Objects -> Value Local -> Bool
reachableByCall objects = maybe True (escaped objects) . objectOf objects

-- | Whether a call that touches only what its arguments reach can reach this
-- storage.
--
-- Stronger than 'reachableByCall' and asked instead of it, never as well:
-- storage that escaped is storage a stranger can name, but a callee promising
-- @memory(argmem: ...)@ has said it will not name it that way — the only
-- storage it touches is the storage its own arguments point into.  So the
-- question stops being whether the address got out and becomes whether any of
-- these arguments points into the same object.
--
-- An argument whose object cannot be worked out could be pointing anywhere, and
-- an address whose object cannot be worked out could be anywhere; either way
-- the answer is that it might.  Only the pointers are looked at: an argument
-- that is not one is not a way to reach storage.
reachableByArguments :: Objects -> [Value Local] -> Value Local -> Bool
reachableByArguments objects arguments address = case objectOf objects address of
  Nothing -> True
  Just object -> any (into object) arguments
  where
    into object argument = case objectOf objects argument of
      Nothing -> True
      Just other -> other == object

-- | Whether storage can be reached other than through a pointer this can
-- follow back to it.
escaped :: Objects -> Object -> Bool
escaped objects object = case object of
  OnStack slot -> Set.member slot (leaking objects)
  -- The program's interface to everything outside it is exactly its symbols.
  InGlobal _ -> True
