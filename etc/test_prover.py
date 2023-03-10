import argparse
import time
import inspect
import subprocess
import re
import os
import sys
import random
import logging

try:
    os.nice(20)
except AttributeError:
    # Python on Windows doesn't have 'nice'
    pass

logger = logging.getLogger()
logger.addHandler(logging.StreamHandler(sys.stdout))
logger.setLevel(logging.DEBUG)


def trace(a):
    info = inspect.getframeinfo(inspect.currentframe().f_back)
    logger.debug(f"{info.filename}:{info.function}:{info.lineno}: {repr(a)}")


def getExpected(filename):
    if filename.endswith(".p"):
        for s in open(filename):
            m = re.match(r"%\s*Status\s*:\s*(\w+)", s)
            if m:
                return m[1]
    elif filename.endswith(".cnf"):
        for s in open(filename):
            m = re.match(r"c.* (SAT|UNSAT) .*", s)
            if m:
                return m[1]
    return "-"


def meaning(s):
    if s in ("sat", "unsat"):
        return s
    if s in ("SAT", "UNSAT"):
        return s.lower()
    if s == "Satisfiable":
        return "sat"
    if s == "CounterSatisfiable":
        return "sat"
    if s == "Unsatisfiable":
        return "unsat"
    if s == "Theorem":
        return "unsat"
    if s == "ContradictoryAxioms":
        return "unsat"


def hasProof(xs):
    for x in xs:
        if "SZS output start CNFRefutation" in x:
            return 1


parser = argparse.ArgumentParser(description="Test prover")
parser.add_argument("prover")
parser.add_argument("problems")
parser.add_argument("-m", "--max", help="max number of problems to attempt", type=int)
parser.add_argument(
    "-o", "--output-solved", help="output list of solved problems to a file"
)
parser.add_argument("-p", "--proof", help="extract proofs", action="store_true")
parser.add_argument(
    "-r", "--random", metavar="seed", help="deterministic random sequence"
)
parser.add_argument("-s", "--shuffle", help="shuffle problem list", action="store_true")
parser.add_argument(
    "-t", "--cpu-limit", metavar="seconds", help="time limit per problem", type=float
)
args = parser.parse_args()

print(args.prover)
prover = args.prover.split()
problems = args.problems

if problems.casefold() == "tptp".casefold():
    tptp = os.getenv("TPTP")
    problems = []
    for root, dirs, files in os.walk(tptp):
        for filename in files:
            if os.path.splitext(filename)[1] == ".p":
                problems.append(os.path.join(root, filename))
elif re.match(r"[a-zA-Z][a-zA-Z][a-zA-Z]\d\d\d[\+\-_]\d.*", problems):
    tptp = os.getenv("TPTP")
    p = problems.upper()
    domain = p[:3]
    if "." not in p or re.match(r".*\.\d\d\d$", p):
        p += ".p"
    p = tptp + "/Problems/" + domain + "/" + p
    problems = [p]
elif re.match(r"[a-zA-Z][a-zA-Z][a-zA-Z]", problems):
    tptp = os.getenv("TPTP")
    domain = problems.upper()
    problems = []
    for root, dirs, files in os.walk(tptp + "/Problems/" + domain):
        for filename in files:
            if os.path.splitext(filename)[1] == ".p":
                problems.append(os.path.join(root, filename))
elif problems.endswith(".lst"):
    problems = [s.rstrip() for s in open(problems)]
else:
    problems = [problems]

if args.shuffle:
    if args.random:
        random.seed(args.random)
    random.shuffle(problems)

timeout = 60.0
if args.cpu_limit:
    timeout = args.cpu_limit

alreadyWritten = set()
if args.output_solved:
    try:
        for s in open(args.output_solved).readlines():
            s = s.strip()
            set.add(s)
    except:
        pass

attempted = 0
solved = 0
for filename in problems:
    if "^" in filename:
        continue
    if args.max and attempted == args.max:
        break
    attempted += 1
    pname = os.path.basename(os.path.splitext(filename)[0])
    expected = getExpected(filename)
    print(pname, end="\t")
    print(expected, end="\t")
    sys.stdout.flush()
    cmd = prover + [filename]
    start = time.time()
    stderr = ""
    try:
        p = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        stdout, stderr = p.communicate(timeout=timeout)
        stdout = str(stdout, "utf-8")
        stderr = str(stderr, "utf-8")
        stdouts = stdout.split("\n")

        result = "-"
        for x in stdouts:
            x = x.strip()
            if x in ("sat", "unsat"):
                result = x
                break
            m = re.match(r".*SZS status (\w+)", x)
            if m:
                result = m[1]
                break
        print(result, end="\t")

        if (
            meaning(expected)
            and meaning(result)
            and meaning(expected) != meaning(result)
        ):
            raise Exception(result)

        if args.proof and hasProof(stdouts):
            print("*", end="")
            with open(pname + "-proof.p", "w") as f:
                for x in stdouts:
                    f.write(x + "\n")

        if meaning(result):
            # At this stage of development,
            # if the prover thinks it has solved an open problem,
            # it's a bug
            if expected in ("Open", "Unknown"):
                raise Exception(expected)
            solved += 1
            if args.output_solved and filename not in alreadyWritten:
                osf = open(args.output_solved, "a")
                osf.write(filename + "\n")
    except subprocess.TimeoutExpired:
        p.kill()
        print("Timeout", end="\t")
    print("%.3f" % (time.time() - start))
    if stderr:
        print(stdout, end="")
        print(stderr, end="")
print("%d/%d" % (solved, attempted))
