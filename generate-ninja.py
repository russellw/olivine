#!/usr/bin/env python3
import glob
import os

# Create obj directory if it doesn't exist
os.makedirs("obj", exist_ok=True)

# Write the ninja build file
with open("build.ninja", "w") as f:
    # Write build file header and global variables
    f.write("# Generated ninja build file for olivine project\n\n")

    # Define compiler and flags
    f.write("cxx = cl\n")
    f.write("cxxflags = /std:c++17 /nologo /c /EHsc /Isrc /I\\boost /W3 /WX\n")
    f.write("\n")

    # Define the rule for C++ compilation
    f.write("rule cxx\n")
    f.write("  command = $cxx $cxxflags /Foobj\\ $in\n")
    f.write("  description = CXX $out\n")
    f.write("\n")

    # Define the rule for linking
    f.write("rule link\n")
    f.write("  command = $cxx $in /Fe$out\n")
    f.write("  description = LINK $out\n")
    f.write("\n")

    # Get all source files
    src_files = glob.glob("src/*.cpp")
    header_files = glob.glob("src/*.h")

    # Create object file targets for each source file
    obj_files = []
    for src in src_files:
        obj = os.path.basename(src).replace(".cpp", ".obj")
        obj_path = f"obj\\{obj}"
        obj_files.append(obj_path)

        # Each source file implicitly depends on headers through includes
        # We don't list headers on command line as source files
        f.write(f"build {obj_path}: cxx {src}")
        # Add headers as order-only dependencies
        if header_files:
            f.write(" |")  # Single pipe for all order-only dependencies
            for header in header_files:
                f.write(f" {header}")
        f.write("\n")

    # Add main.cpp compilation
    main_obj = "obj\\main.obj"
    f.write(f"build {main_obj}: cxx main.cpp")
    if header_files:
        f.write(" |")
        for header in header_files:
            f.write(f" {header}")
    f.write("\n\n")

    # Create the final executable target
    f.write("build olivine.exe: link")
    for obj in obj_files:
        f.write(f" {obj}")
    f.write(f" {main_obj}\n")

    # Add a default target
    f.write("\ndefault olivine.exe\n")

    # Add test executable build
    test_obj = "obj\\unit-tests.obj"
    f.write(f"\nbuild {test_obj}: cxx unit-tests.cpp")
    if header_files:
        f.write(" | unit-tests.h")
        for header in header_files:
            f.write(f" {header}")
    f.write("\n")

    f.write("\nbuild test.exe: link")
    for obj in obj_files:
        f.write(f" {obj}")
    f.write(f" {test_obj}\n")
