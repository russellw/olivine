-- | The @phi@ instruction.
--
-- Read faithfully and no more.  Turning a phi into stores and a load is what
-- the core representation is for, and doing any of it here would mean the
-- round trip could no longer be checked by comparing output with input.
module Phis (phiTests) where

import Data.Text (Text)
import Data.Text qualified as T
import Test.Tasty
import Test.Tasty.HUnit

import Corpus (expectParse)
import Olivine.Syntax.Ast
import Olivine.Syntax.Function
import Olivine.Syntax.Instruction
import Olivine.Syntax.Name
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Type
import Olivine.Syntax.Value

-- | Lines in the spelling LLVM emits, with what each should parse to.
emitted :: [(Text, Operation)]
emitted =
  [ ( "  %r = phi i32 [ %x, %b1 ], [ %y, %b2 ]"
    , phi
        (TInteger 32)
        [ (VLocal (Name Bare "x"), Name Bare "b1")
        , (VLocal (Name Bare "y"), Name Bare "b2")
        ]
    )
  , -- Constants arrive along edges as readily as locals do.
    ( "  %r = phi i32 [ 0, %b1 ], [ -1, %b2 ]"
    , phi
        (TInteger 32)
        [(VInteger 0, Name Bare "b1"), (VInteger (-1), Name Bare "b2")]
    )
  , ( "  %r = phi i1 [ false, %b1 ], [ true, %b2 ]"
    , phi
        (TInteger 1)
        [(VBoolean False, Name Bare "b1"), (VBoolean True, Name Bare "b2")]
    )
  , ( "  %r = phi ptr [ null, %b1 ], [ %p, %b2 ]"
    , phi
        (TPointer Nothing)
        [(VNull, Name Bare "b1"), (VLocal (Name Bare "p"), Name Bare "b2")]
    )
  , ( "  %r = phi i32 [ poison, %b1 ], [ %x, %b2 ]"
    , phi
        (TInteger 32)
        [(VPoison, Name Bare "b1"), (VLocal (Name Bare "x"), Name Bare "b2")]
    )
  , -- More than two predecessors, which is the shape a switch produces.
    ( "  %r = phi i32 [ 10, %b1 ], [ 20, %b2 ], [ 30, %b3 ], [ -1, %b4 ]"
    , phi
        (TInteger 32)
        [ (VInteger 10, Name Bare "b1")
        , (VInteger 20, Name Bare "b2")
        , (VInteger 30, Name Bare "b3")
        , (VInteger (-1), Name Bare "b4")
        ]
    )
  , -- A single predecessor is legal, if unusual.
    ("  %r = phi i32 [ %x, %b1 ]", phi (TInteger 32) [(VLocal (Name Bare "x"), Name Bare "b1")])
  , -- Vectors, as the corpus has them.
    ( "  %r = phi <4 x i32> [ zeroinitializer, %b1 ], [ %v, %b2 ]"
    , phi
        (TVector FixedWidth 4 (TInteger 32))
        [ (VZeroInitializer, Name Bare "b1")
        , (VLocal (Name Bare "v"), Name Bare "b2")
        ]
    )
  , -- Fast-math flags, which a floating point phi may carry.
    ( "  %r = phi fast double [ %d, %b1 ], [ %e, %b2 ]"
    , OPhi
        Phi
          { phiFlags = [FlagFast]
          , phiType = TFloat FDouble
          , phiIncoming =
              [ (VLocal (Name Bare "d"), Name Bare "b1")
              , (VLocal (Name Bare "e"), Name Bare "b2")
              ]
          }
    )
  ]
  where
    phi t incoming =
      OPhi Phi {phiFlags = [], phiType = t, phiIncoming = incoming}

-- | Malformed, and so left opaque.
rejected :: [Text]
rejected =
  [ "  %r = phi i32"
  , "  %r = phi i32 [ %x ]"
  , "  %r = phi i32 [ %x, %b1 "
  , "  %r = phi [ %x, %b1 ]"
  , -- A branch target takes the label keyword; a phi predecessor does not.
    "  %r = phi i32 [ %x, label %b1 ]"
  ]

phiTests :: TestTree
phiTests =
  testGroup
    "phi"
    [ testGroup
        "round trip"
        [testCase (name line) (roundTrips line) | (line, _) <- emitted]
    , testGroup
        "parsed shape"
        [testCase (name line) (parsesTo line operation) | (line, operation) <- emitted]
    , testGroup
        "malformed stays opaque"
        [testCase (name line) (staysOpaque line) | line <- rejected]
    , testGroup
        "a phi is not a terminator"
        [ testCase (name line) (isTerminator operation @?= False)
        | (line, operation) <- emitted
        ]
    ]
  where
    name = T.unpack . T.strip

-- | A phi must have exactly one entry for each predecessor of its block, so
-- the wrapper gives it as many predecessor blocks as the line has entries.
--
-- The blocks are named so that they cannot collide with the parameters: LLVM
-- keeps labels and values in one namespace, so a block named @c@ and a
-- parameter named @%c@ are a conflict rather than two things.
inFunction :: Text -> Text
inFunction line =
  T.unlines $
    [ "define void @f(i1 %c, i32 %x, i32 %y, ptr %p, double %d, double %e, <4 x i32> %v) {"
    , "entry:"
    , "  switch i32 %x, label %b1 ["
    ]
      <> ["    i32 " <> number n <> ", label %b" <> number n | n <- [2 .. edges]]
      <> ["  ]"]
      <> concat [["", "b" <> number n <> ":", "  br label %join"] | n <- [1 .. edges]]
      <> ["", "join:", line, "  ret void", "}"]
  where
    edges = max 1 (T.count "[ " line)
    number = T.pack . show

roundTrips :: Text -> Assertion
roundTrips line = do
  let source = inFunction line
  parsed <- expectParse "<inline>" source
  renderModule parsed @?= source

parsesTo :: Text -> Operation -> Assertion
parsesTo line operation = do
  instructions <- instructionsIn (inFunction line)
  filter isPhi instructions @?= [IOperation (Just (Name Bare "r")) operation []]
  where
    isPhi (IOperation _ (OPhi _) _) = True
    isPhi _ = False

staysOpaque :: Text -> Assertion
staysOpaque line = do
  let source = inFunction line
  instructions <- instructionsIn source
  case [raw | IOpaque raw <- instructions] of
    [raw] -> raw @?= line
    other -> assertFailure ("expected one opaque instruction, got " <> show other)
  parsed <- expectParse "<inline>" source
  renderModule parsed @?= source

instructionsIn :: Text -> IO [Instruction]
instructionsIn source = do
  parsed <- expectParse "<inline>" source
  case [d | EDefine d <- moduleEntries parsed] of
    [d] -> pure (concatMap blockBody (definitionBlocks d))
    _ -> assertFailure "expected exactly one definition"
