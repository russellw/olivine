#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(ProgramTests)

// Test default constructor
BOOST_AUTO_TEST_CASE(TestDefaultConstructor) {
	Program program;
	BOOST_CHECK(program.empty());
	BOOST_CHECK_EQUAL(program.size(), 0);
	BOOST_CHECK(program.globals().empty());
}

// Test parameterized constructor
BOOST_AUTO_TEST_CASE(TestParameterizedConstructor) {
	vector<Global> globals = {Global(), Global()};
	vector<Fn> defs = {Fn(), Fn(), Fn()};

	Program program(globals, defs);

	// Check size
	BOOST_CHECK_EQUAL(program.size(), 3);
	BOOST_CHECK(!program.empty());

	// Check globals
	auto programGlobals = program.globals();
	BOOST_CHECK_EQUAL(programGlobals.size(), 2);
}

// Test array access operator
BOOST_AUTO_TEST_CASE(TestArrayAccess) {
	vector<Global> globals;
	vector<Fn> defs = {Fn(), Fn()};

	Program program(globals, defs);

	// Check valid access
	BOOST_CHECK_NO_THROW(program[0]);
	BOOST_CHECK_NO_THROW(program[1]);

	// Check out of bounds access
	BOOST_CHECK_THROW(program[2], std::exception);
}

// Test iterators
BOOST_AUTO_TEST_CASE(TestIterators) {
	vector<Global> globals;
	vector<Fn> defs = {Fn(), Fn(), Fn()};

	Program program(globals, defs);

	// Test begin/end iteration
	size_t count = 0;
	for (auto it = program.begin(); it != program.end(); ++it) {
		count++;
	}
	BOOST_CHECK_EQUAL(count, 3);

	// Test const begin/end iteration
	count = 0;
	for (auto it = program.cbegin(); it != program.cend(); ++it) {
		count++;
	}
	BOOST_CHECK_EQUAL(count, 3);
}

// Test empty program behavior
BOOST_AUTO_TEST_CASE(TestEmptyProgram) {
	vector<Global> globals;
	vector<Fn> defs;

	Program program(globals, defs);

	BOOST_CHECK(program.empty());
	BOOST_CHECK_EQUAL(program.size(), 0);
	BOOST_CHECK(program.begin() == program.end());
	BOOST_CHECK(program.cbegin() == program.cend());
}

// Test program with only globals
BOOST_AUTO_TEST_CASE(TestProgramWithOnlyGlobals) {
	vector<Global> globals = {Global(), Global()};
	vector<Fn> defs;

	Program program(globals, defs);

	BOOST_CHECK(program.empty());
	BOOST_CHECK_EQUAL(program.size(), 0);
	BOOST_CHECK_EQUAL(program.globals().size(), 2);
}

// Test const correctness
BOOST_AUTO_TEST_CASE(TestConstCorrectness) {
	vector<Global> globals = {Global()};
	vector<Fn> defs = {Fn()};

	const Program program(globals, defs);

	// These should all compile and work with const Program
	BOOST_CHECK_EQUAL(program.size(), 1);
	BOOST_CHECK(!program.empty());
	BOOST_CHECK_NO_THROW(program[0]);
	BOOST_CHECK(program.begin() != program.end());
	BOOST_CHECK(program.cbegin() != program.cend());
	BOOST_CHECK_EQUAL(program.globals().size(), 1);
}

BOOST_AUTO_TEST_SUITE_END()
