call %~dp0..\build.bat
if %errorlevel% neq 0 goto :eof

python C:\olivine\etc\minify_tptp.py "java -Xmx20g -cp %tmp% -ea --enable-preview Prover -t=60" %*
