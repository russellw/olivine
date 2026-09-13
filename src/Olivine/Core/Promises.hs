-- | What a module says about the symbols it names, read once for everyone who
-- asks.
--
-- An attribute is written in whichever of several places the front end found
-- convenient — spelled on a function, spelled on a call site, or put in a group
-- that both point at — and a pass that reads only one of them reads almost
-- nothing: clang puts @noinline@ in a group and points every function at
-- @-O0@ at it, and writes @returns_twice@ on the @declare@ of @setjmp@ as well
-- as on the calls to it.  Following those references is what this does, and it
-- is here rather than in a pass because two passes now ask the same questions
-- and have to get the same answers.
--
-- __A declaration promises as much as a definition.__  The symbols whose
-- promises decide anything are mostly ones the module only declares, @setjmp@
-- above all; a declaration is retained syntax with no core form, so the
-- signature LLVM printed it in is the only place its attributes are written
-- down.  'promisesOf' therefore reads every header the module has, from all
-- three places one can be: a @declare@, a definition the lowering took, and a
-- definition it did not and which is carried through whole.
module Olivine.Core.Promises
  ( Promises
  , promisesOf
  , promisedNames
  , resolve
  , attributesOf
  , returnsTwiceIn
  , keepsArgument
  , freedBy
  , allocatedBy
  , interposable
  , copied
  ) where

import Data.Foldable (toList)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Maybe (listToMaybe)
import Numeric.Natural (Natural)

import Olivine.Core.Instruction
import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Attribute
  ( AttributeItem (..)
  , FunctionAttribute (..)
  , ParamAttribute (..)
  )
