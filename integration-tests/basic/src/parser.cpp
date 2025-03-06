#include "all.h"

// Read a file into a vector of strings, one per line
vector<string> readLines(string file) {
	std::ifstream inFile(file);
	if (!inFile.is_open()) {
		throw runtime_error("Failed to open file: " + file);
	}

	vector<string> lines;
	string line;
	while (std::getline(inFile, line)) {
		lines.push_back(line);
	}

	if (inFile.bad()) {
		throw runtime_error("Error while reading file: " + file);
	}

	inFile.close();
	return lines;
}

string removeComment(string line) {
	bool inQuote = false;
	size_t i = 0;

	// Process the line character by character
	while (i < line.length()) {
		// Handle quoted strings
		if (line[i] == '\"') {
			inQuote = !inQuote;
			i++;
			continue;
		}

		// Only check for comments when not inside a quoted string
		if (!inQuote) {
			// Check for REM comment - need to ensure it's not part of a word
			if (i + 3 <= line.length() && line.substr(i, 3) == "REM" && (i == 0 || !isalnum(line[i - 1])) &&
				(i + 3 == line.length() || !isalnum(line[i + 3]))) {
				return line.substr(0, i);
			}

			// Check for apostrophe comment
			if (line[i] == '\'') {
				return line.substr(0, i);
			}
		}

		i++;
	}

	// No comment found, return the original line
	return line;
}
