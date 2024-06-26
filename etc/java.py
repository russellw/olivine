import os
import re

import etc


class Class:
    def __init__(self, header, sig):
        self.header = header
        self.sig = sig
        self.members = []

        # Name
        r = re.search(r"\bclass (\w+)", sig)
        self.name = r[1]

    def __repr__(self):
        return self.name

    def category(self):
        return "class"

    def compose(self, r):
        r.extend(self.header)
        r.append(self.sig)
        for i in range(len(self.members)):
            a = self.members[i]
            if i and separate(self.members[i - 1], a):
                r.append("")
            a.compose(r)
        if not self.sig.endswith("}"):
            r.append("}")

    def sort(self):
        for a in self.members:
            a.sort()
        self.members.sort(key=key)

    def walk(self, f):
        for a in self.members:
            a.walk(f)
        f(self)


class Enum:
    def __init__(self, header, sig):
        self.header = header
        self.sig = sig
        self.members = []

        # Name
        r = re.search(r"\benum (\w+)", sig)
        self.name = r[1]

    def __repr__(self):
        return self.name

    def category(self):
        return "enum"

    def compose(self, r):
        r.extend(self.header)
        r.append(self.sig)
        r.extend(self.members)
        if not self.sig.endswith("}"):
            r.append("}")

    def sort(self):
        self.members.sort()

    def walk(self, f):
        f(self)


class Field:
    def __init__(self, header, sig):
        self.header = header
        self.sig = sig
        self.value = []

        # Name
        r = re.search(r"(\w+) =", sig)
        if r:
            self.name = r[1]
        else:
            r = re.search(r"(\w+);", sig)
            self.name = r[1]

    def __repr__(self):
        return self.name

    def category(self):
        if re.search(r"\bstatic\b", self.sig):
            if re.search(r"\bfinal int\b", self.sig):
                return "constant"
            return "static field"
        return "field"

    def compose(self, r):
        r.extend(self.header)
        r.append(self.sig)
        r.extend(self.value)

    def sort(self):
        pass

    def walk(self, f):
        f(self)


class FieldClass:
    def __init__(self, header, sig, sig1):
        self.header = header
        self.sig = sig
        self.sig1 = sig1
        self.members = []

        # Name
        r = re.search(r"(\w+) =", sig)
        self.name = r[1]

    def __repr__(self):
        return self.name

    def category(self):
        return "field class"

    def compose(self, r):
        r.extend(self.header)
        r.append(self.sig)
        r.append(self.sig1)
        for i in range(len(self.members)):
            a = self.members[i]
            if i and separate(self.members[i - 1], a):
                r.append("")
            a.compose(r)
        r.append("};")

    def sort(self):
        for a in self.members:
            a.sort()
        self.members.sort(key=key)

    def walk(self, f):
        for a in self.members:
            a.walk(f)
        f(self)


class Method:
    def __init__(self, header, sig):
        self.header = header
        self.sig = sig
        self.body = []

        # Name
        r = re.search(r"(\w+)\(.*\)", sig)
        self.name = r[1]

    def __repr__(self):
        return self.name

    def category(self):
        return "method"

    def compose(self, r):
        r.extend(self.header)
        r.append(self.sig)
        compose1(self.body, r)
        if self.sig[-1] not in ";}":
            r.append("}")

    def sort(self):
        pass

    def walk(self, f):
        f(self)


def category_rank(a):
    s = a.category()
    ranks = [
        "constant",
        "class",
        "field class",
        "static field",
        "field",
        "method",
    ]
    for i in range(len(ranks)):
        if s == ranks[i]:
            return i
    raise Exception(s)


def closes(dent, s):
    return s == " " * dent + "}"


def closes_semi(dent, s):
    return s == " " * dent + "};"


def comment(s):
    return re.match(" *//", s)


def compose(a):
    r = []
    a.compose(r)
    return r


def compose1(v, r):
    for i in range(len(v)):
        a = v[i]
        if i and separate1(v[i - 1], a):
            r.append("")
        r.append(a)


def key(a):
    return category_rank(a), etc.quasinumeric_key(a.name), a.sig


def lex(s, i):
    while s[i].isspace():
        i += 1
    j = i
    if s[j].isalnum():
        while s[j].isalnum() or s[j] == "_":
            j += 1
    elif s[j] in "'\"":
        q = s[j]
        j += 1
        while s[j] != q:
            if s[j] == "\\":
                j += 1
            j += 1
        j += 1
    elif s[j : j + 2] == "->":
        j += 2
    else:
        j += 1
    return i, j


def parse(v):
    v = [s for s in v if s]
    i = 0

    # Package
    assert v[i].startswith("package")
    i += 1

    # Imports or comments
    while not v[i] or v[i].startswith("import") or v[i].startswith("//"):
        i += 1
    header = v[:i]

    def member():
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
        sig = v[i]
        dent = etc.indentation(sig)
        i += 1

        # Enum
        if re.search(r"\benum \w", sig):
            a = Enum(header, sig)
            while not closes(dent, v[i]):
                a.members.append(v[i])
                i += 1
            i += 1
            return a

        # Empty class
        if re.search(r"\bclass \w.*{}$", sig):
            return Class(header, sig)

        # Class
        if re.search(r"\bclass \w", sig):
            a = Class(header, sig)
            while 1:
                while not v[i]:
                    i += 1
                if closes(dent, v[i]):
                    break
                a.members.append(member())
            i += 1
            return a

        # Field whose value is an anonymous class
        if sig.endswith("="):
            sig1 = v[i]
            if re.match(r" *new \w+\(\) {$", sig1):
                dent = etc.indentation(sig1)
                i += 1
                a = FieldClass(header, sig, sig1)
                while 1:
                    while not v[i]:
                        i += 1
                    if closes_semi(dent, v[i]):
                        break
                    a.members.append(member())
                i += 1
                return a

        # Abstract method
        if re.search(r"\babstract .*\w\(.*\).*;$", sig):
            return Method(header, sig)

        # Empty method
        if re.search(r"\w\(.*\) .*{}$", sig):
            return Method(header, sig)

        # Method
        if re.search(r"\w\(.*\) .*{$", sig):
            a = Method(header, sig)
            while not closes(dent, v[i]):
                a.body.append(v[i])
                i += 1
            i += 1
            return a

        # One-line field
        if sig.endswith(";"):
            return Field(header, sig)

        # Multiline field
        if sig.endswith("="):
            a = Field(header, sig)
            while dent < etc.indentation(v[i]):
                a.value.append(v[i])
                i += 1
            while not a.value[-1]:
                a.value.pop()
            return a

        # Unknown syntax
        raise Exception(f"{i}: {sig}")

    a = member()
    a.header = header + a.header
    return a


def separate(a, b):
    if not isinstance(a, Field):
        return True
    if not isinstance(b, Field):
        return True
    return a.category() != b.category()


def separate1(a, b):
    # Blank line before comment
    if not comment(b):
        return

    # But not between comments
    if comment(a):
        return

    # And not at the beginning of a block
    if etc.indentation(a) < etc.indentation(b):
        return

    # All criteria pass
    return True


def src_files():
    r = []
    etc.get_files(os.path.join("src", "main", "java", "olivine"), ".java", r)
    return r


def visibility(a):
    s = a.sig
    if re.search(r"\bpublic\b", s):
        return "public"
    if re.search(r"\bprivate\b", s):
        return "private"
    if re.search(r"\bprotected\b", s):
        return "protected"
    return ""
