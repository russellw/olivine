#include "all.h"

int main(int argc, char** argv) {
	vector<string> files;
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
}
