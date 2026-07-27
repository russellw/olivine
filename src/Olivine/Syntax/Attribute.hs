-- | Attributes on a parameter or on a return value.
--
-- The two draw on the same vocabulary, so they share one type; which of them
-- are legal in which position is a matter for a verifier, not for reading
-- back what was written.
--
-- A few attributes take an argument that is a small language of its own —
-- @captures(address, provenance)@, @range(i32 0, 10)@, @nofpclass(nan inf)@,
-- @initializes((0, 4))@.  Those interiors are carried as the text between the
-- parentheses.  They are rare, none of them changes what the surrounding
-- signature means, and decoding them would be a grammar apiece for no gain
-- until a pass actually asks.
module Olivine.Syntax.Attribute
  ( ParamAttribute (..)
  , FunctionAttribute (..)
  , AttributeContext (..)
  , AttributeItem (..)
  ) where

import Data.Text (Text)
import Numeric.Natural (Natural)

import Olivine.Syntax.Type (Type)

data ParamAttribute
  = -- Flags.
    PAZeroExt
  | PASignExt
  | PANoExt
  | PAInReg
  | PANoAlias
  | PANoCapture
  | PANoFree
  | PANest
  | PAReturned
  | PANonNull
  | PANoUndef
  | PASwiftSelf
  | PASwiftAsync
  | PASwiftError
  | PAImmArg
  | PAAllocAlign
  | PAAllocPtr
  | PAReadNone
  | PAReadOnly
  | PAWriteOnly
  | PAWritable
  | PADeadOnUnwind
  | PADeadOnReturn
  | -- Attributes taking a number.
    PAAlign Natural
  | PAAlignStack Natural
  | PADereferenceable Natural
  | PADereferenceableOrNull Natural
  | -- Attributes taking a type.
    PAByVal Type
  | PAByRef Type
  | PAPreallocated Type
  | PAInAlloca Type
  | PASRet Type
  | PAElementType Type
  | -- Attributes whose argument is left as written.
    PACaptures Text
  | PARange Text
  | PANoFPClass Text
  | PAInitializes Text
  deriving (Eq, Show)

-- | Where a function attribute is written.
--
-- It matters for exactly one attribute: LLVM spells stack alignment
-- @alignstack(16)@ on a function but @alignstack=16@ inside a group, and
-- rejects each spelling in the other's position.  Everything else reads and
-- writes the same either way.
data AttributeContext
  = InGroup
  | OnFunction
  deriving (Eq, Show)

-- | Attributes on a function, whether written into an attribute group or
-- spelled out on the function itself.
--
-- The string form is open by design: @"target-features"="+cmov,+sse2"@ and
-- its neighbours are how the front end passes target configuration through,
-- and no enumeration could close that set.  So it is the one attribute kind
-- carried as a name and an optional value rather than a constructor.
data FunctionAttribute
  = -- Flags.
    FAAlwaysInline
  | FABuiltin
  | FACold
  | FAConvergent
  | FADisableSanitizerInstrumentation
  | FAFnRetThunkExtern
  | FAHot
  | FAInlineHint
  | FAJumpTable
  | FAMinSize
  | FAMustProgress
  | FANaked
  | FANoBuiltin
  | FANoCallback
  | FANoCfCheck
  | FANoDuplicate
  | FANoFree
  | FANoImplicitFloat
  | FANoInline
  | FANoMerge
  | FANonLazyBind
  | FANoProfile
  | FANoRecurse
  | FANoRedZone
  | FANoReturn
  | FANoSanitizeBounds
  | FANoSanitizeCoverage
  | FANoSync
  | FANoUnwind
  | FANullPointerIsValid
  | FAOptDebug
  | FAOptForFuzzing
  | FAOptNone
  | FAOptSize
  | FAPreSplitCoroutine
  | FAReturnsTwice
  | FASafeStack
  | FASanitizeAddress
  | FASanitizeHwAddress
  | FASanitizeMemTag
  | FASanitizeMemory
  | FASanitizeRealtime
  | FASanitizeThread
  | FASanitizeType
  | FAShadowCallStack
  | FASpeculatable
  | FASpeculativeLoadHardening
  | FAStrictFP
  | FASsp
  | FASspReq
  | FASspStrong
  | FAWillReturn
  | -- Attributes taking arguments.
    FAAlignStack Natural
  | FAAllocKind Text
  | FAAllocSize Natural (Maybe Natural)
  | FAVScaleRange Natural (Maybe Natural)
  | -- | @uwtable@, or @uwtable(sync)@ and the like.
    FAUwTable (Maybe Text)
  | -- | @memory(argmem: read)@ and its relatives, carried as the text
    -- between the parentheses for the same reason as 'PACaptures'.
    FAMemory Text
  | -- | @"key"@ or @"key"="value"@.
    FAString Text (Maybe Text)
  deriving (Eq, Show)

-- | One item of the attribute slot a function signature or a call site
-- carries: either a reference to a group, or an attribute written out.
--
-- They share one list because LLVM's grammar puts them in one slot and
-- either may come first.
data AttributeItem
  = -- | A reference to an attribute group, as in the @#1@ of
    -- @declare void \@free(ptr) #1@.
    AIGroup Natural
  | -- | An attribute written out rather than referenced.
    AIAttribute FunctionAttribute
  deriving (Eq, Show)
