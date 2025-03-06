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

ostream& operator<<(ostream& os, const Line& line) {
	return os << std::left << std::setw(6) << line.label << ' ' << line.text;
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
			newText.replace(startPos, length, "_STRING_LITERAL_" + to_string(literalIndex) + "$");
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
		string definition = "LET _STRING_LITERAL_" + to_string(i) + "$ = " + stringLiterals[i];
		result.insert(result.begin() + i, Line("", definition));
	}

	return result;
}

/*
Add END terminating statement to a Basic program
if it is not already present
*/
vector<Line> addEnd(vector<Line> lines) {
	// Check if there's already an END statement in the program
	bool hasEnd = false;

	for (const Line& line : lines) {
		// Convert the line text to uppercase for case-insensitive comparison
		string upperText = line.text;
		std::transform(upperText.begin(), upperText.end(), upperText.begin(), [](unsigned char c) { return std::toupper(c); });

		// Remove any leading spaces for the comparison
		size_t firstNonSpace = upperText.find_first_not_of(" \t");
		if (firstNonSpace != string::npos) {
			upperText = upperText.substr(firstNonSpace);
		}

		// Check if the line starts with "END"
		if (upperText == "END" || upperText.find("END ") == 0) {
			hasEnd = true;
			break;
		}
	}

	// If there's no END statement, add one
	if (!hasEnd && !lines.empty()) {
		lines.push_back(Line("", "END"));
	}
	// If the vector is empty, add an END statement with no label
	else if (lines.empty()) {
		lines.push_back(Line("", "END"));
	}

	return lines;
}

// Declare subroutineNumber as a global variable with initialization
size_t subroutineNumber = 0;

/*
Add a subroutine to the end of a program:
First add a line with the label naming the subroutine
Then the body that was passed as a parameter
And finally a RETURN statement

The name of each subroutine so added, is constructed from:
the string `_SUBROUTINE_`
and the integer subroutineNumber

The name is then returned from addSubroutine

For example, if as a starting condition subroutineNumber=0
and `PRINT A$` is passed
the added code is:
_SUBROUTINE_0:
PRINT A$
RETURN

subroutineNumber is incremented to 1
and "_SUBROUTINE_0" is returned
*/
string addSubroutine(vector<Line>& program, vector<Line> body) {
	// Construct the subroutine name
	string subroutineName = "_SUBROUTINE_" + to_string(subroutineNumber);

	// Create the subroutine label line
	Line labelLine(subroutineName, "");
	program.push_back(labelLine);

	// Add the body of the subroutine
	program.insert(program.end(), body.begin(), body.end());

	// Add the RETURN statement at the end
	Line returnLine("", "RETURN");
	program.push_back(returnLine);

	// Increment the subroutine counter
	subroutineNumber++;

	// Return the name of the subroutine
	return subroutineName;
}

