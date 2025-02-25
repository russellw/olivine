BOOST_AUTO_TEST_SUITE(HashVectorTests)

BOOST_AUTO_TEST_CASE(EmptyVectorTest) {
	vector<int> empty;
	BOOST_CHECK_EQUAL(hashVector(empty), 0);
}

BOOST_AUTO_TEST_CASE(SingleElementVectorTest) {
	vector<int> v{42};
	// Store the hash value calculated by hashVector
	size_t actual = hashVector(v);
	// Verify the hash is non-zero and consistent
	BOOST_CHECK_NE(actual, 0);
	BOOST_CHECK_EQUAL(hashVector(v), actual);
}

BOOST_AUTO_TEST_CASE(MultipleElementsVectorTest) {
	vector<int> v{1, 2, 3, 4, 5};
	size_t actual = hashVector(v);
	// Verify the hash is non-zero and consistent
	BOOST_CHECK_NE(actual, 0);
	BOOST_CHECK_EQUAL(hashVector(v), actual);
}

BOOST_AUTO_TEST_CASE(StringVectorTest) {
	vector<string> v{"hello", "world"};
	size_t actual = hashVector(v);
	// Verify the hash is non-zero and consistent
	BOOST_CHECK_NE(actual, 0);
	BOOST_CHECK_EQUAL(hashVector(v), actual);
}

BOOST_AUTO_TEST_CASE(OrderDependencyTest) {
	vector<int> v1{1, 2, 3};
	vector<int> v2{3, 2, 1};
	// Hashes should be different for different orders
	BOOST_CHECK_NE(hashVector(v1), hashVector(v2));
}

BOOST_AUTO_TEST_CASE(ConsistencyTest) {
	vector<int> v{1, 2, 3, 4, 5};
	size_t hash1 = hashVector(v);
	size_t hash2 = hashVector(v);
	// Same vector should produce same hash
	BOOST_CHECK_EQUAL(hash1, hash2);
}

BOOST_AUTO_TEST_CASE(DifferentTypesTest) {
	vector<int> v1{1, 2, 3};
	vector<double> v2{1.0, 2.0, 3.0};
	// Different types should produce different hashes even with "same" values
	BOOST_CHECK_NE(hashVector(v1), hashVector(v2));
}

BOOST_AUTO_TEST_CASE(LargeVectorTest) {
	vector<int> large(1000);
	for (int i = 0; i < 1000; ++i) {
		large[i] = i;
	}
	// Just verify it doesn't crash and returns non-zero
	BOOST_CHECK_NE(hashVector(large), 0);
}

BOOST_AUTO_TEST_SUITE_END()
