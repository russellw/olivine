#include "all.h"
#include <boost/test/included/unit_test.hpp>
namespace fw = fixed_width_ops;

BOOST_AUTO_TEST_SUITE(FixedWidthOpsTests)

BOOST_AUTO_TEST_CASE(test_arithmetic) {
	// Test addition with overflow
	BOOST_CHECK_EQUAL(fw::add(15, 1, 4), 0);

	// Test subtraction with underflow
	BOOST_CHECK_EQUAL(fw::sub(0, 1, 4), 15);

	// Test multiplication with overflow
	BOOST_CHECK_EQUAL(fw::mul(8, 2, 4), 0);
}

BOOST_AUTO_TEST_CASE(test_signed_division) {
	// Test signed division with negative numbers
	// In 4 bits: 7 = 0111, -3 = 1101 (13 unsigned)
	BOOST_CHECK_EQUAL(fw::sdiv(7, 13, 4), 14); // 7 / -3 = -2 (14 unsigned)

	// Test signed remainder
	BOOST_CHECK_EQUAL(fw::srem(7, 13, 4), 1); // 7 % -3 = 1
}

BOOST_AUTO_TEST_CASE(test_shifts) {
	// Test logical shifts
	BOOST_CHECK_EQUAL(fw::shl(5, 1, 4), 10 & 15);
	BOOST_CHECK_EQUAL(fw::lshr(12, 1, 4), 6);

	// Test arithmetic shift
	BOOST_CHECK_EQUAL(fw::ashr(12, 1, 4), 14); // 1100 -> 1110
}

BOOST_AUTO_TEST_CASE(test_comparisons) {
	// Test unsigned comparisons
	BOOST_CHECK_EQUAL(fw::ult(5, 10, 4), 1);
	BOOST_CHECK_EQUAL(fw::ule(5, 5, 4), 1);

	// Test signed comparisons
	// 5 = 0101, -3 = 1101 (13 unsigned)
	BOOST_CHECK_EQUAL(fw::slt(5, 13, 4), 0);  // 5 < -3 is false
	BOOST_CHECK_EQUAL(fw::sle(13, 13, 4), 1); // -3 <= -3 is true
}

BOOST_AUTO_TEST_CASE(test_edge_cases) {
	// Test division by zero
	BOOST_CHECK_THROW(fw::udiv(1, 0, 4), std::domain_error);
	BOOST_CHECK_THROW(fw::sdiv(1, 0, 4), std::domain_error);

	// Test large shifts
	BOOST_CHECK_EQUAL(fw::shl(1, 4, 4), 0);
	BOOST_CHECK_EQUAL(fw::lshr(15, 4, 4), 0);
	BOOST_CHECK_EQUAL(fw::ashr(8, 4, 4), 15); // Sign extends 1000 to 1111
}

BOOST_AUTO_TEST_SUITE_END()
