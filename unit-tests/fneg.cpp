BOOST_AUTO_TEST_CASE(test_fneg_float_constant) {
	// Create a float constant to negate
	Term f = floatConst(floatTy(), "1.0");
	Term neg = arithmetic(FNeg, f);

	// Verify properties
	BOOST_CHECK_EQUAL(neg.tag(), FNeg);
	BOOST_CHECK_EQUAL(neg.ty(), floatTy());
	BOOST_CHECK_EQUAL(neg.size(), 1);
	BOOST_CHECK_EQUAL(neg[0], f);
}

BOOST_AUTO_TEST_CASE(test_fneg_double_constant) {
	// Create a double constant to negate
	Term d = floatConst(doubleTy(), "2.5");
	Term neg = arithmetic(FNeg, d);

	// Verify properties
	BOOST_CHECK_EQUAL(neg.tag(), FNeg);
	BOOST_CHECK_EQUAL(neg.ty(), doubleTy());
	BOOST_CHECK_EQUAL(neg.size(), 1);
	BOOST_CHECK_EQUAL(neg[0], d);
}

BOOST_AUTO_TEST_CASE(test_fneg_variable) {
	// Create a float variable to negate
	Term var1 = var(floatTy(), 1);
	Term neg = arithmetic(FNeg, var1);

	// Verify properties
	BOOST_CHECK_EQUAL(neg.tag(), FNeg);
	BOOST_CHECK_EQUAL(neg.ty(), floatTy());
	BOOST_CHECK_EQUAL(neg.size(), 1);
	BOOST_CHECK_EQUAL(neg[0], var1);
}

BOOST_AUTO_TEST_CASE(test_double_negation) {
	// Verify that negating twice preserves type and structure
	Term f = floatConst(floatTy(), "3.14");
	Term neg1 = arithmetic(FNeg, f);
	Term neg2 = arithmetic(FNeg, neg1);

	BOOST_CHECK_EQUAL(neg2.tag(), FNeg);
	BOOST_CHECK_EQUAL(neg2.ty(), floatTy());
	BOOST_CHECK_EQUAL(neg2.size(), 1);
	BOOST_CHECK_EQUAL(neg2[0], neg1);
}

BOOST_AUTO_TEST_CASE(test_fneg_equality) {
	// Create two identical FNeg expressions
	Term f = floatConst(floatTy(), "1.0");
	Term neg1 = arithmetic(FNeg, f);
	Term neg2 = arithmetic(FNeg, f);

	// They should be equal due to value semantics
	BOOST_CHECK_EQUAL(neg1, neg2);
}

BOOST_AUTO_TEST_CASE(test_fneg_hash_consistency) {
	// Create two identical FNeg expressions
	Term f = floatConst(floatTy(), "1.0");
	Term neg1 = arithmetic(FNeg, f);
	Term neg2 = arithmetic(FNeg, f);

	// Their hashes should be equal
	std::hash<Term> hasher;
	BOOST_CHECK_EQUAL(hasher(neg1), hasher(neg2));
}

BOOST_AUTO_TEST_CASE(test_fneg_type_preservation) {
	// Test with both float and double
	Term f = floatConst(floatTy(), "1.0");
	Term d = floatConst(doubleTy(), "1.0");

	Term negF = arithmetic(FNeg, f);
	Term negD = arithmetic(FNeg, d);

	BOOST_CHECK_EQUAL(negF.ty(), f.ty());
	BOOST_CHECK_EQUAL(negD.ty(), d.ty());
}
