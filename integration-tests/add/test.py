import os
import sys

current_dir = os.path.dirname(__file__)
sys.path.append(os.path.dirname(current_dir))
from common.etc import *

src = os.path.join(current_dir, "add.c")
clang("-emit-llvm -S " + src)
olivine("add.ll")
clang("-c a.ll")
