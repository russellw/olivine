# Normalize visibility, change default to public
# Internal tool, designed for this project only
# Does NOT work for arbitrary Java code
import etc
import java


def f(a):
    if not java.visibility(a):
        s = a.sig
        i = etc.indentation(s)
        s = s[:i] + "public " + s[i:]
        a.sig = s


for file in java.src_files():
    v = etc.read_lines(file)
    a = java.parse(v)
    a.walk(f)
    r = java.compose(a)
    etc.write_lines(file, r)
