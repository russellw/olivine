#include "all.h"
#include <boost/test/unit_test.hpp>

// Reset subroutineNumber before each test
struct ResetFixture {
	ResetFixture() {
		// Reset the global counter before each test
		subroutineNumber = 0;
	}
};

BOOST_FIXTURE_TEST_SUITE(add_subroutine_tests, ResetFixture)

BOOST_AUTO_TEST_CASE(test_empty_body) {
	// Test with an empty body
	vector<Line> program;
	vector<Line> body;

	string result = addSubroutine(program, body);

	// Check the result
	BOOST_CHECK_EQUAL(result, "_SUBROUTINE_0");

	// Check the program structure
	BOOST_REQUIRE_EQUAL(program.size(), 2);
	BOOST_CHECK_EQUAL(program[0].label, "_SUBROUTINE_0");
	BOOST_CHECK_EQUAL(program[0].text, "");
	BOOST_CHECK_EQUAL(program[1].label, "");
	BOOST_CHECK_EQUAL(program[1].text, "RETURN");

	// Check that subroutineNumber was incremented
	BOOST_CHECK_EQUAL(subroutineNumber, 1);
}

BOOST_AUTO_TEST_CASE(test_single_line_body) {
	// Test with a single line in the body
	vector<Line> program;
	vector<Line> body = {Line("", "PRINT A$")};

	string result = addSubroutine(program, body);

	// Check the result
	BOOST_CHECK_EQUAL(result, "_SUBROUTINE_0");

	// Check the program structure
	BOOST_REQUIRE_EQUAL(program.size(), 3);
	BOOST_CHECK_EQUAL(program[0].label, "_SUBROUTINE_0");
	BOOST_CHECK_EQUAL(program[0].text, "");
	BOOST_CHECK_EQUAL(program[1].label, "");
	BOOST_CHECK_EQUAL(program[1].text, "PRINT A$");
	BOOST_CHECK_EQUAL(program[2].label, "");
	BOOST_CHECK_EQUAL(program[2].text, "RETURN");

	// Check that subroutineNumber was incremented
	BOOST_CHECK_EQUAL(subroutineNumber, 1);
}

BOOST_AUTO_TEST_CASE(test_multi_line_body) {
	// Test with multiple lines in the body
	vector<Line> program;
	vector<Line> body = {Line("", "LET X = 10"), Line("", "PRINT X"), Line("", "LET Y = X * 2")};

	string result = addSubroutine(program, body);

	// Check the result
	BOOST_CHECK_EQUAL(result, "_SUBROUTINE_0");

	// Check the program structure
	BOOST_REQUIRE_EQUAL(program.size(), 5);
	BOOST_CHECK_EQUAL(program[0].label, "_SUBROUTINE_0");
	BOOST_CHECK_EQUAL(program[0].text, "");
	BOOST_CHECK_EQUAL(program[1].label, "");
	BOOST_CHECK_EQUAL(program[1].text, "LET X = 10");
	BOOST_CHECK_EQUAL(program[2].label, "");
	BOOST_CHECK_EQUAL(program[2].text, "PRINT X");
	BOOST_CHECK_EQUAL(program[3].label, "");
	BOOST_CHECK_EQUAL(program[3].text, "LET Y = X * 2");
	BOOST_CHECK_EQUAL(program[4].label, "");
	BOOST_CHECK_EQUAL(program[4].text, "RETURN");

	// Check that subroutineNumber was incremented
	BOOST_CHECK_EQUAL(subroutineNumber, 1);
}

BOOST_AUTO_TEST_CASE(test_body_with_labels) {
	// Test with lines that have labels in the body
	vector<Line> program;
	vector<Line> body = {Line("10", "LET X = 10"), Line("20", "PRINT X")};

	string result = addSubroutine(program, body);

	// Check that labels in the body are preserved
	BOOST_REQUIRE_EQUAL(program.size(), 4);
	BOOST_CHECK_EQUAL(program[1].label, "10");
	BOOST_CHECK_EQUAL(program[1].text, "LET X = 10");
	BOOST_CHECK_EQUAL(program[2].label, "20");
	BOOST_CHECK_EQUAL(program[2].text, "PRINT X");
}

BOOST_AUTO_TEST_CASE(test_multiple_subroutines) {
	// Test adding multiple subroutines
	vector<Line> program;

	// Add first subroutine
	vector<Line> body1 = {Line("", "PRINT \"First\"")};
	string result1 = addSubroutine(program, body1);

	// Add second subroutine
	vector<Line> body2 = {Line("", "PRINT \"Second\"")};
	string result2 = addSubroutine(program, body2);

	// Check results
	BOOST_CHECK_EQUAL(result1, "_SUBROUTINE_0");
	BOOST_CHECK_EQUAL(result2, "_SUBROUTINE_1");

	// Check the program structure
	BOOST_REQUIRE_EQUAL(program.size(), 6);

	// First subroutine
	BOOST_CHECK_EQUAL(program[0].label, "_SUBROUTINE_0");
	BOOST_CHECK_EQUAL(program[1].label, "");
	BOOST_CHECK_EQUAL(program[1].text, "PRINT \"First\"");
	BOOST_CHECK_EQUAL(program[2].label, "");
	BOOST_CHECK_EQUAL(program[2].text, "RETURN");

	// Second subroutine
	BOOST_CHECK_EQUAL(program[3].label, "_SUBROUTINE_1");
	BOOST_CHECK_EQUAL(program[4].label, "");
	BOOST_CHECK_EQUAL(program[4].text, "PRINT \"Second\"");
	BOOST_CHECK_EQUAL(program[5].label, "");
	BOOST_CHECK_EQUAL(program[5].text, "RETURN");

	// Check that subroutineNumber was incremented twice
	BOOST_CHECK_EQUAL(subroutineNumber, 2);
}

BOOST_AUTO_TEST_CASE(test_adding_to_existing_program) {
	// Test adding a subroutine to a non-empty program
	vector<Line> program = {Line("100", "LET A = 5"), Line("110", "PRINT A")};

	vector<Line> body = {Line("", "PRINT \"Subroutine\"")};
	string result = addSubroutine(program, body);

	// Check the result
	BOOST_CHECK_EQUAL(result, "_SUBROUTINE_0");

	// Check the program structure
	BOOST_REQUIRE_EQUAL(program.size(), 5);

	// Original program
	BOOST_CHECK_EQUAL(program[0].label, "100");
	BOOST_CHECK_EQUAL(program[0].text, "LET A = 5");
	BOOST_CHECK_EQUAL(program[1].label, "110");
	BOOST_CHECK_EQUAL(program[1].text, "PRINT A");

	// Added subroutine
	BOOST_CHECK_EQUAL(program[2].label, "_SUBROUTINE_0");
	BOOST_CHECK_EQUAL(program[2].text, "");
	BOOST_CHECK_EQUAL(program[3].label, "");
	BOOST_CHECK_EQUAL(program[3].text, "PRINT \"Subroutine\"");
	BOOST_CHECK_EQUAL(program[4].label, "");
	BOOST_CHECK_EQUAL(program[4].text, "RETURN");
}

BOOST_AUTO_TEST_SUITE_END()
