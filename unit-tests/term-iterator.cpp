BOOST_AUTO_TEST_SUITE(TermIteratorTests)

// Test empty term iteration
BOOST_AUTO_TEST_CASE(EmptyTermTest) {
	Term emptyTerm;
	BOOST_CHECK(emptyTerm.begin() == emptyTerm.end());
	BOOST_CHECK(emptyTerm.cbegin() == emptyTerm.cend());

	// Verify iterator equality
	BOOST_CHECK(emptyTerm.begin() == emptyTerm.cbegin());
	BOOST_CHECK(emptyTerm.end() == emptyTerm.cend());
}

// Test iteration over function parameters
BOOST_AUTO_TEST_CASE(ParametersIterationTest) {
	// Create parameters with different types
	std::vector<Term> params = {var(intTy(32), "a"), var(doubleTy(), "b"), var(ptrTy(), "c")};

	Term paramTerm = tuple(params);

	// Check size matches number of parameters
	BOOST_CHECK_EQUAL(paramTerm.size(), 3);

	// Test forward iteration
	auto it = paramTerm.begin();
	BOOST_CHECK_EQUAL((*it).ty(), intTy(32));
	++it;
	BOOST_CHECK_EQUAL((*it).ty(), doubleTy());
	++it;
	BOOST_CHECK_EQUAL((*it).ty(), ptrTy());
	++it;
	BOOST_CHECK(it == paramTerm.end());
}

// Test iteration over arithmetic expressions
BOOST_AUTO_TEST_CASE(ArithmeticExpressionIterationTest) {
	Term a = var(intTy(32), "a");
	Term b = var(intTy(32), "b");
	Term addExpr = arithmetic(Add, a, b);

	// Check size
	BOOST_CHECK_EQUAL(addExpr.size(), 2);

	// Test const iteration
	auto cit = addExpr.cbegin();
	BOOST_CHECK_EQUAL((*cit).str(), "a");
	++cit;
	BOOST_CHECK_EQUAL((*cit).str(), "b");
	++cit;
	BOOST_CHECK(cit == addExpr.cend());
}

// Test comparison operations
BOOST_AUTO_TEST_CASE(IteratorComparisonTest) {
	Term a = var(intTy(32), "a");
	Term b = var(intTy(32), "b");
	Term expr = arithmetic(Add, a, b);

	auto it1 = expr.begin();
	auto it2 = expr.begin();
	auto end = expr.end();

	// Test equality
	BOOST_CHECK(it1 == it2);

	// Test inequality
	++it2;
	BOOST_CHECK(it1 != it2);

	// Test const iterator comparison
	auto cit1 = expr.cbegin();
	auto cit2 = expr.cbegin();
	BOOST_CHECK(cit1 == cit2);
}

// Test iterator invalidation
BOOST_AUTO_TEST_CASE(IteratorInvalidationTest) {
	std::vector<Term> params = {var(intTy(32), "a"), var(intTy(32), "b")};

	Term paramTerm = tuple(params);
	auto it = paramTerm.begin();
	auto end = paramTerm.end();

	// Store initial values
	std::vector<Term> initialValues;
	for (; it != end; ++it) {
		initialValues.push_back(*it);
	}

	// Create new term with same structure
	Term newParamTerm = tuple(params);

	// Verify iterators on original term still valid
	it = paramTerm.begin();
	for (const auto& initial : initialValues) {
		BOOST_CHECK_EQUAL(*it, initial);
		++it;
	}
}

BOOST_AUTO_TEST_SUITE_END()
