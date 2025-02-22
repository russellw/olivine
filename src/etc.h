void stackTrace(std::ostream& out = std::cout);

// Helper function to create detailed error messages
namespace message_detail {
template <typename T> string toString(const T& val) {
	ostringstream oss;
	oss << val;
	return oss.str();
}

inline string makeAssertMessage(const char* expression, const char* file, int line, const string& message = "") {
	ostringstream oss;
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

inline bool endsWith(const string& s, int c) {
	return s.size() && s.back() == c;
}

// The signedness of plain char is implementation-defined, typically signed
// and the ctype.h functions have undefined behavior on signed input
// so, unless we want to count on never forgetting to cast to unsigned at every call site,
// we need to provide our own
inline bool isSpace(int c) {
	return c <= ' ' && c;
}

inline bool isDigit(int c) {
	return '0' <= c && c <= '9';
}

inline bool isLower(int c) {
	return 'a' <= c && c <= 'z';
}

inline bool isUpper(int c) {
	return 'A' <= c && c <= 'Z';
}

inline bool isAlpha(int c) {
	return isLower(c) || isUpper(c);
}

inline bool isAlnum(int c) {
	return isAlpha(c) || isDigit(c);
}

inline bool isXDigit(int c) {
	return isDigit(c) || 'a' <= c && c <= 'f' || 'A' <= c && c <= 'F';
}

// Is the input character a valid part of an LLVM identifier?
// This includes more punctuation than most programming languages
bool isIdPart(int c);

bool containsAt(const string& haystack, size_t position, const string& needle);

// Parse hexadecimal digits starting at a given position, updating pos accordingly
// Hexadecimal digits are classified by the function isXDigit
// Stops when it reaches the end of the string, or a character that is not a hexadecimal digit, or it has parsed maxLen digits
// At least one hexadecimal digit must be present, or an exception is thrown
unsigned parseHex(const string& s, size_t& pos, int maxLen = 8);

// Remove the leading sigil from an LLVM identifier or string, if there is one
string removeSigil(const string& s);

// Unwrap an LLVM identifier or string
// Remove the leading sigil if any
// If there are quotes, remove them, and evaluate escape sequences
// Check for validity, and throw runtime_error if the string is not valid
// The LLVM language manual doesn't say exactly what escape sequences are valid
// Testing what the LLVM parser actually accepts, it seems to be just \ or two hex digits
// Otherwise, the first \ is just treated as an ordinary character
string unwrap(string s);

template <typename T> std::vector<T> tail(const std::vector<T>& vec) {
	if (vec.empty()) {
		return std::vector<T>();
	}
	return std::vector<T>(vec.begin() + 1, vec.end());
}

template <typename T, typename F> vector<invoke_result_t<F, T>> map(const vector<T>& input, F func) {
	vector<invoke_result_t<F, T>> result;
	result.reserve(input.size());

	transform(input.begin(), input.end(), back_inserter(result), func);

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

// Count newlines before current position to get line number
size_t currentLine(const string& input, size_t pos);

// In LLVM, some things can be referred to by index numbers or strings
typedef std::variant<size_t, string> Ref;

// Parse an LLVM identifier or string to a reference containing index number or string as appropriate
// after removing the leading sigil if there is one
// Correctly distinguishes between %9 and %"9"
Ref parseRef(string s);

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

string quote(const string& s);
string readFile(const string& filename);
