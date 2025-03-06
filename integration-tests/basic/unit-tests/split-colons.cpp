#include "all.h"
#include <boost/test/unit_test.hpp>

// Helper function to compare Lines for testing
bool linesEqual(const Line& a, const Line& b) {
	return a.label == b.label && a.text == b.text;
}

// Helper function to compare vectors of Lines for testing
bool lineVectorsEqual(const vector<Line>& a, const vector<Line>& b) {
	if (a.size() != b.size()) {
		return false;
	}
	for (size_t i = 0; i < a.size(); ++i) {
		if (!linesEqual(a[i], b[i])) {
			return false;
		}
	}
	return true;
}

BOOST_AUTO_TEST_CASE(TestStringLiteralPreservation) {
	Line input("10", "LET _STRING_LITERAL_0$ = \"Hello:World\"");
	vector<Line> expected = {input}; // Should remain unchanged
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}

BOOST_AUTO_TEST_CASE(TestSingleStatement) {
	Line input("20", "PRINT \"Hello, World!\"");
	vector<Line> expected = {input}; // Should remain unchanged
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}

BOOST_AUTO_TEST_CASE(TestSimpleSplit) {
	Line input("30", "PRINT \"Hello\":PRINT \"World\"");
	vector<Line> expected = {Line("30", "PRINT \"Hello\""), Line("", "PRINT \"World\"")};
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}

BOOST_AUTO_TEST_CASE(TestMultipleSplit) {
	Line input("40", "LET A=1:LET B=2:PRINT A+B");
	vector<Line> expected = {Line("40", "LET A=1"), Line("", "LET B=2"), Line("", "PRINT A+B")};
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}

BOOST_AUTO_TEST_CASE(TestColonInQuotedString) {
	Line input("50", "PRINT \"A:B\":PRINT \"C:D\"");
	vector<Line> expected = {Line("50", "PRINT \"A:B\""), Line("", "PRINT \"C:D\"")};
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}

BOOST_AUTO_TEST_CASE(TestEmptyStatement) {
	Line input("70", "LET A=1::LET B=2");
	vector<Line> expected = {Line("70", "LET A=1"), Line("", ""), Line("", "LET B=2")};
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}

BOOST_AUTO_TEST_CASE(TestTrailingColon) {
	Line input("80", "PRINT \"Hello\":");
	vector<Line> expected = {
		Line("80", "PRINT \"Hello\""),
	};
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}

BOOST_AUTO_TEST_CASE(TestEmptyInput) {
	Line input("90", "");
	vector<Line> expected = {input}; // Should remain unchanged
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}

BOOST_AUTO_TEST_CASE(TestOnlyColon) {
	Line input("100", ":");
	vector<Line> expected = {
		Line("100", ""),
	};
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}

BOOST_AUTO_TEST_CASE(TestUnbalancedQuotes) {
	// This tests how the function handles malformed input with unbalanced quotes
	Line input("110", "PRINT \"Hello:PRINT \"World\"");
	vector<Line> expected = {Line("110", "PRINT \"Hello:PRINT \"World\"")};
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}

BOOST_AUTO_TEST_CASE(TestComplexCase) {
	Line input("120", "PRINT \"First:Second\":LET A=1:PRINT \"Third:Fourth\":GOSUB 200");
	vector<Line> expected = {
		Line("120", "PRINT \"First:Second\""), Line("", "LET A=1"), Line("", "PRINT \"Third:Fourth\""), Line("", "GOSUB 200")};
	vector<Line> result = splitColons(input);

	BOOST_CHECK(lineVectorsEqual(result, expected));
}
