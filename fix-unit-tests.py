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
    '<vector>', '<string>', '<map>', '<unordered_map>', '<set>', '<unordered_set>',
    '<iostream>', '<fstream>', '<sstream>', '<iomanip>', '<algorithm>', '<numeric>',
    '<memory>', '<utility>', '<functional>', '<chrono>', '<thread>', '<mutex>',
    '<condition_variable>', '<atomic>', '<cmath>', '<cstdlib>', '<cstdio>', '<cstring>',
    '<cassert>', '<ctime>', '<random>', '<regex>', '<tuple>', '<array>', '<bitset>',
    '<queue>', '<stack>', '<deque>', '<list>', '<forward_list>', '<iterator>', '<limits>',
    '<type_traits>', '<optional>', '<variant>', '<any>'
]

def is_comment_or_blank(line):
    """Check if a line is a comment or blank."""
    stripped = line.strip()
    return not stripped or stripped.startswith('//') or stripped.startswith('/*')

def fix_unit_test_file(file_path):
    """Fix a unit test file to ensure proper includes."""
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading file {file_path}: {e}")
        return False
    
    # Track if we need to modify the file
    modified = False
    
    # Find first non-blank, non-comment line
    first_code_line_idx = 0
    while first_code_line_idx < len(lines) and is_comment_or_blank(lines[first_code_line_idx]):
        first_code_line_idx += 1
    
    # Check for "all.h" include
    all_h_include = '#include "all.h"\n'
    has_all_h = False
    all_h_idx = -1
    
    for i, line in enumerate(lines):
        if all_h_include in line:
            has_all_h = True
            all_h_idx = i
            break
    
    # Add "all.h" if missing or not the first non-comment line
    if not has_all_h or all_h_idx != first_code_line_idx:
        if has_all_h:
            # Remove existing all.h include
            lines.pop(all_h_idx)
            if all_h_idx < first_code_line_idx:
                first_code_line_idx -= 1
        
        # Insert all.h as first non-comment line
        lines.insert(first_code_line_idx, all_h_include)
        modified = True
        # Adjust indices for any following operations since we added a line
        first_code_line_idx += 1
    
    # Check for boost test includes
    boost_header_only = '#include <boost/test/included/unit_test.hpp>\n'
    boost_regular = '#include <boost/test/unit_test.hpp>\n'
    
    has_boost_header_only = any(boost_header_only in line for line in lines)
    boost_regular_idx = -1
    
    for i, line in enumerate(lines):
        if boost_regular in line:
            boost_regular_idx = i
            break
    
    # Fix boost includes
    if not has_boost_header_only:
        if boost_regular_idx >= 0:
            # Replace regular boost include with header-only version
            lines[boost_regular_idx] = boost_header_only
            modified = True
        else:
            # Add header-only boost include after all.h
            include_idx = first_code_line_idx
            lines.insert(include_idx + 1, boost_header_only)
            modified = True
    
    # Remove redundant standard library includes
    i = 0
    while i < len(lines):
        line = lines[i]
        if any(f'#include {header}' in line for header in STD_HEADERS):
            lines.pop(i)
            modified = True
        else:
            i += 1
    
    # Save changes if modified
    if modified:
        try:
            with open(file_path, 'w') as f:
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
    
    for path in Path(directory).rglob('*.cpp'):
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
	