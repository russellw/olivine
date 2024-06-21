import java

import etc

for file in java.src_files():
    print(file)
    v = etc.read_lines(file)
    a = java.parse(v)
    etc.write_lines(file, java.compose(a))
