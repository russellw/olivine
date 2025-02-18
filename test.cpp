#include "all.h"

#define BOOST_TEST_MODULE Unit_Test
#include <boost/test/included/unit_test.hpp>

Term arithmetic(Tag tag, Term a) {
	return Term(tag, a.type(), a);
}

Term arithmetic(Tag tag, Term a, Term b) {
	return Term(tag, a.type(), a, b);
}

Term cmp(Tag tag, Term a, Term b) {
	return Term(tag, boolType(), vector<Term>{a, b});
}

Type functionType(const vector<Type>& v) {
	ASSERT(v.size());
	return functionType(v[0], tail(v));
}

BOOST_AUTO_TEST_CASE(BasicTypeProperties) {
	BOOST_CHECK_EQUAL(voidType().kind(), VoidKind);
	BOOST_CHECK_EQUAL(voidType().size(), 0);

	BOOST_CHECK_EQUAL(floatType().kind(), FloatKind);
	BOOST_CHECK_EQUAL(floatType().size(), 0);

	BOOST_CHECK_EQUAL(doubleType().kind(), DoubleKind);
	BOOST_CHECK_EQUAL(doubleType().size(), 0);

	BOOST_CHECK_EQUAL(boolType().kind(), IntKind);
	BOOST_CHECK_EQUAL(boolType().size(), 0);
}

BOOST_AUTO_TEST_CASE(TypeEquality) {
	BOOST_CHECK(voidType() == voidType());
	BOOST_CHECK(floatType() == floatType());
	BOOST_CHECK(doubleType() == doubleType());
	BOOST_CHECK(boolType() == boolType());

	BOOST_CHECK(voidType() != floatType());
	BOOST_CHECK(floatType() != doubleType());
	BOOST_CHECK(doubleType() != boolType());
}

BOOST_AUTO_TEST_CASE(IntegerTypeProperties) {
	// Test common integer widths
	Type int8 = intType(8);
	Type int16 = intType(16);
	Type int32 = intType(32);
	Type int64 = intType(64);

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
	BOOST_CHECK_EQUAL(boolType().len(), 1);
}

BOOST_AUTO_TEST_CASE(IntegerTypeEquality) {
	// Test equality of same-width integers
	Type int32_1 = intType(32);
	Type int32_2 = intType(32);
	BOOST_CHECK(int32_1 == int32_2);

	// Test inequality of different-width integers
	Type int16 = intType(16);
	Type int32 = intType(32);
	Type int64 = intType(64);
	BOOST_CHECK(int16 != int32);
	BOOST_CHECK(int32 != int64);
	BOOST_CHECK(int16 != int64);

	// Test inequality with other types
	BOOST_CHECK(int32 != floatType());
	BOOST_CHECK(int64 != doubleType());
	BOOST_CHECK(int16 != voidType());
}

BOOST_AUTO_TEST_CASE(IntegerTypeEdgeCases) {
	// Test unusual bit widths
	Type int1 = intType(1);
	Type int3 = intType(3);
	Type int128 = intType(128);

	// Check properties
	BOOST_CHECK_EQUAL(int1.kind(), IntKind);
	BOOST_CHECK_EQUAL(int3.kind(), IntKind);
	BOOST_CHECK_EQUAL(int128.kind(), IntKind);

	BOOST_CHECK_EQUAL(int1.len(), 1);
	BOOST_CHECK_EQUAL(int3.len(), 3);
	BOOST_CHECK_EQUAL(int128.len(), 128);

	// Verify 1-bit integer is equivalent to bool type
	BOOST_CHECK(int1 == boolType());

	// Test equality with same unusual widths
	Type int3_2 = intType(3);
	Type int128_2 = intType(128);
	BOOST_CHECK(int3 == int3_2);
	BOOST_CHECK(int128 == int128_2);
}

BOOST_AUTO_TEST_CASE(ArrayTypeProperties) {
	// Test array types with different element types and lengths
	Type int32 = intType(32);
	Type float_arr_10 = arrayType(10, floatType());
	Type int_arr_5 = arrayType(5, int32);
	Type bool_arr_2 = arrayType(2, boolType());

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
	BOOST_CHECK(float_arr_10[0] == floatType());
	BOOST_CHECK(int_arr_5[0] == int32);
	BOOST_CHECK(bool_arr_2[0] == boolType());
}

BOOST_AUTO_TEST_CASE(ArrayTypeEquality) {
	Type int32 = intType(32);

	// Test equality of arrays with same element type and length
	Type int_arr_5_1 = arrayType(5, int32);
	Type int_arr_5_2 = arrayType(5, int32);
	BOOST_CHECK(int_arr_5_1 == int_arr_5_2);

	// Test inequality with different lengths
	Type int_arr_10 = arrayType(10, int32);
	BOOST_CHECK(int_arr_5_1 != int_arr_10);

	// Test inequality with different element types
	Type float_arr_5 = arrayType(5, floatType());
	BOOST_CHECK(int_arr_5_1 != float_arr_5);

	// Test nested arrays
	Type nested_arr = arrayType(3, arrayType(2, int32));
	Type nested_arr_2 = arrayType(3, arrayType(2, int32));
	BOOST_CHECK(nested_arr == nested_arr_2);
}

BOOST_AUTO_TEST_CASE(VectorTypeProperties) {
	Type int32 = intType(32);
	Type float_vec_4 = vecType(4, floatType());
	Type int_vec_8 = vecType(8, int32);

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
	BOOST_CHECK(float_vec_4[0] == floatType());
	BOOST_CHECK(int_vec_8[0] == int32);
}

BOOST_AUTO_TEST_CASE(StructTypeProperties) {
	// Test structure with various field types
	vector<Type> fields = {intType(32), floatType(), boolType(), ptrType()};
	Type struct_type = structType(fields);

	// Check kind
	BOOST_CHECK_EQUAL(struct_type.kind(), StructKind);

	// Check size (should be number of fields)
	BOOST_CHECK_EQUAL(struct_type.size(), 4);

	// Check field types
	BOOST_CHECK(struct_type[0] == intType(32));
	BOOST_CHECK(struct_type[1] == floatType());
	BOOST_CHECK(struct_type[2] == boolType());
	BOOST_CHECK(struct_type[3] == ptrType());

	// Test empty struct
	vector<Type> empty_fields;
	Type empty_struct = structType(empty_fields);
	BOOST_CHECK_EQUAL(empty_struct.kind(), StructKind);
	BOOST_CHECK_EQUAL(empty_struct.size(), 0);
}

BOOST_AUTO_TEST_CASE(StructTypeEquality) {
	vector<Type> fields1 = {intType(32), floatType()};
	vector<Type> fields2 = {intType(32), floatType()};
	vector<Type> fields3 = {floatType(), intType(32)};

	Type struct1 = structType(fields1);
	Type struct2 = structType(fields2);
	Type struct3 = structType(fields3);

	// Test equality of identical structs
	BOOST_CHECK(struct1 == struct2);

	// Test inequality of structs with same types in different order
	BOOST_CHECK(struct1 != struct3);

	// Test nested structs
	vector<Type> nested_fields = {struct1, floatType()};
	Type nested_struct1 = structType(nested_fields);
	Type nested_struct2 = structType(nested_fields);
	BOOST_CHECK(nested_struct1 == nested_struct2);
}

BOOST_AUTO_TEST_CASE(FunctionTypeProperties) {
	// Test function type with various parameter types
	vector<Type> params = {
		intType(32), // return type
		floatType(), // param 1
		boolType(),	 // param 2
		ptrType()	 // param 3
	};
	Type func_type = functionType(params);

	// Check kind
	BOOST_CHECK_EQUAL(func_type.kind(), FuncKind);

	// Check size (should be 1 + number of parameters)
	BOOST_CHECK_EQUAL(func_type.size(), 4);

	// Check return type (component 0)
	BOOST_CHECK(func_type[0] == intType(32));

	// Check parameter types
	BOOST_CHECK(func_type[1] == floatType());
	BOOST_CHECK(func_type[2] == boolType());
	BOOST_CHECK(func_type[3] == ptrType());

	// Test function with no parameters (just return type)
	vector<Type> void_return = {voidType()};
	Type void_func = functionType(void_return);
	BOOST_CHECK_EQUAL(void_func.kind(), FuncKind);
	BOOST_CHECK_EQUAL(void_func.size(), 1);
	BOOST_CHECK(void_func[0] == voidType());
}

BOOST_AUTO_TEST_CASE(FunctionTypeEquality) {
	vector<Type> params1 = {intType(32), floatType(), boolType()};
	vector<Type> params2 = {intType(32), floatType(), boolType()};
	vector<Type> params3 = {intType(32), boolType(), floatType()};

	Type func1 = functionType(params1);
	Type func2 = functionType(params2);
	Type func3 = functionType(params3);

	// Test equality of identical function types
	BOOST_CHECK(func1 == func2);

	// Test inequality of functions with same types in different order
	BOOST_CHECK(func1 != func3);

	// Test functions with different return types
	vector<Type> params4 = {floatType(), floatType(), boolType()};
	Type func4 = functionType(params4);
	BOOST_CHECK(func1 != func4);
}

BOOST_AUTO_TEST_CASE(ComplexTypeCompositions) {
	Type int32 = intType(32);

	// Create a struct containing an array of vectors
	Type vec4_float = vecType(4, floatType());
	Type arr3_vec = arrayType(3, vec4_float);
	vector<Type> struct_fields = {int32, arr3_vec};
	Type complex_struct = structType(struct_fields);

	// Check the structure
	BOOST_CHECK_EQUAL(complex_struct.kind(), StructKind);
	BOOST_CHECK_EQUAL(complex_struct.size(), 2);
	BOOST_CHECK(complex_struct[0] == int32);
	BOOST_CHECK(complex_struct[1] == arr3_vec);

	// Create a function type that uses this struct
	vector<Type> func_params = {voidType(), complex_struct, ptrType()};
	Type complex_func = functionType(func_params);

	BOOST_CHECK_EQUAL(complex_func.kind(), FuncKind);
	BOOST_CHECK_EQUAL(complex_func.size(), 3);
	BOOST_CHECK(complex_func[0] == voidType());
	BOOST_CHECK(complex_func[1] == complex_struct);
	BOOST_CHECK(complex_func[2] == ptrType());
}

