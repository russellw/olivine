import os
import sys

# Import common functions from ../common
current_dir = os.path.dirname(__file__)
sys.path.append(os.path.dirname(current_dir))
from common.etc import *

# Simple test with one source file
name = os.path.basename(current_dir)
src = os.path.join(current_dir, name + ".c")

# Compile to .ll
clang("-emit-llvm -S " + src)

# Process
olivine(name + ".ll")

# Compile to an executable
clang("a.ll")

# Check result
check_return_code("a", (), 123)
