-- | Command line driver: read LLVM IR, optimize, write LLVM IR.
module Main (main) where

import Data.Maybe (listToMaybe)
import Data.Text (Text)
import Data.Text.IO qualified as TIO
import Options.Applicative
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import Olivine.Core.Program (Program)
import Olivine.Core.Raise (raise)
import Olivine.Core.Verify qualified as Core
import Olivine.Pipeline (stages)
import Olivine.Syntax.Ast (Module)
import Olivine.Syntax.Parser (parseModule, renderParseError)
import Olivine.Syntax.Printer (renderModule)
import Olivine.Syntax.Verify qualified as Syntax

data Options = Options
  { optInput :: FilePath
  -- ^ @-@ means standard input.
  , optOutput :: Maybe FilePath
  -- ^ 'Nothing' means standard output.
  , optVerify :: Bool
  -- ^ Check the core program as it is read and after each pass.
  }

options :: Parser Options
options =
  Options
    <$> strArgument
      ( metavar "INPUT"
          <> value "-"
          <> showDefault
          <> help "LLVM IR to read, or - for standard input"
      )
    <*> optional
      ( strOption
          ( long "output"
              <> short 'o'
              <> metavar "FILE"
              <> help "Where to write the result (default: standard output)"
          )
      )
    <*> switch
      ( long "verify"
          <> help "Check the program as it is read and after each pass, and write nothing if it is wrong"
      )

main :: IO ()
main = run =<< execParser opts
  where
    opts =
      info
        (options <**> helper)
        ( fullDesc
            <> header "olivine - a whole-program optimizer for LLVM IR"
        )

run :: Options -> IO ()
run opts = do
  let input = optInput opts
  source <- if input == "-" then TIO.getContents else TIO.readFile input
  case parseModule input source of
    Left err -> do
      hPutStrLn stderr (renderParseError err)
      exitFailure
    Right m -> do
      let core = stages m
          result = raise (snd (last core))
      case if optVerify opts then broken m core result else Nothing of
        Just (stage, problems) -> do
          hPutStrLn stderr ("olivine: " <> stage <> ":")
          mapM_ (TIO.hPutStrLn stderr) problems
          exitFailure
        Nothing -> do
          let written = renderModule result
          maybe (TIO.putStr written) (`TIO.writeFile` written) (optOutput opts)

-- | The first point at which the program is wrong, and what is wrong with it.
--
-- The first, because a pass handed a broken program will be blamed for what it
-- was given: what names the culprit is where the problems start, and
-- everything after that is a consequence.
--
-- The two ends are judged by the syntax verifier and everything between them
-- by the core one, each asking what only it can see.  Reading comes first
-- because a module that arrives broken is not the optimizer's doing, and
-- writing comes last because a module that leaves broken is.
broken :: Module -> [(String, Program)] -> Module -> Maybe (String, [Text])
broken m core result =
  listToMaybe
    [ (stage, problems)
    | (stage, problems) <- checks
    , not (null problems)
    ]
  where
    checks =
      ("as read", map Syntax.renderProblem (Syntax.verify m))
        : [ (stage, map Core.renderProblem (Core.verify program))
          | (stage, program) <- core
          ]
          <> [("as written", map Syntax.renderProblem (Syntax.verify result))]
