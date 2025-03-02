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

string readFile(const string& filename) {
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
