call mvn compile||exit /b
clang -emit-llvm -S \t\a.c -o a1.ll||exit /b
java -classpath target\classes -enableassertions olivine.Main a1.ll||exit /b
type a.ll
clang a.ll
