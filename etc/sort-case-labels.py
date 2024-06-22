# Sort labels in multilabel case
# Internal tool, designed for this project only
# Does NOT work for arbitrary Java code
import etc
import java

for file in java.src_files():
    etc.debug(file)
    s = open(file).read()
    i = 0
    r = []
    while 1:
        j = s.find(" case ", i)
        if j < 0:
            r.append(s[i:])
            break
        j += 6
        r.append(s[i:j])
        labels = []
        while 1:
            # label
            i, j = java.lex(s, j)
            labels.append(s[i:j])

            # punctuation?
            i, j = java.lex(s, j)
            t = s[i:j]
            if t == ",":
                continue
            if t == "->":
                break

            # pattern match
            if not (t[0].isalpha() or t == "_"):
                raise Exception(t)
            assert len(labels) == 1
            r.extend(labels)
            r.append(" ")
            r.append(t)
            labels.clear()

            # eat punctuation
            i, j = java.lex(s, j)
            t = s[i:j]
            if t != "->":
                raise Exception(t)
            break
        labels.sort()
        r.append(",".join(labels))
        r.append("->")
        i = j
    open(file, "w", newline="\n").write("".join(r))
