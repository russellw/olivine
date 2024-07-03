rem Python
python etc\case-comments-py.py||exit /b

python etc\sort-py.py||exit /b
black .||exit /b
isort .||exit /b

rem Java
python etc\case-comments-java.py||exit /b

python etc\norm-visibility.py||exit /b
google-java-format -i src/main/java/olivine/*.java||exit /b

python etc\sort-case-labels.py||exit /b
google-java-format -i src/main/java/olivine/*.java||exit /b

python etc\sort-cases.py||exit /b
google-java-format -i src/main/java/olivine/*.java||exit /b

python etc\sort-members.py||exit /b
google-java-format -i src/main/java/olivine/*.java||exit /b

rem Check the results
git diff
