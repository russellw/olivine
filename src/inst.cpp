#include "all.h"

struct InstImpl {
	const Opcode opcode;
	const vector<Term> v;

	InstImpl(Opcode opcode, const vector<Term>& v): opcode(opcode), v(v) {
	}
};

Inst::Inst(Opcode opcode) {
	p = new InstImpl(opcode, {});
}

Inst::Inst(Opcode opcode, Term a) {
	p = new InstImpl(opcode, {a});
}

Inst::Inst(Opcode opcode, Term a, Term b) {
	p = new InstImpl(opcode, {a, b});
}

Inst::Inst(Opcode opcode, Term a, Term b, Term c) {
	p = new InstImpl(opcode, {a, b, c});
}

Inst::Inst(Opcode opcode, const vector<Term>& v) {
	p = new InstImpl(opcode, v);
}

Opcode Inst::opcode() const {
	return p->opcode;
}

size_t Inst::size() const {
	return p->v.size();
}

Term Inst::operator[](size_t i) const {
	ASSERT(i < size());
	return p->v[i];
}

Inst::const_iterator Inst::begin() const {
	return p->v.begin();
}

Inst::const_iterator Inst::end() const {
	return p->v.end();
}

Inst::const_iterator Inst::cbegin() const {
	return p->v.cbegin();
}

Inst::const_iterator Inst::cend() const {
	return p->v.cend();
}

bool Inst::operator==(Inst b0) const {
	auto a = p;
	auto b = b0.p;
	if (a->opcode != b->opcode) {
		return false;
	}
	return a->v == b->v;
}
