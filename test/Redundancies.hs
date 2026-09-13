-- | The redundancy pass — expressions and loads both — and the aliasing it
-- stands on for the loads.
--
-- Two things are checked separately: which computations and loads are answered
-- from earlier ones, and which must not be.  The second is where the bugs are —
-- sharing a call, answering a load across something that wrote the address, or
-- reusing an expression whose operand was reassigned in between gives a module
-- LLVM accepts and a program that computes something else.
module Redundancies (redundancyTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Core.Alias
import Olivine.Core.Instruction
import Olivine.Core.Layout (layoutOf)
import Olivine.Core.Lower (lower)
import Olivine.Core.Effects (Behaviour (..), anything, nothing)
import Olivine.Core.Pass.Redundancies (eliminateRedundancies, shareable)
import Olivine.Core.Pass.Promote (promoteMemory)
import Olivine.Core.Program
import Olivine.Syntax.Instruction hiding (Operation (..))
import Olivine.Syntax.Name
import Olivine.Syntax.Type
import Olivine.Syntax.Value

redundancyTests :: TestTree
redundancyTests =
  testGroup
    "redundancies"
    [ testGroup
        "what is shared"
        [ -- Locals are numbered as they are defined: the two parameters, then
          -- %x %y %z as 2 to 4.
          testCase "the same sum twice in one block" $ do
            copies <- copiesIn twice
            assertEqual "the second reads the first" [(Local 3, Local 2)] copies
        , -- The point of walking the blocks rather than each block alone: the
          -- entry block is the only way to reach %again, so what it worked out
          -- is worked out wherever control is in there.
          testCase "across a branch, from the block above it" $ do
            copies <- copiesIn dominating
            assertEqual "the second reads the first" [(Local 4, Local 3)] copies
        , -- Two pointer steps written identically arrive here reading two
          -- different locals, because the lowering splits a getelementptr and
          -- what LLVM wrote once becomes a chain.  Resolving the operands
          -- through the copies is what makes them one expression again.
          testCase "a pointer step whose operands are copies" $ do
            copies <- copiesIn stepped
            assertBool
              ("expected a shared step in " <> show copies)
              (not (null copies))
        , -- Both computations in the body are the one the block before the
          -- loop already made, so neither is left to make.  The locals here
          -- are the three parameters, then %e %i %c %x %y %j as 3 to 8.
          testCase "twice in a loop body" $ do
            copies <- copiesIn looping
            assertEqual
              "both read what the block before the loop worked out"
              [(Local 6, Local 3), (Local 7, Local 3)]
              copies
        ]
    , testGroup
        "what iterating buys"
        [ -- The whole of what the rounds are for.  The block the loop begins
          -- at has a predecessor below it, so one walk over the blocks has
          -- nothing to say about what arrives along that edge and can only
          -- assume the worst; the rounds start by assuming the best instead
          -- and take away what some path does not carry, and no path into the
          -- loop fails to carry this.
          testCase "an expression carried into a loop is available" $ do
            copies <- copiesIn carried
            assertEqual "%x reads what came in" [(Local 6, Local 3)] copies
        , -- Two edges deep, which takes a round to reach the outer loop and
          -- another to reach the inner one.  The locals are the three
          -- parameters, then %e %i %c %j %x %m %d %k as 3 to 10.
          testCase "carried into a loop inside a loop" $ do
            copies <- copiesIn nested
            assertEqual "%x reads what came in" [(Local 7, Local 3)] copies
        ]
    , testGroup
        "what is not"
        [ -- @add nsw@ is poison where it overflows and @add@ is a number, so
          -- the two are not one expression.  Sharing the plain result for the
          -- flagged instruction would be sound and is not done; sharing the
          -- flagged result for the plain one would spread poison.
          testCase "the same sum with different flags" $ do
            copies <- copiesIn flagged
            assertEqual "nothing is shared" [] copies
        , -- The reason availability is a question at all.  Promotion turns
          -- the slot into a local assigned twice, and the second addition
          -- reads what the second assignment left there.
          testCase "an operand reassigned in between" $ do
            copies <- promotedCopiesIn reassigned
            assertEqual "nothing is shared" [] copies
        , -- The other half of the same rule: %a was a copy of the slot, and
          -- the store means it is no longer, so the additions that read %a and
          -- the slot are not the same expression however alike they look.
          testCase "an operand that has stopped being a copy" $ do
            copies <- promotedCopiesIn stale
            assertEqual "nothing is shared" [] copies
        , -- Available means computed on every path that arrives, and one arm
          -- of a branch is not every path.
          testCase "computed on only one path to here" $ do
            copies <- copiesIn oneArm
            assertEqual "nothing is shared" [] copies
        , -- Both arms compute it, but into different locals, so there is no
          -- one local a block below can read it from.  The core could hold
          -- the answer — two arms assigning to one local is exactly what
          -- reconstruction turns into a phi — which makes this a refinement
          -- this pass does not make rather than something it cannot say.
          testCase "computed on both paths into different locals" $ do
            copies <- copiesIn bothArms
            assertEqual "nothing is shared" [] copies
        , testCase "two calls to the same function" $ do
            copies <- copiesIn calling
            assertEqual "nothing is shared" [] copies
        , testCase "two allocations of the same size" $ do
            copies <- copiesIn allocating
            assertEqual "nothing is shared" [] copies
        ]
    , testGroup
        "what memory answers"
        [ -- Locals are numbered as they are defined: the parameter, then %a %b
          -- %s as 1 to 3.
          testCase "a second load of one address" $ do
            answered <- assignmentsIn twiceLoaded
            assertEqual
              "the second load reads what the first left"
              [(Local 2, VLocal (Local 1))]
              answered
        , -- The other half of the same fact.  What memory holds does not
          -- remember whether a load or a store put it there, so a store answers
          -- a load below it for the same reason one load answers another.
          testCase "a load of what was just stored" $ do
            answered <- assignmentsIn storedThenLoaded
            assertEqual
              "the load reads the stored value"
              [(Local 2, VLocal (Local 1))]
              answered
        , -- And it need not be a local: a store of a constant leaves the
          -- constant there.
          testCase "a load of a constant that was stored" $ do
            answered <- assignmentsIn loading
            assertEqual
              "the second load is the stored constant"
              [(Local 2, VInteger 99)]
              answered
        , -- Two allocations are two objects, so a write to one is not a write to
          -- the other however alike the accesses look.  The locals are the
          -- parameter, then %x %y %a %b %s as 1 to 5.
          testCase "across a store to a different allocation" $ do
            answered <- assignmentsIn otherSlot
            assertEqual
              "the second load reads the first"
              [(Local 4, VLocal (Local 3))]
              answered
        , -- Two fields of one struct the caller owns, which is the case the
          -- data layout answers: the store lands in the four bytes the other
          -- field is not in.  The locals are the parameter, then %a %b %c %d %s
          -- as 1 to 5.
          testCase "across a store to another field of one struct" $ do
            answered <- assignmentsIn otherField
            assertEqual
              "the second load reads the first"
              [(Local 4, VLocal (Local 2))]
              answered
        , -- And the same module with nothing said about the target, where
          -- which bytes a field is at is not something anything knows.
          testCase "and not where the module states no layout" $ do
            answered <- assignmentsIn (T.unlines (drop 1 (T.lines otherField)))
            assertEqual "the second load stays a load" [] answered
        , -- The precision the whole thing turns on.  A callee reaches what it
          -- was handed and what has a symbol, and this slot is neither, so a
          -- call in between writes nothing that can be read here.  The locals
          -- are %x %a %b %s as 0 to 3.
          testCase "across a call, of a slot whose address never left" $ do
            answered <- assignmentsIn pastACall
            assertEqual
              "the second load reads the first"
              [(Local 2, VLocal (Local 1))]
              answered
        , -- A symbol names its storage as plainly as an allocation does, so a
          -- load through one is answered the same way.  The locals here are
          -- %a %b %s as 0 to 2, there being no parameters.
          testCase "a second load of a symbol" $ do
            answered <- assignmentsIn symbolTwice
            assertEqual
              "the second load reads the first"
              [(Local 1, VLocal (Local 0))]
              answered
        , -- What iterating buys for memory, as 'carried' is what it buys for
          -- arithmetic.  The block the loop begins at is reached from below as
          -- well as above, and nothing round the loop writes memory.  The
          -- locals are the two parameters, then %a %i %t %c %b %u %j as 2 to 8.
          testCase "a load carried into a loop" $ do
            answered <- assignmentsIn carriedLoad
            assertEqual
              "the body reads what the block above the loop read"
              [(Local 6, VLocal (Local 2))]
              answered
        , -- Both arms wrote the address, and both wrote the same thing, which is
          -- what makes it something a block below them can be told.  The locals
          -- are the three parameters, then %a as 3.
          testCase "stored to the same value on both paths here" $ do
            answered <- assignmentsIn storedAlike
            assertEqual
              "the load reads what both arms wrote"
              [(Local 3, VLocal (Local 2))]
              answered
        ]
    , testGroup
        "what memory does not"
        [ -- The address was handed to the callee, so the callee could write it.
          testCase "across a call that was given the address" $ do
            answered <- assignmentsIn escapedSlot
            assertEqual "nothing is answered" [] answered
        , -- Except where the callee is a lifetime marker, which is handed the
          -- address and does nothing with it.  A slot bracketed this way is a
          -- slot whose address never left, so a stranger's call in between
          -- writes nothing anyone here can see.  The locals are %x %a %b %s as
          -- 0 to 3, the markers assigning to nothing.
          testCase "though not across a marker that was given it" $ do
            answered <- assignmentsIn markedSlot
            assertEqual
              "the second load reads the first"
              [(Local 2, VLocal (Local 1))]
              answered
        , -- An atomic is where a write by another thread becomes visible, so
          -- what a load of storage this function let out of its sight read
          -- before one is not what it reads after.  A fence names no address
          -- and is no exception: ordering is the whole of what it does.
          testCase "across a fence, of a slot whose address left" $ do
            answered <- assignmentsIn pastAFence
            assertEqual "nothing is answered" [] answered
        , testCase "and across a read modify write" $ do
            answered <- assignmentsIn pastAnRmw
            assertEqual "nothing is answered" [] answered
        , -- But storage no stranger can name is storage no other thread can
          -- name either, so a slot whose address stayed here is read once
          -- however it is ordered around.  The locals are %x %a %b %s as 0 to
          -- 3.
          testCase "though not of a slot whose address never left" $ do
            answered <- assignmentsIn fencedConfinedSlot
            assertEqual
              "the second load reads the first"
              [(Local 2, VLocal (Local 1))]
              answered
        , -- A buffer a call handed back, written and read at one element with
          -- the element above it written in between.  Which element a step
          -- reaches is what the layout measures, and it measures it from a
          -- local this cannot place the same way it measures it from one it
          -- can.
          testCase "across a store to another element of a buffer" $ do
            answered <- assignmentsIn acquiredThenRead
            assertEqual
              "the load reads what was stored"
              [(Local 3, VLocal (Local 0))]
              answered
        , -- And the same buffer with the store in between made through a
          -- pointer this cannot place at all, which may be pointing at it.
          testCase "across a store through a pointer this cannot place" $ do
            answered <- assignmentsIn acquiredThenClobbered
            assertEqual "nothing is answered" [] answered
        , -- Two pointers this cannot tell apart, so the store between the loads
          -- has to be taken for a store to the one being read.
          testCase "across a store through another pointer" $ do
            answered <- assignmentsIn throughAnother
            assertEqual "nothing is answered" [] answered
        , -- Two symbols, and nothing here tells them apart: an alias is a second
          -- name for storage that already had one.  Reading the module to find
          -- which names are aliases of what is what this case is waiting for,
          -- and until then it is a load answered less often than it could be.
          testCase "across a store to another symbol" $ do
            answered <- assignmentsIn symbolAndAnother
            assertEqual "nothing is answered" [] answered
        , -- Eight bytes were written and four are being read.  The load is of
          -- part of what the store wrote, and a part is not something the store
          -- said anything about.
          testCase "a load narrower than the store above it" $ do
            answered <- assignmentsIn otherWidth
            assertEqual "nothing is answered" [] answered
        , -- The point of a volatile access is that it happens, so neither is
          -- replaced by a copy of the other.
          testCase "a second volatile load" $ do
            answered <- assignmentsIn volatileTwice
            assertEqual "nothing is answered" [] answered
        , -- And what one leaves behind is not a fact to keep: reading a volatile
          -- address is not the same as remembering what it read.
          testCase "a plain load below a volatile one" $ do
            answered <- assignmentsIn volatileThenPlain
            assertEqual "nothing is answered" [] answered
        , -- Both arms wrote the address and they wrote different things, so
          -- there is nothing the block below them can be told it holds.
          testCase "stored to different values on the two paths here" $ do
            answered <- assignmentsIn storedEitherWay
            assertEqual "nothing is answered" [] answered
        , -- Storage allocated in a loop is a new object each time round, holding
          -- whatever it holds, so what the last iteration left at that address
          -- is not what this one finds there.  Two things say so — the
          -- allocation assigns to the local naming the address, and no path from
          -- above the loop carries a fact about a local only the loop assigns —
          -- and this asks for the answer rather than for either of them.
          testCase "a slot allocated again each time round the loop" $ do
            answered <- assignmentsIn reallocated
            assertEqual "nothing is answered" [] answered
        ]
    , testGroup
        "which pointers may be one"
        [ testCase "an allocation is the storage it made" $ do
            (objects, [x, _]) <- aliasingIn twoSlots
            assertEqual "named by its own local" (Just (OnStack x)) (objectOf objects (VLocal x))
        , testCase "two allocations are two objects" $ do
            (objects, [x, y]) <- aliasingIn twoSlots
            assertEqual
              "which cannot overlap"
              False
              (mayAlias objects (reading (VLocal x)) (reading (VLocal y)))
        , testCase "an allocation and a symbol" $ do
            (objects, [x, _]) <- aliasingIn twoSlots
            assertEqual
              "no symbol names stack storage"
              False
              (mayAlias objects (reading (VLocal x)) (reading (VGlobal (Name Bare "g"))))
        , -- Two names, possibly one object: an alias is a second name for
          -- storage that already had one, and two declarations can be one
          -- symbol once the linker has been over them.
          testCase "two symbols are not told apart" $ do
            (objects, _) <- aliasingIn twoSlots
            assertEqual
              "which is the cautious answer"
              True
              ( mayAlias
                  objects
                  (reading (VGlobal (Name Bare "g")))
                  (reading (VGlobal (Name Bare "h")))
              )
        , -- A pointer that says nothing about where it points may point
          -- anywhere a pointer got to, and this slot's address never got
          -- anywhere.
          testCase "a slot whose address stayed put, and a stranger" $ do
            (objects, [x]) <- aliasingIn confinedSlot
            (_, [q]) <- strangersIn confinedSlot
            assertEqual
              "cannot be the same storage"
              False
              (mayAlias objects (reading (VLocal x)) (reading (VLocal q)))
        , testCase "and no call can reach it either" $ do
            (objects, [x]) <- aliasingIn confinedSlot
            assertEqual "having no way to name it" False (reachableByCall objects (VLocal x))
        , -- One step is all it takes: the address was written somewhere a
          -- callee could read it back.
          testCase "a slot whose address was stored somewhere" $ do
            (objects, [x]) <- aliasingIn handedOver
            (_, [q]) <- strangersIn handedOver
            assertEqual
              "may be any pointer at all"
              True
              (mayAlias objects (reading (VLocal x)) (reading (VLocal q)))
        , testCase "and a call may reach it" $ do
            (objects, [x]) <- aliasingIn handedOver
            assertEqual "the address being out there" True (reachableByCall objects (VLocal x))
        , -- But not by way of a parameter, whatever the address did afterwards.
          -- An argument is computed before the call it is an argument to, so
          -- there was no such slot to point at when the caller worked it out.
          -- LLVM answers the same: @opt -passes=gvn@ takes a load across a
          -- store through a parameter to storage the function allocated and
          -- whose address it stored somewhere first.
          testCase "and yet a parameter cannot be pointing at it" $ do
            (objects, [x]) <- aliasingIn handedOver
            assertEqual
              "the argument being older than the slot"
              False
              (mayAlias objects (reading (VLocal x)) (reading (VLocal (Local 0))))
        , -- Argument memory is the exception, being the caller's rather than
          -- this function's however it is written.
          testCase "unless the slot is where the arguments were built" $ do
            (objects, [x]) <- aliasingIn inallocaSlot
            assertEqual
              "which the caller names already"
              True
              (mayAlias objects (reading (VLocal x)) (reading (VLocal (Local 0))))
        , -- A local a call left a pointer in is assigned in one place, so it
          -- holds one address wherever it is read and two accesses stepped
          -- from it are that far apart.  Where the buffer is is still not
          -- known, and this asks nothing about that.
          testCase "two elements of a buffer a call handed back" $ do
            (objects, _) <- aliasingIn acquiredBuffers
            (_, [b, _]) <- acquiredIn acquiredBuffers
            (_, [n]) <- steppingIn acquiredBuffers
            assertEqual
              "one base and two offsets"
              False
              (mayAlias objects (reading (VLocal b)) (reading (VLocal n)))
        , -- Two calls, and nothing here tells their answers apart: that two
          -- allocations are two objects is a fact about where each points, and
          -- where either points is what the walk stopped without finding.
          -- LLVM answers otherwise, from the @noalias@ on the return.
          testCase "two buffers two calls handed back" $ do
            (objects, _) <- aliasingIn acquiredBuffers
            (_, [b, c]) <- acquiredIn acquiredBuffers
            assertEqual
              "which is the cautious answer"
              True
              (mayAlias objects (reading (VLocal b)) (reading (VLocal c)))
        , testCase "a buffer and a slot whose address stayed put" $ do
            (objects, [x, _]) <- aliasingIn acquiredBuffers
            (_, [b, _]) <- acquiredIn acquiredBuffers
            assertEqual
              "no call having a way to name it"
              False
              (mayAlias objects (reading (VLocal b)) (reading (VLocal x)))
        , -- And the slot next to it, whose address a callee could have read
          -- back and handed straight over.  This is why what a call left in a
          -- local is not asked the questions a parameter is asked: an argument
          -- was computed before the call began and cannot point into storage
          -- the call went on to allocate, and a returned pointer is the other
          -- way round.
          testCase "a buffer and a slot whose address was handed over" $ do
            (objects, [_, y]) <- aliasingIn acquiredBuffers
            (_, [b, _]) <- acquiredIn acquiredBuffers
            assertEqual
              "the call being free to hand it back"
              True
              (mayAlias objects (reading (VLocal b)) (reading (VLocal y)))
        , testCase "a buffer and a parameter" $ do
            (objects, _) <- aliasingIn acquiredBuffers
            (_, [b, _]) <- acquiredIn acquiredBuffers
            assertEqual
              "which may be one pointer"
              True
              (mayAlias objects (reading (VLocal b)) (reading (VLocal (Local 0))))
        ]
    , -- The same four questions of the same function with @noalias@ on the
      -- return, which is the call saying the pointer it handed back reaches
      -- nothing the caller reaches any other way.  Three of the answers above
      -- turn over, and the fourth was already as sharp as it goes.
      testGroup
        "what the callee promised"
        [ testCase "two buffers two promises handed back" $ do
            (objects, _) <- aliasingIn promisedBuffers
            (_, [b, c]) <- acquiredIn promisedBuffers
            assertEqual
              "each promise excluding what the other returned"
              False
              (mayAlias objects (reading (VLocal b)) (reading (VLocal c)))
        , -- The slot whose address was handed over, which without the promise
          -- is a slot the callee could have read back and returned.  The
          -- promise is what says it did not.
          testCase "a buffer and a slot whose address was handed over" $ do
            (objects, [_, y]) <- aliasingIn promisedBuffers
            (_, [b, _]) <- acquiredIn promisedBuffers
            assertEqual
              "the promise being about every pointer the caller holds"
              False
              (mayAlias objects (reading (VLocal b)) (reading (VLocal y)))
        , -- And a parameter, which the caller held before the call began.
          testCase "a buffer and a parameter" $ do
            (objects, _) <- aliasingIn promisedBuffers
            (_, [b, _]) <- acquiredIn promisedBuffers
            assertEqual
              "which the promise excludes as well"
              False
              (mayAlias objects (reading (VLocal b)) (reading (VLocal (Local 0))))
        , -- Unchanged: two accesses stepped from one buffer were already told
          -- apart by their offsets, the promise having nothing to add about
          -- two places in one object.
          testCase "two elements of one promised buffer" $ do
            (objects, _) <- aliasingIn promisedBuffers
            (_, [b, _]) <- acquiredIn promisedBuffers
            (_, [n]) <- steppingIn promisedBuffers
            assertEqual
              "one object and two offsets"
              False
              (mayAlias objects (reading (VLocal b)) (reading (VLocal n)))
        ]
    , testGroup
        "what the caller promised"
        [ -- Two parameters and one promise, which is enough: what is reached
          -- through a noalias parameter is not reached any other way, and the
          -- other parameter is another way.
          testCase "a noalias parameter and another parameter" $ do
            (objects, _) <- aliasingIn promisedApartSource
            assertEqual
              "which the promise keeps apart"
              False
              (mayAlias objects (reading (VLocal (Local 0))) (reading (VLocal (Local 1))))
        , testCase "and the same two without the promise" $ do
            (objects, _) <- aliasingIn nothingPromised
            assertEqual
              "which may be one pointer"
              True
              (mayAlias objects (reading (VLocal (Local 0))) (reading (VLocal (Local 1))))
        , -- A symbol is a name everything outside the function can use, so it
          -- is one of the other ways the promise is about.
          testCase "a noalias parameter and a symbol" $ do
            (objects, _) <- aliasingIn promisedApartSource
            assertEqual
              "which the promise keeps apart as well"
              False
              (mayAlias objects (reading (VLocal (Local 0))) (reading (VGlobal (Name Bare "g"))))
        , testCase "and a plain parameter and a symbol" $ do
            (objects, _) <- aliasingIn nothingPromised
            assertEqual
              "which may well be where it points"
              True
              (mayAlias objects (reading (VLocal (Local 0))) (reading (VGlobal (Name Bare "g"))))
        , -- The promise is about other ways of reaching the storage, not about
          -- the parameter itself: two accesses off one of them are two
          -- accesses to one thing, and only the offsets say whether they meet.
          testCase "one noalias parameter twice over" $ do
            (objects, _) <- aliasingIn promisedApartSource
            assertEqual
              "which is the same storage either way"
              True
              (mayAlias objects (reading (VLocal (Local 0))) (reading (VLocal (Local 0))))
        , -- And it says nothing about a pointer this cannot follow, which may
          -- be a select or a phi that the promise covers rather than excludes.
          testCase "a noalias parameter and a stranger" $ do
            (objects, _) <- aliasingIn promisedApartSource
            (_, [q]) <- strangersIn promisedApartSource
            assertEqual
              "there being no saying what it was derived from"
              True
              (mayAlias objects (reading (VLocal (Local 0))) (reading (VLocal q)))
        ]
    , testGroup
        "which bytes an access touches"
        [ -- The whole of what the data layout buys here.  Neither pointer says
          -- what it points into — both are steps off a parameter — but they are
          -- steps off the /same/ parameter, and the fields they arrive at do not
          -- meet.
          testCase "two fields of one struct" $ do
            (objects, [a, b, _, _]) <- steppingIn intoFields
            assertEqual
              "which cannot be one address"
              False
              (mayAlias objects (reading (VLocal a)) (reading (VLocal b)))
        , testCase "the same field twice" $ do
            (objects, [a, _, _, _]) <- steppingIn intoFields
            assertEqual
              "which is one address"
              True
              (mayAlias objects (reading (VLocal a)) (reading (VLocal a)))
        , -- How far each access reaches is half of the answer: an @i64@ read
          -- where the @i32@ is covers both fields.
          testCase "a wider access at the earlier field" $ do
            (objects, [a, b, _, _]) <- steppingIn intoFields
            assertEqual
              "which reaches into the later one"
              True
              (mayAlias objects (Access (VLocal a) (TInteger 64)) (reading (VLocal b)))
        , -- Three bytes into the struct is still the first field.
          testCase "a byte inside the earlier field" $ do
            (objects, [a, b, c, _]) <- steppingIn intoFields
            assertEqual
              "meets the field it is in"
              True
              (mayAlias objects (reading (VLocal a)) (Access (VLocal c) (TInteger 8)))
            assertEqual
              "and not the one after it"
              False
              (mayAlias objects (reading (VLocal b)) (Access (VLocal c) (TInteger 8)))
        , -- An index the program has not settled is a step of unknown length,
          -- which leaves the walk with the base and no offset.
          testCase "a step by an index nothing settles" $ do
            (objects, [a, _, _, d]) <- steppingIn intoFields
            assertEqual
              "may be anywhere"
              True
              (mayAlias objects (reading (VLocal a)) (reading (VLocal d)))
        , -- The same module with nothing said about the target: which bytes a
          -- field is at is exactly what the layout string answers.
          testCase "and none of it where the module states no layout" $ do
            (objects, [a, b, _, _]) <- steppingIn (T.unlines (drop 1 (T.lines intoFields)))
            assertEqual
              "so two fields may be one address"
              True
              (mayAlias objects (reading (VLocal a)) (reading (VLocal b)))
        ]
    , testGroup
        "what may be shared at all"
        [ testCase "arithmetic" $ shareable opaque (binary OpAdd) @?= True
        , testCase "a comparison" $ shareable opaque comparison @?= True
        , testCase "a conversion" $ shareable opaque conversion @?= True
        , testCase "a pointer step" $ shareable opaque step @?= True
        , testCase "a field selection" $ shareable opaque field @?= True
        , -- Dividing by zero is poison rather than a fault, so a division is
          -- as shareable opaque as an addition: two of them with the same operands
          -- are poison together or a number together.
          testCase "division" $ shareable opaque (binary OpSDiv) @?= True
        , -- Fresh storage each time, so two allocations are two objects.
          testCase "an allocation" $ shareable opaque allocation @?= False
        , testCase "a load" $ shareable opaque load' @?= False
        , testCase "a store" $ shareable opaque store' @?= False
        , -- A call nothing is known about may answer differently each time it
          -- is asked, and may do anything on the way to answering.
          testCase "a call" $ shareable opaque call' @?= False
        , -- One the whole program says touches no memory answers out of its
          -- arguments alone, so two written the same way are one computation.
          -- Throwing and not returning are no objection: the second run is
          -- reached only when the first came back.
          testCase "a call that touches nothing" $
            shareable (const nothing) call' @?= True
        , testCase "a call that may throw" $
            shareable (const nothing {mayUnwind = True}) call' @?= True
        , testCase "a call that reads memory" $
            shareable (const nothing {readsMemory = True}) call' @?= False
        , testCase "a call that writes memory" $
            shareable (const nothing {writesMemory = True}) call' @?= False
        , -- Already the value it holds; there is no computation to repeat.
          testCase "an assignment" $ shareable opaque assignment @?= False
        ]
    ]

-- | The instructions the pass turned into a copy of an earlier local, as the
-- local assigned and the local read.
--
-- An assignment of anything but a local is not one of these: the lowering
-- writes those itself, for a phi and for a pointer step that moves nowhere,
-- and they are not what this pass leaves behind.
copiesIn :: Text -> IO [(Local, Local)]
copiesIn source = locals <$> assignmentsAfter id source
  where
    locals xs = [(name, read') | (name, VLocal read') <- xs]

-- | The same, of a function promotion has already been over.
--
-- Promotion is what puts a local assigned more than once in front of this
-- pass, which no LLVM function can be written to produce directly: single
-- assignment is what the input is in.  The pipeline runs them in this order
-- for its own reasons, and these cases are why the order is not the only
-- thing keeping the answer right.
promotedCopiesIn :: Text -> IO [(Local, Local)]
promotedCopiesIn source = locals <$> assignmentsAfter promoteMemory source
  where
    locals xs = [(name, read') | (name, VLocal read') <- xs]

-- | Everything the pass turned into an assignment, as the local assigned and
-- the value it now holds.
--
-- Wider than 'copiesIn' because a load can be answered by something that is not
-- a local: a store of a constant leaves the constant at the address, and a load
-- reading it becomes an assignment with no local in it at all.
assignmentsIn :: Text -> IO [(Local, Value Local)]
assignmentsIn = assignmentsAfter id

assignmentsAfter :: (Program -> Program) -> Text -> IO [(Local, Value Local)]
assignmentsAfter before source = do
  parsed <- expectParse "<inline>" source
  let shared = eliminateRedundancies (before (lower parsed))
      original = before (lower parsed)
      assignments program =
        [ (name, value)
        | f <- functionsIn program
        , b <- functionBlocks f
        , Instruction (Just name) (OAssign (TypedValue _ value)) _ <-
            blockInstructions b
        ]
  -- What the pass added, rather than every assignment in the result: lowering
  -- and promotion write their own, and those are not this pass's doing.
  pure [a | a <- assignments shared, a `notElem` assignments original]

-- | The first function of a module, lowered, for the questions that are asked
-- of the analysis rather than of the rewrite.
functionOf :: Text -> IO Function
functionOf source = do
  parsed <- expectParse "<inline>" source
  case functionsIn (lower parsed) of
    f : _ -> pure f
    [] -> assertFailure "no function lowered"

-- | What a function says about its pointers, and the locals its allocations
-- assign to, in the order written.
--
-- The slots are looked for rather than counted to, because an @alloca@ is not
-- the only instruction the lowering issues a local for and counting would
-- break on the next test that added one.
aliasingIn :: Text -> IO (Objects, [Local])
aliasingIn source = do
  parsed <- expectParse "test" source
  let program = lower parsed
  case functionsIn program of
    [] -> assertFailure "no function lowered"
    f : _ ->
      pure
        ( objectsIn (layoutOf program) f
        , [ slot
          | b <- functionBlocks f
          , Instruction (Just slot) (OAlloca _) _ <- blockInstructions b
          ]
        )

-- | What a function says about its pointers, and the locals its loads of
-- pointers assign to, in the order written.
--
-- A pointer read out of memory is what a stranger is: the walk stops at the
-- local the load assigns and has found nothing that says where it points,
-- which is the case the answers about strangers are answers about.  A
-- parameter used to serve for one in these tests and no longer can, where an
-- argument may point being something the analysis now says something about.
strangersIn :: Text -> IO (Objects, [Local])
strangersIn source = do
  parsed <- expectParse "test" source
  let program = lower parsed
  case functionsIn program of
    [] -> assertFailure "no function lowered"
    f : _ ->
      pure
        ( objectsIn (layoutOf program) f
        , [ result
          | b <- functionBlocks f
          , Instruction (Just result) (OLoad l) _ <- blockInstructions b
          , TPointer _ <- [loadType l]
          ]
        )

-- | What a function says about its pointers, and the locals its calls assign
-- to, in the order written.
--
-- Storage a call handed back is a base with no syntax of its own: an
-- allocation is written @alloca@ and a parameter stands in the signature, and
-- this is an ordinary local whose one assignment happens to say nothing about
-- where it points.  So the fixtures using this name their calls' results by
-- looking for them, as the ones about steps do.
acquiredIn :: Text -> IO (Objects, [Local])
acquiredIn source = do
  parsed <- expectParse "test" source
  let program = lower parsed
  case functionsIn program of
    [] -> assertFailure "no function lowered"
    f : _ ->
      pure
        ( objectsIn (layoutOf program) f
        , [ result
          | b <- functionBlocks f
          , Instruction (Just result) (OCall _) _ <- blockInstructions b
          ]
        )

-- | An access at the width most of these tests are written in.
--
-- Where a test is about the offsets rather than about the objects it says the
-- type itself, since how far an access reaches is half of what decides.
reading :: Value Local -> Access
reading at = Access at (TInteger 32)

-- | What a function says about its pointers, and the locals its pointer steps
-- assign to, in the order written.
--
-- The steps are looked for rather than counted to for the reason the
-- allocations are: which local a @getelementptr@ leaves its answer in depends
-- on how many instructions the lowering issued before it.
steppingIn :: Text -> IO (Objects, [Local])
steppingIn source = do
  parsed <- expectParse "test" source
  let program = lower parsed
  case functionsIn program of
    [] -> assertFailure "no function lowered"
    f : _ ->
      pure
        ( objectsIn (layoutOf program) f
        , [ result
          | b <- functionBlocks f
          , Instruction (Just result) operation _ <- blockInstructions b
          , stepping operation
          ]
        )
  where
    stepping (OOffset _) = True
    stepping (OField _) = True
    stepping _ = False

twice :: Text
twice =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b) {"
    , "entry:"
    , "  %x = add i32 %a, %b"
    , "  %y = add i32 %a, %b"
    , "  %z = add i32 %x, %y"
    , "  ret i32 %z"
    , "}"
    ]

