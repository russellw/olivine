# Sort labels in multilabel case
# Internal tool, designed for this project only
# Does NOT work for arbitrary Java code
import etc

for file in java.src_files():
    v = etc.read_lines(file)
    r = java.compose(a)
    if r != v:
        print(file)
        etc.write_lines(file, r)
