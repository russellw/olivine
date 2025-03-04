template <class T, T eos> class tstream {
	vector<T> v;
	size_t pos;

public:
	tstream(const vector<T>& v): v(v) {
	}

	size_t size() {
		return v.size() - pos;
	}

	T operator[](size_t i) {
		if (pos + i < v.size()) {
			return v[pos + i];
		}
		return eos;
	}

	T operator*() {
		return (*this)[0];
	}

	void operator++(int) {
		if (pos < v.size()) {
			pos++;
		}
	}
};
