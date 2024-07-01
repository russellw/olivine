# Sort Python functions and classes, normalize blank lines
# Internal tool, designed for this project only
# Does NOT work for arbitrary Python code
import etc
import py

for file in py.src_files():
    v = etc.read_lines(file)
    a = py.parse(v)
    py.sort(a)
    v = py.compose(a)
    etc.write_lines(file, v)
