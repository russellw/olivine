struct GlobalImpl;

class Global {
	GlobalImpl* p;

public:
	Global();

	// For internal use
	explicit Global(GlobalImpl* p): p(p) {
	}

	Global(Type ty, const Ref& ref);

	Type ty() const;
	Ref ref() const;

	// Comparison by value
	bool operator==(Global b) const;
	bool operator!=(Global b) const;
};
