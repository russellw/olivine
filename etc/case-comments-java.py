# Uppercase first letter of comments
# Internal tool, designed for this project only
# Does NOT work for arbitrary Java code
import re

import etc
import java


def f(s):
    r = re.match("( *// )([a-z])(.*)", s)
    if r:
        return f"{r[1]}{r[2].upper()}{r[3]}"
    return s


for file in java.src_files():
    v = etc.read_lines(file)
    for i in range(len(v)):
        if java.comment(v[i]) and not (i and java.comment(v[i - 1])):
            v[i] = f(v[i])
    etc.write_lines(file, v)
