class Ref {
	string str1;
	size_t num1 = ~(size_t)0;

public:
	Ref(): num1(0) {
	}

	Ref(string str): str1(str) {
	}

	Ref(const char* str): str1(str) {
	}

	Ref(size_t num): num1(num) {
		ASSERT(num != (std::numeric_limits<size_t>::max)());
	}

	// Accessors
	bool numeric() const {
		return num1 != ~(size_t)0;
	}

	string str() const {
		ASSERT(!numeric());
		return str1;
	}

	size_t num() const {
		ASSERT(numeric());
		return num1;
	}

	// Comparison by value
	bool operator==(const Ref& b) const;

	bool operator!=(const Ref& b) const {
		return !(*this == b);
	}

	bool operator<(const Ref& b) const;
};

namespace std {
template <> struct hash<Ref> {
	size_t operator()(const Ref& ref) const {
		if (ref.numeric()) {
			return hash<size_t>()(ref.num());
		}
		return hash<string>()(ref.str());
	}
};
} // namespace std
