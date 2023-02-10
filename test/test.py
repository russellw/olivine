import argparse
import os
import re
import subprocess
import time

parser = argparse.ArgumentParser(description="Run test cases")
parser.add_argument("-v", "--verbose", action="count", help="increase output verbosity")
parser.add_argument("files", nargs="*")
args = parser.parse_args()

verbose = 0
if args.verbose:
    verbose = args.verbose

here = os.path.dirname(os.path.realpath(__file__))
projectDir = os.path.join(here, "..")

compiler = ["javac", "-d", ".", "--enable-preview", "-source", "18"]
subprocess.check_call((compiler + [os.path.join(projectDir, "src", "*.java")]))
subprocess.check_call((compiler + [os.path.join(projectDir, "test", "*.java")]))


def do(file):
    if verbose >= 1:
        print(file)
    subprocess.check_call(
        ("java", "-ea", "--enable-preview", os.path.splitext(file)[0])
    )


if args.files:
    for file in args.files:
        do(file)
else:
    for root, dirs, files in os.walk(here):
        for file in files:
            ext = os.path.splitext(file)[1]
            if ext == ".java":
                do(file)
print("ok")
