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

	// A Call expression has 1+N operands, the function itself plus the arguments
	Call,

	// Convert the single operand to the specified type
	// LLVM breaks this down into several different instructions
	// Olivine amalgamates most of them into one
	// Where applicable, source and destination are treated as unsigned
	// Specifically signed conversions use SCast
	Cast,

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

	Int,
	LShr,
	Label,

	// Load takes a pointer operand
	// and tries to load from it a value of the specified type
	// with the usual caveats about bad pointers being undefined behavior
	// Note that the corresponding Store is an instruction, not a term
	Load,

	Mul,

	// Logical negation doesn't correspond to an LLVM instruction
	// but is useful enough to be worth having in the internal representation
	// and having introduced it, we don't need separate tags for Ne and FNe
	Not,

	Null,
	Or,

	// Convert the single operand to the specified type
	// Treat source or destination as signed
	SCast,

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
	Term(Tag tag, Type ty, const Ref& ref);

	// Compound constructors
	Term(Tag tag, Type ty, Term a);
	Term(Tag tag, Type ty, Term a, Term b);
	Term(Tag tag, Type ty, const vector<Term>& v);

	// Every term has a tag and type
	Tag tag() const;
	Type ty() const;

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
	size_t operator()(const Term& a) const {
		size_t h = 0;
		hash_combine(h, hash<Tag>()(a.tag()));
		hash_combine(h, hash<Type>()(a.ty()));
		hash_combine(h, hash<Ref>()(a.ref()));
		hash_combine(h, hash<cpp_int>()(a.intVal()));
		hash_combine(h, hashRange(a.begin(), a.end()));
		return h;
	}
};
} // namespace std

extern Term trueConst;
extern Term falseConst;

// Null is the only pointer constant
extern Term nullConst;

// Integer constants are arbitrary precision
Term intConst(Type ty, const cpp_int& val);

// SORT FUNCTIONS

inline Term array(Type elementType, const vector<Term>& elements) {
	return Term(Array, arrayTy(elements.size(), elementType), elements);
}

inline Term call(Type ty, Term f, const vector<Term>& args) {
	return Term(Call, ty, cons(f, args));
}

inline Term cmp(Tag tag, Term a, Term b) {
	return Term(tag, boolTy(), a, b);
}

inline Term floatConst(Type ty, const string& val) {
	return Term(Float, ty, Ref(val));
}

inline Term globalRef(Type ty, const Ref& ref) {
	return Term(GlobalRef, ty, ref);
}

inline Term label(const Ref& ref) {
	return Term(Label, ptrTy(), ref);
}

inline Term not1(Term a) {
	return Term(Not, a.ty(), a);
}

inline Term tuple(const vector<Term>& elements) {
	auto tys = map(elements, [](Term a) { return a.ty(); });
	return Term(Tuple, structTy(tys), elements);
}

inline Term var(Type ty, const Ref& ref) {
	return Term(Var, ty, ref);
}
