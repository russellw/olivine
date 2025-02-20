#include "all.h"

struct TermImpl {
	const Tag tag;
	const Type type;

	// Atom
	const Ref ref;
	const cpp_int intVal;

	// Compound
	const vector<Term> v;

	TermImpl(Tag tag, Type type): tag(tag), type(type) {
	}

	TermImpl(Tag tag, Type type, const Ref& ref): tag(tag), type(type), ref(ref) {
	}

	TermImpl(Tag tag, Type type, const cpp_int& intVal): tag(tag), type(type), intVal(intVal) {
	}

	TermImpl(Tag tag, Type type, const vector<Term>& v): tag(tag), type(type), v(v) {
	}
};

TermImpl trueImpl(Int, boolTy(), cpp_int(1));
TermImpl falseImpl(Int, boolTy(), cpp_int(0));

TermImpl nullImpl(Null, ptrType());

Term::Term(): p(&nullImpl) {
}

Term::Term(Tag tag) {
	p = new TermImpl(tag, voidTy());
}

Term::Term(Tag tag, Type type, const Ref& ref) {
	p = new TermImpl(tag, type, ref);
}

Term::Term(Tag tag, Type type, Term a) {
	p = new TermImpl(tag, type, {a});
}

Term::Term(Tag tag, Type type, Term a, Term b) {
	p = new TermImpl(tag, type, {a, b});
}

Term ::Term(Tag tag, Type type, const vector<Term>& v) {
	p = new TermImpl(tag, type, v);
}

Tag Term::tag() const {
	return p->tag;
}

Type Term::type() const {
	return p->type;
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
	if (a->type != b->type) {
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

Term intConst(Type type, const cpp_int& val) {
	ASSERT(type.kind() == IntKind);
	auto p = new TermImpl(Int, type, val);
	return Term(p);
}
