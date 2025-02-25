BOOST_AUTO_TEST_SUITE(TypeIteratorTests)

// Test scalar types have empty iteration range
BOOST_AUTO_TEST_CASE(ScalarTypeIterators) {
	// Test void type
	{
		Type t = voidTy();
		BOOST_CHECK(t.begin() == t.end());
		BOOST_CHECK(t.cbegin() == t.cend());
		BOOST_CHECK_EQUAL(std::distance(t.begin(), t.end()), 0);
	}

	// Test integer type
	{
		Type t = intTy(32);
		BOOST_CHECK(t.begin() == t.end());
		BOOST_CHECK(t.cbegin() == t.cend());
		BOOST_CHECK_EQUAL(std::distance(t.begin(), t.end()), 0);
	}

	// Test float type
	{
		Type t = floatTy();
		BOOST_CHECK(t.begin() == t.end());
		BOOST_CHECK(t.cbegin() == t.cend());
		BOOST_CHECK_EQUAL(std::distance(t.begin(), t.end()), 0);
	}
}

// Test vector type iteration
BOOST_AUTO_TEST_CASE(VectorTypeIterators) {
	Type elementType = intTy(32);
	Type vecT = vecTy(4, elementType);

	BOOST_CHECK(vecT.begin() != vecT.end());
	BOOST_CHECK(vecT.cbegin() != vecT.cend());
	BOOST_CHECK_EQUAL(std::distance(vecT.begin(), vecT.end()), 1);

	// Check element type through iterator
	BOOST_CHECK(*vecT.begin() == elementType);
}

// Test array type iteration
BOOST_AUTO_TEST_CASE(ArrayTypeIterators) {
	Type elementType = doubleTy();
	Type arrT = arrayTy(10, elementType);

	BOOST_CHECK(arrT.begin() != arrT.end());
	BOOST_CHECK(arrT.cbegin() != arrT.cend());
	BOOST_CHECK_EQUAL(std::distance(arrT.begin(), arrT.end()), 1);

	// Check element type through iterator
	BOOST_CHECK(*arrT.begin() == elementType);
}

// Test struct type iteration
BOOST_AUTO_TEST_CASE(StructTypeIterators) {
	std::vector<Type> fields = {intTy(32), floatTy(), doubleTy()};
	Type structT = structTy(fields);

	BOOST_CHECK(structT.begin() != structT.end());
	BOOST_CHECK(structT.cbegin() != structT.cend());
	BOOST_CHECK_EQUAL(std::distance(structT.begin(), structT.end()), fields.size());

	// Check field types through iterators
	auto it = structT.begin();
	for (const auto& field : fields) {
		BOOST_CHECK(*it == field);
		++it;
	}
}

// Test function type iteration
BOOST_AUTO_TEST_CASE(FuncTypeIterators) {
	std::vector<Type> params = {intTy(32), floatTy(), ptrTy()};
	Type rty = voidTy();
	std::vector<Type> funcTys = params;
	funcTys.insert(funcTys.begin(), rty);
	Type funcT = funcTy(funcTys);

	BOOST_CHECK(funcT.begin() != funcT.end());
	BOOST_CHECK(funcT.cbegin() != funcT.cend());
	BOOST_CHECK_EQUAL(std::distance(funcT.begin(), funcT.end()), params.size() + 1);

	// Check return type
	BOOST_CHECK(*funcT.begin() == rty);

	// Check parameter types
	auto it = std::next(funcT.begin());
	for (const auto& param : params) {
		BOOST_CHECK(*it == param);
		++it;
	}
}

// Test iterator comparison and assignment
BOOST_AUTO_TEST_CASE(IteratorOperations) {
	Type structT = structTy({intTy(32), floatTy()});

	// Test iterator assignment and comparison
	auto it1 = structT.begin();
	auto it2 = it1;
	BOOST_CHECK(it1 == it2);

	// Test iterator increment
	++it2;
	BOOST_CHECK(it1 != it2);

	// Test const_iterator assignment and comparison
	auto cit1 = structT.cbegin();
	auto cit2 = cit1;
	BOOST_CHECK(cit1 == cit2);

	// Test const_iterator increment
	++cit2;
	BOOST_CHECK(cit1 != cit2);

	// Test iterator to const_iterator conversion
	Type::const_iterator cit3 = it1;
	BOOST_CHECK(cit3 == it1);
}

// Test iterator invalidation
BOOST_AUTO_TEST_CASE(IteratorInvalidation) {
	Type structT1 = structTy({intTy(32), floatTy()});
	auto it1 = structT1.begin();

	// Create a new struct type
	Type structT2 = structTy({doubleTy(), ptrTy()});

	// Original iterator should still be valid and point to the original type
	BOOST_CHECK(*it1 == intTy(32));
}

BOOST_AUTO_TEST_SUITE_END()
