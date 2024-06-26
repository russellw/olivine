# Sort labels in multilabel case
# Internal tool, designed for this project only
# Does NOT work for arbitrary Java code
import etc
import java

for file in java.src_files():
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
            # Label
            i, j = java.lex(s, j)
            labels.append(s[i:j])

            # Punctuation?
            i, j = java.lex(s, j)
            t = s[i:j]
            if t == ",":
                continue
            if t == "->":
                break

            # Pattern match
            if not (t[0].isalpha() or t == "_"):
                raise Exception(t)
            assert len(labels) == 1
            r.extend(labels)
            r.append(" ")
            r.append(t)
            labels.clear()

            # Eat punctuation
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
