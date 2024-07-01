# Uppercase first letter of comments
# Internal tool, designed for this project only
# Does NOT work for arbitrary Python code
import re

import etc
import py


def f(s):
    r = re.match("( *# )([a-z])(.*)", s)
    if r:
        return f"{r[1]}{r[2].upper()}{r[3]}"
    return s


for file in py.src_files():
    v = etc.read_lines(file)
    for i in range(len(v)):
        if py.comment(v[i]) and not (i and py.comment(v[i - 1])):
            v[i] = f(v[i])
    etc.write_lines(file, v)
