-- | Operands: literals, constant expressions, and references to globals and
-- locals, all in one type.
--
-- LLVM makes constants a subtype of values, so a @switch@ case being a
-- constant costs it nothing to say.  Haskell has no subtyping, and encoding
-- the relation as two parallel types costs a conversion at every boundary and
-- a second copy of every function over operands — a recurring price paid for
-- a single check.  So the distinction lives in 'isConstant' instead, for a
-- verifier to apply where it matters.
--
-- This layer reads back what was written and does not judge it: it already
-- admits type mismatches, branches to blocks that do not exist, and function
-- types LLVM would reject, so refusing a local in a global initializer would
-- have closed one gap in a wall that is mostly gaps.
module Olivine.Syntax.Value
  ( Value (..)
  , TypedValue (..)
  , InlineAsm (..)
  , CastOp (..)
  , GepFlag (..)
  , isConstant
  , globalsIn
  , blockAddressesIn
  , renameBlockAddresses
  , holdsAsm
  ) where

import Data.Text (Text)

import Olivine.Syntax.Name (Name)
import Olivine.Syntax.Type (Packedness, Type)

-- | What a local is called is a parameter, for the reason a block's
-- destination is: in the syntax it is a 'Name', because that is what was
-- written, and in the core it is a number the optimizer issued.  A global is
-- not a parameter and never will be — a global's name is the program's
-- interface to everything outside it, and is the one thing here that must
-- survive exactly as written.
data Value local
  = VInteger Integer
  | -- | @true@ and @false@.
    VBoolean Bool
  | -- | A floating point literal, kept as the text that was written.
    --
    -- LLVM normalizes these when it prints — @1.0@ comes back as
    -- @1.000000e+00@ — so holding the source spelling keeps the round trip
    -- exact without reimplementing that formatting, and without ever
    -- rounding a literal by decoding and re-encoding it.
    VFloat Text
  | VNull
  | VNone
  | VUndef
  | VPoison
  | VZeroInitializer
  | -- | @c"..."@, with escapes left undecoded.
    VString Text
  | -- | @[i32 1, i32 2]@
    VArray [TypedValue local]
  | -- | @\<i32 1, i32 2\>@
    VVector [TypedValue local]
  | -- | @splat (i32 4)@, a vector every element of which is the same.
    --
    -- Held as written rather than expanded into a 'VVector' of copies, for the
    -- reason a float literal is held as its text: this is LLVM's own canonical
    -- spelling, so keeping it is what makes the round trip exact.  It
    -- normalizes @\<i32 4, i32 4\>@ to this and not the other way about, so
    -- expanding on the way in would mean printing a form LLVM does not write
    -- and comparing output with input would stop meaning anything.
    --
    -- How many elements it has is not here, because it is not in the syntax
    -- either: the width comes from the type the operand is written with, so
    -- @splat (i32 4)@ is as many fours as its context says.
    VSplat (TypedValue local)
  | -- | @{ i32 1, ptr \@g }@ and its packed form.
    VStruct Packedness [TypedValue local]
  | -- | A reference to a global, as in @\@counter@.
    VGlobal Name
  | -- | @blockaddress(\@f, %b)@: the address of a block, which a computed
    -- @goto@ jumps to and an @indirectbr@ arrives at.
    --
    -- Two names and neither of them the type parameter.  The first is a
    -- global's, since it is a function the rest of the world can name; the
    -- second is a block's, which is a name in that function and not a local
    -- — a block is not a value and cannot be assigned to, so nothing that
    -- rewrites the operands of an instruction may reach it.
    --
    -- __The block named is a block of another function than the one this is
    -- written in__, as often as not: the table a threaded interpreter jumps
    -- through is a global, and every entry in it names a block of the
    -- function that walks it.  That is what makes this the one operand whose
    -- meaning is not local to where it stands, and why the core has to hold
    -- the block it names by identity rather than by spelling — see
    -- 'Olivine.Core.Program.functionAddressed'.
    VBlockAddress Name Name
  | -- | @%x@, naming a local.  In the core representation these will have
    -- addresses and be reassignable; here it is simply what was written.
    VLocal local
  | -- | @asm sideeffect "rdtsc", "={ax},={dx}"@, a run of machine
    -- instructions written in the source where a function would otherwise
    -- stand.
    --
    -- A value, because that is what LLVM makes it: it appears in the callee
    -- position of a call and nowhere else, which is a rule about where it may
    -- be written rather than a reason to hold it apart from the operand it
    -- stands in.  Holding it here is what lets a call keep one callee slot,
    -- so everything asking what a call calls asks it in one place, and what
    -- an @invoke@ or a @callbr@ calls needs no second answer — the last of
    -- those being a call that has to hold one.  That it appears nowhere else
    -- is 'Olivine.Syntax.Verify.verifyModule's to say.
    VAsm InlineAsm
  | -- | @ptrtoint (ptr \@g to i64)@ and the other surviving casts.
    VCast CastOp (TypedValue local) Type
  | -- | @getelementptr inbounds (i8, ptr \@g, i64 8)@.  The 'Type' is the
    -- source element type; the operands are the pointer and the indices.
    VGetElementPtr [GepFlag] Type [TypedValue local]
  deriving (Eq, Show)

