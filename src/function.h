struct FunctionImpl;

class Function {
	FunctionImpl* p;

public:
	Function();

	// For internal use
	explicit Function(FunctionImpl* p): p(p) {
	}

	Function(Type returnType,Ref ref,const vector<Term>&params,const vector<Instruction>&instructions);

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
size_t		h = hash<Type>()(t.returnType()) + 0x9e3779b9 + (h << 6) + (h >> 2);
		h ^= hash<Ref>()(t.ref()) + 0x9e3779b9 + (h << 6) + (h >> 2);
		for (size_t i = 0; i < t.size(); ++i) {
			h ^= hash<Instruction>()(t[i]) + 0x9e3779b9 + (h << 6) + (h >> 2);
		}
		return h;
	}
};
} // namespace std
