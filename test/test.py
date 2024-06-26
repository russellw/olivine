import argparse
import os
import random
import re
import shlex
import subprocess


def call(cmd):
    p = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    stdout, stderr = p.communicate()
    stdout = str(stdout, "utf-8")
    stderr = str(stderr, "utf-8")
    if stderr:
        raise Exception(stderr)
    if p.returncode:
        raise Exception(str(p.returncode))
    return stdout


def compare(prg1, prg2, v):
    s = call([prg1] + v)
    t = call([prg2] + v)
    if s != t:
        print(s, end="")
        print(t, end="")
        exit(1)


def exe_file(file):
    if os.name == "nt":
        return file + ".exe"
    return file


def subst(s):
    if not s.startswith("$"):
        return s
    s = s[1:]
    if s == "f":
        return str(random.random())
    if s == "s":
        n = 1 + random.randrange(20)
        r = []
        for i in range(n):
            r.append(chr(97 + random.randrange(26)))
        return "".join(r)
    if s == "u64":
        return str(random.randrange(1 << 64))
    raise Exception(s)


parser = argparse.ArgumentParser(description="Run test cases")
parser.add_argument("files", nargs="*")
args = parser.parse_args()

random.seed(0)
test_dir = os.path.dirname(os.path.realpath(__file__))


def do(file):
    print(file)
    v = []
    for s in open(file):
        m = re.match(r"//\s*argv:(.*)", s)
        if m:
            v = shlex.split(m[1])
            break
        if not s.startswith("//"):
            break
    subprocess.check_call(
        [
            "clang",
            "-S",
            "-emit-llvm",
            "-O2",
            file,
        ]
    )
    file = os.path.basename(file)
    file = os.path.splitext(file)[0]
    subprocess.check_call(["clang", "-o", exe_file(file), file + ".ll"])
    subprocess.check_call(["olivine", file + ".ll"], shell=True)
    subprocess.check_call(["clang", "a.ll"])
    if any(map(lambda s: s.startswith("$"), v)):
        for i in range(10):
            compare(file, "a", list(map(subst, v)))
    else:
        compare(file, "a", v)


tests = [test_dir]
if args.files:
    tests = args.files
for test in tests:
    if os.path.isfile(test):
        do(test)
        continue
    if not os.path.isdir(test):
        print(test + ": not found")
        exit(1)
    for root, dirs, files in os.walk(test):
        for file in files:
            # TODO
            if file == "fnv.c":
                continue
            ext = os.path.splitext(file)[1]
            if ext in (".c", ".cpp"):
                do(os.path.join(root, file))
