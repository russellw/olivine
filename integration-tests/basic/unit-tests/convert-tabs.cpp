#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(ConvertTabsTests)

// Test 1: Basic tab replacement
BOOST_AUTO_TEST_CASE(BasicTabReplacement) {
	Line input("10", "PRINT\tHELLO");
	Line expected("10", "PRINT HELLO");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test 2: Multiple tabs
BOOST_AUTO_TEST_CASE(MultipleTabsReplacement) {
	Line input("20", "IF\tX\t=\t10\tTHEN\tPRINT\t\"YES\"");
	Line expected("20", "IF X = 10 THEN PRINT \"YES\"");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test 3: Leading tabs
BOOST_AUTO_TEST_CASE(LeadingTabsReplacement) {
	Line input("30", "\t\tPRINT \"HELLO\"");
	Line expected("30", "  PRINT \"HELLO\"");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test 4: Trailing tabs
BOOST_AUTO_TEST_CASE(TrailingTabsReplacement) {
	Line input("40", "PRINT \"HELLO\"\t\t");
	Line expected("40", "PRINT \"HELLO\"  ");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test 5: No tabs present
BOOST_AUTO_TEST_CASE(NoTabsPresent) {
	Line input("50", "PRINT \"NO TABS HERE\"");
	Line expected("50", "PRINT \"NO TABS HERE\"");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test 6: Empty text
BOOST_AUTO_TEST_CASE(EmptyText) {
	Line input("60", "");
	Line expected("60", "");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test 7: String literal preservation
BOOST_AUTO_TEST_CASE(StringLiteralPreservation) {
	Line input("", "LET _STRING_LITERAL_0$ = \"HELLO\tWORLD\"");
	Line expected("", "LET _STRING_LITERAL_0$ = \"HELLO\tWORLD\"");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test 8: Only tabs
BOOST_AUTO_TEST_CASE(OnlyTabs) {
	Line input("70", "\t\t\t");
	Line expected("70", "   ");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test 9: Mix of tabs and spaces
BOOST_AUTO_TEST_CASE(MixedTabsAndSpaces) {
	Line input("80", "IF X\t= 10 THEN\tGOTO 100");
	Line expected("80", "IF X = 10 THEN GOTO 100");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test 10: Label only, no text
BOOST_AUTO_TEST_CASE(LabelOnlyWithNoText) {
	Line input("90", "");
	Line expected("90", "");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

// Test 11: String literal that's not at the beginning
BOOST_AUTO_TEST_CASE(NonLeadingStringLiteral) {
	Line input("100", "A = LET _STRING_LITERAL_1$ + \t\"TAB\"");
	Line expected("100", "A = LET _STRING_LITERAL_1$ +  \"TAB\"");

	Line result = convertTabs(input);

	BOOST_CHECK_EQUAL(result.label, expected.label);
	BOOST_CHECK_EQUAL(result.text, expected.text);
}

BOOST_AUTO_TEST_SUITE_END()
