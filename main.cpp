#include "all.h"
using std::invalid_argument;

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
	++i;
	if (i == argc) {
		throw runtime_error(string(argv[i]) + ": expected arg");
	}
	return argv[i];
}

int main(int argc, char** argv) {
	try {
#ifdef _WIN32
		SetUnhandledExceptionFilter(unhandledExceptionFilter);
#endif
		vector<string> files;
		const char* outFile = "a.ll";
		for (int i = 1; i < argc; i++) {
			auto s = argv[i];
			if (*s == '-') {
				while (*s == '-') {
					s++;
				}
				switch (*s) {
				case 'V':
				case 'v':
					cout << "Olivine 0\n";
					return 0;
				case 'h':
					cout << "Usage: olivine [options] file.ll ...\n";
					cout << "\n";
					cout << "-h          Show help\n";
					cout << "-V          Show version\n";
					cout << "-o file.ll  Name output file\n";
					return 0;
				case 'o':
					outFile = optArg(argc, argv, i, s);
					continue;
				}
				throw runtime_error(string(argv[i]) + ": unknown option");
			}
			files.push_back(s);
		}
		if (files.empty()) {
			throw runtime_error("No files given");
		}
		vector<Module*> modules;
		for (auto file : files) {
			auto text = readFile(file);
			Parser parser(file, text);
			modules.push_back(parser.module);
		}
		std::ofstream os(outFile, std::ios::binary);
		os << modules[0];
		return 0;
	} catch (const std::exception& e) {
		cerr << e.what() << '\n';
		return 1;
	} catch (...) {
		cerr << "Unknown exception\n";
		return 1;
	}
}
