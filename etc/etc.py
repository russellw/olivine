import os
import re


def src_files():
    directory = os.path.join("src", "main", "java", "olivine")
    java_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".java"):
                file_path = os.path.join(root, file)
                java_files.append(file_path)
    return java_files


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


def parse_java(v):
    i = 0
    while not is_class_start(v[i]) and not is_enum_start(v[i]):
        i += 1
    header = v[:i]

    if is_enum_start(v[i]):
        j = i
        while v[j] != "}":
            j += 1

    def parse_class():
        assert is_class_start(v[i])
        assert v[i].endswith("{")

    def parse_member():
        nonlocal i

        # Comments
        j = i
        while re.match(r" *//", v[j]):
            j += 1

        # Annotations
        while re.match(r" *@", v[j]):
            j += 1
        header = v[i:j]
        i = j

        # Signature
        assert re.match(r" *\w", v[i])
        signature = v[i]
        i += 1

        # Enum
        if is_enum_start(signature):
            a = Enum(header, signature)
            while re.match(r" *\w,$", v[i]):
                a.members.append(v[i])
                i += 1
            assert re.match(r" *}$", v[i])
            assert indentation(signature) == indentation(v[i])
            i += 1
            return a

        # Class
        if is_class_start(signature):
            dent = indentation(signature)
            a = Class(header, signature)
            while 1:
                while not v[i]:
                    i += 1
                if closes(dent, v[i]):
                    break
                a.members.append(parse_member())
            assert re.match(r" *}$", v[i])
            assert indentation(signature) == indentation(v[i])
            i += 1
            return a

        # Method
        if re.match(r" *[\w ]*\(.*\) {$", signature):
            pass

    return header


def closes(dent, s):
    return s == " " * dent + "}"


class Class:
    def __init__(self, header, signature):
        self.header = header
        self.signature = signature
        self.members = []


class Enum:
    def __init__(self, header, signature):
        self.header = header
        self.signature = signature
        self.members = []
