#include "all.h"
#include <boost/test/included/unit_test.hpp>
BOOST_AUTO_TEST_SUITE(WrapTests)

// Test valid identifiers that shouldn't need quotes
BOOST_AUTO_TEST_CASE(ValidIdentifiers) {
	// Basic valid identifiers
	BOOST_CHECK_EQUAL(wrap("foo"), "foo");
	BOOST_CHECK_EQUAL(wrap("_foo"), "_foo");
	BOOST_CHECK_EQUAL(wrap(".foo"), ".foo");
	BOOST_CHECK_EQUAL(wrap("foo_bar"), "foo_bar");
	BOOST_CHECK_EQUAL(wrap("foo.bar"), "foo.bar");

	// Valid identifiers with numbers
	BOOST_CHECK_EQUAL(wrap("foo123"), "foo123");
	BOOST_CHECK_EQUAL(wrap("foo_123"), "foo_123");

	// Valid identifiers with mixed case
	BOOST_CHECK_EQUAL(wrap("FooBar"), "FooBar");
	BOOST_CHECK_EQUAL(wrap("fooBar"), "fooBar");
}

// Test invalid identifiers that need quotes
BOOST_AUTO_TEST_CASE(InvalidIdentifiers) {
	// Empty string
	BOOST_CHECK_EQUAL(wrap(""), "\"\"");

	// Starting with number
	BOOST_CHECK_EQUAL(wrap("123foo"), "\"123foo\"");

	// Contains spaces
	BOOST_CHECK_EQUAL(wrap("foo bar"), "\"foo bar\"");

	// Contains special characters
	BOOST_CHECK_EQUAL(wrap("foo+bar"), "\"foo+bar\"");
	BOOST_CHECK_EQUAL(wrap("foo-bar"), "foo-bar");
	BOOST_CHECK_EQUAL(wrap("foo@bar"), "\"foo@bar\"");
}

// Test strings with characters that need hex escaping
BOOST_AUTO_TEST_CASE(HexEscapes) {
	// Quote character
	BOOST_CHECK_EQUAL(wrap("foo\"bar"), "\"foo\\22bar\"");

	// Multiple quotes
	BOOST_CHECK_EQUAL(wrap("\"foo\"bar\""), "\"\\22foo\\22bar\\22\"");

	// Non-printable characters
	BOOST_CHECK_EQUAL(wrap("foo\nbar"), "\"foo\\0abar\"");
	BOOST_CHECK_EQUAL(wrap("foo\tbar"), "\"foo\\09bar\"");
	BOOST_CHECK_EQUAL(wrap("foo\rbar"), "\"foo\\0dbar\"");

	// Control characters
	char control1 = 1;
	char control2 = 31;
	BOOST_CHECK_EQUAL(wrap(string("foo") + control1 + "bar"), "\"foo\\01bar\"");
	BOOST_CHECK_EQUAL(wrap(string("foo") + control2 + "bar"), "\"foo\\1fbar\"");

	// Extended ASCII
	char extended1 = char(128);
	char extended2 = char(255);
	BOOST_CHECK_EQUAL(wrap(string("foo") + extended1 + "bar"), "\"foo\\80bar\"");
	BOOST_CHECK_EQUAL(wrap(string("foo") + extended2 + "bar"), "\"foo\\ffbar\"");
}

// Test strings with backslashes
BOOST_AUTO_TEST_CASE(Backslashes) {
	// Single backslash
	BOOST_CHECK_EQUAL(wrap("foo\\bar"), "\"foo\\\\bar\"");

	// Multiple backslashes
	BOOST_CHECK_EQUAL(wrap("foo\\\\bar"), "\"foo\\\\\\\\bar\"");

	// Backslash at start/end
	BOOST_CHECK_EQUAL(wrap("\\foo"), "\"\\\\foo\"");
	BOOST_CHECK_EQUAL(wrap("foo\\"), "\"foo\\\\\"");
}

// Test edge cases
BOOST_AUTO_TEST_CASE(EdgeCases) {
	// Single character strings
	BOOST_CHECK_EQUAL(wrap("a"), "a");
	BOOST_CHECK_EQUAL(wrap("\\"), "\"\\\\\"");
	BOOST_CHECK_EQUAL(wrap("\""), "\"\\22\"");
	BOOST_CHECK_EQUAL(wrap("\n"), "\"\\0a\"");

	// Mixed special cases
	BOOST_CHECK_EQUAL(wrap("foo\\\"\nbar"), "\"foo\\\\\\22\\0abar\"");

	string controlChars;
	controlChars += char(1);
	controlChars += char(2);
	controlChars += char(3);
	BOOST_CHECK_EQUAL(wrap(controlChars), "\"\\01\\02\\03\"");

	// Valid identifier characters mixed with invalid ones
	BOOST_CHECK_EQUAL(wrap("foo_bar+baz"), "\"foo_bar+baz\"");
	BOOST_CHECK_EQUAL(wrap("foo.bar@baz"), "\"foo.bar@baz\"");
}

BOOST_AUTO_TEST_SUITE_END()
