#!/usr/bin/env python3
"""
Script to fix C++ unit test files to ensure proper includes for boost testing.
"""

import os
import re
import sys
from pathlib import Path

# Standard library headers that might be redundantly included
STD_HEADERS = [
    "<vector>",
    "<string>",
    "<map>",
    "<unordered_map>",
    "<set>",
    "<unordered_set>",
    "<iostream>",
    "<fstream>",
    "<sstream>",
    "<iomanip>",
    "<algorithm>",
    "<numeric>",
    "<memory>",
    "<utility>",
    "<functional>",
    "<chrono>",
    "<thread>",
    "<mutex>",
    "<condition_variable>",
    "<atomic>",
    "<cmath>",
    "<cstdlib>",
    "<cstdio>",
    "<cstring>",
    "<cassert>",
    "<ctime>",
    "<random>",
    "<regex>",
    "<tuple>",
    "<array>",
    "<bitset>",
    "<queue>",
    "<stack>",
    "<deque>",
    "<list>",
    "<forward_list>",
    "<iterator>",
    "<limits>",
    "<type_traits>",
    "<optional>",
    "<variant>",
    "<any>",
]


def is_comment_or_blank(line):
    """Check if a line is a comment or blank."""
    stripped = line.strip()
    return not stripped or stripped.startswith("//") or stripped.startswith("/*")


def fix_unit_test_file(file_path):
    """Fix a unit test file to ensure proper includes."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading file {file_path}: {e}")
        return False

    # Make a copy of the original lines for change detection
    original_lines = lines.copy()

    # Find first non-blank, non-comment line
    first_code_line_idx = 0
    while first_code_line_idx < len(lines) and is_comment_or_blank(
        lines[first_code_line_idx]
    ):
        first_code_line_idx += 1

    if first_code_line_idx >= len(lines):
        print(f"No code found in {file_path}")
        return True  # Empty file, nothing to fix

    # Step 1: Handle "all.h" include - it must be the first non-comment line
    all_h_include = '#include "all.h"\n'

    # Check if all.h is already the first non-comment line
    if not (
        first_code_line_idx < len(lines) and all_h_include in lines[first_code_line_idx]
    ):
        # Remove any existing all.h include
        lines = [line for line in lines if all_h_include not in line]

        # Recalculate first_code_line_idx after removal
        first_code_line_idx = 0
        while first_code_line_idx < len(lines) and is_comment_or_blank(
            lines[first_code_line_idx]
        ):
            first_code_line_idx += 1

        # Insert all.h as first non-comment line
        if first_code_line_idx < len(lines):
            lines.insert(first_code_line_idx, all_h_include)
        else:
            # Empty file after removing comments, add at the end
            lines.append(all_h_include)
            first_code_line_idx = len(lines) - 1

    # Step 2: Handle boost includes
    boost_header_only = "#include <boost/test/included/unit_test.hpp>\n"
    boost_regular = "#include <boost/test/unit_test.hpp>\n"

    # Remove any existing boost regular include
    lines = [line for line in lines if boost_regular not in line]

    # Check if boost header-only is already present
    has_boost_header_only = False
    boost_header_idx = -1

    for i, line in enumerate(lines):
        if boost_header_only in line:
            has_boost_header_only = True
            boost_header_idx = i
            break

    if not has_boost_header_only:
        # We need to add the boost header-only include
        # Find where the first Boost test code or test suite starts
        test_code_idx = len(lines)
        for i, line in enumerate(lines):
            if (
                line.strip().startswith("BOOST_")
                or "BOOST_AUTO_TEST" in line
                or "BOOST_TEST" in line
                or "test_suite" in line.lower()
            ):
                test_code_idx = i
                break

        # Find the proper position to insert (after all.h but before test code)
        # Start right after all.h
        insert_position = first_code_line_idx + 1

        # Find the last include before test code
        for i in range(first_code_line_idx + 1, test_code_idx):
            if lines[i].strip().startswith("#include"):
                insert_position = i + 1

        # Insert the boost header at the determined position
        lines.insert(insert_position, boost_header_only)
        boost_header_idx = insert_position

    # Step 3: Ensure there's a blank line after boost header if followed by any BOOST test code
    if boost_header_idx >= 0 and boost_header_idx + 1 < len(lines):
        next_line = lines[boost_header_idx + 1].strip()
        if next_line.startswith("BOOST_AUTO_TEST_CASE") or next_line.startswith(
            "BOOST_AUTO_TEST_SUITE"
        ):
            # Insert a blank line between boost include and test code
            lines.insert(boost_header_idx + 1, "\n")

    # Step 3: Remove redundant standard library includes
    final_lines = []
    for line in lines:
        # Skip standard library includes
        if any(f"#include {header}" in line for header in STD_HEADERS):
            continue
        final_lines.append(line)

    # Check if anything changed
    modified = original_lines != final_lines

    if modified:
        try:
            # Write with UNIX line endings (LF) even on Windows
            with open(file_path, "w", encoding="utf-8", newline="\n") as f:
                f.writelines(final_lines)
            print(f"Fixed: {file_path}")
        except Exception as e:
            print(f"Error writing to file {file_path}: {e}")
            return False
    else:
        print(f"No changes needed: {file_path}")

    return True

    # Save changes if modified
    if modified:
        try:
            with open(file_path, "w") as f:
                f.writelines(lines)
            print(f"Fixed: {file_path}")
            return True
        except Exception as e:
            print(f"Error writing to file {file_path}: {e}")
            return False
    else:
        print(f"No changes needed: {file_path}")
        return True


def process_directory(directory):
    """Process all .cpp files in the given directory."""
    success_count = 0
    fail_count = 0
    skip_count = 0

    for path in Path(directory).rglob("*.cpp"):
        # You may want to add additional checks here to confirm it's a unit test file
        if fix_unit_test_file(path):
            success_count += 1
        else:
            fail_count += 1

    print(f"\nSummary:")
    print(f"  Processed files: {success_count + fail_count}")
    print(f"  Successfully fixed: {success_count}")
    print(f"  Failed: {fail_count}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python fix_unit_tests.py <directory>")
        sys.exit(1)

    directory = sys.argv[1]
    if not os.path.isdir(directory):
        print(f"Error: {directory} is not a valid directory")
        sys.exit(1)

    process_directory(directory)
