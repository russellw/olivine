#include "all.h"

#define BOOST_TEST_MODULE Unit_Test
#include <boost/test/included/unit_test.hpp>

BOOST_AUTO_TEST_CASE(BasicTypeProperties) {
	BOOST_CHECK_EQUAL(voidTy().kind(), VoidKind);
	BOOST_CHECK_EQUAL(voidTy().size(), 0);

	BOOST_CHECK_EQUAL(floatTy().kind(), FloatKind);
	BOOST_CHECK_EQUAL(floatTy().size(), 0);

	BOOST_CHECK_EQUAL(doubleTy().kind(), DoubleKind);
	BOOST_CHECK_EQUAL(doubleTy().size(), 0);

	BOOST_CHECK_EQUAL(boolTy().kind(), IntKind);
	BOOST_CHECK_EQUAL(boolTy().size(), 0);
}

BOOST_AUTO_TEST_CASE(TypeEquality) {
	BOOST_CHECK(voidTy() == voidTy());
	BOOST_CHECK(floatTy() == floatTy());
	BOOST_CHECK(doubleTy() == doubleTy());
	BOOST_CHECK(boolTy() == boolTy());

	BOOST_CHECK(voidTy() != floatTy());
	BOOST_CHECK(floatTy() != doubleTy());
	BOOST_CHECK(doubleTy() != boolTy());
}

BOOST_AUTO_TEST_CASE(IntegerTypeProperties) {
	// Test common integer widths
	Type int8 = intTy(8);
	Type int16 = intTy(16);
	Type int32 = intTy(32);
	Type int64 = intTy(64);

	// Check kind
	BOOST_CHECK_EQUAL(int8.kind(), IntKind);
	BOOST_CHECK_EQUAL(int16.kind(), IntKind);
	BOOST_CHECK_EQUAL(int32.kind(), IntKind);
	BOOST_CHECK_EQUAL(int64.kind(), IntKind);

	// Check bit widths
	BOOST_CHECK_EQUAL(int8.len(), 8);
	BOOST_CHECK_EQUAL(int16.len(), 16);
	BOOST_CHECK_EQUAL(int32.len(), 32);
	BOOST_CHECK_EQUAL(int64.len(), 64);

	// Check sizes (should be 0 for scalar types)
	BOOST_CHECK_EQUAL(int8.size(), 0);
	BOOST_CHECK_EQUAL(int16.size(), 0);
	BOOST_CHECK_EQUAL(int32.size(), 0);
	BOOST_CHECK_EQUAL(int64.size(), 0);

	// Check bool type bits
	BOOST_CHECK_EQUAL(boolTy().len(), 1);
}

BOOST_AUTO_TEST_CASE(IntegerTypeEquality) {
	// Test equality of same-width integers
	Type int32_1 = intTy(32);
	Type int32_2 = intTy(32);
	BOOST_CHECK(int32_1 == int32_2);

	// Test inequality of different-width integers
	Type int16 = intTy(16);
	Type int32 = intTy(32);
	Type int64 = intTy(64);
	BOOST_CHECK(int16 != int32);
	BOOST_CHECK(int32 != int64);
	BOOST_CHECK(int16 != int64);

	// Test inequality with other types
	BOOST_CHECK(int32 != floatTy());
	BOOST_CHECK(int64 != doubleTy());
	BOOST_CHECK(int16 != voidTy());
}

BOOST_AUTO_TEST_CASE(IntegerTypeEdgeCases) {
	// Test unusual bit widths
	Type int1 = intTy(1);
	Type int3 = intTy(3);
	Type int128 = intTy(128);

	// Check properties
	BOOST_CHECK_EQUAL(int1.kind(), IntKind);
	BOOST_CHECK_EQUAL(int3.kind(), IntKind);
	BOOST_CHECK_EQUAL(int128.kind(), IntKind);

	BOOST_CHECK_EQUAL(int1.len(), 1);
	BOOST_CHECK_EQUAL(int3.len(), 3);
	BOOST_CHECK_EQUAL(int128.len(), 128);

	// Verify 1-bit integer is equivalent to bool type
	BOOST_CHECK(int1 == boolTy());

	// Test equality with same unusual widths
	Type int3_2 = intTy(3);
	Type int128_2 = intTy(128);
	BOOST_CHECK(int3 == int3_2);
	BOOST_CHECK(int128 == int128_2);
}

