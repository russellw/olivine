#include "all.h"
#include <boost/test/unit_test.hpp>

// Disable max/min macros to avoid conflicts with std::numeric_limits
#undef max
#undef min

BOOST_AUTO_TEST_SUITE(RefStreamOperatorTests)

// Test numeric references
BOOST_AUTO_TEST_CASE(NumericRef) {
	Ref ref(static_cast<size_t>(42));
	std::ostringstream oss;
	oss << ref;
	BOOST_CHECK_EQUAL(oss.str(), "42");
}

// Test valid identifier strings that don't need quoting
BOOST_AUTO_TEST_CASE(ValidIdentifierString) {
	Ref ref(std::string("valid_name"));
	std::ostringstream oss;
	oss << ref;
	BOOST_CHECK_EQUAL(oss.str(), "valid_name");
}

// Test string starting with digit that needs quoting
BOOST_AUTO_TEST_CASE(StringStartingWithDigit) {
	Ref ref(std::string("123name"));
	std::ostringstream oss;
	oss << ref;
	BOOST_CHECK_EQUAL(oss.str(), "\"123name\"");
}

// Test string with special characters that need escaping
BOOST_AUTO_TEST_CASE(StringWithSpecialChars) {
	Ref ref(std::string("test\\path"));
	std::ostringstream oss;
	oss << ref;
	BOOST_CHECK_EQUAL(oss.str(), "\"test\\\\path\"");
}

// Test string with quotes and special characters
BOOST_AUTO_TEST_CASE(StringWithQuotesAndSpecials) {
	Ref ref(std::string("\"quoted\""));
	std::ostringstream oss;
	oss << ref;
	BOOST_CHECK_EQUAL(oss.str(), "\"\\22quoted\\22\"");
}

// Test empty string
BOOST_AUTO_TEST_CASE(EmptyString) {
	Ref ref(std::string(""));
	std::ostringstream oss;
	oss << ref;
	BOOST_CHECK_EQUAL(oss.str(), "\"\"");
}

// Test string with spaces
BOOST_AUTO_TEST_CASE(StringWithSpaces) {
	Ref ref(std::string("my variable"));
	std::ostringstream oss;
	oss << ref;
	BOOST_CHECK_EQUAL(oss.str(), "\"my variable\"");
}

// Test string with non-printable characters
BOOST_AUTO_TEST_CASE(StringWithNonPrintable) {
	Ref ref(std::string("test\n\tname"));
	std::ostringstream oss;
	oss << ref;
	BOOST_CHECK_EQUAL(oss.str(), "\"test\\0a\\09name\"");
}

// Test large numeric value
BOOST_AUTO_TEST_CASE(LargeNumericRef) {
	const size_t large_value = (std::numeric_limits<size_t>::max)(); // Use parentheses to avoid macro issues
	Ref ref(large_value);
	std::ostringstream oss;
	oss << ref;
	std::ostringstream expected;
	expected << large_value;
	BOOST_CHECK_EQUAL(oss.str(), expected.str());
}

// Test zero numeric value
BOOST_AUTO_TEST_CASE(ZeroNumericRef) {
	Ref ref(static_cast<size_t>(0));
	std::ostringstream oss;
	oss << ref;
	BOOST_CHECK_EQUAL(oss.str(), "0");
}

BOOST_AUTO_TEST_SUITE_END()
