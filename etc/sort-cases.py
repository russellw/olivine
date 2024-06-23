# Sort cases in new-style switch
# Internal tool, designed for this project only
# Does NOT work for arbitrary Java code
import re

import etc
import java


def case(i):
    assert is_case(i)
    dent = etc.indentation(v[i])
    j = i + 1
    while dent < etc.indentation(v[j]):
        j += 1
    if java.closes(dent, v[j]):
        j += 1
    return tuple(v[i:j])


def cases(i):
    i = find(is_case, len(v), i)
    if i < 0:
        return i, []
    j = i
    r = []
    while is_case(j):
        c = case(j)
        r.append(c)
        j += len(c)
    return i, r


def find(f, n, i):
    while i < n:
        if f(i):
            return i
        i += 1
    return -1


def is_case(i):
    if re.match(" *case ", v[i]):
        return True
    if re.match(" *default ", v[i]):
        return True


for file in java.src_files():
    v = etc.read_lines(file)
    i = 0
    r = []
    while 1:
        j, cs = cases(i)
        if j < 0:
            r.extend(v[i:])
            break
        r.extend(v[i:j])
        i = j
        cs.sort()
        for c in cs:
            r.extend(c)
            i += len(c)
    etc.write_lines(file, r)
