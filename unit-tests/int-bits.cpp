// Helper function to create a cpp_int with specific bits set
#include "all.h"
#include <boost/test/unit_test.hpp>
cpp_int create_test_number(const std::vector<size_t>& set_bits) {
	cpp_int result = 0;
	for (size_t bit : set_bits) {
		bit_set(result, bit);
	}
	return result;
}

BOOST_AUTO_TEST_SUITE(TruncateBitsTests)

BOOST_AUTO_TEST_CASE(test_zero_input) {
	cpp_int input = 0;
	BOOST_CHECK_EQUAL(truncate_to_bits(input, 32), 0);
}

BOOST_AUTO_TEST_CASE(test_small_number) {
	cpp_int input = 42; // 101010 in binary
	BOOST_CHECK_EQUAL(truncate_to_bits(input, 32), 42);
}

BOOST_AUTO_TEST_CASE(test_exact_bit_length) {
	// Create number with exactly 8 bits: 10101010 (170 in decimal)
	cpp_int input = create_test_number({1, 3, 5, 7});
	BOOST_CHECK_EQUAL(truncate_to_bits(input, 8), 170);
}

BOOST_AUTO_TEST_CASE(test_truncation_needed) {
	// Create number with bits set beyond desired length
	cpp_int input = create_test_number({0, 2, 4, 8, 16, 32});
	cpp_int expected = create_test_number({0, 2, 4});
	BOOST_CHECK_EQUAL(truncate_to_bits(input, 5), expected);
}

BOOST_AUTO_TEST_CASE(test_large_numbers) {
	// Test with a very large number
	cpp_int input = cpp_int(1) << 1000;
	input -= 1; // Creates a number with 1000 ones

	// Truncate to 64 bits
	cpp_int expected = (cpp_int(1) << 64) - 1;
	BOOST_CHECK_EQUAL(truncate_to_bits(input, 64), expected);
}

BOOST_AUTO_TEST_CASE(test_single_bit) {
	cpp_int input = create_test_number({0, 1, 2, 3, 4});
	BOOST_CHECK_EQUAL(truncate_to_bits(input, 1), 1);
}

BOOST_AUTO_TEST_CASE(test_invalid_input) {
	cpp_int input = 42;
	BOOST_CHECK_THROW(truncate_to_bits(input, 0), std::invalid_argument);
}

BOOST_AUTO_TEST_CASE(test_specific_bit_patterns) {
	// Test alternating bit pattern
	cpp_int alternating = create_test_number({0, 2, 4, 6, 8, 10});
	BOOST_CHECK_EQUAL(truncate_to_bits(alternating, 4), 5); // Should keep only 0101

	// Test consecutive bits
	cpp_int consecutive = create_test_number({0, 1, 2, 3, 4, 5});
	BOOST_CHECK_EQUAL(truncate_to_bits(consecutive, 4), 15); // Should keep only 1111
}

BOOST_AUTO_TEST_SUITE_END()