import Olivine.Syntax.Function (Definition (..), Parameter (..), Signature (..))
import Olivine.Syntax.Instruction (Argument (..), Call (..))
import Olivine.Syntax.Linkage (Linkage (..))
import Olivine.Syntax.Name (Name (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

-- | The attribute groups the module defines, and what each symbol it names
-- promises with those followed through.
data Promises = Promises
  { -- | @attributes #0 = { ... }@, so that a slot referring to a group can be
    -- asked what it actually says.
    promiseGroups :: Map Natural [FunctionAttribute]
  , -- | What each symbol promises about itself, groups resolved.  Names as
    -- text, since @\@f@ and @\@"f"@ are one symbol and the quoting is a fact
    -- about the writing rather than about what is called.
    promiseSymbols :: Map Text [FunctionAttribute]
  , -- | The signature each symbol is declared with, for the promises that are
    -- made about a /parameter/ rather than about the function.
    --
    -- Kept whole rather than reduced to the parameter attributes, because the
    -- two questions asked of it so far want different parts and a second
    -- reduction would be a second thing to keep right.  Groups are not
    -- resolved into it and there is nothing to resolve: @attributes #0@ holds
    -- function attributes, and a parameter's are always written out beside it.
    promiseSignatures :: Map Text Signature
  }

promisesOf :: Program -> Promises
promisesOf program =
  Promises
    { promiseGroups = groups
    , promiseSymbols =
        Map.fromList
          [ (nameText (signatureName s), resolveWith groups (signatureAttributes s))
          | s <- signatures
          ]
    , promiseSignatures =
        Map.fromList [(nameText (signatureName s), s) | s <- signatures]
    }
  where
    groups =
      Map.fromList
        [ (n, toList attributes)
        | ERetained (Syntax.EAttributeGroup n attributes) <- programEntries program
        ]

    -- The last is not a corner case: a definition holding one line nothing
    -- models is retained entire, and it is still a symbol somebody is about to
    -- decide something about.
    signatures =
      concat
        [ case e of
            EFunction f -> [functionSignature f]
            ERetained (Syntax.EDeclare s) -> [s]
            ERetained (Syntax.EDefine d) -> [definitionSignature d]
            ERetained _ -> []
        | e <- programEntries program
        ]

-- | What every symbol the module names promises, groups resolved.
--
-- The whole map rather than a lookup, because the one caller wanting it —
-- "Olivine.Core.Effects" — starts by reading the promises of everything and
-- then settles them against the bodies, and asking name by name would mean
-- knowing the names first.
promisedNames :: Promises -> [(Text, [FunctionAttribute])]
promisedNames = Map.toList . promiseSymbols

-- | An attribute slot with its group references followed through.
--
-- A function and a call site have the same slot, so this reads either.
resolve :: Promises -> [AttributeItem] -> [FunctionAttribute]
resolve = resolveWith . promiseGroups

-- | The same, given the groups alone, which is what 'promisesOf' has while it
-- is still building the rest.
resolveWith :: Map Natural [FunctionAttribute] -> [AttributeItem] -> [FunctionAttribute]
resolveWith groups = concatMap item
  where
    item (AIGroup n) = Map.findWithDefault [] n groups
    item (AIAttribute a) = [a]

-- | What a function's attributes actually say, groups resolved.
attributesOf :: Promises -> Signature -> [FunctionAttribute]
attributesOf promises = resolve promises . signatureAttributes

-- | Whether a body holds a call that may come back more than once — @setjmp@
-- and its relatives.
--
-- What both callers do with the answer is refuse to move the frame the call
-- was written in.  A @longjmp@ arrives back in that frame with the locals as
-- it left them, and the licence every language gives for that is scoped to the
-- function holding the call: copying the body into a caller
-- ("Olivine.Core.Pass.Inline") hands the second return a frame that was never
-- covered, and reusing the frame for the next turn of a loop
-- ("Olivine.Core.Pass.TailRecursion") hands it one that has been written over.
-- Both were confirmed against @opt@ — @-passes=inline@ and
-- @-passes=tailcallelim@ each refuse a function they would otherwise take.
--
-- Every call is read, the ones standing where a branch stands included.  An
-- @invoke@ is a call, and asking of every kind here means the rule does not
-- quietly stop holding on the day a pass starts accepting one.
returnsTwiceIn :: Promises -> Function -> Bool
returnsTwiceIn promises f = any twice (callsIn f)
  where
    -- Asked of the call site and of the callee alike, because either may carry
    -- the attribute and LLVM reads both: clang writes it in a group on the call
    -- (@call i32 \@_setjmp(ptr \@env) #3@, with @#3 = { nounwind returns_twice }@)
    -- and also on the @declare@, and hand-written IR routinely has only the
    -- declaration.  Confirmed by giving @opt@ each spelling separately; each on
    -- its own is enough to stop it.
    --
    -- Only a direct call can be asked the second question.  A call through a
    -- pointer is not refused for it — LLVM does not refuse one either — since
    -- nothing about the pointer says what it points at, and the front end that
    -- knows puts the attribute on the site.
    twice call =
      FAReturnsTwice `elem` resolve promises (callAttributes call)
        || case typedValue (callCallee call) of
          VGlobal name ->
            FAReturnsTwice
              `elem` Map.findWithDefault [] (nameText name) (promiseSymbols promises)
          _ -> False

-- | Whether a call may keep the pointer it is handed at an argument position.
--
-- The cautious answer is that it does, so a position nothing says anything
-- about — an indirect call, a callee the module never declares, an argument
-- past the end of a variadic signature — is one that keeps.
--
-- The attributes are on the /declaration/ rather than on the call: clang writes
-- @declare void \@free(ptr allocptr noundef captures(none))@ and then calls it
-- with @noundef nonnull@ and nothing else, so there is no reading this off the
-- call site alone.  The site is read as well, because either may carry it and
-- LLVM reads both — the rule 'returnsTwiceIn' already follows for an attribute
-- of the whole call, and a parameter's is no different.
--
-- __Keeping is not touching.__  A callee promising @captures(none)@ may do
-- what it likes to the storage while it runs; what it promises is not to have
-- a pointer to it afterwards.  So this says an address did not get out of
-- sight, and what the call does to the storage during the call is a separate
-- question asked separately — 'Olivine.Core.Effects.mayReach'.
--
-- Only @captures(none)@ and the @nocapture@ it replaced count.  The other
-- spellings — @captures(address)@, @captures(address, provenance)@ — say the
-- callee keeps some of what it was handed, and some is enough.
keepsArgument :: Promises -> Call (TypedValue Local) -> Int -> Bool
keepsArgument promises call n = not (any released (atSite <> atCallee))
  where
    atSite = take 1 (drop n (map argumentAttributes (callArguments call)))

    atCallee = case typedValue (callCallee call) of
      VGlobal name
        | Just signature <- Map.lookup (nameText name) (promiseSignatures promises) ->
            take 1 (drop n (map parameterAttributes (signatureParameters signature)))
      _ -> []

    released = any letGo

    letGo PANoCapture = True
    letGo (PACaptures raw) = T.strip raw == "none"
    letGo _ = False

-- | The argument a call gives back to the allocator, where it gives one back.
--
-- @allockind(\"free\")@ on the callee says the call deallocates, and
-- @allocptr@ on a parameter says which argument is the pointer it deallocates.
-- Both are needed and neither does on its own: @realloc@ carries @allocptr@ too
-- and is no deallocation of the old storage — it is a copy of it — so reading
-- the parameter attribute alone would have this call a buffer dead at the
-- moment its contents are about to be moved.
--
-- Asked of the callee only, unlike 'returnsTwiceIn'.  @allocptr@ is a
-- parameter attribute, and what a call site writes in that position is the
-- attributes of the argument rather than of the parameter; the one place the
-- two are certain to agree is the signature.  A call through a pointer is
-- therefore no deallocation here, which is the cautious answer.
freedBy :: Promises -> Call (TypedValue Local) -> Maybe (TypedValue Local)
freedBy promises call = do
  signature <- calleeOf promises call
  True <- Just ("free" `elem` allocationKinds promises signature)
  (argument, _) <-
    listToMaybe
      [ pair
      | pair@(_, parameter) <- zip (callArguments call) (signatureParameters signature)
      , PAAllocPtr `elem` parameterAttributes parameter
      ]
  pure (argumentValue argument)

-- | Whether a call hands back storage it has just made.
--
-- @allockind(\"alloc\")@ says so, and is the same attribute 'freedBy' reads for
-- the other direction; the kinds it is not are what tell the two apart, since
-- @realloc@ is written @allockind(\"realloc\")@ and is neither.  The rest of
-- the list says what the storage is like — @uninitialized@, @zeroed@,
-- @aligned@ — and none of that decides anything here.
--
-- Asked of the callee only, for the reason 'freedBy' is: a call site writes
-- the attributes of its arguments, and the promise is the function's.
allocatedBy :: Promises -> Call (TypedValue Local) -> Bool
allocatedBy promises call = case calleeOf promises call of
  Just signature -> "alloc" `elem` allocationKinds promises signature
  Nothing -> False

-- | The signature of the symbol a call names, where it names one.
calleeOf :: Promises -> Call (TypedValue Local) -> Maybe Signature
calleeOf promises call = do
  VGlobal name <- Just (typedValue (callCallee call))
  Map.lookup (nameText name) (promiseSignatures promises)

-- | What an @allockind@ attribute lists, as the words it is written from.
--
-- The kind is a comma-separated list, @allockind(\"alloc,uninitialized\")@
-- being one attribute and not two, so it is split before anything is looked
-- for rather than compared whole.
allocationKinds :: Promises -> Signature -> [Text]
allocationKinds promises signature =
  [ T.strip kind
  | FAAllocKind kinds <- resolve promises (signatureAttributes signature)
  , kind <- T.splitOn "," kinds
  ]

-- | Every call a body makes, the ones standing where a branch stands
-- included.
callsIn :: Function -> [Call (TypedValue Local)]
callsIn f =
  [ call
  | b <- functionBlocks f
  , call <-
      [c | i <- blockInstructions b, OCall c <- [instructionOperation i]]
        <> [c | Just c <- [callIn (terminatorTransfer (blockTerminator b))]]
  ]

-- | Whether the definition here might not be the one that runs.
--
-- A @weak@ or @linkonce@ definition is one candidate among several and the
-- linker picks; a pass that copies its body, or that replaces a call to it
-- with a branch into the body, has decided which candidate the program calls.
-- The @_odr@ forms are exempt because that is what the suffix promises — every
-- candidate has the same body, so any of them is the right one.
--
-- Symbol interposition at load time is deliberately not treated as making a
-- definition uncertain. It would make almost every external function
-- untouchable in a shared library, and it is the behaviour clang itself
-- assumes: @-fno-semantic-interposition@ is its default.
interposable :: Maybe Linkage -> Bool
interposable linkage = case linkage of
  Just LinkWeak -> True
  Just LinkLinkOnce -> True
  Just LinkCommon -> True
  Just LinkExternWeak -> True
  _ -> False

-- | Whether an attribute says the argument is passed by making a copy of what
-- it points at.
--
-- These are the ones a pass cannot honour by binding a local to the value:
-- @byval@ means the callee gets its own copy of the pointee and may write to
-- it freely, so a call replaced without materializing that copy would let the
-- body write the caller's object. The others are the same promise made by
-- other ABI machinery.
copied :: ParamAttribute -> Bool
copied attribute = case attribute of
  PAByVal _ -> True
  PAByRef _ -> True
  PAPreallocated _ -> True
  PAInAlloca _ -> True
  _ -> False
