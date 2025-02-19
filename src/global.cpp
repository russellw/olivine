#include "all.h"

struct GlobalImpl {
	const Type ty;
	const Ref ref;

	GlobalImpl(Type ty, const Ref& ref): ty(ty), ref(ref) {
	}
};

Global::Global(Type ty, const Ref& ref) {
	p = new GlobalImpl(ty, ref);
}
