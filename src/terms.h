// Terms represent all code and data
// including constants, variables, instructions and functions
enum Tag {
	// Logic operations are similar to arithmetic operations, but only work on integers
	AShr,

	// Most arithmetic operations take two operands
	// which must be of the same type
	// and return that type
	// Term(Add, a.type(), a, b)
	Add,

	And,
	Array,

	// The left-hand side of an assignment instruction must be a variable of compatible type
	// The assignment instruction itself has type void
	// as it is an instruction that changes the world, rather than an expression that returns a value
	Assign,

	// A conditional branch has three operands
	// The condition is an expression of Boolean type
	// The true and false branches are goto instructions
	Br,

	// Equality applies to integers and compound types
	// but not to floating-point numbers, which have a separate equality operation
	// Term(Eq, boolType(), a, b)
	Eq,

	// Floating-point arithmetic is separate from integer arithmetic
	FAdd,

	FDiv,

	// Floating-point equality is a distinct operation
	// that does not behave the same way as the usual notion of equality
	FEq,

	FLe,
	FLt,
	FMul,

	// Unary arithmetic operations take one operand
	// and return that type
	// Term(FNeg, a.type(), a)
	FNeg,

	FRem,
	FSub,

	// Representing floating-point numbers is complicated
	// For now, they are stored in their original string format
	Float,

	Function,

	// GlobalRef represents a reference to a global variable or function
	// Like local variables, these can be strings or index numbers
	GlobalRef,

	GlobalVar,
	Int,

	// A Jmp instruction (unconditional branch) has an integer constant operand
	// that is the index in the current function of the target instruction
	// During parsing, a label that has not yet been resolved
	// is represented as a variable
	Jmp,

	LShr,
	Mul,

	// Logical negation doesn't correspond to an LLVM instruction
	// but is useful enough to be worth having in the internal representation
	// and having introduced it, we don't need separate tags for Ne and FNe
	Not,

	Null,
	Or,

	// A return instruction has a single operand
	// of any type other than void
	// that must match the type of the host function
	Ret,

	// A `ret void` instruction has no operands
	RetVoid,

	SDiv,
	SLe,
	SLt,
	SRem,
	Shl,
	Sub,
	Tuple,
	UDiv,
	ULe,
	ULt,
	URem,
	Unreachable,

	// Var represents local variables, including function parameters
	// All occurrences of a given variable in a given function must have the same type
	Var,

	Xor,
};

struct TermImpl;

class Term {
	TermImpl* p;

public:
	// The default Term is Null
	Term();

	// For internal use
	explicit Term(TermImpl* p): p(p) {
	}

	// Atom constructors
	explicit Term(Tag tag);
	Term(Tag tag, Type type, const Ref& ref);

	// Compound constructors
	Term(Tag tag, Type type, Term a);
	Term(Tag tag, Type type, Term a, Term b);
	Term(Tag tag, Type type, const vector<Term>& v);

	// Every term has a tag and type
	Tag tag() const;
	Type type() const;

	// Atom data
	Ref ref() const;
	string str() const;
	cpp_int intVal() const;

	// Compound terms contain other terms
	size_t size() const;
	Term operator[](size_t i) const;

	// Iterators
	using const_iterator = vector<Term>::const_iterator;

	const_iterator begin() const;
	const_iterator end() const;

	const_iterator cbegin() const;
	const_iterator cend() const;

	// Comparison by value
	bool operator==(Term b) const;
	bool operator!=(Term b) const;
};

namespace std {
template <> struct hash<Term> {
	size_t operator()(const Term& t) const {
		size_t h = hash<Tag>()(t.tag());
		h ^= hash<Type>()(t.type()) + 0x9e3779b9 + (h << 6) + (h >> 2);
		h ^= hash<Ref>()(t.ref()) + 0x9e3779b9 + (h << 6) + (h >> 2);
		h ^= hash<cpp_int>()(t.intVal()) + 0x9e3779b9 + (h << 6) + (h >> 2);
		for (size_t i = 0; i < t.size(); ++i) {
			h ^= hash<Term>()(t[i]) + 0x9e3779b9 + (h << 6) + (h >> 2);
		}
		return h;
	}
};
} // namespace std

extern Term trueConst;
extern Term falseConst;

// Null is the only pointer constant
extern Term nullConst;

// Integer constants are arbitrary precision
Term intConst(Type type, const cpp_int& val);

// There are two varieties of general compound data terms
// An array contains zero or more items, all the same type
Term array(Type elementType, const vector<Term>& elements);

// A tuple contains zero or more items, that may be of different types
// An example of where a tuple of zero items is useful in practice:
// the parameter list of a function that takes no parameters
Term tuple(const vector<Term>& elements);

// A function is represented as a term whose elements are:
// 0   GlobalRef, name or index number
// 1   Parameter list
// 2.. Instructions
Term function(Type returnType, Term ref, const vector<Term>& params, const vector<Term>& instructions);

inline Term getFunctionRef(Term f) {
	return f[0];
}

inline Term getFunctionParams(Term f) {
	return f[1];
}

vector<Term> getFunctionInstructions(Term f);

#define unpackFunction(f)                                                                                                          \
	auto ref = getFunctionRef(f);                                                                                                  \
	auto params = getFunctionParams(f);                                                                                            \
	auto instructions = getFunctionInstructions(f)

// SORT FUNCTIONS

inline Term assign(Term a, Term b) {
	return Term(Assign, voidType(), a, b);
}

inline Term floatConst(Type type, const string& val) {
	return Term(Float, type, Ref(val));
}

inline Term globalRef(Type type, const Ref& ref) {
	return Term(GlobalRef, type, ref);
}

inline Term ret() {
	return Term(RetVoid);
}

inline Term ret(Term a) {
	return Term(Ret, voidType(), a);
}

inline Term unreachable() {
	return Term(Unreachable);
}

inline Term var(Type type, const Ref& ref) {
	return Term(Var, type, ref);
}
