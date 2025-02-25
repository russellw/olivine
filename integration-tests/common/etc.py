import subprocess
import sys
import os
from typing import List, Optional, Union


def run_clang(args: List[str], cwd: Optional[str] = None, 
              capture_output: bool = False) -> Union[subprocess.CompletedProcess, None]:
    """
    Run clang with the given arguments and fail the whole process if compilation fails.
    
    Args:
        args: List of arguments to pass to clang
        cwd: Working directory for clang (optional)
        capture_output: Whether to capture stdout/stderr (default: False)
    
    Returns:
        CompletedProcess object if capture_output is True and compilation succeeds
        None if capture_output is False and compilation succeeds
    
    Raises:
        SystemExit: If clang process fails
    """
    try:
        # Construct the command: 'clang' followed by all arguments
        cmd = ['clang'] + args
        
        print(f"Running: {' '.join(cmd)}")
        
        # Run the clang process
        if capture_output:
            result = subprocess.run(
                cmd,
                check=True,  # Will raise CalledProcessError if return code is non-zero
                cwd=cwd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True  # Return stdout/stderr as strings
            )
            return result
        else:
            # Run with output directly to console
            subprocess.run(
                cmd,
                check=True,  # Will raise CalledProcessError if return code is non-zero
                cwd=cwd
            )
            return None
            
    except subprocess.CalledProcessError as e:
        print(f"Clang compilation failed with error code {e.returncode}", file=sys.stderr)
        if capture_output:
            print(f"STDOUT:\n{e.stdout}", file=sys.stderr)
            print(f"STDERR:\n{e.stderr}", file=sys.stderr)
        # Exit with the same return code as clang
        sys.exit(e.returncode)
    except FileNotFoundError:
        print("Error: 'clang' executable not found. Make sure it's installed and in your PATH.", 
              file=sys.stderr)
        sys.exit(1)


# Example usage:
if __name__ == "__main__":
    # Example 1: Compile a simple program
    # run_clang(['-c', 'hello.c', '-o', 'hello.o'])
    
    # Example 2: Compile with specific flags and capture output
    # result = run_clang(['-O2', '-Wall', '-c', 'complex.c', '-o', 'complex.o'], 
    #                   capture_output=True)
    # if result:
    #     print(f"Compilation successful. Warnings:\n{result.stderr}")
    
    # Example 3: Run clang with arguments from command line
    if len(sys.argv) > 1:
        run_clang(sys.argv[1:])
    else:
        print("Usage: python clang_runner.py [clang arguments]")
        sys.exit(1)
