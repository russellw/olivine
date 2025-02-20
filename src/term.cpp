#include "all.h"

struct TermImpl {
	const Tag tag;
	const Type ty;

	// Atom
	const Ref ref;
	const cpp_int intVal;

	// Compound
	const vector<Term> v;

	TermImpl(Tag tag, Type ty): tag(tag), ty(ty) {
	}

	TermImpl(Tag tag, Type ty, const Ref& ref): tag(tag), ty(ty), ref(ref) {
	}

	TermImpl(Tag tag, Type ty, const cpp_int& intVal): tag(tag), ty(ty), intVal(intVal) {
	}

	TermImpl(Tag tag, Type ty, const vector<Term>& v): tag(tag), ty(ty), v(v) {
	}
};

TermImpl trueImpl(Int, boolTy(), cpp_int(1));
TermImpl falseImpl(Int, boolTy(), cpp_int(0));

TermImpl nullImpl(Null, ptrTy());

Term::Term(): p(&nullImpl) {
}

Term::Term(Tag tag) {
	p = new TermImpl(tag, voidTy());
}

Term::Term(Tag tag, Type ty, const Ref& ref) {
	p = new TermImpl(tag, ty, ref);
}

Term::Term(Tag tag, Type ty, Term a) {
	p = new TermImpl(tag, ty, {a});
}

Term::Term(Tag tag, Type ty, Term a, Term b) {
	p = new TermImpl(tag, ty, {a, b});
}

Term ::Term(Tag tag, Type ty, const vector<Term>& v) {
	p = new TermImpl(tag, ty, v);
}

Tag Term::tag() const {
	return p->tag;
}

Type Term::ty() const {
	return p->ty;
}

Ref Term::ref() const {
	return p->ref;
}

string Term::str() const {
	return std::get<string>(p->ref);
}

cpp_int Term::intVal() const {
	return p->intVal;
}

size_t Term::size() const {
	return p->v.size();
}

Term Term::operator[](size_t i) const {
	ASSERT(i < p->v.size());
	return p->v[i];
}

Term::const_iterator Term::begin() const {
	return p->v.begin();
}

Term::const_iterator Term::end() const {
	return p->v.end();
}

Term::const_iterator Term::cbegin() const {
	return p->v.cbegin();
}

Term::const_iterator Term::cend() const {
	return p->v.cend();
}

bool Term::operator==(Term b0) const {
	auto a = p;
	auto b = b0.p;
	if (a->tag != b->tag) {
		return false;
	}
	if (a->ty != b->ty) {
		return false;
	}
	if (a->ref != b->ref) {
		return false;
	}
	if (a->intVal != b->intVal) {
		return false;
	}
	return a->v == b->v;
}

bool Term::operator!=(Term b) const {
	return !(*this == b);
}

Term trueConst(&trueImpl);
Term falseConst(&falseImpl);

Term nullConst(&nullImpl);

Term intConst(Type ty, const cpp_int& val) {
	ASSERT(ty.kind() == IntKind);
	auto p = new TermImpl(Int, ty, val);
	return Term(p);
}