// Test construction and basic properties of constants
BOOST_AUTO_TEST_CASE(ConstantTerms) {
	// Test boolean constants
	BOOST_CHECK_EQUAL(trueConst.type(), boolType());
	BOOST_CHECK_EQUAL(trueConst.tag(), Int);
	BOOST_CHECK_EQUAL(trueConst.intVal(), 1);

	BOOST_CHECK_EQUAL(falseConst.type(), boolType());
	BOOST_CHECK_EQUAL(falseConst.tag(), Int);
	BOOST_CHECK_EQUAL(falseConst.intVal(), 0);

	// Test null constant
	BOOST_CHECK_EQUAL(nullConst.type(), ptrType());
	BOOST_CHECK_EQUAL(nullConst.tag(), Null);

	// Test integer constant creation
	Type int32Type = intType(32);
	cpp_int val(42);
	Term intTerm = intConst(int32Type, val);
	BOOST_CHECK_EQUAL(intTerm.type(), int32Type);
	BOOST_CHECK_EQUAL(intTerm.tag(), Int);
	BOOST_CHECK_EQUAL(intTerm.intVal(), val);

	// Test float constant creation
	Term floatTerm = floatConst(floatType(), "3.14");
	BOOST_CHECK_EQUAL(floatTerm.type(), floatType());
	BOOST_CHECK_EQUAL(floatTerm.tag(), Float);
	BOOST_CHECK_EQUAL(floatTerm.str(), "3.14");
}

// Test variable creation and properties
BOOST_AUTO_TEST_CASE(Variables) {
	Type int64Type = intType(64);
	Term var1 = var(int64Type, 1);
	Term var2 = var(int64Type, 2);

	BOOST_CHECK_EQUAL(var1.type(), int64Type);
	BOOST_CHECK_EQUAL(var1.tag(), Var);
	BOOST_CHECK(var1 != var2);
}

Term compound(Tag tag, const vector<Term>& v) {
	ASSERT(v.size());
	auto type = v[0].type();
	return Term(tag, type, v);
}

// Test arithmetic operations
BOOST_AUTO_TEST_CASE(ArithmeticOperations) {
	Type int32Type = intType(32);
	Term a = var(int32Type, 1);
	Term b = var(int32Type, 2);

	// Test addition
	vector<Term> addOps = {a, b};
	Term add = compound(Add, addOps);
	BOOST_CHECK_EQUAL(add.type(), int32Type);
	BOOST_CHECK_EQUAL(add.tag(), Add);
	BOOST_CHECK_EQUAL(add.size(), 2);
	BOOST_CHECK_EQUAL(add[0], a);
	BOOST_CHECK_EQUAL(add[1], b);

	// Test multiplication
	vector<Term> mulOps = {a, b};
	Term mul = compound(Mul, mulOps);
	BOOST_CHECK_EQUAL(mul.type(), int32Type);
	BOOST_CHECK_EQUAL(mul.tag(), Mul);
	BOOST_CHECK_EQUAL(mul.size(), 2);

	// Test floating point operations
	Term f1 = var(floatType(), 3);
	Term f2 = var(floatType(), 4);
	vector<Term> faddOps = {f1, f2};
	Term fadd = compound(FAdd, faddOps);
	BOOST_CHECK_EQUAL(fadd.type(), floatType());
	BOOST_CHECK_EQUAL(fadd.tag(), FAdd);

	// Test unary operations
	vector<Term> fnegOps = {f1};
	Term fneg = compound(FNeg, fnegOps);
	BOOST_CHECK_EQUAL(fneg.type(), floatType());
	BOOST_CHECK_EQUAL(fneg.tag(), FNeg);
	BOOST_CHECK_EQUAL(fneg.size(), 1);
}

// Test equality comparison
BOOST_AUTO_TEST_CASE(TermEquality) {
	Type int32Type = intType(32);
	cpp_int val(42);

	Term int1 = intConst(int32Type, val);
	Term int2 = intConst(int32Type, val);
	Term int3 = intConst(int32Type, val + 1);

	BOOST_CHECK(int1 == int2);
	BOOST_CHECK(int1 != int3);

	Term var1 = var(int32Type, 1);
	Term var2 = var(int32Type, 1);
	Term var3 = var(int32Type, 2);

	BOOST_CHECK(var1 == var2);
	BOOST_CHECK(var1 != var3);
}

// Helper function to convert Type to string
std::string typeToString(Type type) {
	std::ostringstream oss;
	oss << type;
	return oss.str();
}

BOOST_AUTO_TEST_CASE(BasicTypeOutput) {
	// Test void type
	BOOST_CHECK_EQUAL(typeToString(voidType()), "void");

	// Test float and double
	BOOST_CHECK_EQUAL(typeToString(floatType()), "float");
	BOOST_CHECK_EQUAL(typeToString(doubleType()), "double");

	// Test bool (1-bit integer)
	BOOST_CHECK_EQUAL(typeToString(boolType()), "i1");

	// Test pointer
	BOOST_CHECK_EQUAL(typeToString(ptrType()), "ptr");
}

BOOST_AUTO_TEST_CASE(IntegerTypeOutput) {
	// Test common integer sizes
	BOOST_CHECK_EQUAL(typeToString(intType(8)), "i8");
	BOOST_CHECK_EQUAL(typeToString(intType(16)), "i16");
	BOOST_CHECK_EQUAL(typeToString(intType(32)), "i32");
	BOOST_CHECK_EQUAL(typeToString(intType(64)), "i64");

	// Test unusual sizes
	BOOST_CHECK_EQUAL(typeToString(intType(7)), "i7");
	BOOST_CHECK_EQUAL(typeToString(intType(128)), "i128");
}

BOOST_AUTO_TEST_CASE(ArrayTypeOutput) {
	// Test arrays of basic types
	BOOST_CHECK_EQUAL(typeToString(arrayType(4, intType(32))), "[4 x i32]");
	BOOST_CHECK_EQUAL(typeToString(arrayType(2, floatType())), "[2 x float]");

	// Test nested arrays
	Type nestedArray = arrayType(3, arrayType(2, intType(8)));
	BOOST_CHECK_EQUAL(typeToString(nestedArray), "[3 x [2 x i8]]");
}

BOOST_AUTO_TEST_CASE(VectorTypeOutput) {
	// Test vectors of basic types
	BOOST_CHECK_EQUAL(typeToString(vecType(4, intType(32))), "<4 x i32>");
	BOOST_CHECK_EQUAL(typeToString(vecType(2, floatType())), "<2 x float>");

	// Test unusual vector sizes
	BOOST_CHECK_EQUAL(typeToString(vecType(3, intType(1))), "<3 x i1>");
}

BOOST_AUTO_TEST_CASE(StructTypeOutput) {
	std::vector<Type> fields;

	// Test empty struct
	BOOST_CHECK_EQUAL(typeToString(structType(fields)), "{}");

	// Test simple struct
	fields.push_back(intType(32));
	fields.push_back(floatType());
	BOOST_CHECK_EQUAL(typeToString(structType(fields)), "{i32, float}");

	// Test nested struct
	std::vector<Type> innerFields;
	innerFields.push_back(intType(8));
	innerFields.push_back(doubleType());
	fields.push_back(structType(innerFields));
	BOOST_CHECK_EQUAL(typeToString(structType(fields)), "{i32, float, {i8, double}}");
}

BOOST_AUTO_TEST_CASE(FunctionTypeOutput) {
	std::vector<Type> params;

	// Test function with no parameters
	params.push_back(voidType()); // return type
	BOOST_CHECK_EQUAL(typeToString(functionType(params)), "void ()");

	// Test function with basic parameters
	params.push_back(intType(32));
	params.push_back(floatType());
	BOOST_CHECK_EQUAL(typeToString(functionType(params)), "void (i32, float)");

	// Test function returning non-void
	params[0] = ptrType();
	BOOST_CHECK_EQUAL(typeToString(functionType(params)), "ptr (i32, float)");

	// Test function with complex parameter types
	params.push_back(arrayType(4, intType(8)));
	BOOST_CHECK_EQUAL(typeToString(functionType(params)), "ptr (i32, float, [4 x i8])");
}

BOOST_AUTO_TEST_CASE(ComplexTypeOutput) {
	// Test combination of various type constructs
	std::vector<Type> fields;
	fields.push_back(arrayType(2, vecType(4, intType(32))));
	fields.push_back(ptrType());

	std::vector<Type> funcParams;
	funcParams.push_back(structType(fields)); // return type
	funcParams.push_back(doubleType());
	funcParams.push_back(arrayType(3, floatType()));

	Type complexType = functionType(funcParams);

	BOOST_CHECK_EQUAL(typeToString(complexType), "{[2 x <4 x i32>], ptr} (double, [3 x float])");
}

BOOST_AUTO_TEST_CASE(BasicTypeMapping) {
	std::unordered_map<Type, int> typeMap;

	// Test primitive types
	typeMap[voidType()] = 1;
	typeMap[intType(32)] = 2;
	typeMap[boolType()] = 3;

	BOOST_CHECK_EQUAL(typeMap[voidType()], 1);
	BOOST_CHECK_EQUAL(typeMap[intType(32)], 2);
	BOOST_CHECK_EQUAL(typeMap[boolType()], 3);
}

BOOST_AUTO_TEST_CASE(CompoundTypeMapping) {
	std::unordered_map<Type, std::string> typeMap;

	// Create some compound types
	Type arrayOfInt = arrayType(10, intType(32));
	Type vectorOfFloat = vecType(4, floatType());

	typeMap[arrayOfInt] = "array of int";
	typeMap[vectorOfFloat] = "vector of float";

	BOOST_CHECK_EQUAL(typeMap[arrayOfInt], "array of int");
	BOOST_CHECK_EQUAL(typeMap[vectorOfFloat], "vector of float");

	// Test that identical types map to the same value
	Type sameArrayType = arrayType(10, intType(32));
	BOOST_CHECK_EQUAL(typeMap[sameArrayType], "array of int");
}

