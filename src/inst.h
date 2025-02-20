enum Opcode {
	// Alloca has three operands
	// First, the variable to which the result will be assigned
	// Second, the type to be allocated
	// Instruction operands are terms not types, so this is specified in the form of a zero value of the appropriate type
	// Third, the number of elements
	// This is usually the constant 1, but can be a variable
	Alloca,

	// The left-hand side of an assignment instruction must be a variable of compatible type
	Assign,

	// A Block instruction marks the beginning of a basic block
	// Its operand is a label
	Block,

	// A conditional branch has three operands
	// The condition is an expression of Boolean type
	// The true and false branches are labels
	Br,

	// A Drop instruction evaluates its operand and discards the value
	// It is used in particular for function calls that do not return a value, or whose value is not used
	Drop,

	// A Jmp instruction (unconditional branch) has one Label operand
	Jmp,

	// A return instruction has a single operand
	// of any type other than void
	// that must match the type of the host function
	Ret,

	// A `ret void` instruction has no operands
	RetVoid,

	// Store takes two operands
	// the value (with corresponding type) to be stored
	// and the pointer
	// with the usual caveats about bad pointers being undefined behavior
	// Note that the corresponding Load is a term, not an instruction
	Store,

	Unreachable,
};

struct InstImpl;

class Inst {
	InstImpl* p;

public:
	Inst();

	// For internal use
	explicit Inst(InstImpl* p): p(p) {
	}

	explicit Inst(Opcode opcode);
	Inst(Opcode opcode, Term a);
	Inst(Opcode opcode, Term a, Term b);
	Inst(Opcode opcode, Term a, Term b, Term c);

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
	bool operator==(Inst b) const;

	bool operator!=(Inst b) const{
		return !(*this == b);
	}
};

// SORT FUNCTIONS

inline Inst alloca(Term lval, Type ty, Term n) {
	return Inst(Alloca, lval, zeroVal(ty), n);
}

inline Inst assign(Term a, Term b) {
	return Inst(Assign, a, b);
}

inline Inst block(const Ref& ref) {
	return Inst(Block, label(ref));
}

inline Inst br(Term cond, const Ref& ifTrue, const Ref& ifFalse) {
	ASSERT(cond.ty() == boolTy());
	return Inst(Br, cond, label(ifTrue), label(ifFalse));
}

inline Inst jmp(const Ref& target) {
	return Inst(Jmp, label(target));
}

inline Inst ret() {
	return Inst(RetVoid);
}

inline Inst ret(Term a) {
	return Inst(Ret, a);
}

inline Inst unreachable() {
	return Inst(Unreachable);
}
