#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(ZeroValTests)

// Test void type
BOOST_AUTO_TEST_CASE(TestVoidType) {
	Type ty = voidTy();
	Term result = zeroVal(ty);
	BOOST_CHECK_EQUAL(result.tag(), Tag::Null);
}

// Test integer types
BOOST_AUTO_TEST_CASE(TestIntegerTypes) {
	// Test bool (1-bit integer)
	{
		Type ty = boolTy();
		Term result = zeroVal(ty);
		BOOST_CHECK_EQUAL(result.tag(), Tag::Int);
		BOOST_CHECK_EQUAL(result.intVal(), 0);
	}

	// Test 32-bit integer
	{
		Type ty = intTy(32);
		Term result = zeroVal(ty);
		BOOST_CHECK_EQUAL(result.tag(), Tag::Int);
		BOOST_CHECK_EQUAL(result.intVal(), 0);
	}

	// Test 64-bit integer
	{
		Type ty = intTy(64);
		Term result = zeroVal(ty);
		BOOST_CHECK_EQUAL(result.tag(), Tag::Int);
		BOOST_CHECK_EQUAL(result.intVal(), 0);
	}
}

// Test floating point types
BOOST_AUTO_TEST_CASE(TestFloatTypes) {
	// Test float
	{
		Type ty = floatTy();
		Term result = zeroVal(ty);
		BOOST_CHECK_EQUAL(result.tag(), Tag::Float);
		BOOST_CHECK_EQUAL(result.str(), "0.0");
	}

	// Test double
	{
		Type ty = doubleTy();
		Term result = zeroVal(ty);
		BOOST_CHECK_EQUAL(result.tag(), Tag::Float);
		BOOST_CHECK_EQUAL(result.str(), "0.0");
	}
}

// Test pointer type
BOOST_AUTO_TEST_CASE(TestPointerType) {
	Type ty = ptrTy();
	Term result = zeroVal(ty);
	BOOST_CHECK_EQUAL(result, nullConst);
}

// Test array type
BOOST_AUTO_TEST_CASE(TestArrayType) {
	// Create an array of 3 integers
	Type elemTy = intTy(32);
	Type arrayTy3 = arrayTy(3, elemTy);
	Term result = zeroVal(arrayTy3);

	BOOST_CHECK_EQUAL(result.tag(), Tag::Array);
	BOOST_CHECK_EQUAL(result.size(), 3);

	// Check each element is zero
	for (size_t i = 0; i < 3; ++i) {
		BOOST_CHECK_EQUAL(result[i].tag(), Tag::Int);
		BOOST_CHECK_EQUAL(result[i].intVal(), 0);
	}
}

// Test vector type
BOOST_AUTO_TEST_CASE(TestVectorType) {
	// Create a vector of 4 floats
	Type elemTy = floatTy();
	Type vecTy4 = vecTy(4, elemTy);
	Term result = zeroVal(vecTy4);

	BOOST_CHECK_EQUAL(result.tag(), Tag::Vec);
	BOOST_CHECK_EQUAL(result.size(), 4);

	// Check each element is zero
	for (size_t i = 0; i < 4; ++i) {
		BOOST_CHECK_EQUAL(result[i].tag(), Tag::Float);
		BOOST_CHECK_EQUAL(result[i].str(), "0.0");
	}
}

// Test struct type
BOOST_AUTO_TEST_CASE(TestStructType) {
	// Create a struct with mixed types: {int32, float, ptr}
	vector<Type> fields = {intTy(32), floatTy(), ptrTy()};
	Type structTy1 = structTy(fields);
	Term result = zeroVal(structTy1);

	BOOST_CHECK_EQUAL(result.tag(), Tag::Tuple);
	BOOST_CHECK_EQUAL(result.size(), 3);

	// Check each field
	BOOST_CHECK_EQUAL(result[0].tag(), Tag::Int);
	BOOST_CHECK_EQUAL(result[0].intVal(), 0);

	BOOST_CHECK_EQUAL(result[1].tag(), Tag::Float);
	BOOST_CHECK_EQUAL(result[1].str(), "0.0");

	BOOST_CHECK_EQUAL(result[2], nullConst);
}

// Test nested types
BOOST_AUTO_TEST_CASE(TestNestedTypes) {
	// Create a struct containing an array of pointers
	Type ptrTy1 = ptrTy();
	Type arrayTy2 = arrayTy(2, ptrTy1);
	vector<Type> fields = {intTy(32), arrayTy2};
	Type structTy1 = structTy(fields);

	Term result = zeroVal(structTy1);

	BOOST_CHECK_EQUAL(result.tag(), Tag::Tuple);
	BOOST_CHECK_EQUAL(result.size(), 2);

	// Check integer field
	BOOST_CHECK_EQUAL(result[0].tag(), Tag::Int);
	BOOST_CHECK_EQUAL(result[0].intVal(), 0);

	// Check array field
	BOOST_CHECK_EQUAL(result[1].tag(), Tag::Array);
	BOOST_CHECK_EQUAL(result[1].size(), 2);
	BOOST_CHECK_EQUAL(result[1][0], nullConst);
	BOOST_CHECK_EQUAL(result[1][1], nullConst);
}

// Test function type (should throw)
BOOST_AUTO_TEST_CASE(TestFunctionType) {
	Type returnTy = voidTy();
	vector<Type> paramTys = {intTy(32)};
	Type fnTy1 = fnTy(returnTy, paramTys);

	BOOST_CHECK_THROW(zeroVal(fnTy1), std::runtime_error);
}

BOOST_AUTO_TEST_SUITE_END()