BOOST_AUTO_TEST_CASE(StructureTypeMapping) {
	std::unordered_map<Type, int> typeMap;

	std::vector<Type> fields1 = {intType(32), floatType()};
	std::vector<Type> fields2 = {intType(32), floatType()}; // Same structure
	std::vector<Type> fields3 = {floatType(), intType(32)}; // Different order

	Type struct1 = structType(fields1);
	Type struct2 = structType(fields2);
	Type struct3 = structType(fields3);

	typeMap[struct1] = 1;

	// Test structural equality
	BOOST_CHECK_EQUAL(typeMap[struct2], 1);

	// Different structure should get different slot
	typeMap[struct3] = 2;
	BOOST_CHECK_EQUAL(typeMap[struct3], 2);
}

BOOST_AUTO_TEST_CASE(FunctionTypeMapping) {
	std::unordered_map<Type, std::string> typeMap;

	// Function type: int32 (float, bool)
	std::vector<Type> params1 = {intType(32), floatType(), boolType()};
	Type func1 = functionType(params1);

	// Same function type
	std::vector<Type> params2 = {intType(32), floatType(), boolType()};
	Type func2 = functionType(params2);

	typeMap[func1] = "int32 (float, bool)";

	// Test that identical function types map to the same value
	BOOST_CHECK_EQUAL(typeMap[func2], "int32 (float, bool)");
}

BOOST_AUTO_TEST_CASE(TypeMapOverwrite) {
	std::unordered_map<Type, int> typeMap;

	Type int32Type = intType(32);
	typeMap[int32Type] = 1;
	BOOST_CHECK_EQUAL(typeMap[int32Type], 1);

	// Overwrite existing value
	typeMap[int32Type] = 2;
	BOOST_CHECK_EQUAL(typeMap[int32Type], 2);
}

BOOST_AUTO_TEST_CASE(TypeMapErase) {
	std::unordered_map<Type, int> typeMap;

	Type int32Type = intType(32);
	typeMap[int32Type] = 1;

	// Test erase
	size_t eraseCount = typeMap.erase(int32Type);
	BOOST_CHECK_EQUAL(eraseCount, 1);
	BOOST_CHECK_EQUAL(typeMap.count(int32Type), 0);
}

BOOST_AUTO_TEST_CASE(BasicTermMapping) {
	std::unordered_map<Term, int> termMap;

	// Test constant terms
	termMap[trueConst] = 1;
	termMap[falseConst] = 2;
	termMap[nullConst] = 3;

	BOOST_CHECK_EQUAL(termMap[trueConst], 1);
	BOOST_CHECK_EQUAL(termMap[falseConst], 2);
	BOOST_CHECK_EQUAL(termMap[nullConst], 3);
}

BOOST_AUTO_TEST_CASE(IntegerTermMapping) {
	std::unordered_map<Term, std::string> termMap;

	// Create some integer constants
	Term int32_5 = intConst(intType(32), 5);
	Term int32_10 = intConst(intType(32), 10);
	Term int64_5 = intConst(intType(64), 5); // Same value, different type

	termMap[int32_5] = "32-bit 5";
	termMap[int32_10] = "32-bit 10";
	termMap[int64_5] = "64-bit 5";

	BOOST_CHECK_EQUAL(termMap[int32_5], "32-bit 5");
	BOOST_CHECK_EQUAL(termMap[int32_10], "32-bit 10");
	BOOST_CHECK_EQUAL(termMap[int64_5], "64-bit 5");
}

BOOST_AUTO_TEST_CASE(FloatTermMapping) {
	std::unordered_map<Term, int> termMap;

	Term float1 = floatConst(floatType(), "1.0");
	Term float2 = floatConst(floatType(), "2.0");
	Term double1 = floatConst(doubleType(), "1.0"); // Same value, different type

	termMap[float1] = 1;
	termMap[float2] = 2;
	termMap[double1] = 3;

	BOOST_CHECK_EQUAL(termMap[float1], 1);
	BOOST_CHECK_EQUAL(termMap[float2], 2);
	BOOST_CHECK_EQUAL(termMap[double1], 3);
}

BOOST_AUTO_TEST_CASE(VariableTermMapping) {
	std::unordered_map<Term, std::string> termMap;

	// Create some variables
	Term var1 = var(intType(32), 1);
	Term var2 = var(intType(32), 2);
	Term var1_float = var(floatType(), 1); // Same index, different type

	termMap[var1] = "int var 1";
	termMap[var2] = "int var 2";
	termMap[var1_float] = "float var 1";

	BOOST_CHECK_EQUAL(termMap[var1], "int var 1");
	BOOST_CHECK_EQUAL(termMap[var2], "int var 2");
	BOOST_CHECK_EQUAL(termMap[var1_float], "float var 1");
}

BOOST_AUTO_TEST_CASE(CompoundTermMapping) {
	std::unordered_map<Term, std::string> termMap;

	// Create some arithmetic terms
	Term a = var(intType(32), 1);
	Term b = var(intType(32), 2);

	Term add = arithmetic(Add, a, b);
	Term mul = arithmetic(Mul, a, b);
	Term add_same = arithmetic(Add, a, b); // Same as first add

	termMap[add] = "a + b";
	termMap[mul] = "a * b";

	BOOST_CHECK_EQUAL(termMap[add], "a + b");
	BOOST_CHECK_EQUAL(termMap[mul], "a * b");
	BOOST_CHECK_EQUAL(termMap[add_same], "a + b"); // Should map to same value
}

BOOST_AUTO_TEST_CASE(ComparisonTermMapping) {
	std::unordered_map<Term, std::string> termMap;

	Term a = var(intType(32), 1);
	Term b = var(intType(32), 2);

	Term eq = cmp(Eq, a, b);
	Term lt = cmp(SLt, a, b);
	Term eq_same = cmp(Eq, a, b); // Same as first eq

	termMap[eq] = "a == b";
	termMap[lt] = "a < b";

	BOOST_CHECK_EQUAL(termMap[eq], "a == b");
	BOOST_CHECK_EQUAL(termMap[lt], "a < b");
	BOOST_CHECK_EQUAL(termMap[eq_same], "a == b");
}

BOOST_AUTO_TEST_CASE(TermMapOperations) {
	std::unordered_map<Term, int> termMap;

	Term var1 = var(intType(32), 1);

	// Test insert and lookup
	termMap[var1] = 1;
	BOOST_CHECK_EQUAL(termMap[var1], 1);

	// Test overwrite
	termMap[var1] = 2;
	BOOST_CHECK_EQUAL(termMap[var1], 2);

	// Test erase
	size_t eraseCount = termMap.erase(var1);
	BOOST_CHECK_EQUAL(eraseCount, 1);
	BOOST_CHECK_EQUAL(termMap.count(var1), 0);
}

// Helper function to create test environment
unordered_map<Term, Term> makeEnv(const vector<pair<Term, Term>>& bindings) {
	unordered_map<Term, Term> env;
	for (const auto& p : bindings) {
		env[p.first] = p.second;
	}
	return env;
}

BOOST_AUTO_TEST_CASE(constants_and_variables) {
	// Constants should remain unchanged
	Term nullTerm = nullConst;
	Term intTerm = intConst(intType(32), 42);
	Term floatTerm = floatConst(floatType(), "3.14");

	unordered_map<Term, Term> emptyEnv;
	BOOST_CHECK_EQUAL(simplify(emptyEnv, nullTerm), nullTerm);
	BOOST_CHECK_EQUAL(simplify(emptyEnv, intTerm), intTerm);
	BOOST_CHECK_EQUAL(simplify(emptyEnv, floatTerm), floatTerm);

	// Variables should be looked up in environment
	Term var1 = var(intType(32), 1);
	Term val1 = intConst(intType(32), 123);
	auto env = makeEnv({{var1, val1}});

	BOOST_CHECK_EQUAL(simplify(env, var1), val1);
	BOOST_CHECK_EQUAL(simplify(emptyEnv, var1), var1); // Not in environment
}

BOOST_AUTO_TEST_CASE(basic_arithmetic) {
	unordered_map<Term, Term> emptyEnv;
	Type i32 = intType(32);

	// Addition
	Term a = intConst(i32, 5);
	Term b = intConst(i32, 3);
	Term sum = compound(Add, {a, b});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, sum).intVal(), 8);

	// x + 0 = x
	Term zero = intConst(i32, 0);
	Term addZero = compound(Add, {a, zero});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, addZero), a);

	// Subtraction
	Term diff = compound(Sub, {a, b});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, diff).intVal(), 2);

	// x - x = 0
	Term subSelf = compound(Sub, {a, a});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, subSelf).intVal(), 0);

	// Multiplication
	Term prod = compound(Mul, {a, b});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, prod).intVal(), 15);

	// x * 1 = x
	Term one = intConst(i32, 1);
	Term mulOne = compound(Mul, {a, one});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, mulOne), a);

	// x * 0 = 0
	Term mulZero = compound(Mul, {a, zero});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, mulZero).intVal(), 0);
}

BOOST_AUTO_TEST_CASE(division_and_remainder) {
	unordered_map<Term, Term> emptyEnv;
	Type i32 = intType(32);

	Term a = intConst(i32, 15);
	Term b = intConst(i32, 4);
	Term zero = intConst(i32, 0);

	// Unsigned division
	Term udiv = compound(UDiv, {a, b});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, udiv).intVal(), 3);

	// Division by zero should not be simplified
	Term divZero = compound(UDiv, {a, zero});
	BOOST_CHECK(simplify(emptyEnv, divZero).tag() == UDiv);

	// Signed division
	Term sdiv = compound(SDiv, {a, b});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, sdiv).intVal(), 3);

	// Remainder
	Term urem = compound(URem, {a, b});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, urem).intVal(), 3);
}

