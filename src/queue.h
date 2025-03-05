// Sequence of elements to be consumed from the front
// Particularly intended for sequences of tokens in parser
// Intentionally not a drop-in replacement for std::queue
// In particular, trying to read past the end is not an error
// but returns a sentinel value
template <class T, T sentinel> class queue {
	vector<T> v;
	size_t pos = 0;

public:
	queue(const vector<T>& v): v(v) {
	}

	// SORT FUNCTIONS

	T operator*() {
		return (*this)[0];
	}

	void operator++(int) {
		if (pos < v.size()) {
			pos++;
		}
	}

	T operator[](size_t i) {
		if (pos + i < v.size()) {
			return v[pos + i];
		}
		return sentinel;
	}

	size_t size() {
		return v.size() - pos;
	}
};
