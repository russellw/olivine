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

vector<Line> extractStringLiterals(vector<Line> lines) {
	vector<Line> result;
	vector<string> stringLiterals;

	// First pass: collect all string literals and create variable definitions
	for (const Line& line : lines) {
		string text = line.text;
		size_t pos = 0;
		bool inQuote = false;
		string currentLiteral;
		string newText = text;
		vector<pair<size_t, size_t>> replacements; // start position, length

		// Find all string literals in the line
		while (pos < text.length()) {
			if (text[pos] == '"') {
				if (inQuote) {
					// End of string literal
					currentLiteral += '"';

					// Store the string literal and its position for replacement
					size_t literalIndex = stringLiterals.size();
					stringLiterals.push_back(currentLiteral);
					size_t startPos = pos - currentLiteral.length() + 1;
					replacements.push_back({startPos, currentLiteral.length()});

					currentLiteral.clear();
					inQuote = false;
				} else {
					// Start of string literal
					inQuote = true;
					currentLiteral = "\"";
				}
			} else if (inQuote) {
				// Add character to current string literal
				currentLiteral += text[pos];
			}
			pos++;
		}

		// If we're still in a quote at the end of the line, handle the error
		// In a real implementation, this might throw an exception or handle it more gracefully
		if (inQuote) {
			// For this implementation, we'll just close the quote
			currentLiteral += '"';
			stringLiterals.push_back(currentLiteral);
			size_t startPos = text.length() - currentLiteral.length() + 1;
			replacements.push_back({startPos, currentLiteral.length() - 1});
		}

		// Replace string literals with variables in reverse order to maintain correct positions
		std::reverse(replacements.begin(), replacements.end());
		for (size_t i = 0; i < replacements.size(); i++) {
			size_t literalIndex = stringLiterals.size() - i - 1;
			size_t startPos = replacements[i].first;
			size_t length = replacements[i].second;

			// Replace the literal with the variable
			newText.replace(startPos, length, "STRING_LITERAL_" + to_string(literalIndex) + "$");
		}

		// Add the modified line to the result
		if (!replacements.empty()) {
			result.push_back(Line(line.label, newText));
		} else {
			// No string literals in this line, just add it unchanged
			result.push_back(line);
		}
	}

	// Add string literal definitions at the beginning
	for (size_t i = 0; i < stringLiterals.size(); i++) {
		string definition = "LET STRING_LITERAL_" + to_string(i) + "$ = " + stringLiterals[i];
		result.insert(result.begin() + i, Line("", definition));
	}

	return result;
}

vector<Line> splitColons(Line line) {
	// If the line begins with "LET STRING_LITERAL_", return it unchanged
	if (line.text.substr(0, 17) == "LET STRING_LITERAL_") {
		return {line};
	}

	vector<Line> result;
	string currentText = line.text;
	size_t pos = 0;
	bool inQuote = false;

	// Find the position of the next colon that's not inside a quoted string
	for (size_t i = 0; i < currentText.length(); ++i) {
		if (currentText[i] == '"') {
			inQuote = !inQuote;
		} else if (currentText[i] == ':' && !inQuote) {
			// Found a colon not in a quoted string
			string statement = currentText.substr(pos, i - pos);

			// First statement gets the label, others don't
			if (result.empty()) {
				result.push_back(Line(line.label, statement));
			} else {
				result.push_back(Line("", statement));
			}

			pos = i + 1; // Skip the colon
		}
	}

	// Add the last statement
	if (pos < currentText.length()) {
		string lastStatement = currentText.substr(pos);
		if (result.empty()) {
			result.push_back(Line(line.label, lastStatement));
		} else {
			result.push_back(Line("", lastStatement));
		}
	} else if (pos == currentText.length() && result.empty()) {
		// Handle case where the line ends with a colon
		result.push_back(Line(line.label, ""));
	}

	return result;
}

/*
 * Take a Basic line that may be in mixed case
 * and convert it to all upper case, both label and text
 * Lines beginning with `LET STRING_LITERAL_` are returned unchanged
 * As all string literals have been factored out by now, that means we do not need to worry about quoted strings
 */
Line upper(Line line) {
	// Check if the line begins with `LET STRING_LITERAL_`
	// If it does, return it unchanged
	if (line.text.size() >= 18 && line.text.substr(0, 18) == "LET STRING_LITERAL_") {
		return line;
	}

	// Convert the label to uppercase
	string upperLabel = line.label;
	std::transform(upperLabel.begin(), upperLabel.end(), upperLabel.begin(), ::toupper);

	// Convert the text to uppercase
	string upperText = line.text;
	std::transform(upperText.begin(), upperText.end(), upperText.begin(), ::toupper);

	// Return a new Line with the uppercase label and text
	return Line(upperLabel, upperText);
}
