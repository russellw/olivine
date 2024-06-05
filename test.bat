rem call mvn test||exit /b
call mvn compile||exit /b
clang -emit-llvm -S test.c
java -cp target\classes olivine.Main test.ll||exit /b
type a.ll
