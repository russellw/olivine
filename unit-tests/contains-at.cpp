#include "all.h"
#include <boost/test/included/unit_test.hpp>

BOOST_AUTO_TEST_CASE(basic_match) {
	BOOST_TEST(containsAt("Hello World", 6, "World") == true);
}

BOOST_AUTO_TEST_CASE(match_at_beginning) {
	BOOST_TEST(containsAt("Hello World", 0, "Hello") == true);
}

BOOST_AUTO_TEST_CASE(match_at_end) {
	BOOST_TEST(containsAt("Hello World", 10, "d") == true);
}

BOOST_AUTO_TEST_CASE(no_match_wrong_position) {
	BOOST_TEST(containsAt("Hello World", 1, "Hello") == false);
}

BOOST_AUTO_TEST_CASE(empty_needle) {
	BOOST_TEST(containsAt("Hello World", 5, "") == true);
	BOOST_TEST(containsAt("Hello", 5, "") == true);	 // Empty needle at end of string
	BOOST_TEST(containsAt("Hello", 6, "") == false); // Position beyond string length
}

BOOST_AUTO_TEST_CASE(empty_haystack) {
	BOOST_TEST(containsAt("", 0, "") == true);
	BOOST_TEST(containsAt("", 0, "x") == false);
	BOOST_TEST(containsAt("", 1, "") == false); // Position beyond empty string
}

BOOST_AUTO_TEST_CASE(position_out_of_bounds) {
	BOOST_TEST(containsAt("Hello", 6, "") == false);
	BOOST_TEST(containsAt("Hello", 6, "x") == false);
}

BOOST_AUTO_TEST_CASE(needle_too_long) {
	BOOST_TEST(containsAt("Hello", 3, "loWorld") == false);
}

BOOST_AUTO_TEST_CASE(case_sensitivity) {
	BOOST_TEST(containsAt("Hello World", 6, "world") == false);
}

BOOST_AUTO_TEST_CASE(special_characters) {
	BOOST_TEST(containsAt("Hello\n\tWorld", 5, "\n\t") == true);
}
