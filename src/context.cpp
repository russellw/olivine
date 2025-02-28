#include "all.h"

namespace context {
string datalayout;
string triple;
std::set<Ref> comdats;
vector<Fn> decls;

void clear() {
	datalayout.clear();
	triple.clear();
	comdats.clear();
	decls.clear();
}
} // namespace context
