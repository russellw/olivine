import etc


class Class:
    def __init__(self, sig):
        self.sig = sig
        self.contents = []

        # Name
        r = re.search(r"\bclass (\w+)", sig)
        self.name = r[1]

    def category(self):
        return "class"


class Function:
    def __init__(self, sig):
        self.sig = sig
        self.contents = []

        # Name
        r = re.search(r"\bdef (\w+)", sig)
        self.name = r[1]

    def category(self):
        return "function"


def compose(a):
    r = []
    a.compose(r)
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