BOOST_AUTO_TEST_CASE(bitwise_operations) {
	unordered_map<Term, Term> emptyEnv;
	Type i32 = intType(32);

	Term a = intConst(i32, 0b1100);
	Term b = intConst(i32, 0b1010);
	Term zero = intConst(i32, 0);

	// AND
	Term andOp = compound(And, {a, b});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, andOp).intVal(), 0b1000);

	// x & 0 = 0
	Term andZero = compound(And, {a, zero});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, andZero).intVal(), 0);

	// OR
	Term orOp = compound(Or, {a, b});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, orOp).intVal(), 0b1110);

	// x | 0 = x
	Term orZero = compound(Or, {a, zero});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, orZero), a);

	// XOR
	Term xorOp = compound(Xor, {a, b});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, xorOp).intVal(), 0b0110);

	// x ^ x = 0
	Term xorSelf = compound(Xor, {a, a});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, xorSelf).intVal(), 0);
}

BOOST_AUTO_TEST_CASE(shift_operations) {
	unordered_map<Term, Term> emptyEnv;
	Type i32 = intType(32);

	Term a = intConst(i32, 0b1100);
	Term shift2 = intConst(i32, 2);
	Term shiftTooLarge = intConst(i32, 33); // Larger than type size

	// Logical left shift
	Term shl = compound(Shl, {a, shift2});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, shl).intVal(), 0b110000);

	// Invalid shift amount should not be simplified
	Term shlInvalid = compound(Shl, {a, shiftTooLarge});
	BOOST_CHECK(simplify(emptyEnv, shlInvalid).tag() == Shl);

	// Logical right shift
	Term lshr = compound(LShr, {a, shift2});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, lshr).intVal(), 0b11);

	// Arithmetic right shift (with sign bit)
	Term negative = intConst(i32, -16); // 0xFFFFFFF0 in two's complement
	Term ashr = compound(AShr, {negative, shift2});
	Term result = simplify(emptyEnv, ashr);
	BOOST_CHECK(result.intVal() < 0); // Should preserve sign
	BOOST_CHECK_EQUAL(result.intVal(), -4);
}

BOOST_AUTO_TEST_CASE(comparison_operations) {
	unordered_map<Term, Term> emptyEnv;
	Type i32 = intType(32);

	Term a = intConst(i32, 5);
	Term b = intConst(i32, 3);
	Term equalA = intConst(i32, 5);

	// Equal
	Term eq1 = cmp(Eq, a, b);
	BOOST_CHECK_EQUAL(simplify(emptyEnv, eq1), falseConst);

	Term eq2 = cmp(Eq, a, equalA);
	BOOST_CHECK_EQUAL(simplify(emptyEnv, eq2), trueConst);

	// Unsigned comparison
	Term ult = cmp(ULt, a, b);
	BOOST_CHECK_EQUAL(simplify(emptyEnv, ult), falseConst);

	// Signed comparison
	Term slt = cmp(SLt, a, b);
	BOOST_CHECK_EQUAL(simplify(emptyEnv, slt), falseConst);
}

BOOST_AUTO_TEST_CASE(floating_point_operations) {
	unordered_map<Term, Term> emptyEnv;

	// Floating point operations should not be simplified
	Term a = floatConst(floatType(), "3.14");
	Term b = floatConst(floatType(), "2.0");

	Term fadd = compound(FAdd, {a, b});
	BOOST_CHECK(simplify(emptyEnv, fadd).tag() == FAdd);

	Term fmul = compound(FMul, {a, b});
	BOOST_CHECK(simplify(emptyEnv, fmul).tag() == FMul);

	Term fneg = compound(FNeg, {a});
	BOOST_CHECK(simplify(emptyEnv, fneg).tag() == FNeg);
}

BOOST_AUTO_TEST_CASE(complex_expressions) {
	unordered_map<Term, Term> emptyEnv;
	Type i32 = intType(32);

	// Test nested expressions: (5 + 3) * (10 - 4)
	Term a = intConst(i32, 5);
	Term b = intConst(i32, 3);
	Term c = intConst(i32, 10);
	Term d = intConst(i32, 4);

	Term sum = compound(Add, {a, b});		   // 5 + 3
	Term diff = compound(Sub, {c, d});		   // 10 - 4
	Term product = compound(Mul, {sum, diff}); // (5 + 3) * (10 - 4)

	BOOST_CHECK_EQUAL(simplify(emptyEnv, product).intVal(), 48); // (8 * 6)
}

// New test case specifically for same-component simplifications
BOOST_AUTO_TEST_CASE(same_component_simplifications) {
	unordered_map<Term, Term> emptyEnv;
	Type i32 = intType(32);

	// Create some variables
	Term x = var(i32, 1);
	Term y = var(i32, 2);

	// x - x = 0
	Term subSelf = compound(Sub, {x, x});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, subSelf).intVal(), 0);

	// y - y = 0 (using different variable)
	Term subSelfY = compound(Sub, {y, y});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, subSelfY).intVal(), 0);

	// x ^ x = 0
	Term xorSelf = compound(Xor, {x, x});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, xorSelf).intVal(), 0);

	// x & x = x
	Term andSelf = compound(And, {x, x});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, andSelf), x);

	// x | x = x
	Term orSelf = compound(Or, {x, x});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, orSelf), x);

	// Nested cases to ensure simplification happens even when subexpressions don't change
	// (x & y) - (x & y) = 0
	Term complex1 = compound(And, {x, y});
	Term subComplex = compound(Sub, {complex1, complex1});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, subComplex).intVal(), 0);

	// (x | y) ^ (x | y) = 0
	Term complex2 = compound(Or, {x, y});
	Term xorComplex = compound(Xor, {complex2, complex2});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, xorComplex).intVal(), 0);

	// Test with constants to ensure the same-component rules take precedence
	// even when components are constants
	Term c = intConst(i32, 42);
	Term subConst = compound(Sub, {c, c});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, subConst).intVal(), 0);

	// Multiple levels of nesting
	// ((x & y) | (x & y)) = (x & y)
	Term nested1 = compound(And, {x, y});
	Term orNested = compound(Or, {nested1, nested1});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, orNested), nested1);

	// More complex expressions that should still simplify
	// (x & x & x) = x
	Term multiAnd = compound(And, {compound(And, {x, x}), x});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, multiAnd), x);

	// (x | (x | x)) = x
	Term multiOr = compound(Or, {x, compound(Or, {x, x})});
	BOOST_CHECK_EQUAL(simplify(emptyEnv, multiOr), x);
}

BOOST_AUTO_TEST_CASE(test_fneg_float_constant) {
	// Create a float constant to negate
	Term f = floatConst(floatType(), "1.0");
	Term neg = arithmetic(FNeg, f);

	// Verify properties
	BOOST_CHECK_EQUAL(neg.tag(), FNeg);
	BOOST_CHECK_EQUAL(neg.type(), floatType());
	BOOST_CHECK_EQUAL(neg.size(), 1);
	BOOST_CHECK_EQUAL(neg[0], f);
}

BOOST_AUTO_TEST_CASE(test_fneg_double_constant) {
	// Create a double constant to negate
	Term d = floatConst(doubleType(), "2.5");
	Term neg = arithmetic(FNeg, d);

	// Verify properties
	BOOST_CHECK_EQUAL(neg.tag(), FNeg);
	BOOST_CHECK_EQUAL(neg.type(), doubleType());
	BOOST_CHECK_EQUAL(neg.size(), 1);
	BOOST_CHECK_EQUAL(neg[0], d);
}

BOOST_AUTO_TEST_CASE(test_fneg_variable) {
	// Create a float variable to negate
	Term var1 = var(floatType(), 1);
	Term neg = arithmetic(FNeg, var1);

	// Verify properties
	BOOST_CHECK_EQUAL(neg.tag(), FNeg);
	BOOST_CHECK_EQUAL(neg.type(), floatType());
	BOOST_CHECK_EQUAL(neg.size(), 1);
	BOOST_CHECK_EQUAL(neg[0], var1);
}

BOOST_AUTO_TEST_CASE(test_double_negation) {
	// Verify that negating twice preserves type and structure
	Term f = floatConst(floatType(), "3.14");
	Term neg1 = arithmetic(FNeg, f);
	Term neg2 = arithmetic(FNeg, neg1);

	BOOST_CHECK_EQUAL(neg2.tag(), FNeg);
	BOOST_CHECK_EQUAL(neg2.type(), floatType());
	BOOST_CHECK_EQUAL(neg2.size(), 1);
	BOOST_CHECK_EQUAL(neg2[0], neg1);
}

BOOST_AUTO_TEST_CASE(test_fneg_equality) {
	// Create two identical FNeg expressions
	Term f = floatConst(floatType(), "1.0");
	Term neg1 = arithmetic(FNeg, f);
	Term neg2 = arithmetic(FNeg, f);

	// They should be equal due to value semantics
	BOOST_CHECK_EQUAL(neg1, neg2);
}

BOOST_AUTO_TEST_CASE(test_fneg_hash_consistency) {
	// Create two identical FNeg expressions
	Term f = floatConst(floatType(), "1.0");
	Term neg1 = arithmetic(FNeg, f);
	Term neg2 = arithmetic(FNeg, f);

	// Their hashes should be equal
	std::hash<Term> hasher;
	BOOST_CHECK_EQUAL(hasher(neg1), hasher(neg2));
}

BOOST_AUTO_TEST_CASE(test_fneg_type_preservation) {
	// Test with both float and double
	Term f = floatConst(floatType(), "1.0");
	Term d = floatConst(doubleType(), "1.0");

	Term negF = arithmetic(FNeg, f);
	Term negD = arithmetic(FNeg, d);

	BOOST_CHECK_EQUAL(negF.type(), f.type());
	BOOST_CHECK_EQUAL(negD.type(), d.type());
}

// Test assigning to an integer variable
BOOST_AUTO_TEST_CASE(IntegerAssignment) {
	// Create a variable of integer type (32 bits)
	Term lhs = var(intType(32), 1);
	// Create an integer constant
	Term rhs = intConst(intType(32), 42);

	// Create assignment instruction
	Term assignment = assign(lhs, rhs);

	// Check the structure
	BOOST_CHECK_EQUAL(assignment.tag(), Assign);
	BOOST_CHECK_EQUAL(assignment.size(), 2);
	BOOST_CHECK(assignment[0] == lhs);
	BOOST_CHECK(assignment[1] == rhs);
	BOOST_CHECK(assignment.type() == voidType());
}

