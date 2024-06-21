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

    # Package
    assert v[i].startswith("package")
    i += 1

    # Imports or comments
    while not v[i] or v[i].startswith("import") or v[i].startswith("//"):
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
        dent = etc.indentation(signature)
        i += 1

        # Enum
        if re.search(r"\benum \w", signature):
            a = Enum(header, signature)
            while not closes(dent, v[i]):
                a.members.append(v[i])
                i += 1
            i += 1
            return a

        # Empty class
        if re.search(r"\bclass \w.*{}$", signature):
            return Class(header, signature)

        # Class
        if re.search(r"\bclass \w", signature):
            a = Class(header, signature)
            while 1:
                while not v[i]:
                    i += 1
                if closes(dent, v[i]):
                    break
                a.members.append(parse_member())
            i += 1
            return a

        # Empty method
        if re.search(r"\w\(.*\) .*{}$", signature):
            return Method(header, signature)

        # Method
        if re.search(r"\w\(.*\) .*{$", signature):
            a = Method(header, signature)
            while not closes(dent, v[i]):
                a.body.append(v[i])
                i += 1
            i += 1
            return a

        # One-line field
        if signature.endswith(";"):
            return Field(header, signature)

        # Multiline field
        if signature.endswith("="):
            a = Field(header, signature)
            while dent < etc.indentation(v[i]):
                a.value.append(v[i])
                i += 1
            while not a.value[-1]:
                a.value.pop()
            return a

        raise Exception(f"{i}: {signature}")

    a = parse_member()
    a.header = header + a.header
    return a


def closes(dent, s):
    return s == " " * dent + "}"


def compose(a):
    r = []
    a.compose(r)
    return r


def separate(a, b):
    if not isinstance(a, Field):
        return True
    if not isinstance(b, Field):
        return True
    return a.category() != b.category()


class Class:
    def __init__(self, header, signature):
        self.header = header
        self.signature = signature
        self.members = []

    def category(self):
        return "class"

    def compose(self, r):
        r.extend(self.header)
        r.append(self.signature)
        for i in range(len(self.members)):
            a = self.members[i]
            if i and separate(self.members[i - 1], a):
                r.append("")
            a.compose(r)
        if not self.signature.endswith("}"):
            r.append(" " * etc.indentation(self.signature) + "}")


class Field:
    def __init__(self, header, signature):
        self.header = header
        self.signature = signature
        self.value = []

    def category(self):
        return "field"

    def compose(self, r):
        r.extend(self.header)
        r.append(self.signature)
        r.extend(self.value)


class Method:
    def __init__(self, header, signature):
        self.header = header
        self.signature = signature
        self.body = []

    def category(self):
        return "method"

    def compose(self, r):
        r.extend(self.header)
        r.append(self.signature)
        r.extend(self.body)
        if not self.signature.endswith("}"):
            r.append(" " * etc.indentation(self.signature) + "}")


class Enum:
    def __init__(self, header, signature):
        self.header = header
        self.signature = signature
        self.members = []

    def category(self):
        return "enum"

    def compose(self, r):
        r.extend(self.header)
        r.append(self.signature)
        r.extend(self.members)
        if not self.signature.endswith("}"):
            r.append(" " * etc.indentation(self.signature) + "}")
