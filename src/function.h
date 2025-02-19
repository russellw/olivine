struct FunctionImpl;

class Function {
	FunctionImpl* p;

public:
	Function();

	// For internal use
	explicit Function(FunctionImpl* p): p(p) {
	}

	Function(Type returnType, Ref ref, const vector<Term>& params);
	Function(Type returnType, Ref ref, const vector<Term>& params, const vector<Instruction>& instructions);

	Type returnType() const;
	Ref ref() const;
	vector<Term> params() const;

	size_t size() const;
	Instruction operator[](size_t i) const;

	// Iterators
	using const_iterator = vector<Instruction>::const_iterator;

	const_iterator begin() const;
	const_iterator end() const;

	const_iterator cbegin() const;
	const_iterator cend() const;

	// Comparison by value
	bool operator==(Function b) const;
	bool operator!=(Function b) const;
};

namespace std {
template <> struct hash<Function> {
	size_t operator()(const Function& t) const {
		size_t h = 0;
		hash_combine(h, hash<Type>()(t.returnType()));
		hash_combine(h, hash<Ref>()(t.ref()));
		hash_combine(h, hashVector(t.params()));
		hash_combine(h, hashRange(t.begin(), t.end()));
		return h;
	}
};
} // namespace std
