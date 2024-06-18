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
