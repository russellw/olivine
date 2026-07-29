-- | The verifier, on programs that pass and on programs that do not.
--
-- The corpus is the first half: every module in it, at every stage of the
-- pipeline, must have nothing wrong with it.  That is the check that says the
-- verifier is not simply wrong about what LLVM accepts — a rule stated too
-- strictly shows up here as a complaint about code clang emitted.
--
-- The second half is the other direction, and it is written by breaking a
-- program that passes.  A core program cannot be written down by hand without
-- a signature and a great deal else, and a verifier tested only on hand-built
-- rubble would be tested on programs the lowering could never produce.  So
-- each case takes something real, damages it in one place, and says what the
-- verifier should notice.
module Verify (verifyTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (corpusFiles, expectParse, readCorpusFile)
import Olivine.Core.Instruction
import Olivine.Core.Lower (lower)
import Olivine.Core.Program
import Olivine.Core.Verify
import Olivine.Pipeline (stages)
import Olivine.Syntax.Ast qualified as Syntax
import Olivine.Syntax.Instruction
  ( Binary (..)
  , BinaryOp (..)
  , InstructionFlag (..)
  , Load (..)
  )
import Olivine.Syntax.Name (Name (..), Quoting (..))
import Olivine.Syntax.Type (FloatKind (..), Type (..))
import Olivine.Syntax.Value (TypedValue (..), Value (..))

verifyTests :: IO TestTree
verifyTests = do
  names <- corpusFiles
  pure $
    testGroup
      "verify"
      [ testGroup
          "the corpus passes at every stage"
          [testCase name (clean name) | name <- names]
      , structureTests
      , referenceTests
      , typeTests
      , flagTests
      ]

-- | Nothing the pipeline does to a corpus module may leave it wrong.
--
-- Every stage, not just the last: a pass that breaks a program and a later one
-- that puts it back would pass a check on the output alone, and the point is
-- to name the pass rather than to know that something went wrong somewhere.
clean :: FilePath -> Assertion
clean name = do
  (_, parsed) <- readCorpusFile name
  sequence_
    [ assertEqual stage [] (map (T.unpack . renderProblem) (verify program))
    | (stage, program) <- stages parsed
    ]

-- * What a function is made of

structureTests :: TestTree
structureTests =
  testGroup
    "structure"
    [ testCase "a function that is right has nothing wrong with it" $
        expect arithmetic id []
    , testCase "a definition with no blocks" $
        expect arithmetic (\f -> f {functionBlocks = []}) [NoBlocks]
    , -- A label is the whole of a block's identity, so two blocks holding one
      -- are not two blocks — and the branch to what the second one was called
      -- now goes nowhere.
      testCase "two blocks with one label" $
        expect
          branching
          (atBlock 2 (\b -> b {blockLabel = Label 1}))
          [DuplicateBlock (Label 1), MissingBlock (Label 2)]
    , -- The body refers to its parameters by position, so a body naming fewer
      -- than the signature declares leaves one of them unreachable and the
      -- rest possibly misread.
      testCase "a parameter the body does not name" $
        expect
          arithmetic
          (\f -> f {functionParameters = take 1 (functionParameters f)})
          [ParameterCountDiffers 2 1, UndefinedLocal (Local 1)]
    ]

-- * What a branch and an operand refer to

referenceTests :: TestTree
referenceTests =
  testGroup
    "references"
    [ testCase "a branch to a block that is not there" $
        expect
          branching
          (atBlock 0 (atTerminator (retarget (swap (Label 1) (Label 9)))))
          [MissingBlock (Label 9)]
    , -- The entry block is the one block that may not be a destination: LLVM
      -- rejects a branch to it, and the raising leaves its label unwritten
      -- because nothing can name it.
      testCase "a branch to the entry block" $
        expect
          branching
          (atBlock 0 (atTerminator (retarget (swap (Label 1) (Label 0)))))
          [BranchToEntry]
    , -- The one check that reads the whole program.  Removing the declaration
      -- is what dead symbol elimination does to a symbol it believes nothing
      -- reaches, so this is the shape its mistake would take.
      testCase "a call to a symbol the program does not have" $
        expectOf
          calling
          (\program -> program {programEntries = filter (not . isDeclaration) (programEntries program)})
          [UndefinedGlobal (Name Bare "g")]
    , -- An opaque entry is a line the syntax layer cannot read, and what it
      -- holds may be a definition of anything.  So a program with one in it is
      -- not asked which symbols it has, rather than being asked and answering
      -- from what happens to have been understood.
      testCase "no symbol is missing while something is unread" $
        expectOf unread id []
    , testCase "an operand naming a local nothing defines" $
        expect
          arithmetic
          (atBlock 0 (atInstruction 0 (onBinary (\b -> b {binaryLeft = named (Local 9) (binaryLeft b)}))))
          [UndefinedLocal (Local 9)]
    , -- LLVM numbers an unnamed result itself, so this is legal in isolation
      -- and ruinous here: the raising issues the numbering, and a value it did
      -- not number puts every number after it one out.
      testCase "a value assigned to nothing" $
        expect
          arithmetic
          (atBlock 0 (atInstruction 0 (\i -> i {instructionResult = Nothing})))
          [ResultMissing (TInteger 32), UndefinedLocal (Local 2)]
    , testCase "a result named for something that produces none" $
        expect
          storing
          (atBlock 0 (atInstruction 0 (\i -> i {instructionResult = Just (Local 9)})))
          [ResultOfVoid]
    ]

-- * What the types say

typeTests :: TestTree
typeTests =
  testGroup
    "types"
    [ -- The core writes down what type a local has at each use and nowhere
      -- else, so a pass that rewrites one side of an operand and not the other
      -- leaves nothing but this to notice.
      testCase "a local read at a type it was not defined at" $
        expect
          arithmetic
          (atBlock 0 (atTerminator (onReturn (retyped (TInteger 64)))))
          [ LocalTypeDiffers (Local 2) (TInteger 32) (TInteger 64)
          , ReturnDiffers (TInteger 32) (TInteger 64)
          ]
    , testCase "operands of an addition that do not agree" $
        expect
          arithmetic
          (atBlock 0 (atInstruction 0 (onBinary (\b -> b {binaryRight = retyped (TInteger 64) (binaryRight b)}))))
          [ LocalTypeDiffers (Local 1) (TInteger 32) (TInteger 64)
          , Mismatched (TInteger 32) (TInteger 64)
          ]
    , testCase "an integer opcode on floating point operands" $
        expect
          floating
          (atBlock 0 (atInstruction 0 (onBinary (\b -> b {binaryOp = OpAdd}))))
          [Expected AnInteger (TFloat FFloat)]
    , testCase "a load through something that is not a pointer" $
        expect
          loading
          (atBlock 0 (atInstruction 0 (onLoad (\l -> l {loadPointer = retyped (TInteger 32) (loadPointer l)}))))
          [ LocalTypeDiffers (Local 0) (TPointer Nothing) (TInteger 32)
          , Expected APointer (TInteger 32)
          ]
    , testCase "a return that gives back nothing where something was promised" $
        expect
          arithmetic
          (atBlock 0 (atTerminator (\t -> t {terminatorTransfer = Ret Nothing})))
          [ReturnDiffers (TInteger 32) TVoid]
    , -- What the type stopped saying when constants stopped being a type of
      -- their own.  LLVM requires a case to be a constant; this is where that
      -- is asked.
      testCase "a switch case that is not a constant" $
        expect
          switching
          (atBlock 0 (atTerminator (onCases (named (Local 0)))))
          [CaseNotConstant]
    , -- That a field is there is a fact about the struct, which is named
      -- rather than written out, so answering needs the module's type
      -- definitions and not just the instruction.
      testCase "a field the struct does not have" $
        expect
          selecting
          (atBlock 0 (atInstruction 0 (onField (\field -> field {fieldIndex = 5}))))
          [FieldOutOfRange (TNamed (Name Bare "pair")) 5]
    ]

-- * What an operation may be qualified by

flagTests :: TestTree
flagTests =
  testGroup
    "flags"
    [ testCase "a wrapping flag on arithmetic that can wrap" $
        expect arithmetic (withFlags [FlagNSW]) []
    , -- @exact@ belongs to the divisions and shifts that can lose a bit; LLVM's
      -- own parser will not read it here, so nothing but a pass can write it.
      testCase "an exactness flag on an addition" $
        expect arithmetic (withFlags [FlagExact]) [FlagNotAllowed FlagExact]
    , testCase "a fast-math flag on integer arithmetic" $
        expect arithmetic (withFlags [FlagFast]) [FlagNotAllowed FlagFast]
    , testCase "a fast-math flag on floating point arithmetic" $
        expect floating (withFlags [FlagFast]) []
    ]
  where
    withFlags flags =
      atBlock 0 (atInstruction 0 (onBinary (\b -> b {binaryFlags = flags})))

-- * Programs to damage

arithmetic :: [Text]
arithmetic =
  [ "define i32 @f(i32 %a, i32 %b) {"
  , "  %c = add i32 %a, %b"
  , "  ret i32 %c"
  , "}"
  ]

floating :: [Text]
floating =
  [ "define float @f(float %a, float %b) {"
  , "  %c = fadd float %a, %b"
  , "  ret float %c"
  , "}"
  ]

loading :: [Text]
loading =
  [ "define i32 @f(ptr %p) {"
  , "  %v = load i32, ptr %p"
  , "  ret i32 %v"
  , "}"
  ]

storing :: [Text]
storing =
  [ "define void @f(ptr %p) {"
  , "  store i32 0, ptr %p"
  , "  ret void"
  , "}"
  ]

calling :: [Text]
calling =
  [ "declare i32 @g(i32)"
  , ""
  , "define i32 @f(i32 %a) {"
  , "  %c = call i32 @g(i32 %a)"
  , "  ret i32 %c"
  , "}"
  ]

-- | A module with a line the syntax layer does not read — @\@u@ is written
-- with neither @global@ nor @constant@ — and a call to a symbol nothing
-- declares.
unread :: [Text]
unread =
  [ "@u = i32 0"
  , ""
  , "define i32 @f() {"
  , "  %c = call i32 @h()"
  , "  ret i32 %c"
  , "}"
  ]

branching :: [Text]
branching =
  [ "define i32 @f(i1 %c) {"
  , "entry:"
  , "  br i1 %c, label %yes, label %no"
  , "yes:"
  , "  ret i32 1"
  , "no:"
  , "  ret i32 0"
  , "}"
  ]

switching :: [Text]
switching =
  [ "define i32 @f(i32 %x) {"
  , "  switch i32 %x, label %other [ i32 1, label %one ]"
  , "one:"
  , "  ret i32 10"
  , "other:"
  , "  ret i32 0"
  , "}"
  ]

selecting :: [Text]
selecting =
  [ "%pair = type { i32, i32 }"
  , ""
  , "define ptr @f(ptr %p) {"
  , "  %q = getelementptr %pair, ptr %p, i32 0, i32 1"
  , "  ret ptr %q"
  , "}"
  ]

-- * Saying what should be found

-- | Lower a module written inline, break the function in it, and say what the
-- verifier makes of the result.
expect :: [Text] -> (Function -> Function) -> [Complaint] -> Assertion
expect source damage = expectOf source (onFunctions damage)
  where
    onFunctions change program =
      program {programEntries = map (entry change) (programEntries program)}
    entry change (EFunction f) = EFunction (change f)
    entry _ retained = retained

-- | The same, where what is damaged is the program rather than a function in
-- it.
expectOf :: [Text] -> (Program -> Program) -> [Complaint] -> Assertion
expectOf source damage wanted = do
  parsed <- expectParse "<inline>" (T.unlines source)
  let found = verify (damage (lower parsed))
  assertEqual
    (unlines (map (T.unpack . renderProblem) found))
    wanted
    (map problemComplaint found)

isDeclaration :: Entry -> Bool
isDeclaration (ERetained (Syntax.EDeclare _)) = True
isDeclaration _ = False

-- * Reaching into a function

atBlock :: Int -> (Block -> Block) -> Function -> Function
atBlock n change f =
  f {functionBlocks = zipWith apply [0 ..] (functionBlocks f)}
  where
    apply i b = if i == n then change b else b

atInstruction :: Int -> (Instruction -> Instruction) -> Block -> Block
atInstruction n change b =
  b {blockInstructions = zipWith apply [0 ..] (blockInstructions b)}
  where
    apply i x = if i == n then change x else x

atTerminator :: (Terminator -> Terminator) -> Block -> Block
atTerminator change b = b {blockTerminator = change (blockTerminator b)}

onBinary :: (Binary (TypedValue Local) -> Binary (TypedValue Local)) -> Instruction -> Instruction
onBinary change i = case instructionOperation i of
  OBinary b -> i {instructionOperation = OBinary (change b)}
  _ -> i

onLoad :: (Load (TypedValue Local) -> Load (TypedValue Local)) -> Instruction -> Instruction
onLoad change i = case instructionOperation i of
  OLoad l -> i {instructionOperation = OLoad (change l)}
  _ -> i

onField :: (Field (TypedValue Local) -> Field (TypedValue Local)) -> Instruction -> Instruction
onField change i = case instructionOperation i of
  OField field -> i {instructionOperation = OField (change field)}
  _ -> i

onReturn :: (TypedValue Local -> TypedValue Local) -> Terminator -> Terminator
onReturn change t = case terminatorTransfer t of
  Ret value -> t {terminatorTransfer = Ret (change <$> value)}
  _ -> t

onCases :: (TypedValue Local -> TypedValue Local) -> Terminator -> Terminator
onCases change t = case terminatorTransfer t of
  Switch value target cases ->
    t {terminatorTransfer = Switch value target [(change x, label) | (x, label) <- cases]}
  _ -> t

-- | The same operand at another type, and the same type naming another local:
-- the two halves a pass can rewrite one of.
retyped :: Type -> TypedValue local -> TypedValue local
retyped t value = value {typedValueType = t}

named :: local -> TypedValue local -> TypedValue local
named local value = value {typedValue = VLocal local}

swap :: Eq a => a -> a -> a -> a
swap this that x = if x == this then that else x
