import os
import re


def get_szs(filename):
    for s in open(filename).readlines():
        m = re.match(r"%\s*Status\s*:\s*(\w+)", s)
        if m:
            return m[1]
    raise Exception(filename + ": Status not defined")


tptp = os.getenv("TPTP")
if not tptp:
    raise Exception("TPTP not defined")

szs = set()
for root, dirs, files in os.walk(tptp + "/Problems/"):
    for filename in files:
        if "^" in filename:
            continue
        if os.path.splitext(filename)[1] == ".p":
            filename = os.path.join(root, filename)
            szs.add(get_szs(filename))

szs = list(szs)
for s in szs:
    print(s + ",")