-- | The template a piece of inline assembly is written as, the constraints
-- saying how its operands and results reach it, and the four words LLVM lets
-- stand between the keyword and the template.
--
-- The template and the constraints are held as the text that was written,
-- escapes undecoded, for the reason a float literal is: this layer's business
-- is to give back what it read, and neither string means anything to the
-- optimizer — what the machine instructions do is exactly what it does not
-- know.
--
-- Four fields rather than a list of flags because LLVM's parser fixes their
-- order and refuses any other: @sideeffect alignstack inteldialect unwind@,
-- each optional, none repeatable.  A list would be able to say things the
-- grammar cannot, and the printer would have to sort it back.
data InlineAsm = InlineAsm
  { -- | That it does something the constraints do not describe, and so may
    -- not be removed when nothing reads its result.
    asmSideEffect :: Bool
  , asmAlignStack :: Bool
  , asmIntelDialect :: Bool
  , -- | That it may throw, which is what an @invoke@ of one needs.
    asmUnwind :: Bool
  , asmTemplate :: Text
  , asmConstraints :: Text
  }
  deriving (Eq, Show)

-- | An operand written together with its type, which is how operands appear
-- everywhere except as a global's initializer, where the global already names
-- the type.
data TypedValue local = TypedValue
  { typedValueType :: Type
  , typedValue :: Value local
  }
  deriving (Eq, Show)

-- | Visiting the locals of an operand, which is how one gets renamed.
--
-- Standalone because the two types are mutually recursive — an aggregate
-- holds operands — and each instance needs the other in scope.  A local
-- inside an aggregate is reached like any other, which matters: a name is a
-- name however deeply it is written.
deriving instance Functor Value

deriving instance Foldable Value

deriving instance Traversable Value

deriving instance Functor TypedValue

deriving instance Foldable TypedValue

deriving instance Traversable TypedValue

-- | The conversion opcodes, shared by the @\<op\> \<ty\> \<v\> to \<ty\>@
-- instruction and by the constant expression of the same shape.
--
-- Not every one of them survives as a constant expression — LLVM removed
-- @zext@ and others from that position — but that is a fact about where an
-- operation may appear, which the parser follows, rather than a reason for
-- two enumerations that would have to be converted between.
data CastOp
  = CastTrunc
  | CastZExt
  | CastSExt
  | CastFPTrunc
  | CastFPExt
  | CastFPToUI
  | CastFPToSI
  | CastUIToFP
  | CastSIToFP
  | CastPtrToInt
  | CastIntToPtr
  | CastBitcast
  | CastAddrSpaceCast
  deriving (Eq, Show)

data GepFlag
  = GepInbounds
  | GepNusw
  | GepNuw
  deriving (Eq, Show)

-- | Whether an operand is a compile-time constant.
--
-- This is what a global initializer and a @switch@ case require, and what the
-- type deliberately no longer enforces.  Aggregates and constant expressions
-- are constant exactly when everything inside them is.
isConstant :: Value local -> Bool
isConstant (VLocal _) = False
-- Not a constant in LLVM's hierarchy either, and the answer matters: this is
-- what keeps inline assembly out of an initializer and out of a @switch@
-- case, and what stops the folder treating a callee as a value it knows.
isConstant (VAsm _) = False
isConstant (VArray elements) = all (isConstant . typedValue) elements
isConstant (VVector elements) = all (isConstant . typedValue) elements
isConstant (VSplat element) = isConstant (typedValue element)
isConstant (VStruct _ fields) = all (isConstant . typedValue) fields
isConstant (VCast _ operand _) = isConstant (typedValue operand)
isConstant (VGetElementPtr _ _ operands) =
  all (isConstant . typedValue) operands