flagged :: Text
flagged =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b) {"
    , "entry:"
    , "  %x = add nsw i32 %a, %b"
    , "  %y = add i32 %a, %b"
    , "  %z = add i32 %x, %y"
    , "  ret i32 %z"
    , "}"
    ]

dominating :: Text
dominating =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
    , "entry:"
    , "  %x = mul i32 %a, %b"
    , "  br i1 %c, label %again, label %done"
    , "again:"
    , "  %y = mul i32 %a, %b"
    , "  %z = add i32 %x, %y"
    , "  ret i32 %z"
    , "done:"
    , "  ret i32 %x"
    , "}"
    ]

oneArm :: Text
oneArm =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %join"
    , "yes:"
    , "  %x = mul i32 %a, %b"
    , "  br label %join"
    , "join:"
    , "  %y = mul i32 %a, %b"
    , "  ret i32 %y"
    , "}"
    ]

bothArms :: Text
bothArms =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i1 %c) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  %x = mul i32 %a, %b"
    , "  br label %join"
    , "no:"
    , "  %y = mul i32 %a, %b"
    , "  br label %join"
    , "join:"
    , "  %z = mul i32 %a, %b"
    , "  ret i32 %z"
    , "}"
    ]

-- | A subscript written twice, which is what the corpus contains: clang emits
-- the same @getelementptr@ for the same expression rather than reusing one.
stepped :: Text
stepped =
  T.unlines
    [ "define i32 @f(ptr %p, i64 %i) {"
    , "entry:"
    , "  %q = getelementptr inbounds [8 x i32], ptr %p, i64 %i, i64 3"
    , "  %a = load i32, ptr %q, align 4"
    , "  %r = getelementptr inbounds [8 x i32], ptr %p, i64 %i, i64 3"
    , "  store i32 %a, ptr %r, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | A loop whose body computes one thing twice, and one thing the block
-- before the loop already computed.
looping :: Text
looping =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i32 %n) {"
    , "entry:"
    , "  %e = mul i32 %a, %b"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %j, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %x = mul i32 %a, %b"
    , "  %y = mul i32 %a, %b"
    , "  %j = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %e"
    , "}"
    ]

