#include "all.h"

bool Ref::operator==(const Ref& b) const {
	return num1 == b.num1 && str1 == b.str1;
}

bool Ref::operator<(const Ref& b) const {
	// First compare by which type
	if (numeric() != b.numeric()) {
		return numeric() < b.numeric();
	}

	// Same type, now compare values
	if (numeric()) {
		// Both are size_t
		return num() < b.num();
	} else {
		// Both are string
		return str() < b.str();
	}
}
