rem call mvn test||exit /b
call mvn compile||exit /b
java -cp target\classes olivine.Main test.c||exit /b
type a.ll
