#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(RefSetSuite)

BOOST_AUTO_TEST_CASE(test_ref_set_deterministic_order) {
	// Create a set with our custom comparator
	std::set<Ref> refSet;

	// Add elements in different order each time
	refSet.insert(std::string("banana"));
	refSet.insert(size_t(100));
	refSet.insert(std::string("apple"));
	refSet.insert(size_t(50));

	// Check size is correct
	BOOST_CHECK_EQUAL(refSet.size(), 4);

	// Convert to vector to check order
	std::vector<Ref> orderedRefs(refSet.begin(), refSet.end());

	// Check that values are in correct order within each type
	BOOST_CHECK_EQUAL(orderedRefs[0].str(), "apple");
	BOOST_CHECK_EQUAL(orderedRefs[1].str(), "banana");
	BOOST_CHECK_EQUAL(orderedRefs[2].num(), 50);
	BOOST_CHECK_EQUAL(orderedRefs[3].num(), 100);
}

BOOST_AUTO_TEST_CASE(test_ref_set_insertion_order_invariance) {
	// Create two sets with different insertion orders
	std::set<Ref> refSet1;
	std::set<Ref> refSet2;

	// First set: Insert in one order
	refSet1.insert(size_t(42));
	refSet1.insert(std::string("hello"));
	refSet1.insert(size_t(10));
	refSet1.insert(std::string("world"));

	// Second set: Insert in different order
	refSet2.insert(std::string("world"));
	refSet2.insert(size_t(10));
	refSet2.insert(std::string("hello"));
	refSet2.insert(size_t(42));

	// Convert both to vectors
	std::vector<Ref> vec1(refSet1.begin(), refSet1.end());
	std::vector<Ref> vec2(refSet2.begin(), refSet2.end());

	// Check that the order is the same regardless of insertion order
	BOOST_REQUIRE_EQUAL(vec1.size(), vec2.size());
	for (size_t i = 0; i < vec1.size(); ++i) {
		BOOST_CHECK_EQUAL(vec1[i], vec2[i]);
	}
}

BOOST_AUTO_TEST_CASE(test_ref_set_duplicate_handling) {
	std::set<Ref> refSet;

	// Insert elements
	refSet.insert(size_t(42));
	refSet.insert(std::string("hello"));

	// Try to insert duplicates
	auto result1 = refSet.insert(size_t(42));
	auto result2 = refSet.insert(std::string("hello"));

	// Verify duplicates were not inserted
	BOOST_CHECK_EQUAL(result1.second, false);
	BOOST_CHECK_EQUAL(result2.second, false);
	BOOST_CHECK_EQUAL(refSet.size(), 2);
}

BOOST_AUTO_TEST_SUITE_END()
