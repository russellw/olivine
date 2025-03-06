#include "all.h"

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

Line parseLabel(string line) {
	// Skip leading whitespace
	size_t start = 0;
	while (start < line.length() && isspace(line[start])) {
		start++;
	}

	if (start >= line.length()) {
		return Line("", "");
	}

	// Check for numeric label (one or more digits)
	if (isdigit(line[start])) {
		size_t labelEnd = start;
		while (labelEnd < line.length() && isdigit(line[labelEnd])) {
			labelEnd++;
		}

		string label = line.substr(start, labelEnd - start);

		// Skip whitespace after the label
		while (labelEnd < line.length() && isspace(line[labelEnd])) {
			labelEnd++;
		}

		string text = (labelEnd < line.length()) ? line.substr(labelEnd) : "";
		return Line(label, text);
	}

	// Check for alphanumeric label
	// (starts with letter/underscore, followed by letters/digits/underscores, ends with colon)
	if (isalpha(line[start]) || line[start] == '_') {
		size_t labelEnd = start;
		while (labelEnd < line.length() && (isalnum(line[labelEnd]) || line[labelEnd] == '_')) {
			labelEnd++;
		}

		// Check if the label is followed by a colon
		if (labelEnd < line.length() && line[labelEnd] == ':') {
			string label = line.substr(start, labelEnd - start);

			// Skip the colon and any whitespace after it
			labelEnd++;
			while (labelEnd < line.length() && isspace(line[labelEnd])) {
				labelEnd++;
			}

			string text = (labelEnd < line.length()) ? line.substr(labelEnd) : "";
			return Line(label, text);
		}
	}

	// No label found
	return Line("", line);
}
