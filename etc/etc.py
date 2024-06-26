import inspect
import logging
import os
import re
import sys

logger = logging.getLogger()
logger.addHandler(logging.StreamHandler(sys.stdout))
logger.setLevel(logging.DEBUG)


def quasinumeric_key(s):
    v = re.split(r"(\d+)", s)
    return tuple(int(t) if t.isdigit() else t for t in v)


def debug(a):
    info = inspect.getframeinfo(inspect.currentframe().f_back)
    logger.debug(f"{info.filename}:{info.function}:{info.lineno}: {repr(a)}")


def get_files(directory, extension, r):
    for entry in os.scandir(directory):
        if entry.is_file() and entry.name.endswith(extension):
            r.append(os.path.join(directory, entry.name))


def indentation(s):
    if not s:
        return 1000
    i = 0
    while s[i] == " ":
        i += 1
    assert s[i] != "\t"
    return i


def read_lines(file):
    with open(file) as f:
        return [s.rstrip() for s in f]


def runs(f, v):
    i = 0
    r = []
    while 1:
        while i < len(v) and not f(v[i]):
            i += 1
        j = i
        while i < len(v) and f(v[i]):
            i += 1
        if i == j:
            return r
        r.append((j, i))


def write_lines(file, v):
    with open(file, "w", newline="\n") as f:
        for s in v:
            f.write(s + "\n")
