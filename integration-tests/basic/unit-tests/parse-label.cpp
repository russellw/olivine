#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(ParseLabelTestSuite)

// Test numeric labels
BOOST_AUTO_TEST_CASE(TestNumericLabel) {
	Line result = parseLabel("10 PRINT \"Hello, World!\"");
	BOOST_CHECK_EQUAL(result.label, "10");
	BOOST_CHECK_EQUAL(result.text, "PRINT \"Hello, World!\"");
}

BOOST_AUTO_TEST_CASE(TestMultiDigitNumericLabel) {
	Line result = parseLabel("1000 GOSUB 2000");
	BOOST_CHECK_EQUAL(result.label, "1000");
	BOOST_CHECK_EQUAL(result.text, "GOSUB 2000");
}

// Test alphanumeric labels
BOOST_AUTO_TEST_CASE(TestAlphaLabel) {
	Line result = parseLabel("loop: PRINT \"Loop\"");
	BOOST_CHECK_EQUAL(result.label, "loop");
	BOOST_CHECK_EQUAL(result.text, "PRINT \"Loop\"");
}

BOOST_AUTO_TEST_CASE(TestAlphaNumericLabel) {
	Line result = parseLabel("start_123: INPUT \"Enter value: \", X");
	BOOST_CHECK_EQUAL(result.label, "start_123");
	BOOST_CHECK_EQUAL(result.text, "INPUT \"Enter value: \", X");
}

BOOST_AUTO_TEST_CASE(TestUnderscoreStartLabel) {
	Line result = parseLabel("_main: GOTO end");
	BOOST_CHECK_EQUAL(result.label, "_main");
	BOOST_CHECK_EQUAL(result.text, "GOTO end");
}

// Test edge cases
BOOST_AUTO_TEST_CASE(TestNoLabel) {
	Line result = parseLabel("PRINT \"No label here\"");
	BOOST_CHECK_EQUAL(result.label, "");
	BOOST_CHECK_EQUAL(result.text, "PRINT \"No label here\"");
}

BOOST_AUTO_TEST_CASE(TestEmptyLine) {
	Line result = parseLabel("");
	BOOST_CHECK_EQUAL(result.label, "");
	BOOST_CHECK_EQUAL(result.text, "");
}

BOOST_AUTO_TEST_CASE(TestWhitespaceLine) {
	Line result = parseLabel("    ");
	BOOST_CHECK_EQUAL(result.label, "");
	BOOST_CHECK_EQUAL(result.text, "");
}

BOOST_AUTO_TEST_CASE(TestLeadingWhitespace) {
	Line result = parseLabel("    20 PRINT \"Indented\"");
	BOOST_CHECK_EQUAL(result.label, "20");
	BOOST_CHECK_EQUAL(result.text, "PRINT \"Indented\"");
}

BOOST_AUTO_TEST_CASE(TestAlphaWithoutColon) {
	// This should not be recognized as a label since there's no colon
	Line result = parseLabel("label PRINT \"Not a label\"");
	BOOST_CHECK_EQUAL(result.label, "");
	BOOST_CHECK_EQUAL(result.text, "label PRINT \"Not a label\"");
}

// Test spaces around labels
BOOST_AUTO_TEST_CASE(TestSpacesAfterLabel) {
	Line result = parseLabel("30    PRINT \"Spaces after label\"");
	BOOST_CHECK_EQUAL(result.label, "30");
	BOOST_CHECK_EQUAL(result.text, "PRINT \"Spaces after label\"");
}

BOOST_AUTO_TEST_CASE(TestSpacesAfterColon) {
	Line result = parseLabel("end:    PRINT \"Spaces after colon\"");
	BOOST_CHECK_EQUAL(result.label, "end");
	BOOST_CHECK_EQUAL(result.text, "PRINT \"Spaces after colon\"");
}

// Test mixed case labels
BOOST_AUTO_TEST_CASE(TestMixedCaseLabel) {
	Line result = parseLabel("MixedCase: PRINT \"Mixed case label\"");
	BOOST_CHECK_EQUAL(result.label, "MixedCase");
	BOOST_CHECK_EQUAL(result.text, "PRINT \"Mixed case label\"");
}

// Test single character labels
BOOST_AUTO_TEST_CASE(TestSingleCharLabel) {
	Line result = parseLabel("X: PRINT \"Single char label\"");
	BOOST_CHECK_EQUAL(result.label, "X");
	BOOST_CHECK_EQUAL(result.text, "PRINT \"Single char label\"");
}

BOOST_AUTO_TEST_SUITE_END()