// Test assigning to a float variable
BOOST_AUTO_TEST_CASE(FloatAssignment) {
	Term lhs = var(floatType(), 2);
	Term rhs = floatConst(floatType(), "3.14");

	Term assignment = assign(lhs, rhs);

	BOOST_CHECK_EQUAL(assignment.tag(), Assign);
	BOOST_CHECK_EQUAL(assignment.size(), 2);
	BOOST_CHECK(assignment[0] == lhs);
	BOOST_CHECK(assignment[1] == rhs);
	BOOST_CHECK(assignment.type() == voidType());
}

// Test assigning to a pointer variable
BOOST_AUTO_TEST_CASE(PointerAssignment) {
	Term lhs = var(ptrType(), 3);
	Term rhs = nullConst;

	Term assignment = assign(lhs, rhs);

	BOOST_CHECK_EQUAL(assignment.tag(), Assign);
	BOOST_CHECK_EQUAL(assignment.size(), 2);
	BOOST_CHECK(assignment[0] == lhs);
	BOOST_CHECK(assignment[1] == rhs);
	BOOST_CHECK(assignment.type() == voidType());
}

// Test assigning result of arithmetic operation
BOOST_AUTO_TEST_CASE(ArithmeticAssignment) {
	Term lhs = var(intType(32), 4);
	Term op1 = var(intType(32), 5);
	Term op2 = intConst(intType(32), 10);
	Term rhs = arithmetic(Add, op1, op2);

	Term assignment = assign(lhs, rhs);

	BOOST_CHECK_EQUAL(assignment.tag(), Assign);
	BOOST_CHECK_EQUAL(assignment.size(), 2);
	BOOST_CHECK(assignment[0] == lhs);
	BOOST_CHECK(assignment[1] == rhs);
	BOOST_CHECK(assignment.type() == voidType());
}

// Test assigning result of comparison
BOOST_AUTO_TEST_CASE(ComparisonAssignment) {
	Term lhs = var(boolType(), 6);
	Term op1 = var(intType(32), 7);
	Term op2 = intConst(intType(32), 0);
	Term rhs = cmp(Eq, op1, op2);

	Term assignment = assign(lhs, rhs);

	BOOST_CHECK_EQUAL(assignment.tag(), Assign);
	BOOST_CHECK_EQUAL(assignment.size(), 2);
	BOOST_CHECK(assignment[0] == lhs);
	BOOST_CHECK(assignment[1] == rhs);
	BOOST_CHECK(assignment.type() == voidType());
}

// Test assigning between vector variables
BOOST_AUTO_TEST_CASE(VectorAssignment) {
	Type vecTy = vecType(4, intType(32));
	Term lhs = var(vecTy, 8);
	Term rhs = var(vecTy, 9);

	Term assignment = assign(lhs, rhs);

	BOOST_CHECK_EQUAL(assignment.tag(), Assign);
	BOOST_CHECK_EQUAL(assignment.size(), 2);
	BOOST_CHECK(assignment[0] == lhs);
	BOOST_CHECK(assignment[1] == rhs);
	BOOST_CHECK(assignment.type() == voidType());
}

// Test assigning to array variable
BOOST_AUTO_TEST_CASE(ArrayAssignment) {
	Type arrayTy = arrayType(10, intType(32));
	Term lhs = var(arrayTy, 10);
	Term rhs = var(arrayTy, 11);

	Term assignment = assign(lhs, rhs);

	BOOST_CHECK_EQUAL(assignment.tag(), Assign);
	BOOST_CHECK_EQUAL(assignment.size(), 2);
	BOOST_CHECK(assignment[0] == lhs);
	BOOST_CHECK(assignment[1] == rhs);
	BOOST_CHECK(assignment.type() == voidType());
}

// Test structure assignment
BOOST_AUTO_TEST_CASE(StructureAssignment) {
	vector<Type> fields = {intType(32), floatType(), boolType()};
	Type structTy = structType(fields);
	Term lhs = var(structTy, 12);
	Term rhs = var(structTy, 13);

	Term assignment = assign(lhs, rhs);

	BOOST_CHECK_EQUAL(assignment.tag(), Assign);
	BOOST_CHECK_EQUAL(assignment.size(), 2);
	BOOST_CHECK(assignment[0] == lhs);
	BOOST_CHECK(assignment[1] == rhs);
	BOOST_CHECK(assignment.type() == voidType());
}

// Test unconditional branch (goto) instruction
BOOST_AUTO_TEST_CASE(UnconditionalBranchTest) {
	// Basic goto instruction
	Term gotoInst = jmp(5);
	BOOST_CHECK_EQUAL(gotoInst.tag(), Jmp);
	BOOST_CHECK_EQUAL(gotoInst.type().kind(), VoidKind);
	BOOST_CHECK_EQUAL(gotoInst[0].intVal(), 5);

	// Verify goto with different target
	Term gotoInst2 = jmp(10);
	BOOST_CHECK_EQUAL(gotoInst2[0].intVal(), 10);

	// Verify different goto instructions with same target are equal
	Term gotoInst3 = jmp(5);
	BOOST_CHECK_EQUAL(gotoInst, gotoInst3);
}

// Test conditional branch instruction
BOOST_AUTO_TEST_CASE(ConditionalBranchTest) {
	// Create a boolean condition (1 == 1)
	Term one = intConst(intType(32), 1);
	Term condition = cmp(Eq, one, one);

	// Basic conditional branch
	Term branchInst = br(condition, 1, 2);
	BOOST_CHECK_EQUAL(branchInst.tag(), If);
	BOOST_CHECK_EQUAL(branchInst.type().kind(), VoidKind);
	BOOST_CHECK_EQUAL(branchInst.size(), 3); // condition + two branches

	// Check condition
	BOOST_CHECK_EQUAL(branchInst[0], condition);

	// Check true branch is a goto with target 1
	BOOST_CHECK_EQUAL(branchInst[1].tag(), Jmp);
	BOOST_CHECK_EQUAL(branchInst[1][0].intVal(), 1);

	// Check false branch is a goto with target 2
	BOOST_CHECK_EQUAL(branchInst[2].tag(), Jmp);
	BOOST_CHECK_EQUAL(branchInst[2][0].intVal(), 2);

	// Verify branches with same condition and targets are equal
	Term branchInst2 = br(condition, 1, 2);
	BOOST_CHECK_EQUAL(branchInst, branchInst2);
}

// Test return instructions
BOOST_AUTO_TEST_CASE(ReturnInstructionTest) {
	// Test void return
	Term voidRet(RetVoid);
	BOOST_CHECK_EQUAL(voidRet.tag(), RetVoid);
	BOOST_CHECK_EQUAL(voidRet.type().kind(), VoidKind);
	BOOST_CHECK_EQUAL(voidRet.size(), 0);

	// Test return with integer value
	Term intVal = intConst(intType(32), 42);
	Term valRet = ret(intVal);
	BOOST_CHECK_EQUAL(valRet.tag(), Ret);
	BOOST_CHECK_EQUAL(valRet.type().kind(), VoidKind);
	BOOST_CHECK_EQUAL(valRet.size(), 1);
	BOOST_CHECK_EQUAL(valRet[0], intVal);

	// Test return with boolean value
	Term boolVal = trueConst;
	Term boolRet = ret(boolVal);
	BOOST_CHECK_EQUAL(boolRet.tag(), Ret);
	BOOST_CHECK_EQUAL(boolRet.type().kind(), VoidKind);
	BOOST_CHECK_EQUAL(boolRet.size(), 1);
	BOOST_CHECK_EQUAL(boolRet[0], boolVal);

	// Verify returns with same value are equal
	Term valRet2 = ret(intVal);
	BOOST_CHECK_EQUAL(valRet, valRet2);
}

// Test error conditions
BOOST_AUTO_TEST_CASE(ErrorConditionsTest) {
	// Create a non-boolean condition
	Term intVal = intConst(intType(32), 1);

	// Verify br() with non-boolean condition throws
	BOOST_CHECK_THROW(br(intVal, 1, 2), std::exception);
}

BOOST_AUTO_TEST_CASE(basic_match) {
	BOOST_TEST(containsAt("Hello World", 6, "World") == true);
}

BOOST_AUTO_TEST_CASE(match_at_beginning) {
	BOOST_TEST(containsAt("Hello World", 0, "Hello") == true);
}

BOOST_AUTO_TEST_CASE(match_at_end) {
	BOOST_TEST(containsAt("Hello World", 10, "d") == true);
}

BOOST_AUTO_TEST_CASE(no_match_wrong_position) {
	BOOST_TEST(containsAt("Hello World", 1, "Hello") == false);
}

BOOST_AUTO_TEST_CASE(empty_needle) {
	BOOST_TEST(containsAt("Hello World", 5, "") == true);
	BOOST_TEST(containsAt("Hello", 5, "") == true);	 // Empty needle at end of string
	BOOST_TEST(containsAt("Hello", 6, "") == false); // Position beyond string length
}

BOOST_AUTO_TEST_CASE(empty_haystack) {
	BOOST_TEST(containsAt("", 0, "") == true);
	BOOST_TEST(containsAt("", 0, "x") == false);
	BOOST_TEST(containsAt("", 1, "") == false); // Position beyond empty string
}

BOOST_AUTO_TEST_CASE(position_out_of_bounds) {
	BOOST_TEST(containsAt("Hello", 6, "") == false);
	BOOST_TEST(containsAt("Hello", 6, "x") == false);
}

BOOST_AUTO_TEST_CASE(needle_too_long) {
	BOOST_TEST(containsAt("Hello", 3, "loWorld") == false);
}

BOOST_AUTO_TEST_CASE(case_sensitivity) {
	BOOST_TEST(containsAt("Hello World", 6, "world") == false);
}

BOOST_AUTO_TEST_CASE(special_characters) {
	BOOST_TEST(containsAt("Hello\n\tWorld", 5, "\n\t") == true);
}

BOOST_AUTO_TEST_CASE(test_basic_parsing) {
	std::string input = "1A2B3C";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0x1A2B3C);
	BOOST_CHECK_EQUAL(pos, 6);
}

