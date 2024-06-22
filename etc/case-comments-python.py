# Uppercase first letter of comments
# Internal tool, designed for this project only
# Does NOT work for arbitrary Python code
import re

import etc
import python


def f(s):
    r = re.match("( *# )([a-z])(.*)", s)
    if r:
        return f"{r[1]}{r[2].upper()}{r[3]}"
    return s


for file in python.src_files():
    v = etc.read_lines(file)
    v = map(f, v)
    etc.write_lines(file, v)
