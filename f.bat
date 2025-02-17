clang-format -i --style=file *.cpp src/*.h src/*.cpp||exit /b
sort-enums -w *.cpp src/*.h src/*.cpp||exit /b
sort-fns-cpp -w *.cpp src/*.h src/*.cpp||exit /b
do-all-recur . sort-cases -w||exit /b
do-all-recur . sort-case-blocks -w||exit /b
git diff
