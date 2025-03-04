#define dbg(a) cout << __FILE__ << ':' << __LINE__ << ": " << (a) << '\n'

#define ASSERT(cond)                                                                                                               \
	do {                                                                                                                           \
		if (!(cond)) {                                                                                                             \
			throw runtime_error(string(__FILE__) + ':' + std::to_string(__LINE__) + ": " + #cond);                                 \
		}                                                                                                                          \
	} while (0)

void stackTrace(std::ostream& out = std::cout);

// SORT FUNCTIONS

template <typename T> vector<T> cons(const T& x, const vector<T>& xs) {
	vector<T> result;
	result.reserve(1 + xs.size());
	result.push_back(x);
	result.insert(result.end(), xs.begin(), xs.end());
	return result;
}

template <typename Iterator> size_t hashRange(Iterator first, Iterator last) {
	size_t h = 0;
	for (; first != last; ++first) {
		hash_combine(h, hash<typename Iterator::value_type>()(*first));
	}
	return h;
}

template <typename T> size_t hashVector(const vector<T>& v) {
	return hashRange(v.begin(), v.end());
}

template <typename T, typename F> vector<std::invoke_result_t<F, T>> map(const vector<T>& input, F func) {
	vector<std::invoke_result_t<F, T>> result;
	result.reserve(input.size());

	std::transform(input.begin(), input.end(), std::back_inserter(result), func);

	return result;
}

template <class K, class V> ostream& operator<<(ostream& os, const unordered_map<K, V>& m) {
	os << '{';
	for (auto i = begin(m); i != end(m); ++i) {
		if (i != begin(m)) {
			os << ", ";
		}
		os << i->first << ':' << i->second;
	}
	return os << '}';
}

template <typename T> std::vector<T> tail(const std::vector<T>& vec) {
	if (vec.empty()) {
		return std::vector<T>();
	}
	return std::vector<T>(vec.begin() + 1, vec.end());
}
