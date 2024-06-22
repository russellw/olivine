black .||exit /b
isort -p java -p python .||exit /b

google-java-format -i src/main/java/olivine/*.java||exit /b
google-java-format -i src/test/java/olivine/*.java||exit /b

for %%x in (test\*.c) do clang-format -i %%x||exit /b
for %%x in (test\*.cpp) do clang-format -i %%x||exit /b
git diff
