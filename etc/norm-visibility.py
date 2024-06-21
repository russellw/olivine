import etc
import java


def f(a):
    if not java.visibility(a):
        s = a.signature


for file in java.src_files():
    v = etc.read_lines(file)
    a = java.parse(v)
    r = java.compose(a)
    if r != v:
        print(file)
        etc.write_lines(file, r)
