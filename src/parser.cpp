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