isConstant _ = True

-- | Every global a value names, however deeply.
--
-- This recurses where reading locals off an operand does not need to.  A
-- local is a name a function gave something and can only appear as an operand
-- in its own right; a global is a symbol, and a symbol can sit inside an
-- initializer's aggregate or inside a constant expression computing an
-- address from it.  A pass asking which functions the program can still reach
-- has to look in both places, since @[1 x ptr] [ptr \@f]@ is how a call
-- through a table names what it calls.
--
-- Names repeat as often as they are written: whether that matters is the
-- caller's to decide, and a caller counting references would be wrong to be
-- handed a set.
globalsIn :: Value local -> [Name]
globalsIn value = case value of
  VGlobal name -> [name]
  -- The function is named here as surely as a call names its callee: a table
  -- of block addresses is the only thing keeping the function that jumps
  -- through it reachable, and a pass removing symbols nothing names would
  -- otherwise take it away.  The block's name is not a symbol and is not one
  -- of these.
  VBlockAddress name _ -> [name]
  VArray elements -> concatMap inside elements
  VVector elements -> concatMap inside elements
  VSplat element -> inside element
  VStruct _ fields -> concatMap inside fields
  VCast _ operand _ -> inside operand
  VGetElementPtr _ _ operands -> concatMap inside operands
  _ -> []
  where
    inside = globalsIn . typedValue

-- | Every block a value takes the address of: the function, and the block in
-- it.
--
-- Recursive for the reason 'globalsIn' is, and the reason is the same one
-- again: the table a computed @goto@ jumps through is
-- @[3 x ptr] [ptr blockaddress(\@f, %a), ...]@, so the addresses are inside an
-- aggregate rather than standing as operands anywhere.
--
-- What asks is the lowering, which has to know which blocks of which
-- functions are spoken for before it can settle any of them — see
-- 'Olivine.Core.Program.functionAddressed'.
blockAddressesIn :: Value local -> [(Name, Name)]
blockAddressesIn value = case value of
  VBlockAddress function block -> [(function, block)]
  VArray elements -> concatMap inside elements
  VVector elements -> concatMap inside elements
  VSplat element -> inside element
  VStruct _ fields -> concatMap inside fields
  VCast _ operand _ -> inside operand
  VGetElementPtr _ _ operands -> concatMap inside operands
  _ -> []
  where
    inside = blockAddressesIn . typedValue

-- | Say what each block a value takes the address of is called now.
--
-- The counterpart of 'blockAddressesIn' and it goes to the same places.  What
-- wants it is the way out: the core numbers a function's blocks afresh, so
-- the name a @blockaddress@ was written with is not the name the block will
-- be printed under, and the one place that knows both is
-- 'Olivine.Core.Raise.raise'.
renameBlockAddresses :: (Name -> Name -> Name) -> Value local -> Value local
renameBlockAddresses rename value = case value of
  VBlockAddress function block -> VBlockAddress function (rename function block)
  VArray elements -> VArray (map inside elements)
  VVector elements -> VVector (map inside elements)
  VSplat element -> VSplat (inside element)
  VStruct packedness fields -> VStruct packedness (map inside fields)
  VCast op operand target -> VCast op (inside operand) target
  VGetElementPtr flags element operands ->
    VGetElementPtr flags element (map inside operands)
  _ -> value
  where
    inside (TypedValue t v) = TypedValue t (renameBlockAddresses rename v)

-- | Whether a value is inline assembly, or has some written inside it.
--
-- Recursive for the reason 'globalsIn' is, and asked for the opposite reason:
-- a verifier wants to know that no operand but a callee holds one.  LLVM's own
-- parser will not read an @asm@ anywhere else at all, so nothing this reads
-- back can have one nested; what the recursion covers is a pass putting one
-- where it does not belong, which is exactly what a verifier is for.
holdsAsm :: Value local -> Bool
holdsAsm value = case value of
  VAsm _ -> True
  VArray elements -> any inside elements
  VVector elements -> any inside elements
  VSplat element -> inside element
  VStruct _ fields -> any inside fields
  VCast _ operand _ -> inside operand
  VGetElementPtr _ _ operands -> any inside operands
  _ -> False
  where
    inside = holdsAsm . typedValue
