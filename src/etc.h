void stackTrace(std::ostream& out = std::cout);

// Helper function to create detailed error messages
namespace message_detail {
template <typename T> string toString(const T& val) {
	std::ostringstream oss;
	oss << val;
	return oss.str();
}

inline string makeAssertMessage(const char* expression, const char* file, int line, const string& message = "") {
	std::ostringstream oss;
	oss << "Assertion failed: " << expression << "\nFile: " << file << "\nLine: " << line;

	if (!message.empty()) {
		oss << "\nMessage: " << message;
	}

	return oss.str();
}
} // namespace message_detail

// Basic assertion that throws std::runtime_error
#define ASSERT(condition)                                                                                                          \
	do {                                                                                                                           \
		if (!(condition)) {                                                                                                        \
			throw runtime_error(message_detail::makeAssertMessage(#condition, __FILE__, __LINE__));                                \
		}                                                                                                                          \
	} while (0)

#define dbg(a) cout << __FILE__ << ':' << __LINE__ << ": " << (a) << '\n'

template <typename T> std::vector<T> tail(const std::vector<T>& vec) {
	if (vec.empty()) {
		return std::vector<T>();
	}
	return std::vector<T>(vec.begin() + 1, vec.end());
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

template <typename T> vector<T> cons(const T& x, const vector<T>& xs) {
	vector<T> result;
	result.reserve(1 + xs.size());
	result.push_back(x);
	result.insert(result.end(), xs.begin(), xs.end());
	return result;
}

// TODO: move some of these
string readFile(const string& filename);
