#include "all.h"

struct FnImpl {
	const Type rty;
	const Ref ref;
	const vector<Term> params;
	const vector<Inst> body;

	FnImpl(Type rty, const Ref& ref, const vector<Term>& params, const vector<Inst>& body)
		: rty(rty), ref(ref), params(params), body(body) {
	}
};

Fn::Fn() {
	p = new FnImpl(voidTy(), (size_t)0, {}, {});
}

Fn::Fn(Type rty, const Ref& ref, const vector<Term>& params) {
	p = new FnImpl(rty, ref, params, {});
}

Fn::Fn(Type rty, const Ref& ref, const vector<Term>& params, const vector<Inst>& body) {
	p = new FnImpl(rty, ref, params, body);
}

Type Fn::rty() const {
	return p->rty;
}

Ref Fn::ref() const {
	return p->ref;
}

vector<Term> Fn::params() const {
	return p->params;
}

size_t Fn::size() const {
	return p->body.size();
}

Inst Fn::operator[](size_t i) const {
	ASSERT(i < size());
	return p->body[i];
}

Fn::const_iterator Fn::begin() const {
	return p->body.begin();
}

Fn::const_iterator Fn::end() const {
	return p->body.end();
}

Fn::const_iterator Fn::cbegin() const {
	return p->body.cbegin();
}

Fn::const_iterator Fn::cend() const {
	return p->body.cend();
}