BOOST_AUTO_TEST_CASE(test_lowercase_hex) {
	std::string input = "deadbeef";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0xdeadbeef);
	BOOST_CHECK_EQUAL(pos, 8);
}

BOOST_AUTO_TEST_CASE(test_mixed_case) {
	std::string input = "AbCdEf";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0xABCDEF);
	BOOST_CHECK_EQUAL(pos, 6);
}

BOOST_AUTO_TEST_CASE(test_max_length_limit) {
	std::string input = "123456789";
	size_t pos = 0;
	unsigned result = parseHex(input, pos, 4);
	BOOST_CHECK_EQUAL(result, 0x1234);
	BOOST_CHECK_EQUAL(pos, 4);
}

BOOST_AUTO_TEST_CASE(test_partial_string) {
	std::string input = "12XY34";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0x12);
	BOOST_CHECK_EQUAL(pos, 2);
}

BOOST_AUTO_TEST_CASE(test_starting_position) {
	std::string input = "XX12AB";
	size_t pos = 2;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0x12AB);
	BOOST_CHECK_EQUAL(pos, 6);
}

BOOST_AUTO_TEST_CASE(test_empty_string) {
	std::string input = "";
	size_t pos = 0;
	BOOST_CHECK_THROW(parseHex(input, pos), std::runtime_error);
	BOOST_CHECK_EQUAL(pos, 0);
}

BOOST_AUTO_TEST_CASE(test_no_hex_digits) {
	std::string input = "XYZ";
	size_t pos = 0;
	BOOST_CHECK_THROW(parseHex(input, pos), std::runtime_error);
	BOOST_CHECK_EQUAL(pos, 0);
}

BOOST_AUTO_TEST_CASE(test_position_beyond_string) {
	std::string input = "123";
	size_t pos = 5;
	BOOST_CHECK_THROW(parseHex(input, pos), std::runtime_error);
	BOOST_CHECK_EQUAL(pos, 5);
}

BOOST_AUTO_TEST_CASE(test_zero) {
	std::string input = "0";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0x0);
	BOOST_CHECK_EQUAL(pos, 1);
}

BOOST_AUTO_TEST_CASE(test_max_value) {
	std::string input = "FFFFFFFF";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0xFFFFFFFF);
	BOOST_CHECK_EQUAL(pos, 8);
}

// Test basic identifier without any special characters
BOOST_AUTO_TEST_CASE(BasicIdentifier) {
	BOOST_CHECK_EQUAL(unwrap("identifier"), "identifier");
	BOOST_CHECK_EQUAL(unwrap("abc123"), "abc123");
	BOOST_CHECK_EQUAL(unwrap("_underscore"), "_underscore");
}

// Test leading sigil removal
BOOST_AUTO_TEST_CASE(LeadingSigil) {
	BOOST_CHECK_EQUAL(unwrap("@variable"), "variable");
	BOOST_CHECK_EQUAL(unwrap("%local"), "local");
}

// Test quoted strings without escape sequences
BOOST_AUTO_TEST_CASE(QuotedStrings) {
	BOOST_CHECK_EQUAL(unwrap("\"quoted\""), "quoted");
	BOOST_CHECK_EQUAL(unwrap("\"\""), ""); // Empty quoted string
}

// Test strings with escape sequences
BOOST_AUTO_TEST_CASE(EscapeSequences) {
	BOOST_CHECK_EQUAL(unwrap("\"\\\\\""), "\\"); // Escaped backslash
}

// Test combinations of features
BOOST_AUTO_TEST_CASE(CombinedFeatures) {
	BOOST_CHECK_EQUAL(unwrap("@\"quoted\""), "quoted"); // Sigil with quotes
}

// Test error cases
BOOST_AUTO_TEST_CASE(ErrorCases) {
	// Unmatched quotes
	BOOST_CHECK_THROW(unwrap("\"unmatched"), std::runtime_error);

	// Invalid escape sequences
	BOOST_CHECK_THROW(unwrap("\"\\"), std::runtime_error); // Trailing backslash

	// Invalid characters in identifiers
	BOOST_CHECK_THROW(unwrap("invalid!char"), std::runtime_error);
	BOOST_CHECK_THROW(unwrap("space invalid"), std::runtime_error);
}

// Test edge cases
BOOST_AUTO_TEST_CASE(EdgeCases) {
	BOOST_CHECK_THROW(unwrap(""), std::runtime_error);
	BOOST_CHECK_EQUAL(unwrap("a"), "a");				// Single character
	BOOST_CHECK_EQUAL(unwrap("_"), "_");				// Just underscore
	BOOST_CHECK_THROW(unwrap("@"), std::runtime_error); // Just sigil
}

// Test whitespace handling
BOOST_AUTO_TEST_CASE(WhitespaceHandling) {
	BOOST_CHECK_EQUAL(unwrap("\"  spaced  \""), "  spaced  "); // Preserve internal spaces
}

// Test fixture for Parser tests
class ParserFixture {
protected:
	Target target;

	void parseFiles(const std::string& content1, const std::string& content2 = "") {
		if (!content1.empty()) {
			Parser("test1.ll", content1, target);
		}
		if (!content2.empty()) {
			Parser("test2.ll", content2, target);
		}
	}

	void expectError(const std::string& content1, const std::string& content2, const std::string& expectedError) {
		try {
			Parser("test1.ll", content1, target);
			Parser("test2.ll", content2, target);
			BOOST_FAIL("Expected error was not thrown");
		} catch (const std::runtime_error& e) {
			BOOST_CHECK_EQUAL(std::string(e.what()), expectedError);
		}
	}

	void expectError(const std::string& content, const std::string& expectedError) {
		try {
			Parser("test.ll", content, target);
			BOOST_FAIL("Expected error was not thrown");
		} catch (const std::runtime_error& e) {
			BOOST_CHECK_EQUAL(std::string(e.what()), expectedError);
		}
	}
};

BOOST_FIXTURE_TEST_SUITE(ParserTests, ParserFixture)

BOOST_AUTO_TEST_CASE(ParseTargetTriple) {
	const std::string input = "target triple = \"x86_64-pc-linux-gnu\"\n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(this->target.triple, "x86_64-pc-linux-gnu");
}

BOOST_AUTO_TEST_CASE(ParseTargetDatalayout) {
	const std::string input =
		"target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(this->target.datalayout, "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128");
}

BOOST_AUTO_TEST_CASE(ParseBothTargets) {
	const std::string input =
		"target triple = \"x86_64-pc-linux-gnu\"\n"
		"target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(this->target.triple, "x86_64-pc-linux-gnu");
	BOOST_CHECK_EQUAL(this->target.datalayout, "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128");
}

BOOST_AUTO_TEST_CASE(ConsistentTargetsAcrossFiles) {
	const std::string input1 = "target triple = \"x86_64-pc-linux-gnu\"\n";
	const std::string input2 = "target triple = \"x86_64-pc-linux-gnu\"\n";
	this->parseFiles(input1, input2);
	BOOST_CHECK_EQUAL(this->target.triple, "x86_64-pc-linux-gnu");
}

BOOST_AUTO_TEST_CASE(InconsistentTriple) {
	const std::string input1 = "target triple = \"x86_64-pc-linux-gnu\"\n";
	const std::string input2 = "target triple = \"aarch64-apple-darwin\"\n";
	this->expectError(input1, input2, "test2.ll:1: inconsistent triple");
}

BOOST_AUTO_TEST_CASE(InconsistentDatalayout) {
	const std::string input1 =
		"target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
	const std::string input2 =
		"target datalayout = \"e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
	this->expectError(input1, input2, "test2.ll:1: inconsistent datalayout");
}

BOOST_AUTO_TEST_CASE(MissingQuotes) {
	const std::string input = "target triple = x86_64-pc-linux-gnu\n";
	this->expectError(input, "test.ll:1: expected string");
}

BOOST_AUTO_TEST_CASE(UnclosedQuote) {
	const std::string input = "target triple = \"x86_64-pc-linux-gnu\n";
	this->expectError(input, "test.ll:1: unclosed quote");
}

BOOST_AUTO_TEST_CASE(MissingEquals) {
	const std::string input = "target triple \"x86_64-pc-linux-gnu\"\n";
	this->expectError(input, "test.ll:1: expected '='");
}

BOOST_AUTO_TEST_CASE(IgnoreComments) {
	const std::string input = "; This is a comment\n"
							  "target triple = \"x86_64-pc-linux-gnu\" ; Another comment\n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(this->target.triple, "x86_64-pc-linux-gnu");
}

BOOST_AUTO_TEST_CASE(IgnoreWhitespace) {
	const std::string input = "   \t  target    triple    =    \"x86_64-pc-linux-gnu\"   \n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(this->target.triple, "x86_64-pc-linux-gnu");
}

BOOST_AUTO_TEST_SUITE_END()

// Helper function to create a parser and return its globals
vector<Term> parse(const string& input) {
	Target target;
	Parser parser("test.ll", input, target);
	return parser.globals;
}

BOOST_AUTO_TEST_SUITE(ParserTests)

// Test parsing a void function with no parameters
BOOST_AUTO_TEST_CASE(VoidFunctionNoParams) {
	auto globals = parse("declare void @empty()\n");
	BOOST_REQUIRE_EQUAL(globals.size(), 1);

	auto func = globals[0];
	BOOST_CHECK_EQUAL(func.type().kind(), FuncKind);
	BOOST_CHECK_EQUAL(func.type()[0].kind(), VoidKind);
	BOOST_CHECK_EQUAL(func.size(), 2);

	auto params = func[1];
	BOOST_CHECK_EQUAL(params.size(), 0); // No parameters
}

// Test parsing an integer function with one parameter
BOOST_AUTO_TEST_CASE(IntFunctionOneParam) {
	auto globals = parse("declare i32 @add(i32 %x)\n");
	BOOST_REQUIRE_EQUAL(globals.size(), 1);

	auto func = globals[0];
	BOOST_CHECK_EQUAL(func.type().kind(), FuncKind);
	BOOST_CHECK_EQUAL(func.type()[0].kind(), IntKind);
	BOOST_CHECK_EQUAL(func.type()[0].len(), 32);

	auto params = func[1];
	BOOST_CHECK_EQUAL(params.size(), 1);
	BOOST_CHECK_EQUAL(params[0].type().kind(), IntKind);
	BOOST_CHECK_EQUAL(params[0].type().len(), 32);
}

