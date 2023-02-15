javac -d %tmp% --enable-preview -source 18 C:\olivine\src\*.java
if %errorlevel% neq 0 goto :eof

python C:\olivine\etc\test_prover.py "java -Xmx20g -cp %tmp% -ea --enable-preview Prover" %*
