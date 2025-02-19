enum Opcode {
	// The left-hand side of an assignment instruction must be a variable of compatible type
	Assign,

	// A conditional branch has three operands
	// The condition is an expression of Boolean type
	// The true and false branches are labels
	Br,

	// A Jmp instruction (unconditional branch) has one Label operand
	Jmp,

	// A return instruction has a single operand
	// of any type other than void
	// that must match the type of the host function
	Ret,

	// A `ret void` instruction has no operands
	RetVoid,

	Unreachable,
};

struct InstructionImpl;

class Instruction {
	InstructionImpl* p;

public:
	Instruction();

	// For internal use
	explicit Instruction(InstructionImpl* p): p(p) {
	}

	explicit Instruction(Opcode opcode);
	Instruction(Opcode opcode, Term a);
	Instruction(Opcode opcode, Term a, Term b);
	Instruction(Opcode opcode, Term a, Term b, Term c);

	Opcode opcode() const;

	size_t size() const;
	Term operator[](size_t i) const;

	// Iterators
	using const_iterator = vector<Term>::const_iterator;

	const_iterator begin() const;
	const_iterator end() const;

	const_iterator cbegin() const;
	const_iterator cend() const;

	// Comparison by value
	bool operator==(Instruction b) const;
	bool operator!=(Instruction b) const;
};

inline Instruction jmp(Ref target) {
	return Instruction(Jmp, label(target));
}

inline Instruction br(Term cond, Ref ifTrue, Ref ifFalse) {
	ASSERT(cond.type() == boolType());
	return Instruction(Br, cond, label(ifTrue), label(ifFalse));
}
inline Instruction assign(Term a, Term b) {
	return Instruction(Assign, a, b);
}

inline Instruction ret() {
	return Instruction(RetVoid);
}

inline Instruction ret(Term a) {
	return Instruction(Ret, a);
}

inline Instruction unreachable() {
	return Instruction(Unreachable);
}
