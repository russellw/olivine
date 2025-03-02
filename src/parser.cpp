#include "all.h"

bool isIdPart(int c) {
	switch (c) {
	case '$':
	case '-':
	case '.':
	case '_':
		return true;
	}
	return isAlnum(c);
}

bool containsAt(const string& haystack, size_t position, const string& needle) {
	// Position beyond string length is invalid
	if (position > haystack.length()) {
		return false;
	}

	// For empty needle, any valid position (including end of string) is a match
	if (needle.empty()) {
		return true;
	}

	// Check if there's enough room for needle
	if (position + needle.length() > haystack.length()) {
		return false;
	}

	return haystack.substr(position, needle.length()) == needle;
}

bool endsWith(const string& s, int c) {
	return s.size() && s.back() == c;
}

unsigned parseHex(const string& s, size_t& pos, int maxLen) {
	// Check if we're already at the end of the string
	if (pos >= s.length()) {
		throw runtime_error("No hexadecimal digits found: end of string");
	}

	unsigned result = 0;
	int digitsProcessed = 0;
	bool foundDigit = false;

	while (pos < s.length() && digitsProcessed < maxLen) {
		char c = s[pos];

		// Convert the character to its numeric value
		unsigned digit;
		if (c >= '0' && c <= '9') {
			digit = c - '0';
		} else if (c >= 'a' && c <= 'f') {
			digit = c - 'a' + 10;
		} else if (c >= 'A' && c <= 'F') {
			digit = c - 'A' + 10;
		} else {
			// Not a hex digit, stop parsing
			break;
		}

		// Update the result and tracking variables
		result = (result << 4) | digit;
		foundDigit = true;
		digitsProcessed++;
		pos++;
	}

	// Check if we found at least one digit
	if (!foundDigit) {
		throw runtime_error("No hexadecimal digits found");
	}

	return result;
}

string removeSigil(const string& s) {
	ASSERT(s.size());
	switch (s[0]) {
	case '$':
	case '%':
	case '@':
		return s.substr(1);
	case 'c':
		if (1 < s.size() && s[1] == '"') {
			return s.substr(1);
		}
		break;
	}
	return s;
}

string unwrap(string s) {
	s = removeSigil(s);
	ASSERT(s.size());

	// Unquoted index number or identifier
	if (s[0] != '"') {
		for (auto c : s) {
			ASSERT(isIdPart(c));
		}
		return s;
	}

	// Quoted identifier or string
	size_t pos = 1;
	string r;
	while (s[pos] != '"') {
		ASSERT(pos < s.size());
		int c = s[pos++];
		if (c == '\\') {
			ASSERT(pos < s.size());
			switch (s[pos]) {
			case '\\':
				pos++;
				break;
			default:
				if (isXDigit(s[pos])) {
					c = parseHex(s, pos, 2);
				}
				break;
			}
		}
		r += c;
	}
	ASSERT(pos == s.size() - 1);
	return r;
}

Ref parseRef(string s) {
	s = removeSigil(s);
	ASSERT(s.size());

	// Index number
	if (isDigit(s[0])) {
		for (auto c : s) {
			ASSERT(isDigit(c));
		}
		return Ref(stoull(s));
	}

	// Identifier or string
	return Ref(unwrap(s));
}
