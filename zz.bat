cls
ninja olivine.exe||exit /b
rem olivine %*
python integration-tests\all.py
type integration-tests\add\a.ll
