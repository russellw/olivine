import os
import subprocess
import sys
from typing import List, Optional, Union


def split_args(args):
    if isinstance(args, str):
        return args.split()
    return args


def clang(
    args: Union[List[str], str], cwd: Optional[str] = None, capture_output: bool = False
) -> Union[subprocess.CompletedProcess, None]:
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
        args_list = split_args(args)

        # Construct the command: 'clang' followed by all arguments
        cmd = ["clang"] + args_list

        print(f"Running: {' '.join(cmd)}")

        # Run the clang process
        if capture_output:
            result = subprocess.run(
                cmd,
                check=True,  # Will raise CalledProcessError if return code is non-zero
                cwd=cwd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,  # Return stdout/stderr as strings
            )
            return result
        else:
            # Run with output directly to console
            subprocess.run(
                cmd,
                check=True,  # Will raise CalledProcessError if return code is non-zero
                cwd=cwd,
            )
            return None

    except subprocess.CalledProcessError as e:
        print(
            f"Clang compilation failed with error code {e.returncode}", file=sys.stderr
        )
        if capture_output:
            print(f"STDOUT:\n{e.stdout}", file=sys.stderr)
            print(f"STDERR:\n{e.stderr}", file=sys.stderr)
        # Exit with the same return code as clang
        sys.exit(e.returncode)
    except FileNotFoundError:
        print(
            "Error: 'clang' executable not found. Make sure it's installed and in your PATH.",
            file=sys.stderr,
        )
        sys.exit(1)


def olivine(args):
    """
    Run the 'olivine' executable located two directories above the script's location.

    Args:
        args: List of command-line arguments to pass to olivine

    Returns:
        CompletedProcess instance with return code, stdout, and stderr

    Raises:
        FileNotFoundError: If olivine executable is not found
        PermissionError: If olivine is not executable
        subprocess.CalledProcessError: If olivine returns a non-zero exit code
    """
    # Get the directory where the script is located (not the current working directory)
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Navigate two directories up to find olivine
    olivine_dir = os.path.normpath(os.path.join(script_dir, "..", ".."))
    olivine_path = os.path.join(olivine_dir, "olivine.exe")

    # Make sure the executable exists
    if not os.path.isfile(olivine_path):
        raise FileNotFoundError(
            f"The olivine executable was not found at {olivine_path}"
        )

    # Make sure it's executable
    if not os.access(olivine_path, os.X_OK):
        raise PermissionError(
            f"The olivine executable at {olivine_path} is not executable"
        )

    # Convert string arguments to list if needed
    args = split_args(args)

    # Execute the program with any provided arguments
    cmd = [olivine_path]
    if args:
        cmd.extend(args)

    # Run the process and check return code (will raise CalledProcessError if return code is non-zero)
    try:
        return subprocess.run(cmd, capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr, end="")
        raise


def check_return_code(executable, args=None, expected_return_code=0):
    """
    Run a specified executable with optional arguments and check its return code.

    Args:
        executable (str): Path to the executable to run
        args (list, optional): List of arguments to pass to the executable
        expected_return_code (int, optional): Expected return code, defaults to 0

    Returns:
        tuple: (stdout_data, stderr_data) as strings

    Raises:
        RuntimeError: If the return code doesn't match the expected value
    """
    # Prepare the command
    command = [executable]
    if args:
        command.extend(args)

    # Run the process
    process = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,  # Return strings instead of bytes
        check=False,  # Don't automatically raise exception on non-zero return
    )

    # Check return code
    if process.returncode != expected_return_code:
        raise RuntimeError(
            f"Executable '{executable}' returned {process.returncode} instead of expected {expected_return_code}.\n"
            f"STDOUT: {process.stdout}\n"
            f"STDERR: {process.stderr}"
        )

    return process.stdout, process.stderr
import subprocess
import re

def check_output(executable, args=None, expected_output=None, expected_pattern=None, expected_return_code=0):
    """
    Run a specified executable with optional arguments and check its stdout output.
    
    Args:
        executable (str): Path to the executable to run
        args (list, optional): List of arguments to pass to the executable
        expected_output (str, optional): Expected exact stdout output
        expected_pattern (str, optional): Regular expression pattern the stdout should match
        expected_return_code (int, optional): Expected return code, defaults to 0
    
    Returns:
        tuple: (stdout_data, stderr_data, return_code) as strings and integer
    
    Raises:
        RuntimeError: If the return code doesn't match the expected value
        ValueError: If the stdout output doesn't match expected output or pattern
    """
    # Validate input arguments
    if expected_output is not None and expected_pattern is not None:
        raise ValueError("Cannot specify both expected_output and expected_pattern")
    
    # Prepare the command
    command = [executable]
    if args:
        command.extend(args)
    
    # Run the process
    process = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,  # Return strings instead of bytes
        check=False,  # Don't automatically raise exception on non-zero return
    )
    
    # Check return code
    if process.returncode != expected_return_code:
        raise RuntimeError(
            f"Executable '{executable}' returned {process.returncode} instead of expected {expected_return_code}.\n"
            f"STDOUT: {process.stdout}\n"
            f"STDERR: {process.stderr}"
        )
    
    # Check stdout output if expected_output is provided
    if expected_output is not None and process.stdout.strip() != expected_output.strip():
        raise ValueError(
            f"Executable '{executable}' stdout output doesn't match expected output.\n"
            f"Expected: {expected_output}\n"
            f"Actual: {process.stdout}"
        )
    
    # Check stdout against pattern if expected_pattern is provided
    if expected_pattern is not None and not re.search(expected_pattern, process.stdout):
        raise ValueError(
            f"Executable '{executable}' stdout output doesn't match expected pattern '{expected_pattern}'.\n"
            f"Actual output: {process.stdout}"
        )
    
    return process.stdout, process.stderr, process.returncode