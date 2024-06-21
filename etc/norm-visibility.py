import etc
import java


def f(a):
    if not java.visibility(a):
        s = a.signature
        i = etc.indentation(s)
        s = s[:i] + "public " + s[i:]
        a.signature = s


for file in java.src_files():
    v = etc.read_lines(file)
    a = java.parse(v)
    a.walk(f)
    r = java.compose(a)
    if r != v:
        print(file)
        etc.write_lines(file, r)
