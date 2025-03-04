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

TermImpl nullImpl(NullPtr, ptrTy());

Term::Term() {
	p = new TermImpl(None, voidTy());
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

Term::Term(Tag tag, Type ty, Term a, Term b, Term c) {
	p = new TermImpl(tag, ty, {a, b, c});
}

Term::Term(Tag tag, Type ty, const vector<Term>& v) {
	p = new TermImpl(tag, ty, v);
}

Term::Term(Tag tag, Term a) {
	p = new TermImpl(tag, a.ty(), {a});
}

Term::Term(Tag tag, Term a, Term b) {
	p = new TermImpl(tag, a.ty(), {a, b});
}

Term ::Term(Tag tag, const vector<Term>& v) {
	ASSERT(v.size());
	p = new TermImpl(tag, v[0].ty(), v);
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
	return p->ref.str();
}

cpp_int Term::intVal() const {
	return p->intVal;
}

size_t Term::size() const {
	return p->v.size();
}

Term Term::operator[](size_t i) const {
	ASSERT(i < size());
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

Term trueConst(&trueImpl);
Term falseConst(&falseImpl);

Term nullPtrConst(&nullImpl);

Term intConst(Type ty, const cpp_int& val) {
	ASSERT(ty.kind() == IntKind);
	auto p = new TermImpl(Int, ty, val);
	return Term(p);
}

Term zeroVal(Type ty) {
	switch (ty.kind()) {
	case ArrayKind: {
		// For arrays, create an array of zero values
		vector<Term> elements;
		Type elemType = ty[0]; // Get element type
		for (size_t i = 0; i < ty.len(); i++) {
			elements.push_back(zeroVal(elemType));
		}
		return array(elemType, elements);
	}
	case DoubleKind:
		// For double type, return 0.0
		return floatConst(ty, "0.0");
	case FloatKind:
		// For float type, return 0.0
		return floatConst(ty, "0.0");
	case FuncKind:
		// Function types cannot have zero values
		throw std::runtime_error("Cannot create zero value for function type");
	case IntKind:
		// For integers, return a zero constant of the appropriate bit length
		return intConst(ty, 0);
	case PtrKind:
		// For pointers, return null
		return nullPtrConst;
	case StructKind: {
		// For structs, create a tuple of zero values for each field
		vector<Term> fields;
		for (Type fieldType : ty) {
			fields.push_back(zeroVal(fieldType));
		}
		return tuple(fields);
	}
	case VecKind: {
		// Vector types are handled similarly to arrays
		vector<Term> elements;
		Type elemType = ty[0]; // Get element type
		for (size_t i = 0; i < ty.len(); i++) {
			elements.push_back(zeroVal(elemType));
		}
		return vec(elemType, elements);
	}
	default:
		throw std::runtime_error("Unknown type kind in zeroVal");
	}
}

Term getElementPtr(Type ty, Term p, const vector<Term>& idxs) {
	for (auto idx : idxs) {
		switch (ty.kind()) {
		case ArrayKind:
			ty = ty[0];
			p = elementPtr(ty, p, idx);
			break;
		case StructKind: {
			auto i = idx.intVal().convert_to<size_t>();
			p = fieldPtr(ty, p, i);
			ty = ty[i];
			break;
		}
		default:
			throw runtime_error("expected compound type");
		}
	}
	return p;
}

Term arrayBytes(unsigned char* v, size_t n) {
	// Create a vector to hold the Term for each byte
	vector<Term> elements;
	elements.reserve(n);

	// Convert each byte to an 8-bit integer Term
	for (size_t i = 0; i < n; ++i) {
		// Create an integer constant Term with intTy(8) type and the byte value
		elements.push_back(intConst(intTy(8), cpp_int(v[i])));
	}

	// Create and return an Array Term containing all the byte elements
	return array(intTy(8), elements);
}
