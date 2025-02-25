import subprocess
import sys
import os
from typing import List, Optional, Union


def clang(args: Union[List[str], str], cwd: Optional[str] = None, 
              capture_output: bool = False) -> Union[subprocess.CompletedProcess, None]:
    """
    Run clang with the given arguments and fail the whole process if compilation fails.
    
    Args:
        args: List of arguments or a single string with space-separated arguments to pass to clang
        cwd: Working directory for clang (optional)
        capture_output: Whether to capture stdout/stderr (default: False)
    
    Returns:
        CompletedProcess object if capture_output is True and compilation succeeds
        None if capture_output is False and compilation succeeds
    
    Raises:
        SystemExit: If clang process fails
    """
    try:
        # Convert string arguments to list if needed
        if isinstance(args, str):
            args_list = args.split()
        else:
            args_list = args
            
        # Construct the command: 'clang' followed by all arguments
        cmd = ['clang'] + args_list
        
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
