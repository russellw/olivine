import re

import etc


class Line:
    def __init__(self, s):
        self.s = s

    def compose(self, r):
        r.append(self.s)

    def sort(self):
        pass


class Class:
    def __repr__(self):
        return self.name

    def __init__(self, sig):
        self.sig = sig
        self.contents = []

        # Name
        r = re.search(r"\bclass (\w+)", sig)
        self.name = r[1]

    def category(self):
        return "class"

    def compose(self, r):
        r.append(self.sig)
        compose1(self.contents, r)

    def sort(self):
        for a in self.contents:
            a.sort()
        self.contents.sort(key=key)


class Function:
    def compose(self, r):
        r.append(self.sig)
        compose1(self.contents, r)

    def __repr__(self):
        return self.name

    def __init__(self, sig):
        self.sig = sig
        self.contents = []

        # Name
        r = re.search(r"\bdef (\w+)", sig)
        self.name = r[1]

    def category(self):
        return "function"

    def sort(self):
        for a in self.contents:
            a.sort()
        sort(self.contents)


def sortable(a):
    return isinstance(a, Function) or isinstance(a, Class)


def sort(v):
    u = etc.runs(sortable, v)
    for i, j in u:
        v[i:j] = sorted(v[i:j], key=key)


def separate(a, b):
    return not comment(a) and comment(b)


def comment(a):
    return isinstance(a, Line) and re.match(" *#", a.s)


def compose1(v, r):
    for i in range(len(v)):
        a = v[i]
        if i and separate(v[i - 1], a):
            r.append("")
        a.compose(r)


def compose(v):
    r = []
    compose1(v, r)
    return r


def category_rank(a):
    s = a.category()
    ranks = [
        "class",
        "function",
    ]
    for i in range(len(ranks)):
        if s == ranks[i]:
            return i
    raise Exception(s)


def src_files():
    r = []
    etc.get_files("etc", ".py", r)
    return r


def key(a):
    return category_rank(a), a.name, a.sig


def parse(v):
    v = [s for s in v if s]
    i = 0

    def element():
        nonlocal i
        s = v[i]
        i += 1

        # class
        if re.match(" *class ", s):
            a = Class(s)
            block(etc.indentation(s), a.contents)
            return a

        # function
        if re.match(" *def ", s):
            a = Function(s)
            block(etc.indentation(s), a.contents)
            return a

        # other
        return Line(s)

    def block(dent, r):
        nonlocal i
        while i < len(v) and etc.indentation(v[i]) > dent:
            r.append(element())

    r = []
    while i < len(v):
        r.append(element())
    return r
