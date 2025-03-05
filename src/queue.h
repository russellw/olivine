// Sequence of elements to be consumed from the front
// Particularly intended for sequences of tokens in parser
// Intentionally not a drop-in replacement for std::queue
// In particular, trying to read past the end is not an error
// but returns a sentinel value
template <class T> class queue {
	vector<T> v;
	T sentinel;
	size_t pos = 0;

public:
	queue(const T& sentinel): sentinel(sentinel) {
	}

	queue(const vector<T>& v, const T& sentinel): v(v), sentinel(sentinel) {
	}

	// SORT FUNCTIONS

	T& operator*()  {
		return (*this)[0];
	}

	T& operator[](size_t i) {
		if (pos + i < v.size()) {
			return v[pos + i];
		}
		return sentinel;
	}
T* operator->() {
        return &(*this)[0];
    }
	T pop() {
		ASSERT(pos <= v.size());
		if (pos == v.size()) {
			return sentinel;
		}
		return v[pos++];
	}

	void push(T a) {
		v.push_back(a);
	}

	size_t size() const {
		ASSERT(pos <= v.size());
		return v.size() - pos;
	}
};
