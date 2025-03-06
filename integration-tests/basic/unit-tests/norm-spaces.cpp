#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_CASE(test_string_literal_preservation) {
	// String literal lines should be preserved exactly as they are
	Line input("", "LET _STRING_LITERAL_0$ = \"test with  spaces\"");
	Line result = normSpaces(input);
	BOOST_CHECK_EQUAL(result.text, "LET _STRING_LITERAL_0$ = \"test with  spaces\"");
	BOOST_CHECK_EQUAL(result.label, "");
}

BOOST_AUTO_TEST_CASE(test_leading_spaces_removal) {
	// Leading spaces should be removed
	Line input("", "    PRINT X");
	Line result = normSpaces(input);
	BOOST_CHECK_EQUAL(result.text, "PRINT X");
	BOOST_CHECK_EQUAL(result.label, "");
}

BOOST_AUTO_TEST_CASE(test_trailing_spaces_removal) {
	// Trailing spaces should be removed
	Line input("", "PRINT X    ");
	Line result = normSpaces(input);
	BOOST_CHECK_EQUAL(result.text, "PRINT X");
	BOOST_CHECK_EQUAL(result.label, "");
}

BOOST_AUTO_TEST_CASE(test_multiple_spaces_reduction) {
	// Multiple spaces should be reduced to a single space
	Line input("", "PRINT   X   +    Y");
	Line result = normSpaces(input);
	BOOST_CHECK_EQUAL(result.text, "PRINT X + Y");
	BOOST_CHECK_EQUAL(result.label, "");
}

BOOST_AUTO_TEST_CASE(test_all_space_normalization) {
	// Test a combination of all space normalization aspects
	Line input("", "   PRINT   X   +    Y    ");
	Line result = normSpaces(input);
	BOOST_CHECK_EQUAL(result.text, "PRINT X + Y");
	BOOST_CHECK_EQUAL(result.label, "");
}

BOOST_AUTO_TEST_CASE(test_empty_string) {
	// Empty string should remain empty
	Line input("", "");
	Line result = normSpaces(input);
	BOOST_CHECK_EQUAL(result.text, "");
	BOOST_CHECK_EQUAL(result.label, "");
}

BOOST_AUTO_TEST_CASE(test_only_spaces) {
	// String with only spaces should become empty
	Line input("", "      ");
	Line result = normSpaces(input);
	BOOST_CHECK_EQUAL(result.text, "");
	BOOST_CHECK_EQUAL(result.label, "");
}

BOOST_AUTO_TEST_CASE(test_with_label) {
	// The label should be preserved
	Line input("10", "   PRINT   X   ");
	Line result = normSpaces(input);
	BOOST_CHECK_EQUAL(result.text, "PRINT X");
	BOOST_CHECK_EQUAL(result.label, "10");
}

BOOST_AUTO_TEST_CASE(test_label_with_string_literal) {
	// String literal with label should be preserved
	Line input("10", "LET _STRING_LITERAL_1$ = \"preserved   spaces\"");
	Line result = normSpaces(input);
	BOOST_CHECK_EQUAL(result.text, "LET _STRING_LITERAL_1$ = \"preserved   spaces\"");
	BOOST_CHECK_EQUAL(result.label, "10");
}

BOOST_AUTO_TEST_CASE(test_basic_commands) {
	// Test with various BASIC commands
	Line input1("20", "LET  X  =  10");
	Line result1 = normSpaces(input1);
	BOOST_CHECK_EQUAL(result1.text, "LET X = 10");
	BOOST_CHECK_EQUAL(result1.label, "20");

	Line input2("30", "IF  X  =  10  THEN  PRINT  \"EQUAL\"");
	Line result2 = normSpaces(input2);
	BOOST_CHECK_EQUAL(result2.text, "IF X = 10 THEN PRINT \"EQUAL\"");
	BOOST_CHECK_EQUAL(result2.label, "30");

	Line input3("40", "FOR  I  =  1  TO  10  STEP  2");
	Line result3 = normSpaces(input3);
	BOOST_CHECK_EQUAL(result3.text, "FOR I = 1 TO 10 STEP 2");
	BOOST_CHECK_EQUAL(result3.label, "40");
}
