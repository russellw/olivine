# Sort members of classes etc, normalize blank lines
# Internal tool, designed for this project only
# Does NOT work for arbitrary Java code
import etc
import java

for file in java.src_files():
    v = etc.read_lines(file)
    a = java.parse(v)
    a.sort()
    r = java.compose(a)
    etc.write_lines(file, r)
