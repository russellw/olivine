# Sort labels in multilabel case
# Internal tool, designed for this project only
# Does NOT work for arbitrary Java code
import etc
import java

for file in java.src_files():
    s = open(file).read()
    j = 0
    r = []
    while 1:
        i = s.find(" case ")
        if i < 0:
            r.append(s[j:])
            break
        i += 6
        r.append(s[j:i])
        labels = []
        while 1:
            # label
            j, i = java.lex(s, i)
            labels.append(s[j:i])

            # punctuation?
            j, i = java.lex(s, i)
            t = s[j:i]
            if t == ",":
                continue
            if t == "->":
                break

            # pattern match
            if not t[0].isalpha():
                raise Exception(t)
            assert len(labels) == 1
            r.extend(labels)
            r.append(" ")
            r.append(t)
            labels.clear()
            break
        labels.sort()
        r.append(",".join(labels))
        r.append("->")
        j = i
    open(file, "w", newline="\n").write("".join(r))
