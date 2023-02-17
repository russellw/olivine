call %~dp0..\build.bat
if %errorlevel% neq 0 goto :eof

javac -cp %tmp%;%~dp0..\lib\asm-9.4.jar -d %tmp% --enable-preview -source 18 %~dp0\*.java
if %errorlevel% neq 0 goto :eof

python %~dp0\test.py %*
