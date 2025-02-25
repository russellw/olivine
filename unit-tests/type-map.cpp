BOOST_AUTO_TEST_CASE(BasicTypeMapping) {
	std::unordered_map<Type, int> typeMap;

	// Test primitive types
	typeMap[voidTy()] = 1;
	typeMap[intTy(32)] = 2;
	typeMap[boolTy()] = 3;

	BOOST_CHECK_EQUAL(typeMap[voidTy()], 1);
	BOOST_CHECK_EQUAL(typeMap[intTy(32)], 2);
	BOOST_CHECK_EQUAL(typeMap[boolTy()], 3);
}

BOOST_AUTO_TEST_CASE(CompoundTypeMapping) {
	std::unordered_map<Type, std::string> typeMap;

	// Create some compound types
	Type arrayOfInt = arrayTy(10, intTy(32));
	Type vectorOfFloat = vecTy(4, floatTy());

	typeMap[arrayOfInt] = "array of int";
	typeMap[vectorOfFloat] = "vector of float";

	BOOST_CHECK_EQUAL(typeMap[arrayOfInt], "array of int");
	BOOST_CHECK_EQUAL(typeMap[vectorOfFloat], "vector of float");

	// Test that identical types map to the same value
	Type sameArrayType = arrayTy(10, intTy(32));
	BOOST_CHECK_EQUAL(typeMap[sameArrayType], "array of int");
}

BOOST_AUTO_TEST_CASE(StructureTypeMapping) {
	std::unordered_map<Type, int> typeMap;

	std::vector<Type> fields1 = {intTy(32), floatTy()};
	std::vector<Type> fields2 = {intTy(32), floatTy()}; // Same structure
	std::vector<Type> fields3 = {floatTy(), intTy(32)}; // Different order

	Type struct1 = structTy(fields1);
	Type struct2 = structTy(fields2);
	Type struct3 = structTy(fields3);

	typeMap[struct1] = 1;

	// Test structural equality
	BOOST_CHECK_EQUAL(typeMap[struct2], 1);

	// Different structure should get different slot
	typeMap[struct3] = 2;
	BOOST_CHECK_EQUAL(typeMap[struct3], 2);
}

BOOST_AUTO_TEST_CASE(FuncTypeMapping) {
	std::unordered_map<Type, std::string> typeMap;

	// Function type: int32 (float, bool)
	std::vector<Type> params1 = {intTy(32), floatTy(), boolTy()};
	Type func1 = funcTy(params1);

	// Same function type
	std::vector<Type> params2 = {intTy(32), floatTy(), boolTy()};
	Type func2 = funcTy(params2);

	typeMap[func1] = "int32 (float, bool)";

	// Test that identical function types map to the same value
	BOOST_CHECK_EQUAL(typeMap[func2], "int32 (float, bool)");
}

BOOST_AUTO_TEST_CASE(TypeMapOverwrite) {
	std::unordered_map<Type, int> typeMap;

	Type int32Type = intTy(32);
	typeMap[int32Type] = 1;
	BOOST_CHECK_EQUAL(typeMap[int32Type], 1);

	// Overwrite existing value
	typeMap[int32Type] = 2;
	BOOST_CHECK_EQUAL(typeMap[int32Type], 2);
}

BOOST_AUTO_TEST_CASE(TypeMapErase) {
	std::unordered_map<Type, int> typeMap;

	Type int32Type = intTy(32);
	typeMap[int32Type] = 1;

	// Test erase
	size_t eraseCount = typeMap.erase(int32Type);
	BOOST_CHECK_EQUAL(eraseCount, 1);
	BOOST_CHECK_EQUAL(typeMap.count(int32Type), 0);
}
