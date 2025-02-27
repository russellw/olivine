import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from common.etc import *

src = os.path.join(os.path.dirname(__file__), "add.c")
clang("-emit-llvm -S " + src)
olivine("add.ll")
clang("-c a.ll")
