clang-format -i --style=file *.cpp src/*.h src/*.cpp||exit /b
do-all-recur . sort-cases -w||exit /b
git diff
