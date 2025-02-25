// Test suite for cons function
BOOST_AUTO_TEST_SUITE(ConsTests)

BOOST_AUTO_TEST_CASE(cons_empty_vector) {
	vector<int> empty;
	auto result = cons(1, empty);

	BOOST_CHECK_EQUAL(result.size(), 1);
	BOOST_CHECK_EQUAL(result[0], 1);
}

BOOST_AUTO_TEST_CASE(cons_nonempty_vector) {
	vector<int> v{2, 3, 4};
	auto result = cons(1, v);

	BOOST_CHECK_EQUAL(result.size(), 4);
	BOOST_CHECK_EQUAL(result[0], 1);
	BOOST_CHECK_EQUAL(result[1], 2);
	BOOST_CHECK_EQUAL(result[2], 3);
	BOOST_CHECK_EQUAL(result[3], 4);
}

BOOST_AUTO_TEST_CASE(cons_preserves_original) {
	vector<int> original{2, 3, 4};
	vector<int> originalCopy = original;
	auto result = cons(1, original);

	BOOST_CHECK_EQUAL_COLLECTIONS(original.begin(), original.end(), originalCopy.begin(), originalCopy.end());
}

BOOST_AUTO_TEST_CASE(cons_with_string) {
	vector<string> v{"world", "!"};
	auto result = cons(string("hello"), v);

	BOOST_CHECK_EQUAL(result.size(), 3);
	BOOST_CHECK_EQUAL(result[0], "hello");
	BOOST_CHECK_EQUAL(result[1], "world");
	BOOST_CHECK_EQUAL(result[2], "!");
}

BOOST_AUTO_TEST_SUITE_END()
