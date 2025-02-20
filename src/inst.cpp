#include "all.h"

struct InstImpl {
	const Opcode opcode;
	const vector<Term> operands;

	InstImpl(Opcode opcode, const vector<Term>& operands): opcode(opcode), operands(operands) {
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
