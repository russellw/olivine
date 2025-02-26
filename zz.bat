cls
ninja olivine.exe||exit /b
rem olivine %*
rem python integration-tests\all.py
rem type integration-tests\add\a.ll
clang -emit-llvm -S integration-tests\add\add.c||exit /b
olivine add.ll||exit /b
echo *** All is well ***
