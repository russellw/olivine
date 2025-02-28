#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(GetElementPtrTests)

// Test GEP on a simple array type
BOOST_AUTO_TEST_CASE(SimpleArrayAccess) {
	// Create an array type of 4 integers
	auto elementType = intTy(32);
	auto arrayType = arrayTy(4, elementType);

	// Create a pointer and index
	auto ptr = var(ptrTy(), Ref("ptr"));
	auto idx = intConst(intTy(64), 2); // Access index 2

	// Get the element pointer
	auto result = getElementPtr(arrayType, ptr, {idx});

	// The result should be equivalent to elementPtr(elementType, ptr, idx)
	auto expected = elementPtr(elementType, ptr, idx);
	BOOST_CHECK_EQUAL(result, expected);
}

// Test GEP on nested array type
BOOST_AUTO_TEST_CASE(NestedArrayAccess) {
	// Create a 3x4 array of integers
	auto elementType = intTy(32);
	auto innerArrayType = arrayTy(4, elementType);
	auto outerArrayType = arrayTy(3, innerArrayType);

	auto ptr = var(ptrTy(), Ref("ptr"));
	auto idx1 = intConst(intTy(64), 1); // First dimension
	auto idx2 = intConst(intTy(64), 2); // Second dimension

	auto result = getElementPtr(outerArrayType, ptr, {idx1, idx2});

	// The result should be equivalent to nested elementPtr calls
	auto intermediate = elementPtr(innerArrayType, ptr, idx1);
	auto expected = elementPtr(elementType, intermediate, idx2);
	BOOST_CHECK_EQUAL(result, expected);
}

// Test GEP on struct type
BOOST_AUTO_TEST_CASE(StructAccess) {
	// Create a struct type with multiple fields
	vector<Type> fields = {
		intTy(32),	// field 0: int32
		doubleTy(), // field 1: double
		ptrTy()		// field 2: pointer
	};
	auto structType = structTy(fields);

	auto ptr = var(ptrTy(), Ref("ptr"));
	auto idx = intConst(intTy(64), 1); // Access field 1 (double)

	auto result = getElementPtr(structType, ptr, {idx});

	// The result should be equivalent to fieldPtr
	auto expected = fieldPtr(structType, ptr, 1);
	BOOST_CHECK_EQUAL(result, expected);
}

// Test GEP on struct containing array
BOOST_AUTO_TEST_CASE(StructWithArrayAccess) {
	// Create a struct containing an array
	auto arrayType = arrayTy(4, intTy(32));
	vector<Type> fields = {
		intTy(64), // field 0: int64
		arrayType  // field 1: array of 4 int32
	};
	auto structType = structTy(fields);

	auto ptr = var(ptrTy(), Ref("ptr"));
	auto fieldIdx = intConst(intTy(64), 1); // Access field 1 (array)
	auto arrayIdx = intConst(intTy(64), 2); // Access array index 2

	auto result = getElementPtr(structType, ptr, {fieldIdx, arrayIdx});

	// The result should be equivalent to fieldPtr followed by elementPtr
	auto intermediate = fieldPtr(structType, ptr, 1);
	auto expected = elementPtr(intTy(32), intermediate, arrayIdx);
	BOOST_CHECK_EQUAL(result, expected);
}

// Test GEP with empty index list
BOOST_AUTO_TEST_CASE(EmptyIndexList) {
	auto arrayType = arrayTy(4, intTy(32));
	auto ptr = var(ptrTy(), Ref("ptr"));

	auto result = getElementPtr(arrayType, ptr, {});

	// With no indices, should return the original pointer
	BOOST_CHECK_EQUAL(result, ptr);
}

// Test GEP with variable indices
BOOST_AUTO_TEST_CASE(VariableIndices) {
	auto arrayType = arrayTy(4, intTy(32));
	auto ptr = var(ptrTy(), Ref("ptr"));
	auto idx = var(intTy(64), Ref("i")); // Variable index

	auto result = getElementPtr(arrayType, ptr, {idx});

	// Should work the same as with constant indices
	auto expected = elementPtr(intTy(32), ptr, idx);
	BOOST_CHECK_EQUAL(result, expected);
}

// Test GEP with null pointer
BOOST_AUTO_TEST_CASE(NullPointerBase) {
	auto arrayType = arrayTy(4, intTy(32));
	auto idx = intConst(intTy(64), 2);

	auto result = getElementPtr(arrayType, nullPtrConst, {idx});

	// Should work with null pointer base
	auto expected = elementPtr(intTy(32), nullPtrConst, idx);
	BOOST_CHECK_EQUAL(result, expected);
}

BOOST_AUTO_TEST_SUITE_END()
