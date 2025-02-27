import os
import sys

current_dir = os.path.dirname(__file__)
sys.path.append(os.path.dirname(current_dir))
from common.etc import *

name = os.path.basename(current_dir)
src = os.path.join(current_dir, name + ".c")
clang("-emit-llvm -S " + src)
olivine(name + ".ll")
clang("-c a.ll")
