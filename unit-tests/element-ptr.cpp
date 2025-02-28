#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(ElementPtrTests)

// Test elementPtr with a basic integer array
BOOST_AUTO_TEST_CASE(BasicIntArrayTest) {
	// Create an array type of 10 32-bit integers
	Type elementType = intTy(32);
	Type arrayType = arrayTy(10, elementType);

	// Create a pointer variable to the array
	Term arrayPtr = var(ptrTy(), Ref("arr"));

	// Create an index
	Term index = intConst(intTy(64), 5);

	// Create the elementPtr term
	Term result = elementPtr(elementType, arrayPtr, index);

	// Verify the result
	BOOST_CHECK_EQUAL(result.tag(), ElementPtr);
	BOOST_CHECK_EQUAL(result.ty(), ptrTy());
	BOOST_CHECK_EQUAL(result.size(), 3);

	// Check that first operand is the element type
	BOOST_CHECK_EQUAL(result[0], none(elementType));

	// Check pointer operand
	BOOST_CHECK_EQUAL(result[1], arrayPtr);

	// Check index operand
	BOOST_CHECK_EQUAL(result[2], index);
}

// Test elementPtr with a structure array
BOOST_AUTO_TEST_CASE(StructArrayTest) {
	// Create a struct type with two fields: int32 and float
	vector<Type> fields = {intTy(32), floatTy()};
	Type structType = structTy(fields);
	Type arrayType = arrayTy(5, structType);

	// Create a pointer variable to the array
	Term arrayPtr = var(ptrTy(), Ref("structArr"));

	// Create an index
	Term index = intConst(intTy(64), 2);

	// Create the elementPtr term
	Term result = elementPtr(structType, arrayPtr, index);

	// Verify the result
	BOOST_CHECK_EQUAL(result.tag(), ElementPtr);
	BOOST_CHECK_EQUAL(result.ty(), ptrTy());
	BOOST_CHECK_EQUAL(result.size(), 3);

	// Check that first operand is zero value of struct type
	BOOST_CHECK_EQUAL(result[0], zeroVal(structType));

	// Check pointer operand
	BOOST_CHECK_EQUAL(result[1], arrayPtr);

	// Check index operand
	BOOST_CHECK_EQUAL(result[2], index);
}

// Test elementPtr with variable index
BOOST_AUTO_TEST_CASE(VariableIndexTest) {
	Type elementType = doubleTy();
	Type arrayType = arrayTy(100, elementType);

	// Create a pointer variable to the array
	Term arrayPtr = var(ptrTy(), Ref("doubleArr"));

	// Create a variable index
	Term index = var(intTy(64), Ref("i"));

	// Create the elementPtr term
	Term result = elementPtr(elementType, arrayPtr, index);

	// Verify the result
	BOOST_CHECK_EQUAL(result.tag(), ElementPtr);
	BOOST_CHECK_EQUAL(result.ty(), ptrTy());

	// Check that variable index is properly used
	BOOST_CHECK_EQUAL(result[2], index);
	BOOST_CHECK_EQUAL(result[2].tag(), Var);
}

// Test elementPtr with vectors
BOOST_AUTO_TEST_CASE(VectorTest) {
	// Create a vector type of 4 floats
	Type elementType = floatTy();
	Type vecType = vecTy(4, elementType);

	// Create a pointer variable to the vector
	Term vecPtr = var(ptrTy(), Ref("vec"));

	// Create an index
	Term index = intConst(intTy(64), 1);

	// Create the elementPtr term
	Term result = elementPtr(elementType, vecPtr, index);

	// Verify the result
	BOOST_CHECK_EQUAL(result.tag(), ElementPtr);
	BOOST_CHECK_EQUAL(result.ty(), ptrTy());

	// Check that first operand is zero value of element type
	BOOST_CHECK_EQUAL(result[0], zeroVal(elementType));
}

// Test error cases (these might need to be handled at a higher level)
BOOST_AUTO_TEST_CASE(EdgeCases) {
	Type elementType = intTy(32);

	// Test with null pointer
	Term nullPtr = nullPtrConst;
	Term index = intConst(intTy(64), 0);

	Term result = elementPtr(elementType, nullPtr, index);

	// Even with null pointer, the term should be well-formed
	BOOST_CHECK_EQUAL(result.tag(), ElementPtr);
	BOOST_CHECK_EQUAL(result.ty(), ptrTy());
	BOOST_CHECK_EQUAL(result[1], nullPtr);
}

BOOST_AUTO_TEST_SUITE_END()
