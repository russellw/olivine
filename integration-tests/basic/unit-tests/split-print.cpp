#include "all.h"
#include <boost/test/unit_test.hpp>

// Helper function to compare vectors of Lines for testing
bool compareLineVectors(const vector<Line>& actual, const vector<Line>& expected) {
	if (actual.size() != expected.size()) {
		return false;
	}

	for (size_t i = 0; i < actual.size(); ++i) {
		if (actual[i] != expected[i]) {
			return false;
		}
	}

	return true;
}

BOOST_AUTO_TEST_CASE(test_non_print_statement) {
	Line input("10", "LET A = 5");
	vector<Line> expected = {input};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_string_literal) {
	Line input("", "LET _STRING_LITERAL_0$ = \"HELLO\"");
	vector<Line> expected = {input};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_empty_print) {
	Line input("20", "PRINT ");
	vector<Line> expected = {input};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_single_print_no_delimiter) {
	Line input("30", "PRINT A");
	vector<Line> expected = {input};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_print_with_semicolon) {
	Line input("40", "PRINT A;B");
	vector<Line> expected = {Line("40", "PRINT_SEMI A"), Line("", "PRINT B")};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_print_with_comma) {
	Line input("50", "PRINT A,B");
	vector<Line> expected = {Line("50", "PRINT_COMMA A"), Line("", "PRINT B")};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_print_with_mixed_delimiters) {
	Line input("60", "PRINT A;B,C");
	vector<Line> expected = {Line("60", "PRINT_SEMI A"), Line("", "PRINT_COMMA B"), Line("", "PRINT C")};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_print_with_parentheses) {
	Line input("70", "PRINT (A;B),C");
	vector<Line> expected = {Line("70", "PRINT_COMMA (A;B)"), Line("", "PRINT C")};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_print_with_nested_parentheses) {
	Line input("80", "PRINT (A;(B,C));D");
	vector<Line> expected = {Line("80", "PRINT_SEMI (A;(B,C))"), Line("", "PRINT D")};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_print_with_multiple_delimiters) {
	Line input("90", "PRINT A;B;C,D,E");
	vector<Line> expected = {Line("90", "PRINT_SEMI A"),
		Line("", "PRINT_SEMI B"),
		Line("", "PRINT_COMMA C"),
		Line("", "PRINT_COMMA D"),
		Line("", "PRINT E")};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_print_with_expressions) {
	Line input("100", "PRINT A+B;C*D,E/F");
	vector<Line> expected = {Line("100", "PRINT_SEMI A+B"), Line("", "PRINT_COMMA C*D"), Line("", "PRINT E/F")};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_print_with_trailing_semicolon) {
	// When a PRINT statement ends with a semicolon, we should split it properly
	Line input("110", "PRINT A;");
	vector<Line> expected = {
		Line("110", "PRINT_SEMI A"),
	};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}

BOOST_AUTO_TEST_CASE(test_print_with_trailing_comma) {
	// When a PRINT statement ends with a comma, we should split it properly
	Line input("120", "PRINT A,");
	vector<Line> expected = {
		Line("120", "PRINT_COMMA A"),
	};
	vector<Line> result = splitPrint(input);

	BOOST_CHECK(compareLineVectors(result, expected));
}
