#include "all.h"

namespace context {
string datalayout;
string triple;

vector<Fn> decls;

void clear() {
	datalayout.clear();
	triple.clear();

	decls.clear();
}
} // namespace context
