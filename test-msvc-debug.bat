cl /std:c++17 /nologo /EHsc /Isrc /I\boost /W3 /WX /Foobj\ /Zi unit-tests.cpp src\*.cpp||exit /b
test
