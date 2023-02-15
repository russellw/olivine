import os
import re
import sys


def read_file(filename):
    lines = open(filename).readlines()
    for s in lines:
        if s.startswith("include("):
            tptp = os.getenv("TPTP")
            if not tptp:
                raise ValueError("TPTP environment variable not set")
            read_file(tptp + "/" + s.split("'")[1])
            continue
        print(s, end="")


f = sys.argv[1]
if re.match(r"[a-zA-Z][a-zA-Z][a-zA-Z]\d\d\d[\+\-_]\d.*", f):
    tptp = os.getenv("TPTP")
    f = f.upper()
    domain = f[:3]
    if "." not in f:
        f += ".p"
    f = tptp + "/Problems/" + domain + "/" + f
read_file(f)
