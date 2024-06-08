google-java-format -i src/main/java/olivine/*.java
google-java-format -i src/test/java/olivine/*.java
black .
for %%x in (test\*.c) do clang-format -i %%x
for %%x in (test\*.cpp) do clang-format -i %%x
git diff
