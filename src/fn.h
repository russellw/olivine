struct FnImpl;

class Fn {
	FnImpl* p;

public:
	Fn();

	// For internal use
	explicit Fn(FnImpl* p): p(p) {
	}

	Fn(Type rty, const Ref& ref, const vector<Term>& params);
	Fn(Type rty, const Ref& ref, const vector<Term>& params, const vector<Inst>& body);

	Type rty() const;
	Ref ref() const;
	vector<Term> params() const;

	size_t size() const;

	bool empty() const {
		return !size();
	}

	Inst operator[](size_t i) const;

	// Iterators
	using const_iterator = vector<Inst>::const_iterator;

	const_iterator begin() const;
	const_iterator end() const;

	const_iterator cbegin() const;
	const_iterator cend() const;
};
