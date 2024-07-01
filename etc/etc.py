import inspect
import logging
import os
import re
import sys

# Colors
BLACK = "\033[30m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
LIGHT_GRAY = "\033[37m"
DARK_GRAY = "\033[90m"
BRIGHT_RED = "\033[91m"
BRIGHT_GREEN = "\033[92m"
BRIGHT_YELLOW = "\033[93m"
BRIGHT_BLUE = "\033[94m"
BRIGHT_MAGENTA = "\033[95m"
BRIGHT_CYAN = "\033[96m"
WHITE = "\033[97m"
RESET = "\033[0m"

# Debug output
logger = logging.getLogger()
logger.addHandler(logging.StreamHandler(sys.stdout))
logger.setLevel(logging.DEBUG)


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


def quasinumeric_key(s):
    v = re.split(r"(\d+)", s)
    return tuple(int(t) if t.isdigit() else t for t in v)


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
