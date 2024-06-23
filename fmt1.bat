rem Python
python etc\case-comments-python.py||exit /b

python etc\sort-python.py||exit /b
black .||exit /b
isort .||exit /b

rem Check the results
git diff
