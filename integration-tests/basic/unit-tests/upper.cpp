#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(UpperFunctionTestSuite)

// Test converting a regular line to uppercase
BOOST_AUTO_TEST_CASE(RegularLineToUppercase) {
	Line input("label1", "print \"hello world\"");
	Line expected("LABEL1", "PRINT \"HELLO WORLD\"");

	Line result = upper(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test converting a line with mixed case to uppercase
BOOST_AUTO_TEST_CASE(MixedCaseToUppercase) {
	Line input("MyLabel", "Print \"Hello World\"");
	Line expected("MYLABEL", "PRINT \"HELLO WORLD\"");

	Line result = upper(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test a line that is already uppercase
BOOST_AUTO_TEST_CASE(AlreadyUppercase) {
	Line input("LABEL", "PRINT \"HELLO WORLD\"");
	Line expected("LABEL", "PRINT \"HELLO WORLD\"");

	Line result = upper(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test a line with no label
BOOST_AUTO_TEST_CASE(NoLabel) {
	Line input("", "print \"hello world\"");
	Line expected("", "PRINT \"HELLO WORLD\"");

	Line result = upper(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test a line that starts with similar but not exact string literal prefix
BOOST_AUTO_TEST_CASE(SimilarToStringLiteral) {
	Line input("", "LET STRING_LITERAL");
	Line expected("", "LET STRING_LITERAL");

	Line result = upper(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Edge case: Test with empty text
BOOST_AUTO_TEST_CASE(EmptyText) {
	Line input("label1", "");
	Line expected("LABEL1", "");

	Line result = upper(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Edge case: Test with empty label and text
BOOST_AUTO_TEST_CASE(EmptyLineAndText) {
	Line input("", "");
	Line expected("", "");

	Line result = upper(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test with special characters
BOOST_AUTO_TEST_CASE(SpecialCharacters) {
	Line input("label_1", "print a+b; rem comment 123");
	Line expected("LABEL_1", "PRINT A+B; REM COMMENT 123");

	Line result = upper(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

BOOST_AUTO_TEST_SUITE_END()
