#include "all.h"

struct InstructionImpl {
	const Opcode opcode;
	const vector<Term> operands;

	InstructionImpl(Opcode opcode, const vector<Term>& operands): opcode(opcode), operands(operands) {
	}
};

Instruction::Instruction(Opcode opcode) {
	p = new InstructionImpl(opcode, {});
}

Instruction::Instruction(Opcode opcode, Term a) {
	p = new InstructionImpl(opcode, {a});
}

Instruction::Instruction(Opcode opcode, Term a, Term b) {
	p = new InstructionImpl(opcode, {a, b});
}

Instruction::Instruction(Opcode opcode, Term a, Term b, Term c) {
	p = new InstructionImpl(opcode, {a, b, c});
}