BOOST_AUTO_TEST_CASE(ArrayTypeProperties) {
	// Test array types with different element types and lengths
	Type int32 = intTy(32);
	Type float_arr_10 = arrayTy(10, floatTy());
	Type int_arr_5 = arrayTy(5, int32);
	Type bool_arr_2 = arrayTy(2, boolTy());

	// Check kinds
	BOOST_CHECK_EQUAL(float_arr_10.kind(), ArrayKind);
	BOOST_CHECK_EQUAL(int_arr_5.kind(), ArrayKind);
	BOOST_CHECK_EQUAL(bool_arr_2.kind(), ArrayKind);

	// Check lengths (number of elements)
	BOOST_CHECK_EQUAL(float_arr_10.len(), 10);
	BOOST_CHECK_EQUAL(int_arr_5.len(), 5);
	BOOST_CHECK_EQUAL(bool_arr_2.len(), 2);

	// Check sizes (should be 1 for array types)
	BOOST_CHECK_EQUAL(float_arr_10.size(), 1);
	BOOST_CHECK_EQUAL(int_arr_5.size(), 1);
	BOOST_CHECK_EQUAL(bool_arr_2.size(), 1);

	// Check element types
	BOOST_CHECK(float_arr_10[0] == floatTy());
	BOOST_CHECK(int_arr_5[0] == int32);
	BOOST_CHECK(bool_arr_2[0] == boolTy());
}

BOOST_AUTO_TEST_CASE(ArrayTypeEquality) {
	Type int32 = intTy(32);

	// Test equality of arrays with same element type and length
	Type int_arr_5_1 = arrayTy(5, int32);
	Type int_arr_5_2 = arrayTy(5, int32);
	BOOST_CHECK(int_arr_5_1 == int_arr_5_2);

	// Test inequality with different lengths
	Type int_arr_10 = arrayTy(10, int32);
	BOOST_CHECK(int_arr_5_1 != int_arr_10);

	// Test inequality with different element types
	Type float_arr_5 = arrayTy(5, floatTy());
	BOOST_CHECK(int_arr_5_1 != float_arr_5);

	// Test nested arrays
	Type nested_arr = arrayTy(3, arrayTy(2, int32));
	Type nested_arr_2 = arrayTy(3, arrayTy(2, int32));
	BOOST_CHECK(nested_arr == nested_arr_2);
}

BOOST_AUTO_TEST_CASE(VectorTypeProperties) {
	Type int32 = intTy(32);
	Type float_vec_4 = vecTy(4, floatTy());
	Type int_vec_8 = vecTy(8, int32);

	// Check kinds
	BOOST_CHECK_EQUAL(float_vec_4.kind(), VecKind);
	BOOST_CHECK_EQUAL(int_vec_8.kind(), VecKind);

	// Check lengths
	BOOST_CHECK_EQUAL(float_vec_4.len(), 4);
	BOOST_CHECK_EQUAL(int_vec_8.len(), 8);

	// Check sizes (should be 1 for vector types)
	BOOST_CHECK_EQUAL(float_vec_4.size(), 1);
	BOOST_CHECK_EQUAL(int_vec_8.size(), 1);

	// Check element types
	BOOST_CHECK(float_vec_4[0] == floatTy());
	BOOST_CHECK(int_vec_8[0] == int32);
}

BOOST_AUTO_TEST_CASE(StructTypeProperties) {
	// Test structure with various field types
	vector<Type> fields = {intTy(32), floatTy(), boolTy(), ptrTy()};
	Type struct_type = structTy(fields);

	// Check kind
	BOOST_CHECK_EQUAL(struct_type.kind(), StructKind);

	// Check size (should be number of fields)
	BOOST_CHECK_EQUAL(struct_type.size(), 4);

	// Check field types
	BOOST_CHECK(struct_type[0] == intTy(32));
	BOOST_CHECK(struct_type[1] == floatTy());
	BOOST_CHECK(struct_type[2] == boolTy());
	BOOST_CHECK(struct_type[3] == ptrTy());

	// Test empty struct
	vector<Type> empty_fields;
	Type empty_struct = structTy(empty_fields);
	BOOST_CHECK_EQUAL(empty_struct.kind(), StructKind);
	BOOST_CHECK_EQUAL(empty_struct.size(), 0);
}