-- | A loop whose body recomputes what the block before it worked out, and
-- nothing else.
carried :: Text
carried =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i32 %n) {"
    , "entry:"
    , "  %e = mul i32 %a, %b"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %j, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %x = mul i32 %a, %b"
    , "  %j = add i32 %i, %x"
    , "  br label %head"
    , "done:"
    , "  ret i32 %e"
    , "}"
    ]

-- | The same, one loop further in.
nested :: Text
nested =
  T.unlines
    [ "define i32 @f(i32 %a, i32 %b, i32 %n) {"
    , "entry:"
    , "  %e = mul i32 %a, %b"
    , "  br label %outer"
    , "outer:"
    , "  %i = phi i32 [ 0, %entry ], [ %k, %latch ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %inner, label %done"
    , "inner:"
    , "  %j = phi i32 [ 0, %outer ], [ %m, %inner ]"
    , "  %x = mul i32 %a, %b"
    , "  %m = add i32 %j, %x"
    , "  %d = icmp slt i32 %m, %n"
    , "  br i1 %d, label %inner, label %latch"
    , "latch:"
    , "  %k = add i32 %i, 1"
    , "  br label %outer"
    , "done:"
    , "  ret i32 %e"
    , "}"
    ]

reassigned :: Text
reassigned =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %n, ptr %s, align 4"
    , "  %v = load i32, ptr %s, align 4"
    , "  %x = add i32 %v, 1"
    , "  store i32 7, ptr %s, align 4"
    , "  %w = load i32, ptr %s, align 4"
    , "  %y = add i32 %w, 1"
    , "  %t = add i32 %x, %y"
    , "  ret i32 %t"
    , "}"
    ]

