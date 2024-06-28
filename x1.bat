call mvn compile||exit /b
clang -O2 -emit-llvm -S \t\a.c -o a1.ll||exit /b
type a1.ll
java -classpath target\classes -enableassertions olivine.Main a1.ll||exit /b
type a.ll
clang a.ll||exit /b
a
echo %errorlevel%
