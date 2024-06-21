# Sort members of classes etc
# Internal tool, designed for this project only
# Does NOT work for arbitrary Java code
import etc
import java

for file in java.src_files():
    v = etc.read_lines(file)
    a = java.parse(v)
    a.sort()
    r = java.compose(a)
    if r != v:
        print(file)
        etc.write_lines(file, r)
