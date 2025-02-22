// Intermediate code representation is similar in some ways to LLVM
// One important difference is that it is not SSA; variables can be reassigned
// Another, even more fundamental difference, is that it is purely functional
// That is, it represents low-level imperative code
// but the data structures in which that code is represented, are purely functional in nature
// An optimization pass that modifies a function, must return a new version of that function, leaving the original untouched
// And all code fragments have value semantics
// If two instructions perform the same operation on the same operand, they are the same
// Instructions are distinguished by their location in a function, not by reference
enum Kind {
	ArrayKind,
	DoubleKind,
	FloatKind,
	FuncKind,
	IntKind,
	PtrKind,
	StructKind,
	VecKind,
	VoidKind,
};

struct TypeImpl;

class Type {
	TypeImpl* p;

public:
	// The default Type is void
	Type();

	// For internal use
	explicit Type(TypeImpl* p): p(p) {
	}

	Kind kind() const;

	// For integers, len is the number of bits
	// As in LLVM, bool is a 1-bit integer type
	// For an array or vector type, it is the number of elements
	size_t len() const;

	// The size of a type is the number of component types it has
	// For scalar types, it is 0
	// For array or vector types, it is 1
	// For structure types, it is the number of fields
	// For function types, it is 1 + the number of parameters
	size_t size() const;

	// For function types, the return type is component 0
	Type operator[](size_t i) const;

	// Iterators
	using const_iterator = vector<Type>::const_iterator;

	const_iterator begin() const;
	const_iterator end() const;

	const_iterator cbegin() const;
	const_iterator cend() const;

	// Comparison by value
	bool operator==(Type b) const;
	bool operator!=(Type b) const;

	friend struct hash<Type>;
};

namespace std {
template <> struct hash<Type> {
	size_t operator()(const Type& t) const {
		return hash<TypeImpl*>()(t.p);
	}
};
} // namespace std

Type voidTy();

Type boolTy();
Type intTy(size_t len);

Type floatTy();
Type doubleTy();

Type ptrTy();

Type vecTy(size_t len, Type element);
Type arrayTy(size_t len, Type element);
Type structTy(const vector<Type>& fields);

Type funcTy(Type rty, const vector<Type>& params);

inline bool isInt(Type ty) {
	return ty.kind() == IntKind;
}

inline bool isFloat(Type ty) {
	switch (ty.kind()) {
	case DoubleKind:
	case FloatKind:
		return true;
	}
	return false;
}
