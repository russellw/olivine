#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(ParseRefTests)

// Test basic numeric references
BOOST_AUTO_TEST_CASE(BasicNumericRefs) {
	// Test simple numeric references
	auto ref1 = parseRef("%0");
	BOOST_CHECK(ref1.numeric());
	BOOST_CHECK_EQUAL(ref1.num(), 0);

	auto ref2 = parseRef("%42");
	BOOST_CHECK(ref2.numeric());
	BOOST_CHECK_EQUAL(ref2.num(), 42);
}

// Test string references
BOOST_AUTO_TEST_CASE(StringRefs) {
	// Test basic string reference
	auto ref1 = parseRef("%foo");
	BOOST_CHECK(!ref1.numeric());
	BOOST_CHECK_EQUAL(ref1.str(), "foo");

	// Test string reference with underscore
	auto ref2 = parseRef("%my_var");
	BOOST_CHECK(!ref2.numeric());
	BOOST_CHECK_EQUAL(ref2.str(), "my_var");
}

// Test quoted references
BOOST_AUTO_TEST_CASE(QuotedRefs) {
	// Test quoted string that looks like a number
	auto ref1 = parseRef("%\"42\"");
	BOOST_CHECK(!ref1.numeric());
	BOOST_CHECK_EQUAL(ref1.str(), "42");

	// Test quoted string with spaces
	auto ref2 = parseRef("%\"hello world\"");
	BOOST_CHECK(!ref2.numeric());
	BOOST_CHECK_EQUAL(ref2.str(), "hello world");
}

// Test escaped sequences in quoted strings
BOOST_AUTO_TEST_CASE(EscapedRefs) {
	// Test string with hex escape
	auto ref2 = parseRef("%\"hello\\20world\"");
	BOOST_CHECK(!ref2.numeric());
	BOOST_CHECK_EQUAL(ref2.str(), "hello world");
}

// Test error cases
BOOST_AUTO_TEST_CASE(ErrorCases) {
	// Empty string
	BOOST_CHECK_THROW(parseRef(""), std::runtime_error);

	// Just sigil
	BOOST_CHECK_THROW(parseRef("%"), std::runtime_error);

	// Invalid number format
	BOOST_CHECK_THROW(parseRef("%42a"), std::runtime_error);

	// Unclosed quote
	BOOST_CHECK_THROW(parseRef("%\"unclosed"), std::runtime_error);
}

// Test edge cases
BOOST_AUTO_TEST_CASE(EdgeCases) {
	// Test maximum numeric value
	auto ref1 = parseRef("%18446744073709551614"); // max size_t - 1
	BOOST_CHECK(ref1.numeric());
	BOOST_CHECK_EQUAL(ref1.num(), 18446744073709551614ULL);

	// Test empty quoted string
	auto ref2 = parseRef("%\"\"");
	BOOST_CHECK(!ref2.numeric());
	BOOST_CHECK_EQUAL(ref2.str(), "");

	// Test string with just spaces
	auto ref3 = parseRef("%\"   \"");
	BOOST_CHECK(!ref3.numeric());
	BOOST_CHECK_EQUAL(ref3.str(), "   ");
}

BOOST_AUTO_TEST_SUITE_END()