// Test parsing a function with multiple parameters of different types
BOOST_AUTO_TEST_CASE(MultipleParamTypes) {
	auto globals = parse("declare float @compute(i64 %a, float %b, ptr %c)\n");
	BOOST_REQUIRE_EQUAL(globals.size(), 1);

	auto func = globals[0];
	BOOST_CHECK_EQUAL(func.type().kind(), FuncKind);
	BOOST_CHECK_EQUAL(func.type()[0].kind(), FloatKind);

	auto params = func[1];
	BOOST_CHECK_EQUAL(params.size(), 3);
	BOOST_CHECK_EQUAL(params[0].type().kind(), IntKind);
	BOOST_CHECK_EQUAL(params[0].type().len(), 64);
	BOOST_CHECK_EQUAL(params[1].type().kind(), FloatKind);
	BOOST_CHECK_EQUAL(params[2].type().kind(), PtrKind);
}

// Test parsing a function with vector parameters
BOOST_AUTO_TEST_CASE(VectorParams) {
	auto globals = parse("declare <4 x float> @vecfunc(<2 x i32> %v)\n");
	BOOST_REQUIRE_EQUAL(globals.size(), 1);

	auto func = globals[0];
	BOOST_CHECK_EQUAL(func.type().kind(), FuncKind);
	BOOST_CHECK_EQUAL(func.type()[0].kind(), VecKind);
	BOOST_CHECK_EQUAL(func.type()[0].len(), 4);
	BOOST_CHECK_EQUAL(func.type()[0][0].kind(), FloatKind);

	auto params = func[1];
	BOOST_CHECK_EQUAL(params.size(), 1);
	BOOST_CHECK_EQUAL(params[0].type().kind(), VecKind);
	BOOST_CHECK_EQUAL(params[0].type().len(), 2);
	BOOST_CHECK_EQUAL(params[0].type()[0].kind(), IntKind);
}

// Test parsing target triple and datalayout
BOOST_AUTO_TEST_CASE(TargetInfo) {
	Target target;
	Parser parser("test.ll",
				  "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n"
				  "target triple = \"x86_64-unknown-linux-gnu\"\n",
				  target);

	BOOST_CHECK_EQUAL(target.datalayout, "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128");
	BOOST_CHECK_EQUAL(target.triple, "x86_64-unknown-linux-gnu");
}

// Test parsing error cases
BOOST_AUTO_TEST_CASE(ParseErrors) {
	// Missing return type
	BOOST_CHECK_THROW(parse("declare @func()\n"), runtime_error);

	// Missing parameter type
	BOOST_CHECK_THROW(parse("declare void @func(%x)\n"), runtime_error);

	// Invalid function name (missing @)
	BOOST_CHECK_THROW(parse("declare void func()\n"), runtime_error);

	// Missing closing parenthesis
	BOOST_CHECK_THROW(parse("declare void @func(\n"), runtime_error);
}

BOOST_AUTO_TEST_SUITE_END()

BOOST_AUTO_TEST_SUITE(TypeIteratorTests)

// Test scalar types have empty iteration range
BOOST_AUTO_TEST_CASE(ScalarTypeIterators) {
	// Test void type
	{
		Type t = voidType();
		BOOST_CHECK(t.begin() == t.end());
		BOOST_CHECK(t.cbegin() == t.cend());
		BOOST_CHECK_EQUAL(std::distance(t.begin(), t.end()), 0);
	}

	// Test integer type
	{
		Type t = intType(32);
		BOOST_CHECK(t.begin() == t.end());
		BOOST_CHECK(t.cbegin() == t.cend());
		BOOST_CHECK_EQUAL(std::distance(t.begin(), t.end()), 0);
	}

	// Test float type
	{
		Type t = floatType();
		BOOST_CHECK(t.begin() == t.end());
		BOOST_CHECK(t.cbegin() == t.cend());
		BOOST_CHECK_EQUAL(std::distance(t.begin(), t.end()), 0);
	}
}

// Test vector type iteration
BOOST_AUTO_TEST_CASE(VectorTypeIterators) {
	Type elementType = intType(32);
	Type vecT = vecType(4, elementType);

	BOOST_CHECK(vecT.begin() != vecT.end());
	BOOST_CHECK(vecT.cbegin() != vecT.cend());
	BOOST_CHECK_EQUAL(std::distance(vecT.begin(), vecT.end()), 1);

	// Check element type through iterator
	BOOST_CHECK(*vecT.begin() == elementType);
}

// Test array type iteration
BOOST_AUTO_TEST_CASE(ArrayTypeIterators) {
	Type elementType = doubleType();
	Type arrT = arrayType(10, elementType);

	BOOST_CHECK(arrT.begin() != arrT.end());
	BOOST_CHECK(arrT.cbegin() != arrT.cend());
	BOOST_CHECK_EQUAL(std::distance(arrT.begin(), arrT.end()), 1);

	// Check element type through iterator
	BOOST_CHECK(*arrT.begin() == elementType);
}

// Test struct type iteration
BOOST_AUTO_TEST_CASE(StructTypeIterators) {
	std::vector<Type> fields = {intType(32), floatType(), doubleType()};
	Type structT = structType(fields);

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
BOOST_AUTO_TEST_CASE(FunctionTypeIterators) {
	std::vector<Type> params = {intType(32), floatType(), ptrType()};
	Type returnType = voidType();
	std::vector<Type> functionTypes = params;
	functionTypes.insert(functionTypes.begin(), returnType);
	Type funcT = functionType(functionTypes);

	BOOST_CHECK(funcT.begin() != funcT.end());
	BOOST_CHECK(funcT.cbegin() != funcT.cend());
	BOOST_CHECK_EQUAL(std::distance(funcT.begin(), funcT.end()), params.size() + 1);

	// Check return type
	BOOST_CHECK(*funcT.begin() == returnType);

	// Check parameter types
	auto it = std::next(funcT.begin());
	for (const auto& param : params) {
		BOOST_CHECK(*it == param);
		++it;
	}
}

// Test iterator comparison and assignment
BOOST_AUTO_TEST_CASE(IteratorOperations) {
	Type structT = structType({intType(32), floatType()});

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
	Type structT1 = structType({intType(32), floatType()});
	auto it1 = structT1.begin();

	// Create a new struct type
	Type structT2 = structType({doubleType(), ptrType()});

	// Original iterator should still be valid and point to the original type
	BOOST_CHECK(*it1 == intType(32));
}

BOOST_AUTO_TEST_SUITE_END()

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
	std::vector<Term> params = {var(intType(32), "a"), var(doubleType(), "b"), var(ptrType(), "c")};

	Term paramTerm = tuple(params);

	// Check size matches number of parameters
	BOOST_CHECK_EQUAL(paramTerm.size(), 3);

	// Test forward iteration
	auto it = paramTerm.begin();
	BOOST_CHECK_EQUAL((*it).type(), intType(32));
	++it;
	BOOST_CHECK_EQUAL((*it).type(), doubleType());
	++it;
	BOOST_CHECK_EQUAL((*it).type(), ptrType());
	++it;
	BOOST_CHECK(it == paramTerm.end());
}

// Test iteration over arithmetic expressions
BOOST_AUTO_TEST_CASE(ArithmeticExpressionIterationTest) {
	Term a = var(intType(32), "a");
	Term b = var(intType(32), "b");
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
	Term a = var(intType(32), "a");
	Term b = var(intType(32), "b");
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
	std::vector<Term> params = {var(intType(32), "a"), var(intType(32), "b")};

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

// Mock implementations for testing
Term createMockFunction(const string& name, const vector<Term>& params, const vector<Term>& instructions) {
	Type returnType = voidType(); // Mock return type
	auto paramTypes = map(params, [](Term a) { return a.type(); });
	Term ref = globalRef(functionType(returnType, paramTypes), name);
	return function(returnType, ref, params, instructions);
}

Term createMockVar(const string& name) {
	return var(floatType(), name);
}

Term createMockInstruction() {
	return Term(RetVoid); // Mock instruction (RetVoid)
}

BOOST_AUTO_TEST_SUITE(UnpackFunctionTests)

BOOST_AUTO_TEST_CASE(test_basic_function_unpacking) {
	// Create a simple function with no parameters and one instruction
	vector<Term> testParams;
	vector<Term> testInstructions = {createMockInstruction()};
	Term f = createMockFunction("test_func", testParams, testInstructions);

	// Unpack the function
	unpackFunction(f);

	// Verify the ref (function name)
	BOOST_CHECK_EQUAL(ref.str(), "test_func");

	// Verify empty params
	BOOST_CHECK_EQUAL(params.size(), 0);

	// Verify instructions
	BOOST_CHECK_EQUAL(instructions.size(), 1);
}

BOOST_AUTO_TEST_CASE(test_function_with_parameters) {
	// Create a function with parameters
	vector<Term> testParams = {createMockVar("param1"), createMockVar("param2")};
	vector<Term> testInstructions = {createMockInstruction()};
	Term f = createMockFunction("func_with_params", testParams, testInstructions);

	// Unpack the function
	unpackFunction(f);

	// Verify parameters
	BOOST_CHECK_EQUAL(params.size(), 2);
	BOOST_CHECK_EQUAL(params[0].str(), "param1");
	BOOST_CHECK_EQUAL(params[1].str(), "param2");
}

BOOST_AUTO_TEST_CASE(test_function_with_multiple_instructions) {
	// Create a function with multiple instructions
	vector<Term> testParams;
	vector<Term> testInstructions = {createMockInstruction(), createMockInstruction(), createMockInstruction()};
	Term f = createMockFunction("multi_instruction_func", testParams, testInstructions);

	// Unpack the function
	unpackFunction(f);

	// Verify instructions
	BOOST_CHECK_EQUAL(instructions.size(), 3);
}

BOOST_AUTO_TEST_CASE(test_empty_function) {
	// Create a function with no parameters and no instructions
	vector<Term> testParams;
	vector<Term> testInstructions;
	Term f = createMockFunction("empty_func", testParams, testInstructions);

	// Unpack the function
	unpackFunction(f);

	// Verify empty collections
	BOOST_CHECK_EQUAL(params.size(), 0);
	BOOST_CHECK_EQUAL(instructions.size(), 0);
	BOOST_CHECK_EQUAL(ref.str(), "empty_func");
}

BOOST_AUTO_TEST_CASE(test_function_components_access) {
	// Create a function with some content
	vector<Term> testParams = {createMockVar("param1")};
	vector<Term> testInstructions = {createMockInstruction()};
	Term f = createMockFunction("test_access", testParams, testInstructions);

	// Test individual component access functions
	Term functionRef = getFunctionRef(f);
	Term functionParams = getFunctionParams(f);

	BOOST_CHECK_EQUAL(functionRef.str(), "test_access");
	BOOST_CHECK_EQUAL(functionParams.size(), 1);
}

BOOST_AUTO_TEST_SUITE_END()

BOOST_AUTO_TEST_SUITE(ParserControlFlow)

// Helper function to create a test Target
Target createTestTarget() {
	Target target;
	target.datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	target.triple = "x86_64-unknown-linux-gnu";
	return target;
}

// Test parsing a simple unconditional branch
BOOST_AUTO_TEST_CASE(UnconditionalBranch) {
	const string source = R"(
define void @test_goto() {
entry:
    br label %exit
exit:
    ret void
}
)";

	Target target = createTestTarget();
	Parser parser("test.ll", source, target);

	BOOST_REQUIRE_EQUAL(parser.globals.size(), 1);
	Term func = parser.globals[0];

	auto instructions = getFunctionInstructions(func);
	BOOST_REQUIRE_EQUAL(instructions.size(), 2);

	// First instruction should be an unconditional branch
	BOOST_CHECK_EQUAL(instructions[0].tag(), Tag::Jmp);

	// Second instruction should be return void
	BOOST_CHECK_EQUAL(instructions[1].tag(), Tag::RetVoid);
}

