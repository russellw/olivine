import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from common.etc import *

clang("-emit-llvm -S add.c")
olivine("add.ll")
