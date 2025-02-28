struct GlobalImpl;

class Global {
	GlobalImpl* p;

public:
	Global();

	// For internal use
	explicit Global(GlobalImpl* p): p(p) {
	}

	Global(Type ty, const Ref& ref);
	Global(Type ty, const Ref& ref, Term val);

	Type ty() const;
	Ref ref() const;
	Term val() const;

	// Comparison by value
	bool operator==(Global b) const;

	bool operator!=(Global b) const {
		return !(*this == b);
	}
};