// Test parsing a conditional branch using true constant
BOOST_AUTO_TEST_CASE(ConditionalBranchTrue) {
	const string source = R"(
define void @test_if() {
entry:
    br i1 true, label %then, label %else
then:
    br label %exit
else:
    br label %exit
exit:
    ret void
}
)";

	Target target = createTestTarget();
	Parser parser("test.ll", source, target);

	BOOST_REQUIRE_EQUAL(parser.globals.size(), 1);
	Term func = parser.globals[0];

	auto instructions = getFunctionInstructions(func);
	BOOST_REQUIRE_EQUAL(instructions.size(), 4);

	// First instruction should be conditional branch
	BOOST_CHECK_EQUAL(instructions[0].tag(), Tag::If);
	BOOST_CHECK_EQUAL(instructions[0][0], trueConst);
	// Targets should be resolved to offsets 1 and 2
	BOOST_CHECK_EQUAL(instructions[0][1].tag(), Jmp);
	BOOST_CHECK_EQUAL(instructions[0][2].tag(), Jmp);
}

// Test parsing a conditional branch using false constant
BOOST_AUTO_TEST_CASE(ConditionalBranchFalse) {
	const string source = R"(
define void @test_if() {
entry:
    br i1 false, label %then, label %else
then:
    br label %exit
else:
    br label %exit
exit:
    ret void
}
)";

	Target target = createTestTarget();
	Parser parser("test.ll", source, target);

	BOOST_REQUIRE_EQUAL(parser.globals.size(), 1);
	Term func = parser.globals[0];

	auto instructions = getFunctionInstructions(func);
	BOOST_REQUIRE_EQUAL(instructions.size(), 4);

	// First instruction should be conditional branch
	BOOST_CHECK_EQUAL(instructions[0].tag(), Tag::If);
	BOOST_CHECK_EQUAL(instructions[0][0], falseConst);
}

// Test error handling for undefined labels
BOOST_AUTO_TEST_CASE(UndefinedLabel) {
	const string source = R"(
define void @test_undefined() {
entry:
    br label %undefined_label
}
)";

	Target target = createTestTarget();
}

// Test parsing multiple branches to the same label
BOOST_AUTO_TEST_CASE(MultipleBranchesToSameLabel) {
	const string source = R"(
define void @test_multi_branch() {
entry:
    br i1 true, label %exit, label %other
other:
    br label %exit
exit:
    ret void
}
)";

	Target target = createTestTarget();
	Parser parser("test.ll", source, target);

	BOOST_REQUIRE_EQUAL(parser.globals.size(), 1);
	Term func = parser.globals[0];

	auto instructions = getFunctionInstructions(func);
	BOOST_REQUIRE_EQUAL(instructions.size(), 3);

	// Both branches should point to the same final offset
	BOOST_CHECK_EQUAL(instructions[0].tag(), Tag::If);
	BOOST_CHECK_EQUAL(instructions[1].tag(), Tag::Jmp);
}

BOOST_AUTO_TEST_SUITE_END()

BOOST_AUTO_TEST_SUITE(ParserTestSuite)

BOOST_AUTO_TEST_CASE(ParseAddInstruction) {
	// Test valid add instruction
	{
		Target target;
		const string input = R"(
define i32 @test() {
    %1 = add i32 %2, %3
    ret i32 %1
}
)";
		Parser parser("test.ll", input, target);
		BOOST_REQUIRE_EQUAL(parser.globals.size(), 1);

		Term func = parser.globals[0];
		BOOST_REQUIRE_EQUAL(func.tag(), Tag::Function);

		auto instructions = getFunctionInstructions(func);
		BOOST_REQUIRE_EQUAL(instructions.size(), 2);

		// Verify the add instruction
		Term addInst = instructions[0];
		BOOST_CHECK_EQUAL(addInst.tag(), Tag::Assign);
		BOOST_CHECK_EQUAL(addInst[0].tag(), Tag::Var); // Left-hand side
		BOOST_CHECK_EQUAL(addInst[1].tag(), Tag::Add); // Right-hand side

		// Check operands of add
		Term addExpr = addInst[1];
		BOOST_CHECK_EQUAL(addExpr[0].tag(), Tag::Var);
		BOOST_CHECK_EQUAL(addExpr[1].tag(), Tag::Var);
		BOOST_CHECK_EQUAL(addExpr[0].type().kind(), Kind::IntKind);
		BOOST_CHECK_EQUAL(addExpr[0].type().len(), 32);
	}

	// Test add instruction with nuw and nsw flags
	{
		Target target;
		const string input = R"(
define i32 @test() {
    %1 = add nuw nsw i32 %2, %3
    ret i32 %1
}
)";
		Parser parser("test.ll", input, target);
		BOOST_REQUIRE_EQUAL(parser.globals.size(), 1);

		auto instructions = getFunctionInstructions(parser.globals[0]);
		BOOST_REQUIRE_EQUAL(instructions.size(), 2);

		// The parser should ignore the nuw and nsw flags while still parsing the instruction
		Term addInst = instructions[0];
		BOOST_CHECK_EQUAL(addInst.tag(), Tag::Assign);
		BOOST_CHECK_EQUAL(addInst[1].tag(), Tag::Add);
	}

	// Test error cases
	{
		Target target;
		// Mismatched types
		const string badInput = R"(
define i32 @test() {
    %1 = add i32 %2, i64 %3
    ret i32 %1
}
)";
		BOOST_CHECK_THROW(Parser("test.ll", badInput, target), runtime_error);

		// Missing operand
		const string missingOperand = R"(
define i32 @test() {
    %1 = add i32 %2
    ret i32 %1
}
)";
		BOOST_CHECK_THROW(Parser("test.ll", missingOperand, target), runtime_error);

		// Missing type
		const string missingType = R"(
define i32 @test() {
    %1 = add %2, %3
    ret i32 %1
}
)";
		BOOST_CHECK_THROW(Parser("test.ll", missingType, target), runtime_error);
	}
}

BOOST_AUTO_TEST_SUITE_END()

BOOST_AUTO_TEST_CASE(test_icmp_eq_parsing) {
	// Create a target for parsing
	Target target;

	// Test case 1: Basic integer comparison
	std::string input1 = R"(
define i32 @test_eq(i32 %a, i32 %b) {
entry:
    %result = icmp eq i32 %a, %b
    ret i32 0
}
)";

	Parser parser1("test.ll", input1, target);
	BOOST_REQUIRE_EQUAL(parser1.globals.size(), 1);

	Term func = parser1.globals[0];
	auto instructions = getFunctionInstructions(func);

	// Verify we have 2 instructions (icmp and ret)
	BOOST_REQUIRE_EQUAL(instructions.size(), 2);

	// Check the icmp instruction
	Term icmp_inst = instructions[0];
	BOOST_CHECK_EQUAL(icmp_inst.tag(), Tag::Assign);
	BOOST_CHECK_EQUAL(icmp_inst[1].tag(), Tag::Eq);

	// Verify operands
	Term cmp_expr = icmp_inst[1];
	BOOST_CHECK_EQUAL(cmp_expr[0].tag(), Tag::Var); // %a
	BOOST_CHECK_EQUAL(cmp_expr[1].tag(), Tag::Var); // %b

	// Test case 2: Compare with constant
	std::string input2 = R"(
define i1 @test_eq_const(i32 %x) {
    %cmp = icmp eq i32 %x, 42
    ret i1 %cmp
}
)";

	Parser parser2("test.ll", input2, target);
	BOOST_REQUIRE_EQUAL(parser2.globals.size(), 1);

	func = parser2.globals[0];
	instructions = getFunctionInstructions(func);

	// Verify instruction
	icmp_inst = instructions[0];
	BOOST_CHECK_EQUAL(icmp_inst.tag(), Tag::Assign);
	BOOST_CHECK_EQUAL(icmp_inst[1].tag(), Tag::Eq);

	// Verify comparison result type is i1 (boolean)
	BOOST_CHECK_EQUAL(icmp_inst[0].type().kind(), Kind::IntKind);
	BOOST_CHECK_EQUAL(icmp_inst[0].type().len(), 1);
}