stale :: Text
stale =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %s = alloca i32, align 4"
    , "  store i32 %n, ptr %s, align 4"
    , "  %a = load i32, ptr %s, align 4"
    , "  store i32 7, ptr %s, align 4"
    , "  %b = load i32, ptr %s, align 4"
    , "  %x = add i32 %a, 1"
    , "  %y = add i32 %b, 1"
    , "  %t = mul i32 %x, %y"
    , "  ret i32 %t"
    , "}"
    ]

calling :: Text
calling =
  T.unlines
    [ "declare i32 @tick(i32)"
    , "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %a = call i32 @tick(i32 %n)"
    , "  %b = call i32 @tick(i32 %n)"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- | A load either side of a store to the same address.  The first load's answer
-- is gone and the store's is there instead.
loading :: Text
loading =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %a = load i32, ptr %p, align 4"
    , "  store i32 99, ptr %p, align 4"
    , "  %b = load i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

twiceLoaded :: Text
twiceLoaded =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %a = load i32, ptr %p, align 4"
    , "  %b = load i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

storedThenLoaded :: Text
storedThenLoaded =
  T.unlines
    [ "define i32 @f(ptr %p, i32 %n) {"
    , "entry:"
    , "  store i32 %n, ptr %p, align 4"
    , "  %a = load i32, ptr %p, align 4"
    , "  ret i32 %a"
    , "}"
    ]

otherSlot :: Text
otherSlot =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %y = alloca i32, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  store i32 %n, ptr %y, align 4"
    , "  %b = load i32, ptr %x, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

pastACall :: Text
pastACall =
  T.unlines
    [ "declare void @sink()"
    , "define i32 @f() {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  call void @sink()"
    , "  %b = load i32, ptr %x, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- | A slot the caller was handed the address of, read either side of a fence.
pastAFence :: Text
pastAFence =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  store ptr %x, ptr %p, align 8"
    , "  %a = load i32, ptr %x, align 4"
    , "  fence seq_cst"
    , "  %b = load i32, ptr %x, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- | The same, with an operation that reads and writes an unrelated address.
pastAnRmw :: Text
pastAnRmw =
  T.unlines
    [ "define i32 @f(ptr %p, ptr %q) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  store ptr %x, ptr %p, align 8"
    , "  %a = load i32, ptr %x, align 4"
    , "  %r = atomicrmw add ptr %q, i32 1 seq_cst, align 4"
    , "  %b = load i32, ptr %x, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- | And a slot whose address stayed in this function, read either side of one.
fencedConfinedSlot :: Text
fencedConfinedSlot =
  T.unlines
    [ "define i32 @f() {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  fence seq_cst"
    , "  %b = load i32, ptr %x, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- | A slot bracketed by lifetime markers, read either side of a call that was
-- not given its address.
markedSlot :: Text
markedSlot =
  T.unlines
    [ "declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none))"
    , "declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none))"
    , "declare void @noise()"
    , "define i32 @f() {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  call void @llvm.lifetime.start.p0(i64 4, ptr %x)"
    , "  %a = load i32, ptr %x, align 4"
    , "  call void @noise()"
    , "  %b = load i32, ptr %x, align 4"
    , "  %s = add i32 %a, %b"
    , "  call void @llvm.lifetime.end.p0(i64 4, ptr %x)"
    , "  ret i32 %s"
    , "}"
    ]

escapedSlot :: Text
escapedSlot =
  T.unlines
    [ "declare void @sink(ptr)"
    , "define i32 @f() {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  call void @sink(ptr %x)"
    , "  %b = load i32, ptr %x, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

throughAnother :: Text
throughAnother =
  T.unlines
    [ "define i32 @f(ptr %p, ptr %q, i32 %n) {"
    , "entry:"
    , "  %a = load i32, ptr %p, align 4"
    , "  store i32 %n, ptr %q, align 4"
    , "  %b = load i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

otherWidth :: Text
otherWidth =
  T.unlines
    [ "define i32 @f(ptr %p, i64 %n) {"
    , "entry:"
    , "  store i64 %n, ptr %p, align 8"
    , "  %a = load i32, ptr %p, align 4"
    , "  ret i32 %a"
    , "}"
    ]

volatileTwice :: Text
volatileTwice =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %a = load volatile i32, ptr %p, align 4"
    , "  %b = load volatile i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

volatileThenPlain :: Text
volatileThenPlain =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %a = load volatile i32, ptr %p, align 4"
    , "  %b = load i32, ptr %p, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- | A loop whose body reads what the block above the loop read, and writes no
-- memory at all.
carriedLoad :: Text
carriedLoad =
  T.unlines
    [ "define i32 @f(ptr %p, i32 %n) {"
    , "entry:"
    , "  %a = load i32, ptr %p, align 4"
    , "  br label %head"
    , "head:"
    , "  %i = phi i32 [ 0, %entry ], [ %j, %body ]"
    , "  %t = phi i32 [ %a, %entry ], [ %u, %body ]"
    , "  %c = icmp slt i32 %i, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %b = load i32, ptr %p, align 4"
    , "  %u = add i32 %t, %b"
    , "  %j = add i32 %i, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %t"
    , "}"
    ]

-- | Storage allocated inside the loop, read before it is written.
reallocated :: Text
reallocated =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  br label %head"
    , "head:"
    , "  %k = phi i32 [ 0, %entry ], [ %k1, %body ]"
    , "  %t = phi i32 [ 0, %entry ], [ %t1, %body ]"
    , "  %c = icmp slt i32 %k, %n"
    , "  br i1 %c, label %body, label %done"
    , "body:"
    , "  %x = alloca i32, align 4"
    , "  %v = load i32, ptr %x, align 4"
    , "  store i32 %k, ptr %x, align 4"
    , "  %t1 = add i32 %t, %v"
    , "  %k1 = add i32 %k, 1"
    , "  br label %head"
    , "done:"
    , "  ret i32 %t"
    , "}"
    ]

storedAlike :: Text
storedAlike =
  T.unlines
    [ "define i32 @f(ptr %p, i1 %c, i32 %n) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  store i32 %n, ptr %p, align 4"
    , "  br label %join"
    , "no:"
    , "  store i32 %n, ptr %p, align 4"
    , "  br label %join"
    , "join:"
    , "  %a = load i32, ptr %p, align 4"
    , "  ret i32 %a"
    , "}"
    ]

storedEitherWay :: Text
storedEitherWay =
  T.unlines
    [ "define i32 @f(ptr %p, i1 %c, i32 %n) {"
    , "entry:"
    , "  br i1 %c, label %yes, label %no"
    , "yes:"
    , "  store i32 1, ptr %p, align 4"
    , "  br label %join"
    , "no:"
    , "  store i32 %n, ptr %p, align 4"
    , "  br label %join"
    , "join:"
    , "  %a = load i32, ptr %p, align 4"
    , "  ret i32 %a"
    , "}"
    ]

symbolTwice :: Text
symbolTwice =
  T.unlines
    [ "@count = internal global i32 0"
    , "define i32 @f() {"
    , "entry:"
    , "  %a = load i32, ptr @count, align 4"
    , "  %b = load i32, ptr @count, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

symbolAndAnother :: Text
symbolAndAnother =
  T.unlines
    [ "@count = internal global i32 0"
    , "@other = internal global i32 7"
    , "define i32 @f() {"
    , "entry:"
    , "  %a = load i32, ptr @count, align 4"
    , "  store i32 3, ptr @other, align 4"
    , "  %b = load i32, ptr @count, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- Functions the aliasing is asked about rather than run over.

twoSlots :: Text
twoSlots =
  T.unlines
    [ "define i32 @f(i32 %n) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %y = alloca i32, align 4"
    , "  store i32 %n, ptr %x, align 4"
    , "  store i32 %n, ptr %y, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | A field read, the other field written, and the first read again — which is
-- @both_ways@ in the corpus, the case the aliasing wanted sizes for.
otherField :: Text
otherField =
  T.unlines
    [ "target datalayout = \"e-m:e-i64:64-n8:16:32:64-S128\""
    , "%pair = type { i32, i32 }"
    , "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %a = getelementptr %pair, ptr %p, i32 0, i32 1"
    , "  %b = load i32, ptr %a, align 4"
    , "  %c = getelementptr %pair, ptr %p, i32 0, i32 0"
    , "  store i32 7, ptr %c, align 4"
    , "  %d = load i32, ptr %a, align 4"
    , "  %s = add i32 %b, %d"
    , "  ret i32 %s"
    , "}"
    ]

-- | Four addresses in one struct a parameter points at: each of the two
-- fields, a byte part way into the first, and a step by an index nothing
-- settles.
--
-- Written through a parameter rather than through an allocation because that is
-- the case the offsets are for: two accesses to storage this function did not
-- make, which the objects alone say nothing about.
intoFields :: Text
intoFields =
  T.unlines
    [ "target datalayout = \"e-m:e-i64:64-n8:16:32:64-S128\""
    , "%pair = type { i32, i32 }"
    , "define i32 @f(ptr %p, i64 %n) {"
    , "entry:"
    , "  %a = getelementptr %pair, ptr %p, i32 0, i32 0"
    , "  %b = getelementptr %pair, ptr %p, i32 0, i32 1"
    , "  %c = getelementptr i8, ptr %p, i64 3"
    , "  %d = getelementptr i32, ptr %p, i64 %n"
    , "  %x = load i32, ptr %a, align 4"
    , "  ret i32 %x"
    , "}"
    ]

-- | A slot read and written and nothing else, beside a pointer that arrived
-- from somewhere this function cannot see.
--
-- The pointer is read out of memory rather than being the parameter, because
-- where a parameter may point is something the analysis now has an opinion
-- about and a stranger is precisely a pointer it has none about.
confinedSlot :: Text
confinedSlot =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %q = load ptr, ptr %p, align 8"
    , "  store i32 1, ptr %x, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  %b = load i32, ptr %q, align 4"
    , "  %s = add i32 %a, %b"
    , "  ret i32 %s"
    , "}"
    ]

-- | The same slot, with its address written where anything could read it back.
handedOver :: Text
handedOver =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  store ptr %x, ptr %p, align 8"
    , "  %q = load ptr, ptr %p, align 8"
    , "  %a = load i32, ptr %x, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | Two buffers a call handed back, a slot whose address stayed put, and a
-- slot whose address did not.
--
-- The step is written as a @getelementptr@ rather than at a second call so
-- that the two accesses through the first buffer are one base and two offsets,
-- which is the whole of what measuring from such a local buys.
acquiredBuffers :: Text
acquiredBuffers =
  T.unlines
    [ "target datalayout = \"e-m:e-i64:64-n8:16:32:64-S128\""
    , "declare ptr @acquire()"
    , "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %y = alloca i32, align 4"
    , "  store ptr %y, ptr %p, align 8"
    , "  %b = call ptr @acquire()"
    , "  %c = call ptr @acquire()"
    , "  %n = getelementptr i32, ptr %b, i64 1"
    , "  %a = load i32, ptr %b, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | The same function with the promise on it, which is the one thing between
-- the two.
--
-- Written out again rather than patched, so that what the promise changes is
-- read off two whole functions side by side rather than off a substitution.
promisedBuffers :: Text
promisedBuffers =
  T.unlines
    [ "target datalayout = \"e-m:e-i64:64-n8:16:32:64-S128\""
    , "declare noalias ptr @acquire()"
    , "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %y = alloca i32, align 4"
    , "  store ptr %y, ptr %p, align 8"
    , "  %b = call noalias ptr @acquire()"
    , "  %c = call noalias ptr @acquire()"
    , "  %n = getelementptr i32, ptr %b, i64 1"
    , "  %a = load i32, ptr %b, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | A buffer a call handed back, read either side of a store to the element
-- above the one being read.
acquiredThenRead :: Text
acquiredThenRead =
  T.unlines
    [ "target datalayout = \"e-m:e-i64:64-n8:16:32:64-S128\""
    , "declare ptr @acquire()"
    , "define i32 @f(i32 %v) {"
    , "entry:"
    , "  %b = call ptr @acquire()"
    , "  store i32 %v, ptr %b, align 4"
    , "  %n = getelementptr i32, ptr %b, i64 1"
    , "  store i32 7, ptr %n, align 4"
    , "  %a = load i32, ptr %b, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | And the same with the store between them made through a pointer this
-- cannot place.
acquiredThenClobbered :: Text
acquiredThenClobbered =
  T.unlines
    [ "target datalayout = \"e-m:e-i64:64-n8:16:32:64-S128\""
    , "declare ptr @acquire()"
    , "define i32 @f(ptr %p, i32 %v) {"
    , "entry:"
    , "  %b = call ptr @acquire()"
    , "  store i32 %v, ptr %b, align 4"
    , "  store i32 7, ptr %p, align 4"
    , "  %a = load i32, ptr %b, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | Storage that is not the function's own however it is written: @inalloca@
-- names the memory the caller built the arguments in.
inallocaSlot :: Text
inallocaSlot =
  T.unlines
    [ "define i32 @f(ptr %p) {"
    , "entry:"
    , "  %x = alloca inalloca i32, align 4"
    , "  %a = load i32, ptr %x, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | Two pointers the caller promised are not the same one, and a symbol
-- beside them.
promisedApartSource :: Text
promisedApartSource =
  T.unlines
    [ "@g = global i32 0"
    , "define i32 @f(ptr noalias %p, ptr %q) {"
    , "entry:"
    , "  %r = load ptr, ptr %q, align 8"
    , "  %a = load i32, ptr %p, align 4"
    , "  ret i32 %a"
    , "}"
    ]

-- | The same function with nothing promised about either pointer.
nothingPromised :: Text
nothingPromised =
  T.unlines
    [ "@g = global i32 0"
    , "define i32 @f(ptr %p, ptr %q) {"
    , "entry:"
    , "  %a = load i32, ptr %p, align 4"
    , "  ret i32 %a"
    , "}"
    ]

allocating :: Text
allocating =
  T.unlines
    [ "declare void @keep(ptr, ptr)"
    , "define void @f() {"
    , "entry:"
    , "  %x = alloca i32, align 4"
    , "  %y = alloca i32, align 4"
    , "  call void @keep(ptr %x, ptr %y)"
    , "  ret void"
    , "}"
    ]

-- Operations at the core's own operand type, for 'shareable', which reads
-- nothing but which operation it is and what the program says its calls do.

-- | A call this knows nothing about, which is what every case here but the
-- ones about calls is written against.
opaque :: Call (TypedValue Local) -> Behaviour
opaque = const anything

binary :: BinaryOp -> Operation (TypedValue Local)
binary op = OBinary (Binary op [] (word 1) (word 2))

comparison :: Operation (TypedValue Local)
comparison = OICmp (Compare [] IEq (word 1) (word 2))

conversion :: Operation (TypedValue Local)
conversion = OConvert (Convert CastZExt [] (word 1) (TInteger 64))

step :: Operation (TypedValue Local)
step = OOffset (Offset [] (TInteger 32) pointer (word 1))

field :: Operation (TypedValue Local)
field = OField (Field [] (TStruct Unpacked [TInteger 32]) pointer 0)

allocation :: Operation (TypedValue Local)
allocation = OAlloca (Alloca False (TInteger 32) Nothing Nothing Nothing)

load' :: Operation (TypedValue Local)
load' = OLoad (Load False (TInteger 32) pointer Nothing)

store' :: Operation (TypedValue Local)
store' = OStore (Store False (word 1) pointer Nothing)

call' :: Operation (TypedValue Local)
call' =
  OCall
    ( Call
        Nothing
        []
        Nothing
        []
        Nothing
        (TInteger 32)
        (TypedValue (TPointer Nothing) (VGlobal (Name Bare "tick")))
        []
        []
        []
    )

assignment :: Operation (TypedValue Local)
assignment = OAssign (word 1)

word :: Integer -> TypedValue Local
word n = TypedValue (TInteger 32) (VInteger n)

pointer :: TypedValue Local
pointer = TypedValue (TPointer Nothing) (VLocal (Local 0))
