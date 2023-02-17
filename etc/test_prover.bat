call %~dp0..\build.bat
if %errorlevel% neq 0 goto :eof

python %~dp0\test_prover.py "java -Xmx20g -cp %tmp% -ea --enable-preview Prover" %*
