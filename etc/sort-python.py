# Sort Python functions and classes, normalize blank lines
# Internal tool, designed for this project only
# Does NOT work for arbitrary Python code
import python

import etc

for file in python.src_files():
    v = etc.read_lines(file)
    a = python.parse(v)
    python.sort(a)
    v = python.compose(a)
    etc.write_lines(file, v)