BOOST_AUTO_TEST_CASE(StructTypeEquality) {
	vector<Type> fields1 = {intTy(32), floatTy()};
	vector<Type> fields2 = {intTy(32), floatTy()};
	vector<Type> fields3 = {floatTy(), intTy(32)};

	Type struct1 = structTy(fields1);
	Type struct2 = structTy(fields2);
	Type struct3 = structTy(fields3);

	// Test equality of identical structs
	BOOST_CHECK(struct1 == struct2);

	// Test inequality of structs with same types in different order
	BOOST_CHECK(struct1 != struct3);

	// Test nested structs
	vector<Type> nested_fields = {struct1, floatTy()};
	Type nested_struct1 = structTy(nested_fields);
	Type nested_struct2 = structTy(nested_fields);
	BOOST_CHECK(nested_struct1 == nested_struct2);
}

BOOST_AUTO_TEST_CASE(FuncTypeProperties) {
	// Test function type with various parameter types
	vector<Type> params = {
		intTy(32), // return type
		floatTy(), // param 1
		boolTy(),  // param 2
		ptrTy()	   // param 3
	};
	Type func_type = fnTy(params);

	// Check kind
	BOOST_CHECK_EQUAL(func_type.kind(), FuncKind);

	// Check size (should be 1 + number of parameters)
	BOOST_CHECK_EQUAL(func_type.size(), 4);

	// Check return type (component 0)
	BOOST_CHECK(func_type[0] == intTy(32));

	// Check parameter types
	BOOST_CHECK(func_type[1] == floatTy());
	BOOST_CHECK(func_type[2] == boolTy());
	BOOST_CHECK(func_type[3] == ptrTy());

	// Test function with no parameters (just return type)
	vector<Type> void_return = {voidTy()};
	Type void_func = fnTy(void_return);
	BOOST_CHECK_EQUAL(void_func.kind(), FuncKind);
	BOOST_CHECK_EQUAL(void_func.size(), 1);
	BOOST_CHECK(void_func[0] == voidTy());
}

BOOST_AUTO_TEST_CASE(FuncTypeEquality) {
	vector<Type> params1 = {intTy(32), floatTy(), boolTy()};
	vector<Type> params2 = {intTy(32), floatTy(), boolTy()};
	vector<Type> params3 = {intTy(32), boolTy(), floatTy()};

	Type func1 = fnTy(params1);
	Type func2 = fnTy(params2);
	Type func3 = fnTy(params3);

	// Test equality of identical function types
	BOOST_CHECK(func1 == func2);

	// Test inequality of functions with same types in different order
	BOOST_CHECK(func1 != func3);

	// Test functions with different return types
	vector<Type> params4 = {floatTy(), floatTy(), boolTy()};
	Type func4 = fnTy(params4);
	BOOST_CHECK(func1 != func4);
}

BOOST_AUTO_TEST_CASE(ComplexTypeCompositions) {
	Type int32 = intTy(32);

	// Create a struct containing an array of vectors
	Type vec4_float = vecTy(4, floatTy());
	Type arr3_vec = arrayTy(3, vec4_float);
	vector<Type> struct_fields = {int32, arr3_vec};
	Type complex_struct = structTy(struct_fields);

	// Check the structure
	BOOST_CHECK_EQUAL(complex_struct.kind(), StructKind);
	BOOST_CHECK_EQUAL(complex_struct.size(), 2);
	BOOST_CHECK(complex_struct[0] == int32);
	BOOST_CHECK(complex_struct[1] == arr3_vec);

	// Create a function type that uses this struct
	vector<Type> func_params = {voidTy(), complex_struct, ptrTy()};
	Type complex_func = fnTy(func_params);

	BOOST_CHECK_EQUAL(complex_func.kind(), FuncKind);
	BOOST_CHECK_EQUAL(complex_func.size(), 3);
	BOOST_CHECK(complex_func[0] == voidTy());
	BOOST_CHECK(complex_func[1] == complex_struct);
	BOOST_CHECK(complex_func[2] == ptrTy());
}
