enum Tag {
	// Logic operations are similar to arithmetic operations, but only work on integers
	AShr,

	// Most arithmetic operations take two operands
	// which must be of the same type
	// and return that type
	// Term(Add, a.type(), a, b)
	Add,

	And,

	// An array contains zero or more items, all the same type
	Array,

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

	// GlobalRef represents a reference to a global variable or function
	// Like local variables, these can be strings or index numbers
	GlobalRef,

	GlobalVar,
	Int,
	LShr,
	Label,
	Mul,

	// Logical negation doesn't correspond to an LLVM instruction
	// but is useful enough to be worth having in the internal representation
	// and having introduced it, we don't need separate tags for Ne and FNe
	Not,

	Null,
	Or,
	SDiv,
	SLe,
	SLt,
	SRem,
	Shl,
	Sub,

	// A tuple contains zero or more items, that may be of different types
	Tuple,

	UDiv,
	ULe,
	ULt,
	URem,

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

// TODO: variable name
// TODO: use hash_combine etc
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

// SORT FUNCTIONS

inline Term array(Type elementType, const vector<Term>& elements) {
	for (auto element : elements) {
		ASSERT(element.type() == elementType);
	}
	return Term(Array, arrayType(elements.size(), elementType), elements);
}

inline Term floatConst(Type type, const string& val) {
	return Term(Float, type, Ref(val));
}

inline Term globalRef(Type type, const Ref& ref) {
	return Term(GlobalRef, type, ref);
}

inline Term label(const Ref& ref) {
	return Term(Label, ptrType(), ref);
}

inline Term tuple(const vector<Term>& elements) {
	auto types = map(elements, [](Term a) { return a.type(); });
	return Term(Tuple, structType(types), elements);
}

inline Term var(Type type, const Ref& ref) {
	return Term(Var, type, ref);
}