vector<Line> splitColons(Line line) {
	// If the line begins with "LET _STRING_LITERAL_", return it unchanged
	if (line.text.substr(0, 20) == "LET _STRING_LITERAL_") {
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
 * Lines beginning with `LET _STRING_LITERAL_` are returned unchanged
 * As all string literals have been factored out by now, that means we do not need to worry about quoted strings
 */
Line upper(Line line) {
	// Check if the line begins with `LET _STRING_LITERAL_`
	// If it does, return it unchanged
	if (line.text.size() >= 20 && line.text.substr(0, 20) == "LET _STRING_LITERAL_") {
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

Line insertLet(Line line) {
	// Skip string literal definitions that have already been extracted
	if (line.text.substr(0, 20) == "LET _STRING_LITERAL_") {
		return line;
	}

	// Check if the line already starts with LET
	if (line.text.substr(0, 4) == "LET ") {
		return line;
	}

	// Check if this is an assignment statement
	// Variable names in BASIC can start with a letter and contain letters, digits, and underscores
	// They can also end with $ for string variables
	// We need to look for patterns like "X = ..." or "NAME$ = ..." at the beginning of the line

	size_t pos = 0;
	size_t len = line.text.length();

	// Skip leading whitespace
	while (pos < len && std::isspace(line.text[pos])) {
		pos++;
	}

	// Check if we have a variable name at the start
	if (pos < len && (std::isalpha(line.text[pos]) || line.text[pos] == '_')) {
		size_t varStart = pos;

		// Consume the variable name (letters, digits, underscores)
		pos++;
		while (pos < len && (std::isalnum(line.text[pos]) || line.text[pos] == '_')) {
			pos++;
		}

		// Check for string variable marker $
		if (pos < len && line.text[pos] == '$') {
			pos++;
		}

		// Skip whitespace after variable name
		while (pos < len && std::isspace(line.text[pos])) {
			pos++;
		}

		// If we have an equal sign, this is an assignment
		if (pos < len && line.text[pos] == '=') {
			// Insert LET at the beginning (respecting leading whitespace)
			string whitespace = line.text.substr(0, varStart);
			string remainder = line.text.substr(varStart);
			line.text = whitespace + "LET " + remainder;
		}
	}

	return line;
}

Line convertTabs(Line line) {
	// Return string literals unchanged
	if (line.text.find("LET _STRING_LITERAL_") == 0) {
		return line;
	}

	// Create a new string for the modified text
	string newText;
	newText.reserve(line.text.length()); // Reserve space to avoid reallocations

	// Process each character, replacing tabs with spaces
	for (char c : line.text) {
		if (c == '\t') {
			// Replace tab with a single space
			newText += ' ';
		} else {
			newText += c;
		}
	}

	// Return a new Line with the same label and modified text
	return Line(line.label, newText);
}

Line normSpaces(Line line) {
	// Don't modify string literal lines
	if (line.text.substr(0, 20) == "LET _STRING_LITERAL_") {
		return line;
	}

	string text = line.text;
	string result;

	// Skip leading spaces
	size_t start = 0;
	while (start < text.length() && text[start] == ' ') {
		start++;
	}

	// Process the text, handling consecutive spaces
	bool prevSpace = false;
	for (size_t i = start; i < text.length(); i++) {
		if (text[i] == ' ') {
			if (!prevSpace) {
				result += ' ';
				prevSpace = true;
			}
		} else {
			result += text[i];
			prevSpace = false;
		}
	}

	// Remove trailing space if it exists
	if (!result.empty() && result.back() == ' ') {
		result.pop_back();
	}

	return Line(line.label, result);
}

vector<Line> splitPrint(Line line) {
	// If this isn't a PRINT statement, return unchanged
	if (line.text.substr(0, 6) != "PRINT ") {
		return {line};
	}

	vector<Line> result;
	string printContent = line.text.substr(6); // Remove "PRINT " from the beginning

	// If the PRINT statement is empty, return it unchanged
	if (printContent.empty()) {
		return {line};
	}

	// State tracking variables
	size_t pos = 0;
	size_t startPos = 0;
	int parenDepth = 0;

	while (pos < printContent.size()) {
		char c = printContent[pos];

		// Track parentheses to avoid splitting inside expressions
		if (c == '(') {
			parenDepth++;
		} else if (c == ')') {
			parenDepth--;
		}

		// Only consider delimiters outside of parentheses
		if (parenDepth == 0 && (c == ';' || c == ',')) {
			// Extract the current operand (excluding the delimiter)
			string operand = printContent.substr(startPos, pos - startPos);

			// Determine which keyword to use based on the delimiter
			string printKeyword;
			if (c == ';') {
				printKeyword = "PRINT_SEMI";
			} else { // c == ','
				printKeyword = "PRINT_COMMA";
			}

			// For the first operand, preserve the original line's label
			string newLabel = result.empty() ? line.label : "";
			result.push_back(Line(newLabel, printKeyword + " " + operand));

			// Move past the delimiter
			startPos = pos + 1;
		}

		pos++;
	}

	// Add the final operand if there is any content remaining
	if (startPos < printContent.size()) {
		string finalOperand = printContent.substr(startPos);
		// Final operand uses regular PRINT keyword
		string newLabel = result.empty() ? line.label : "";
		result.push_back(Line(newLabel, "PRINT " + finalOperand));
	}

	// Edge case: If there were no delimiters found but there is content,
	// return the original line (already a single PRINT statement)
	if (result.empty() && !printContent.empty()) {
		return {line};
	}

	return result;
}
