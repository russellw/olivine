import os
import re


def read_lines(file):
    with open(file) as f:
        return [s.rstrip() for s in f]


def write_lines(file, v):
    with open(file, "w", newline="\n") as f:
        for s in v:
            f.write(s + "\n")


def is_class_start(s):
    return re.search(r"\bclass\b", s)


def is_enum_start(s):
    return re.search(r"\benum\b", s)


def indentation(s):
    i = 0
    while s[i] == " ":
        i += 1
    assert s[i] != "\t"
    return i
