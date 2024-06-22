import os


def get_files(directory, extension, r):
    for entry in os.scandir(directory):
        if entry.is_file() and entry.name.endswith(extension):
            r.append(os.path.join(directory, entry.name))


def read_lines(file):
    with open(file) as f:
        return [s.rstrip() for s in f]


def write_lines(file, v):
    with open(file, "w", newline="\n") as f:
        for s in v:
            f.write(s + "\n")


def indentation(s):
    if not s:
        return 1000
    i = 0
    while s[i] == " ":
        i += 1
    assert s[i] != "\t"
    return i
