del %tmp%\*.class
javac -cp %~dp0\lib\asm-9.4.jar -d %tmp% --enable-preview -source 18 %~dp0\src\*.java
