# Uppercase first letter of comments
# Internal tool, designed for this project only
# Does NOT work for arbitrary Python code
import etc
import python

for file in python.src_files():
    v = etc.read_lines(file)
    a = python.parse(v)
    python.sort(a)
    v = python.compose(a)
    etc.write_lines(file, v)
