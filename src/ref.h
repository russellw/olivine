class Ref {
	string str1;
	size_t num1 = ~(size_t)0;

public:
	Ref(): num1(0) {
	}

	Ref(const string& str): str1(str) {
	}

	Ref(const char* str): str1(str) {
	}

	Ref(size_t num): num1(num) {
	}

	// Accessors
	bool numeric() const {
		return num1 != ~(size_t)0;
	}

	string str() const {
		return str1;
	}

	size_t num() const {
		return num1;
	}

	// Comparison by value
	bool operator==(const Ref& b) const;

	bool operator!=(const Ref& b) const {
		return !(*this == b);
	}
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

struct RefComparator {
	bool operator()(const Ref& a, const Ref& b) const {
		// First compare by which type
		if (a.numeric() != b.numeric()) {
			return a.numeric() < b.numeric();
		}

		// Same type, now compare values
		if (a.numeric()) {
			// Both are size_t
			return a.num() < b.num();
		} else {
			// Both are string
			return a.str() < b.str();
		}
	}
};
