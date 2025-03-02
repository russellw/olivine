#include "all.h"

bool Ref::operator==(const Ref& b) const {
	return num1 == b.num1 && str1 == b.str1;
}
