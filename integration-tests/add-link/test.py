import os
import sys

# Import common functions from ../common
current_dir = os.path.dirname(__file__)
sys.path.append(os.path.dirname(current_dir))
from common.etc import *

# Compile to .ll
clang("-emit-llvm -S " + os.path.join(current_dir, "add.c"))
clang("-emit-llvm -S " + os.path.join(current_dir, "main.c"))

# Process
olivine("add.ll main.ll")

# Compile to an executable
clang("a.ll")

# Check result
check_return_code("a", (), 7)
