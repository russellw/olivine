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

            # punctuation
            j, i = java.lex(s, i)
            t = s[j:i]
            if t == "->":
                break
            if t != ",":
                raise Exception(t)
        labels.sort()
        r.append(",".join(labels))
        r.append("->")
        j = i
    open(file, "w", newline="\n").write("".join(r))
