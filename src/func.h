struct FuncImpl;

class Func {
	FuncImpl* p;

public:
	Func();

	// For internal use
	explicit Func(FuncImpl* p): p(p) {
	}

	Func(Type returnType, const Ref& ref, const vector<Term>& params);
	Func(Type returnType, const Ref& ref, const vector<Term>& params, const vector<Instruction>& instructions);

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
	bool operator==(Func b) const;
	bool operator!=(Func b) const;
};
