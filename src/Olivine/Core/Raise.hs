-- | Core to syntax.
--
-- LLVM has no assignment, so a local the core assigns has to become something
-- LLVM can express.  It becomes memory: a slot allocated once, written where
-- the core assigns, and read where the value is wanted.  That is the same
-- shape clang emits before its own passes run, and it is correct without
-- needing to work out where phi nodes would go.
--
-- __Where the read goes.__  The assignments a phi became sit at the end of
-- the blocks whose edges reach the block the phi was at the head of, so the
-- read belongs at the head of that block, where it dominates everything the
-- phi did.  Raising finds it as the successor those assigning blocks agree
-- on.  That holds for anything the lowering produces, and it is checked
-- rather than assumed; once a pass can move an assignment somewhere else,
-- this has to become a real single assignment reconstruction, which will also
-- put the phi nodes back and undo the memory traffic.
module Olivine.Core.Raise
  ( raise
  ) where

import Data.Char (isDigit)
import Data.List (nub)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T

import Olivine.Core.Program
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Function qualified as Syntax
import Olivine.Syntax.Instruction (Operation (..))
import Olivine.Syntax.Instruction qualified as Syntax
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderName)
import Olivine.Syntax.Type (Type, Type (..))
import Olivine.Syntax.Value

firstOr :: a -> [a] -> a
firstOr fallback = foldr (\x _ -> x) fallback

raise :: Program -> Syntax.Module
raise = Syntax.Module . map raiseEntry . programEntries

raiseEntry :: Entry -> Syntax.Entry
raiseEntry (ERetained entry) = entry
raiseEntry (EFunction f) =
  Syntax.EDefine
    Syntax.Definition
      { Syntax.definitionSignature = functionSignature f
      , Syntax.definitionBlocks = zipWith (raiseBlock f slots) [0 ..] (functionBlocks f)
      }
  where
    slots = slotsOf f

-- | A local the core assigns, and what LLVM needs in its place.
data Slot = Slot
  { slotLocal :: Name
  , slotType :: Type
  , slotRead :: ReadAt
  }

-- | Where the value written to a slot is read back.
--
-- The two cases are not a choice of style.  A local a phi became is written
-- at the end of the blocks whose edges reach the phi's block and read there,
-- so its read belongs at that block's head.  The temporary that breaks an
-- exchange is written and read within one block, and putting its read at a
-- successor's head would read the previous time round instead — which is a
-- bug this had until the behaviour was compared rather than the structure.
data ReadAt
  = -- | At the head of the named block.
    HeadOf Name
  | -- | Immediately after the assignment itself.
    AfterAssignment
  deriving (Eq)

