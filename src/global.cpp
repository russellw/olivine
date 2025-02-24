#include "all.h"

struct GlobalImpl {
	const Type ty;
	const Ref ref;

	GlobalImpl(Type ty, const Ref& ref): ty(ty), ref(ref) {
	}
};

Global::Global() {
	p = new GlobalImpl(voidTy(), 0);
}

Global::Global(Type ty, const Ref& ref) {
	p = new GlobalImpl(ty, ref);
}

Type Global::ty() const {
	return p->ty;
}

Ref Global::ref() const {
	return p->ref;
}
