struct GlobalVarImpl;

class GlobalVar {
	GlobalVarImpl* p;

public:
	GlobalVar();

	// For internal use
	explicit GlobalVar(GlobalVarImpl* p): p(p) {
	}

	GlobalVar(Type type, const Ref& ref);

	Type type() const;
	Ref ref() const;

	// Comparison by value
	bool operator==(GlobalVar b) const;
	bool operator!=(GlobalVar b) const;
};
