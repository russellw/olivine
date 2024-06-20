import etc

for file in etc.src_files():
    v = etc.read_lines(file)
    print(etc.parse_java(v))
