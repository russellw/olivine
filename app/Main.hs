-- | Command line driver: read LLVM IR, optimize, write LLVM IR.
module Main (main) where

import Data.Text.IO qualified as TIO
import Options.Applicative
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import Olivine.Pipeline (optimize)
import Olivine.Syntax.Parser (parseModule, renderParseError)
import Olivine.Syntax.Printer (renderModule)

data Options = Options
  { optInput :: FilePath
  -- ^ @-@ means standard input.
  , optOutput :: Maybe FilePath
  -- ^ 'Nothing' means standard output.
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
      let result = renderModule (optimize m)
      maybe (TIO.putStr result) (`TIO.writeFile` result) (optOutput opts)
