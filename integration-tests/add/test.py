import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from common.etc import *

clang("-emit-llvm -S a.c")
