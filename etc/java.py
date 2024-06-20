import os
import re

import etc


def src_files():
    directory = os.path.join("src", "main", "java", "olivine")
    java_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".java"):
                file_path = os.path.join(root, file)
                java_files.append(file_path)
    return java_files


def parse(v):
    i = 0

    # package
    assert v[i].startswith("package")
    i += 1

    # import
    while not v[i] or v[i].startswith("import"):
        i += 1
    header = v[:i]

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
        if re.search(r"\benum\b", signature):
            a = Enum(header, signature)
            while not closes(dent, v[i]):
                a.members.append(v[i])
                i += 1
            i += 1
            return a

        # Class
        if re.search(r"\bclass\b", signature):
            dent = etc.indentation(signature)
            a = Class(header, signature)
            while 1:
                while not v[i]:
                    i += 1
                if closes(dent, v[i]):
                    break
                a.members.append(parse_member())
            i += 1
            return a

        # Method
        if re.match(r" *[\w ]*\(.*\) {$", signature):
            a = Method(header, signature)
            while not closes(dent, v[i]):
                a.body.append(v[i])
                i += 1
            i += 1
            return a

        raise Exception(f"{i}: {signature}")

    a = parse_member()
    a.header = header + a.header
    return a


def closes(dent, s):
    return s == " " * dent + "}"


class Class:
    def __init__(self, header, signature):
        self.header = header
        self.signature = signature
        self.members = []


class Method:
    def __init__(self, header, signature):
        self.header = header
        self.signature = signature
        self.body = []


class Enum:
    def __init__(self, header, signature):
        self.header = header
        self.signature = signature
        self.members = []
