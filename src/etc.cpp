#include "all.h"

#ifdef _WIN32
#include <windows.h>

#include <dbghelp.h>
#pragma comment(lib, "dbghelp.lib")
#else
#include <execinfo.h>

#include <cxxabi.h>
#include <dlfcn.h>
#endif

void stackTrace(std::ostream& out) {
	constexpr int MAX_FRAMES = 32;

#ifdef _WIN32
	// Initialize symbols
	SymSetOptions(SYMOPT_DEFERRED_LOADS | SYMOPT_UNDNAME | SYMOPT_LOAD_LINES);
	HANDLE process = GetCurrentProcess();
	if (!SymInitialize(process, nullptr, TRUE)) {
		out << "Failed to initialize symbol handler" << std::endl;
		return;
	}

	// Get the stack frames
	void* stack[MAX_FRAMES];
	WORD frames = CaptureStackBackTrace(0, MAX_FRAMES, stack, nullptr);

	// Symbol information buffer
	constexpr int MAX_NAME_LENGTH = 256;
	std::unique_ptr<SYMBOL_INFO[]> symbol_buffer(reinterpret_cast<SYMBOL_INFO*>(new char[sizeof(SYMBOL_INFO) + MAX_NAME_LENGTH]));
	SYMBOL_INFO* symbol = symbol_buffer.get();
	symbol->MaxNameLen = MAX_NAME_LENGTH;
	symbol->SizeOfStruct = sizeof(SYMBOL_INFO);

	// Line information
	IMAGEHLP_LINE64 line;
	line.SizeOfStruct = sizeof(IMAGEHLP_LINE64);
	DWORD displacement;

	out << "Stack trace:" << std::endl;
	for (WORD i = 0; i < frames; i++) {
		// Get symbol name
		if (SymFromAddr(process, reinterpret_cast<DWORD64>(stack[i]), nullptr, symbol)) {
			// Get line information
			if (SymGetLineFromAddr64(process, reinterpret_cast<DWORD64>(stack[i]), &displacement, &line)) {
				out << "\t" << frames - i - 1 << ": " << symbol->Name << " at " << line.FileName << ":" << line.LineNumber
					<< std::endl;
			} else {
				out << "\t" << frames - i - 1 << ": " << symbol->Name << " at "
					<< "unknown location" << std::endl;
			}
		} else {
			out << "\t" << frames - i - 1 << ": "
				<< "<unknown symbol>" << std::endl;
		}
	}

	SymCleanup(process);

#else // UNIX-like systems
	void* stack[MAX_FRAMES];
	int frames = backtrace(stack, MAX_FRAMES);
	std::unique_ptr<char*[], void (*)(void*)> symbols(backtrace_symbols(stack, frames), free);

	if (!symbols) {
		out << "Failed to get stack symbols" << std::endl;
		return;
	}

	out << "Stack trace:" << std::endl;
	for (int i = 1; i < frames; i++) { // Skip the first frame (stackTrace function)
		string symbol(symbols[i]);

		// Parse the symbol string
		size_t nameStart = symbol.find('(');
		size_t nameEnd = symbol.find('+', nameStart);

		if (nameStart != string::npos && nameEnd != string::npos) {
			string mangledName = symbol.substr(nameStart + 1, nameEnd - nameStart - 1);

			int status;
			std::unique_ptr<char, void (*)(void*)> demangledName(
				abi::__cxa_demangle(mangledName.c_str(), nullptr, nullptr, &status), free);

			if (status == 0 && demangledName) {
				// Successfully demangled
				out << "\t" << frames - i - 1 << ": " << demangledName.get();
			} else {
				// Output mangled name if demangling failed
				out << "\t" << frames - i - 1 << ": " << mangledName;
			}

			// Try to get source location using addr2line (could be implemented)
			out << std::endl;
		} else {
			// Fallback to raw symbol
			out << "\t" << frames - i - 1 << ": " << symbol << std::endl;
		}
	}
#endif
}

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

// Count newlines before current position to get line number
size_t currentLine(const string& text, size_t pos) {
	size_t line = 1;
	for (size_t i = 0; i < pos; i++) {
		if (text[i] == '\n') {
			line++;
		}
	}
	return line;
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

string quote(const string& s) {
	if (s == "\n") {
		return "newline";
	}
	return '\'' + s + '\'';
}

string readFile(const string& filename) {
	std::ifstream file(filename, std::ios::binary | std::ios::ate);
	if (!file) {
		return "";
	}

	std::streamsize size = file.tellg();
	file.seekg(0, std::ios::beg);

	string content(size, '\0');
	file.read(&content[0], size);

	return content;
}
