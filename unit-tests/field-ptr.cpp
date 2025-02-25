#include "all.h"
#include <boost/test/included/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(FieldPtrTests)

// Test accessing first field of a simple struct
BOOST_AUTO_TEST_CASE(SimpleStructFirstField) {
	// Create a struct type with two fields: int32 and double
	vector<Type> fields = {intTy(32), doubleTy()};
	Type structType = structTy(fields);

	// Create a pointer to the struct
	Term ptr = var(ptrTy(), Ref("myStruct"));

	// Get pointer to first field
	Term result = fieldPtr(structType, ptr, 0);

	// Verify the result
	BOOST_CHECK_EQUAL(result.tag(), FieldPtr);
	BOOST_CHECK_EQUAL(result.ty(), ptrTy());
	BOOST_CHECK_EQUAL(result.size(), 3);
	BOOST_CHECK_EQUAL(result[0].ty(), structType);
	BOOST_CHECK_EQUAL(result[1], ptr);
	BOOST_CHECK_EQUAL(result[2].tag(), Int);
	BOOST_CHECK_EQUAL(result[2].intVal(), 0);
}

// Test accessing last field of a struct
BOOST_AUTO_TEST_CASE(SimpleStructLastField) {
	// Create a struct type with three fields
	vector<Type> fields = {intTy(32), floatTy(), doubleTy()};
	Type structType = structTy(fields);

	// Create a pointer to the struct
	Term ptr = var(ptrTy(), Ref("myStruct"));

	// Get pointer to last field
	Term result = fieldPtr(structType, ptr, 2);

	// Verify the result
	BOOST_CHECK_EQUAL(result.tag(), FieldPtr);
	BOOST_CHECK_EQUAL(result[2].intVal(), 2);
}

// Test with nested struct
BOOST_AUTO_TEST_CASE(NestedStruct) {
	// Create inner struct type
	vector<Type> innerFields = {intTy(32), floatTy()};
	Type innerStruct = structTy(innerFields);

	// Create outer struct type containing the inner struct
	vector<Type> outerFields = {doubleTy(), innerStruct};
	Type outerStruct = structTy(outerFields);

	// Create a pointer to the outer struct
	Term ptr = var(ptrTy(), Ref("outerStruct"));

	// Get pointer to the inner struct field
	Term result = fieldPtr(outerStruct, ptr, 1);

	BOOST_CHECK_EQUAL(result.tag(), FieldPtr);
	BOOST_CHECK_EQUAL(result.ty(), ptrTy());
	BOOST_CHECK_EQUAL(result[0].ty(), outerStruct);
	BOOST_CHECK_EQUAL(result[2].intVal(), 1);
}

// Test with null pointer
BOOST_AUTO_TEST_CASE(NullPointer) {
	vector<Type> fields = {intTy(32)};
	Type structType = structTy(fields);

	Term result = fieldPtr(structType, nullConst, 0);

	BOOST_CHECK_EQUAL(result.tag(), FieldPtr);
	BOOST_CHECK_EQUAL(result[1], nullConst);
}

// Test with empty struct
BOOST_AUTO_TEST_CASE(EmptyStruct) {
	vector<Type> fields;
	Type structType = structTy(fields);
	Term ptr = var(ptrTy(), Ref("emptyStruct"));

	// Since we're dealing with an empty struct, any index would be invalid
	// but the function itself should still construct a valid FieldPtr term
	Term result = fieldPtr(structType, ptr, 0);

	BOOST_CHECK_EQUAL(result.tag(), FieldPtr);
	BOOST_CHECK_EQUAL(result.ty(), ptrTy());
}

// Test accessing field in a struct containing array
BOOST_AUTO_TEST_CASE(StructWithArray) {
	// Create a struct with an array field
	Type arrayType = arrayTy(10, intTy(32));
	vector<Type> fields = {floatTy(), arrayType};
	Type structType = structTy(fields);

	Term ptr = var(ptrTy(), Ref("structWithArray"));

	// Get pointer to the array field
	Term result = fieldPtr(structType, ptr, 1);

	BOOST_CHECK_EQUAL(result.tag(), FieldPtr);
	BOOST_CHECK_EQUAL(result.ty(), ptrTy());
	BOOST_CHECK_EQUAL(result[0].ty(), structType);
	BOOST_CHECK_EQUAL(result[2].intVal(), 1);
}

BOOST_AUTO_TEST_SUITE_END()
