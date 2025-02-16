#include "all.h"

int main(int argc, char** argv) {
	vector<char*> files;
	for (int i = 1; i < argc; i++) {
		auto s = argv[i];
		if (*s == '-') {
			while (*s == '-') {
				s++;
			}
			switch (*s) {
			case 'h':
				return 0;
			case 'v':
			case 'V':
				cout << "Olivine 0\n";
				return 0;
			}
			cerr << argv[i] << ": unknown option\n";
			return 1;
		}
		files.push_back(s);
	}
	return 0;
}
