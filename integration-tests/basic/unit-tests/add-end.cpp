#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_CASE(test_empty_program) {
	vector<Line> program;
	vector<Line> result = addEnd(program);

	BOOST_CHECK_EQUAL(result.size(), 1);
	BOOST_CHECK_EQUAL(result[0].label, "");
	BOOST_CHECK_EQUAL(result[0].text, "END");
}

BOOST_AUTO_TEST_CASE(test_program_without_end) {
	vector<Line> program = {Line("10", "PRINT \"HELLO WORLD\""), Line("20", "GOTO 10")};

	vector<Line> result = addEnd(program);

	BOOST_CHECK_EQUAL(result.size(), 3);
	BOOST_CHECK_EQUAL(result[2].label, "");
	BOOST_CHECK_EQUAL(result[2].text, "END");
}

BOOST_AUTO_TEST_CASE(test_program_with_end) {
	vector<Line> program = {Line("10", "PRINT \"HELLO WORLD\""), Line("20", "END")};

	vector<Line> result = addEnd(program);

	BOOST_CHECK_EQUAL(result.size(), 2);
	// Check the original program is unchanged
	BOOST_CHECK_EQUAL(result[0].label, "10");
	BOOST_CHECK_EQUAL(result[0].text, "PRINT \"HELLO WORLD\"");
	BOOST_CHECK_EQUAL(result[1].label, "20");
	BOOST_CHECK_EQUAL(result[1].text, "END");
}

BOOST_AUTO_TEST_CASE(test_program_with_lowercase_end) {
	vector<Line> program = {Line("10", "PRINT \"HELLO WORLD\""), Line("20", "end")};

	vector<Line> result = addEnd(program);

	BOOST_CHECK_EQUAL(result.size(), 2);
	// No new END should be added since "end" is already present
	BOOST_CHECK_EQUAL(result[1].label, "20");
	BOOST_CHECK_EQUAL(result[1].text, "end");
}

BOOST_AUTO_TEST_CASE(test_program_with_spaced_end) {
	vector<Line> program = {Line("10", "PRINT \"HELLO WORLD\""), Line("20", "  END")};

	vector<Line> result = addEnd(program);

	BOOST_CHECK_EQUAL(result.size(), 2);
	// No new END should be added
	BOOST_CHECK_EQUAL(result[1].label, "20");
	BOOST_CHECK_EQUAL(result[1].text, "  END");
}

BOOST_AUTO_TEST_CASE(test_program_with_end_plus_args) {
	vector<Line> program = {Line("10", "PRINT \"HELLO WORLD\""), Line("20", "END PROGRAM")};

	vector<Line> result = addEnd(program);

	BOOST_CHECK_EQUAL(result.size(), 2);
	// No new END should be added
	BOOST_CHECK_EQUAL(result[1].label, "20");
	BOOST_CHECK_EQUAL(result[1].text, "END PROGRAM");
}

BOOST_AUTO_TEST_CASE(test_program_with_end_in_middle) {
	vector<Line> program = {Line("10", "PRINT \"HELLO WORLD\""), Line("20", "END"), Line("30", "REM THIS IS UNREACHABLE")};

	vector<Line> result = addEnd(program);

	BOOST_CHECK_EQUAL(result.size(), 3);
	// No new END should be added
	BOOST_CHECK_EQUAL(result[1].label, "20");
	BOOST_CHECK_EQUAL(result[1].text, "END");
}

BOOST_AUTO_TEST_CASE(test_program_with_end_substring) {
	vector<Line> program = {
		Line("10", "PRINT \"HELLO WORLD\""),
		Line("20", "SEND MESSAGE"), // "END" is a substring here
		Line("30", "APPEND DATA")	// "END" is a substring here
	};

	vector<Line> result = addEnd(program);

	BOOST_CHECK_EQUAL(result.size(), 4);
	// A new END should be added
	BOOST_CHECK_EQUAL(result[3].label, "");
	BOOST_CHECK_EQUAL(result[3].text, "END");
}
