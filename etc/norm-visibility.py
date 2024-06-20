import java

import etc

for file in java.src_files():
    v = etc.read_lines(file)
    a = java.parse(v)
    print(a)
