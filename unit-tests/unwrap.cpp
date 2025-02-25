// Test basic identifier without any special characters
#include "all.h"
#include <boost/test/included/unit_test.hpp>

BOOST_AUTO_TEST_CASE(BasicIdentifier) {
	BOOST_CHECK_EQUAL(unwrap("identifier"), "identifier");
	BOOST_CHECK_EQUAL(unwrap("abc123"), "abc123");
	BOOST_CHECK_EQUAL(unwrap("_underscore"), "_underscore");
}

// Test leading sigil removal
BOOST_AUTO_TEST_CASE(LeadingSigil) {
	BOOST_CHECK_EQUAL(unwrap("@variable"), "variable");
	BOOST_CHECK_EQUAL(unwrap("%local"), "local");
}

// Test quoted strings without escape sequences
BOOST_AUTO_TEST_CASE(QuotedStrings) {
	BOOST_CHECK_EQUAL(unwrap("\"quoted\""), "quoted");
	BOOST_CHECK_EQUAL(unwrap("\"\""), ""); // Empty quoted string
}

// Test strings with escape sequences
BOOST_AUTO_TEST_CASE(EscapeSequences) {
	BOOST_CHECK_EQUAL(unwrap("\"\\\\\""), "\\"); // Escaped backslash
}

// Test combinations of features
BOOST_AUTO_TEST_CASE(CombinedFeatures) {
	BOOST_CHECK_EQUAL(unwrap("@\"quoted\""), "quoted"); // Sigil with quotes
}

// Test error cases
BOOST_AUTO_TEST_CASE(ErrorCases) {
	// Unmatched quotes
	BOOST_CHECK_THROW(unwrap("\"unmatched"), std::runtime_error);

	// Invalid escape sequences
	BOOST_CHECK_THROW(unwrap("\"\\"), std::runtime_error); // Trailing backslash

	// Invalid characters in identifiers
	BOOST_CHECK_THROW(unwrap("invalid!char"), std::runtime_error);
	BOOST_CHECK_THROW(unwrap("space invalid"), std::runtime_error);
}

// Test edge cases
BOOST_AUTO_TEST_CASE(EdgeCases) {
	BOOST_CHECK_THROW(unwrap(""), std::runtime_error);
	BOOST_CHECK_EQUAL(unwrap("a"), "a");				// Single character
	BOOST_CHECK_EQUAL(unwrap("_"), "_");				// Just underscore
	BOOST_CHECK_THROW(unwrap("@"), std::runtime_error); // Just sigil
}

// Test whitespace handling
BOOST_AUTO_TEST_CASE(WhitespaceHandling) {
	BOOST_CHECK_EQUAL(unwrap("\"  spaced  \""), "  spaced  "); // Preserve internal spaces
}
