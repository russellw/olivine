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
	return isDigit(c) || ('a' <= c && c <= 'f') || ('A' <= c && c <= 'F');
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

// Count newlines before current position to get line number
size_t currentLine(const string& input, size_t pos);

// In LLVM, some things can be referred to by index numbers or strings
typedef std::variant<size_t, string> Ref;

#include <iostream>
#include <set>
#include <string>
#include <variant>

typedef std::variant<size_t, string> Ref;

// Custom comparator for std::variant
struct RefComparator {
	bool operator()(const Ref& a, const Ref& b) const {
		// First compare by index (which type is in the variant)
		if (a.index() != b.index()) {
			return a.index() < b.index();
		}

		// Same type, now compare values
		if (a.index() == 0) {
			// Both are size_t
			return std::get<size_t>(a) < std::get<size_t>(b);
		} else {
			// Both are string
			return std::get<string>(a) < std::get<string>(b);
		}
	}
};

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

// Opposite of unwrap
// Given a string that is a name
// check whether it is valid as an unquoted LLVM identifier
// If so, return it unchanged
// Otherwise, wrap it in quotes, and escape some characters as necessary
string wrap(const string& s);

/**
 * Truncates a cpp_int to the specified number of bits
 *
 * @param value The cpp_int value to truncate
 * @param bits Number of bits to keep (must be > 0)
 * @return A new cpp_int containing only the specified number of least significant bits
 * @throws std::invalid_argument if bits <= 0
 */
cpp_int truncate_to_bits(const cpp_int& value, std::size_t bits);

/**
 * Common utilities for fixed-width operations
 */
namespace detail {
// Create bit mask for given width
inline cpp_int create_mask(std::size_t bits) {
	return (cpp_int(1) << bits) - 1;
}

// Convert unsigned to signed, assuming value is within bits width
inline cpp_int to_signed(const cpp_int& value, std::size_t bits) {
	cpp_int sign_bit = cpp_int(1) << (bits - 1);
	if ((value & sign_bit) == 0) {
		return value;
	}
	return value - (sign_bit << 1);
}

// Convert signed to unsigned, assuming value fits in bits width
inline cpp_int to_unsigned(const cpp_int& value, std::size_t bits) {
	if (value >= 0) {
		return value;
	}
	return value + (cpp_int(1) << bits);
}

// Validate bit width
inline void validate_bits(std::size_t bits) {
	if (bits <= 0) {
		throw std::invalid_argument("Number of bits must be positive");
	}
}
} // namespace detail

/**
 * Fixed-width arithmetic operations following LLVM semantics.
 * All values are stored as unsigned integers internally.
 */
namespace fixed_width_ops {
// Arithmetic operations
static cpp_int add(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a + b) & detail::create_mask(bits);
}

static cpp_int sub(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a - b) & detail::create_mask(bits);
}

static cpp_int mul(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a * b) & detail::create_mask(bits);
}

static cpp_int udiv(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	if (b == 0) {
		throw std::domain_error("Division by zero");
	}
	return (a / b) & detail::create_mask(bits);
}

static cpp_int sdiv(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	if (b == 0) {
		throw std::domain_error("Division by zero");
	}

	// Convert to signed, perform division, convert back
	cpp_int sa = detail::to_signed(a, bits);
	cpp_int sb = detail::to_signed(b, bits);
	cpp_int result = sa / sb; // Signed division
	return detail::to_unsigned(result, bits);
}

static cpp_int urem(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	if (b == 0) {
		throw std::domain_error("Division by zero");
	}
	return (a % b) & detail::create_mask(bits);
}

static cpp_int srem(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	if (b == 0) {
		throw std::domain_error("Division by zero");
	}

	// Convert to signed, perform remainder, convert back
	cpp_int sa = detail::to_signed(a, bits);
	cpp_int sb = detail::to_signed(b, bits);
	cpp_int result = sa % sb; // Signed remainder
	return detail::to_unsigned(result, bits);
}

// Bitwise operations
static cpp_int and_(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a & b) & detail::create_mask(bits);
}

static cpp_int or_(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a | b) & detail::create_mask(bits);
}

static cpp_int xor_(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a ^ b) & detail::create_mask(bits);
}

// Shift operations
static cpp_int shl(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	// Convert shift amount to size_t
	std::size_t shift = static_cast<std::size_t>(b);
	// LLVM treats shifts >= width as producing poison
	if (shift >= bits) {
		return 0;
	}
	return (a << shift) & detail::create_mask(bits);
}

static cpp_int lshr(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	unsigned long shift = b.convert_to<unsigned long>();
	if (shift >= bits) {
		return 0;
	}
	return a >> shift & detail::create_mask(bits);
}

static cpp_int ashr(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	unsigned long shift = b.convert_to<unsigned long>();
	if (shift >= bits) {
		// Arithmetic shift fills with sign bit
		cpp_int sa = detail::to_signed(a, bits);
		return detail::to_unsigned(sa >= 0 ? 0 : -1, bits);
	}

	// Convert to signed, shift, convert back
	cpp_int sa = detail::to_signed(a, bits);
	cpp_int result = sa >> shift; // Arithmetic shift
	return detail::to_unsigned(result, bits);
}

// Comparison operations (return 1 for true, 0 for false)
static cpp_int eq(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return cpp_int(a == b);
}

static cpp_int ne(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return cpp_int(a != b);
}

static cpp_int ult(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return cpp_int(a < b);
}

static cpp_int ule(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return cpp_int(a <= b);
}

static cpp_int slt(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	cpp_int sa = detail::to_signed(a, bits);
	cpp_int sb = detail::to_signed(b, bits);
	return cpp_int(sa < sb);
}

static cpp_int sle(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	cpp_int sa = detail::to_signed(a, bits);
	cpp_int sb = detail::to_signed(b, bits);
	return cpp_int(sa <= sb);
}
}; // namespace fixed_width_ops
