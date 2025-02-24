#!/usr/bin/env python3

import re
import os
from pathlib import Path
from collections import defaultdict

def extract_includes(content):
    """Extract all include statements from the file."""
    includes = []
    for line in content.split('\n'):
        if line.strip().startswith('#include'):
            includes.append(line.strip())
    return includes

def find_test_suites(content):
    """Find all test suites and their associated tests."""
    # Common patterns for test suite declarations
    suite_patterns = [
        r'BOOST_AUTO_TEST_SUITE\s*\(\s*(\w+)\s*\)',
        r'BOOST_FIXTURE_TEST_SUITE\s*\(\s*(\w+)\s*,\s*\w+\s*\)'
    ]
    
    # Split content into lines for easier processing
    lines = content.split('\n')
    
    suites = defaultdict(list)
    current_suite = None
    current_test = []
    nesting_level = 0
    
    for line in lines:
        # Check for suite start
        for pattern in suite_patterns:
            match = re.search(pattern, line)
            if match:
                current_suite = match.group(1)
                nesting_level = 0
                break
                
        # Check for suite end
        if 'BOOST_AUTO_TEST_SUITE_END' in line and current_suite:
            if nesting_level == 0:
                current_suite = None
            
        # If we're in a suite, collect the lines
        if current_suite:
            if '{' in line:
                nesting_level += line.count('{')
            if '}' in line:
                nesting_level -= line.count('}')
            suites[current_suite].append(line)
            
    return suites

def create_test_file(suite_name, suite_content, includes, output_dir):
    """Create a new test file for a suite."""
    filename = f"{suite_name.lower()}-tests.cpp"
    path = os.path.join(output_dir, filename)
    
    with open(path, 'w') as f:
        # Write includes
        for include in includes:
            f.write(f"{include}\n")
        f.write("\n")
        
        # Write Boost test module definition if it's not already in the includes
        if not any('BOOST_TEST_MODULE' in inc for inc in includes):
            f.write("#define BOOST_TEST_MODULE {}\n".format(suite_name))
            f.write("#include <boost/test/unit_test.hpp>\n\n")
            
        # Write suite content
        f.write('\n'.join(suite_content))
        f.write('\n')
        
    return filename

def main():
    # Parse command line arguments
    import argparse
    parser = argparse.ArgumentParser(description='Split a large Boost unit test file into multiple files.')
    parser.add_argument('input_file', help='The input test file to split')
    parser.add_argument('output_dir', help='The output directory for the split test files')
    args = parser.parse_args()
    
    # Create output directory if it doesn't exist
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Read input file
    with open(args.input_file, 'r') as f:
        content = f.read()
    
    # Extract includes
    includes = extract_includes(content)
    
    # Find test suites
    suites = find_test_suites(content)
    
    # Create individual files for each suite
    created_files = []
    for suite_name, suite_content in suites.items():
        filename = create_test_file(suite_name, suite_content, includes, args.output_dir)
        created_files.append(filename)
        
    # Print summary
    print(f"Split {len(suites)} test suites into separate files:")
    for filename in created_files:
        print(f"  - {filename}")

if __name__ == '__main__':
    main()