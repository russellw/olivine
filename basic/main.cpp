#include "all.h"

#ifdef _WIN32
#include <windows.h>

LONG WINAPI unhandledExceptionFilter(EXCEPTION_POINTERS* exInfo) {
	cerr << "Unhandled exception: " << std::hex << exInfo->ExceptionRecord->ExceptionCode << '\n';
	return EXCEPTION_EXECUTE_HANDLER;
}
#endif

static char* optArg(int argc, char** argv, int& i, char* s) {
	if (s[1]) {
		return s + 1;
	}
	if (i + 1 == argc) {
		throw runtime_error(string(argv[i]) + ": expected arg");
	}
	++i;
	return argv[i];
}

static string readFile(string filename) {
	std::ifstream file(filename, std::ios::binary | std::ios::ate);
	if (!file) {
		// Get the error code and create a system_error with the OS error message
		std::error_code ec(errno, std::system_category());
		throw std::system_error(ec, "Failed to open file: " + filename);
	}

	std::streamsize size = file.tellg();
	file.seekg(0, std::ios::beg);

	string content(size, '\0');
	if (!file.read(&content[0], size)) {
		std::error_code ec(errno, std::system_category());
		throw std::system_error(ec, "Failed to read file: " + filename);
	}

	return content;
}

int main(int argc, char** argv) {
	try {
#ifdef _WIN32
		SetUnhandledExceptionFilter(unhandledExceptionFilter);
#endif
		string file;
		for (int i = 1; i < argc; i++) {
			auto s = argv[i];
			if (*s == '-') {
				while (*s == '-') {
					s++;
				}
				switch (*s) {
				case 'V':
				case 'v':
					cout << "Olivine Basic\n";
					return 0;
				case 'h':
					cout << "Usage: basic [options] file.bas\n";
					cout << "\n";
					cout << "-h  Show help\n";
					cout << "-V  Show version\n";
					return 0;
				}
				throw runtime_error(string(argv[i]) + ": unknown option");
			}
			file = s;
		}
		if (file.empty()) {
			throw runtime_error("No input file");
		}
		auto text = readFile(file);
		return 0;
	} catch (const std::exception& e) {
		cerr << e.what() << '\n';
		return 1;
	} catch (...) {
		cerr << "Unknown exception\n";
		return 1;
	}
}
