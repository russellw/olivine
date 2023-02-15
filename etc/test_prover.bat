R:
cd \

javac -d . --enable-preview -source 18 C:\olivine\src\*.java
if %errorlevel% neq 0 goto :eof

python C:\olivine\etc\test_prover.py "java -Xmx20g -ea --enable-preview Prover -t=60" %*
