@echo off

black .||exit /b
isort .||exit /b

for /r %%f in (*.cpp *.h *.c) do (
    clang-format -i --style=file "%%f"||exit /b
	sort-enums -w "%%f"||exit /b
	sort-blocks -w "%%f"||exit /b
	sort-fns-cpp -w "%%f"||exit /b
	unblank-case -w "%%f"||exit /b
	sort-cases -w "%%f"||exit /b
	rem sort-case-blocks -w "%%f"||exit /b
)

git diff
