import os


def src_files():
    # Define the directory path to search within
    directory = os.path.join("src", "main", "java", "olivine")

    # List to store all .java filenames
    java_files = []

    # Walk through the directory recursively
    for root, _, files in os.walk(directory):
        for file in files:
            # Check if the file ends with .java
            if file.endswith(".java"):
                # Construct the full file path
                file_path = os.path.join(root, file)
                # Append to the list of java_files
                java_files.append(file_path)

    return java_files


def read_lines(file):
    with open(file) as f:
        return [s.rstrip() for s in f]


def write_lines(file, lines):
    with open(file, "w", newline="\n") as f:
        for s in lines:
            f.write(s + "\n")
