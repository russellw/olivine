-- | Command line driver: read LLVM IR, optimize, write LLVM IR.
module Main (main) where

import Data.Maybe (listToMaybe)
import Data.Text.IO qualified as TIO
import Options.Applicative
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import Olivine.Core.Verify (Problem, renderProblem, verify)
import Olivine.Pipeline (optimize, stages)
import Olivine.Syntax.Ast (Module)
import Olivine.Syntax.Parser (parseModule, renderParseError)
import Olivine.Syntax.Printer (renderModule)

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
    Right m -> case if optVerify opts then broken m else Nothing of
      Just (stage, problems) -> do
        hPutStrLn stderr ("olivine: " <> stage <> ":")
        mapM_ (TIO.hPutStrLn stderr . renderProblem) problems
        exitFailure
      Nothing -> do
        let result = renderModule (optimize m)
        maybe (TIO.putStr result) (`TIO.writeFile` result) (optOutput opts)

-- | The first point at which the program is wrong, and what is wrong with it.
--
-- The first, because a pass handed a broken program will be blamed for what it
-- was given: what names the culprit is where the problems start, and
-- everything after that is a consequence.
broken :: Module -> Maybe (String, [Problem])
broken m =
  listToMaybe
    [ (stage, problems)
    | (stage, program) <- stages m
    , let problems = verify program
    , not (null problems)
    ]
