#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(InsertLetTestSuite)

// Test 1: Should not modify lines that already start with LET
BOOST_AUTO_TEST_CASE(AlreadyHasLet) {
	Line input("10", "LET X = 5");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "LET X = 5");
}

// Test 2: Should add LET to simple assignment
BOOST_AUTO_TEST_CASE(SimpleAssignment) {
	Line input("20", "X = 10");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "LET X = 10");
}

// Test 3: Should preserve whitespace
BOOST_AUTO_TEST_CASE(PreservesWhitespace) {
	Line input("30", "  Y = 20");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "  LET Y = 20");
}

// Test 4: Should handle string variables
BOOST_AUTO_TEST_CASE(StringVariable) {
	Line input("40", "NAME$ = \"JOHN\"");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "LET NAME$ = \"JOHN\"");
}

// Test 5: Should not modify string literal definitions
BOOST_AUTO_TEST_CASE(StringLiteralDefinition) {
	Line input("", "LET _STRING_LITERAL_0$ = \"HELLO\"");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "LET _STRING_LITERAL_0$ = \"HELLO\"");
}

// Test 6: Should not modify non-assignment statements
BOOST_AUTO_TEST_CASE(NotAssignment) {
	Line input("50", "PRINT X");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "PRINT X");
}

// Test 7: Should handle complex variable names
BOOST_AUTO_TEST_CASE(ComplexVariableName) {
	Line input("60", "counter_123 = counter_123 + 1");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "LET counter_123 = counter_123 + 1");
}

// Test 8: Should handle variable names starting with underscore
BOOST_AUTO_TEST_CASE(UnderscoreVariable) {
	Line input("70", "_temp = 0");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "LET _temp = 0");
}

// Test 9: Should not add LET to IF statements with equality checks
BOOST_AUTO_TEST_CASE(IfStatement) {
	Line input("80", "IF X = 10 THEN GOTO 100");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "IF X = 10 THEN GOTO 100");
}

// Test 11: Should not add LET to other BASIC keywords
BOOST_AUTO_TEST_CASE(OtherKeywords) {
	Line input("110", "FOR I = 1 TO 10");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "FOR I = 1 TO 10");

	Line input2("120", "PRINT A = B");
	Line result2 = insertLet(input2);
	BOOST_CHECK_EQUAL(result2.text, "PRINT A = B");
}

// Test 10: Should handle empty lines
BOOST_AUTO_TEST_CASE(EmptyLine) {
	Line input("90", "");
	Line result = insertLet(input);
	BOOST_CHECK_EQUAL(result.text, "");
}

BOOST_AUTO_TEST_SUITE_END()
