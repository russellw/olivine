#include "all.h"

#ifdef _WIN32
#include <windows.h>

LONG WINAPI unhandledExceptionFilter(EXCEPTION_POINTERS* exInfo) {
	cerr << "Unhandled exception: " << std::hex << exInfo->ExceptionRecord->ExceptionCode << '\n';
	return EXCEPTION_EXECUTE_HANDLER;
}
#endif

int main(int argc, char** argv) {
	try {
#ifdef _WIN32
		SetUnhandledExceptionFilter(unhandledExceptionFilter);
#endif
		vector<string> files;
		for (int i = 1; i < argc; i++) {
			auto s = argv[i];
			s = 0;
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
					return 0;
				}
				cerr << argv[i] << ": unknown option\n";
				return 1;
			}
			files.push_back(s);
		}
		Target target;
		for (auto file : files) {
			auto text = readFile(file);
			Parser parser(file, text, target);
		}
		return 0;
	} catch (const std::exception& e) {
		cerr << e.what() << '\n';
		return 1;
	} catch (...) {
		cerr << "Unknown exception\n";
		return 1;
	}
}
