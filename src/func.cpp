#include "all.h"

struct FuncImpl {
	const Type rty;
	const Ref ref;
	const vector<Term> params;
	const vector<Inst> body;

	FuncImpl(Type rty, const Ref& ref, const vector<Term>& params, const vector<Inst>& body)
		: rty(rty), ref(ref), params(params), body(body) {
	}
};

Func::Func() {
	p = new FuncImpl(voidTy(), 0, {}, {});
}

Func::Func(Type rty, const Ref& ref, const vector<Term>& params) {
	p = new FuncImpl(rty, ref, params, {});
}

Func::Func(Type rty, const Ref& ref, const vector<Term>& params, const vector<Inst>& body) {
	p = new FuncImpl(rty, ref, params, body);
}

Type Func::rty() const {
	return p->rty;
}

Ref Func::ref() const {
	return p->ref;
}

vector<Term> Func::params() const {
	return p->params;
}

size_t Func::size() const {
	return p->body.size();
}

Inst Func::operator[](size_t i) const {
	ASSERT(i < size());
	return p->body[i];
}

Func::const_iterator Func::begin() const {
	return p->body.begin();
}

Func::const_iterator Func::end() const {
	return p->body.end();
}

Func::const_iterator Func::cbegin() const {
	return p->body.cbegin();
}

Func::const_iterator Func::cend() const {
	return p->body.cend();
}
