struct ProgramImpl;

class Program {
	ProgramImpl* p;

public:
	Program();

	// For internal use
	explicit Program(ProgramImpl* p): p(p) {
	}

	Program(const vector<Global>& globals, const vector<Func>& defs);

	vector<Global> globals() const;

	size_t size() const;

	bool empty() const {
		return !size();
	}

	Func operator[](size_t i) const;

	// Iterators
	using const_iterator = vector<Func>::const_iterator;

	const_iterator begin() const;
	const_iterator end() const;

	const_iterator cbegin() const;
	const_iterator cend() const;
};
