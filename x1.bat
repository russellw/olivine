call mvn compile||exit /b
clang -O2 -emit-llvm -S \t\a.c -o a1.ll||exit /b
type a1.ll
clang a1.ll -o a1.exe||exit /b
java -classpath target\classes -enableassertions olivine.Main a1.ll||exit /b
type a.ll
clang a.ll||exit /b
a1 123
a 123
echo %errorlevel%
