#include "all.h"

struct GlobalImpl {
	const Type ty;
	const Ref ref;
	const Term val;

	GlobalImpl(Type ty, const Ref& ref, Term val): ty(ty), ref(ref), val(val) {
	}
};

Global::Global() {
	p = new GlobalImpl(voidTy(), 0, Term());
}

Global::Global(Type ty, const Ref& ref) {
	p = new GlobalImpl(ty, ref, none(ty));
}

Global::Global(Type ty, const Ref& ref, Term val) {
	p = new GlobalImpl(ty, ref, val);
}

Type Global::ty() const {
	return p->ty;
}

Ref Global::ref() const {
	return p->ref;
}

Term Global::val() const {
	return p->val;
}

bool Global::operator==(Global b0) const {
	auto a = p;
	auto b = b0.p;
	if (a->ty != b->ty) {
		return false;
	}
	if (a->ref != b->ref) {
		return false;
	}
	return a->val == b->val;
}