-- | Every local the function assigns, with the block its value is read in.
slotsOf :: Function -> [Slot]
slotsOf f =
  [ Slot {slotLocal = name, slotType = t, slotRead = readAt name}
  | (name, t) <- nub assigned
  ]
  where
    readAt name
      | readInOwnBlock name = AfterAssignment
      | otherwise = HeadOf (readIn name)
    -- Read in the same block that assigns it, and after that assignment.
    --
    -- Order is what matters.  In an exchange every local involved is both
    -- read and assigned in the one block, but only the temporary is read
    -- after it has been written; the rest are read on the way in, which is
    -- the load at the head of the block they came from.
    readInOwnBlock name =
      or [readsAfterAssignment (blockInstructions b) | b <- functionBlocks f]
      where
        readsAfterAssignment = go False
        go _ [] = False
        go written (Instruction result (Assign value) _ : rest) =
          (written && reads' value) || go (written || writes result) rest
        go written (_ : rest) = go written rest
        writes = (== Just name)
        reads' value = case typedValue value of
          VLocal other -> other == name
          _ -> False
    assigned =
      [ (name, typedValueType value)
      | b <- functionBlocks f
      , Instruction (Just name) (Assign value) _ <- blockInstructions b
      ]
    -- The successor the blocks assigning this local agree on.
    readIn name =
      firstOr
        name
        [ target
        | b <- functionBlocks f
        , any (assigns name) (blockInstructions b)
        , target <- take 1 (targetsOf (blockTerminator b))
        ]
    assigns name (Instruction (Just other) (Assign _) _) = name == other
    assigns _ _ = False

raiseBlock :: Function -> [Slot] -> Int -> Block -> Syntax.BasicBlock
raiseBlock f slots index block =
  Syntax.BasicBlock
    { Syntax.blockLabel = raiseLabel <$> blockLabel block
    , Syntax.blockBody = allocations <> reads' <> body <> [terminator]
    }
  where
    name = blockName f block
    -- The slots are allocated once, in the entry block.
    allocations
      | index == 0 = map allocate slots
      | otherwise = []
    -- and read back at the head of the block that wants them.
    reads' = [readBack s | s <- slots, slotRead s == HeadOf name]
    body = concatMap (raiseInstruction slots) (blockInstructions block)
    terminator =
      Syntax.IOperation
        Nothing
        (terminatorOperation (blockTerminator block))
        (terminatorMetadata (blockTerminator block))
    raiseLabel label =
      Syntax.BlockLabel
        { Syntax.blockLabelName = label
        , Syntax.blockLabelComment = predecessorComment f label
        }

allocate :: Slot -> Syntax.Instruction
allocate s =
  Syntax.IOperation
    (Just (slotName s))
    ( OAlloca
        Syntax.Alloca
          { Syntax.allocaInalloca = False
          , Syntax.allocaType = slotType s
          , Syntax.allocaElementCount = Nothing
          , Syntax.allocaAlignment = Nothing
          , Syntax.allocaAddrSpace = Nothing
          }
    )
    []

readBack :: Slot -> Syntax.Instruction
readBack s =
  Syntax.IOperation
    (Just (slotLocal s))
    ( OLoad
        Syntax.Load
          { Syntax.loadVolatile = False
          , Syntax.loadType = slotType s
          , Syntax.loadPointer =
              TypedValue (TPointer Nothing) (VLocal (slotName s))
          , Syntax.loadAlignment = Nothing
          }
    )
    []

-- | One core instruction, which an assignment read back in its own block
-- turns into two: the write, and the read that follows it.
raiseInstruction :: [Slot] -> Instruction -> [Syntax.Instruction]
raiseInstruction slots i = case (instructionResult i, instructionOperation i) of
  (Just name, Assign value) ->
    Syntax.IOperation
      Nothing
      ( OStore
          Syntax.Store
            { Syntax.storeVolatile = False
            , Syntax.storeValue = value
            , Syntax.storePointer =
                TypedValue (TPointer Nothing) (VLocal (slotFor name))
            , Syntax.storeAlignment = Nothing
            }
      )
      (instructionMetadata i)
      : [readBack s | s <- slots, slotLocal s == name, slotRead s == AfterAssignment]
  (result, Perform operation) ->
    [Syntax.IOperation result operation (instructionMetadata i)]
  (Nothing, Assign _) ->
    -- An assignment to nothing has no effect and nothing to write it to.
    []
  where
    slotFor name =
      slotName
        (firstOr (Slot name (TInteger 8) AfterAssignment) [s | s <- slots, slotLocal s == name])

-- | The name of the memory a local lives in.  Named rather than numbered:
-- LLVM requires unnamed values to be numbered in increasing order, so
-- anything inserted has to carry a name to leave that numbering alone.
slotName :: Slot -> Name
slotName s = Name Bare ("olivine.slot." <> nameText (slotLocal s))

-- | The @; preds = %a, %b@ comment LLVM writes after a label.
--
-- Derived from the control flow graph rather than carried, which is what
-- having structural terminators buys: the comment states which blocks reach
-- this one, so a pass that changes control flow cannot leave it stale.
--
-- LLVM lists predecessors in reverse order of where the blocks appear, once
-- per edge rather than once per block, and writes @; No predecessors!@ for a
-- block nothing reaches.  An entry block gets no comment at all.
predecessorComment :: Function -> Name -> Maybe Text
predecessorComment f name
  | isEntry = Nothing
  | null predecessors = Just "; No predecessors!"
  | otherwise = Just ("; preds = " <> T.intercalate ", " (map reference predecessors))
  where
    isEntry = Just name == (blockLabel =<< listToMaybe (functionBlocks f))
    listToMaybe = foldr (\x _ -> Just x) Nothing
    predecessors =
      concat
        [ [blockName f b | target <- targetsOf (blockTerminator b), target == name]
        | b <- reverse (functionBlocks f)
        ]
    reference n = "%" <> renderName n

blockName :: Function -> Block -> Name
blockName f block = fromMaybe (entryName f) (blockLabel block)

-- | The number LLVM gives an unlabelled entry block.
--
-- LLVM numbers unnamed values in order, and a block takes a number like
-- anything else, so the entry block gets the one after the parameters.  A
-- parameter written @%0@ is an unnamed value whose number has been written
-- down rather than a parameter named zero, so it counts; one written @%x@ is
-- named and does not.
entryName :: Function -> Name
entryName f = Name Bare (T.pack (show (length numbered)))
  where
    numbered =
      [ ()
      | p <- Syntax.signatureParameters (functionSignature f)
      , maybe True (T.all isDigit . nameText) (Syntax.parameterName p)
      ]

targetsOf :: Terminator -> [Name]
targetsOf t = case terminatorOperation t of
  OBr target -> [target]
  OCondBr _ a b -> [a, b]
  OSwitch _ d cases -> d : map snd cases
  OIndirectBr _ ds -> ds
  _ -> []
