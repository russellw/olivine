#include "all.h"

#define BOOST_TEST_MODULE Unit_Test
#include <boost/test/included/unit_test.hpp>

Term arithmetic(Tag tag, Term a) {
	return Term(tag, a.type(), a);
}

Term arithmetic(Tag tag, Term a, Term b) {
	return Term(tag, a.type(), a, b);
}

Type funcType(const vector<Type>& v) {
	ASSERT(v.size());
	return funcType(v[0], tail(v));
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

BOOST_AUTO_TEST_CASE(FuncTypeProperties) {
	// Test function type with various parameter types
	vector<Type> params = {
		intType(32), // return type
		floatType(), // param 1
		boolType(),	 // param 2
		ptrType()	 // param 3
	};
	Type func_type = funcType(params);

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
	Type void_func = funcType(void_return);
	BOOST_CHECK_EQUAL(void_func.kind(), FuncKind);
	BOOST_CHECK_EQUAL(void_func.size(), 1);
	BOOST_CHECK(void_func[0] == voidType());
}

BOOST_AUTO_TEST_CASE(FuncTypeEquality) {
	vector<Type> params1 = {intType(32), floatType(), boolType()};
	vector<Type> params2 = {intType(32), floatType(), boolType()};
	vector<Type> params3 = {intType(32), boolType(), floatType()};

	Type func1 = funcType(params1);
	Type func2 = funcType(params2);
	Type func3 = funcType(params3);

	// Test equality of identical function types
	BOOST_CHECK(func1 == func2);

	// Test inequality of functions with same types in different order
	BOOST_CHECK(func1 != func3);

	// Test functions with different return types
	vector<Type> params4 = {floatType(), floatType(), boolType()};
	Type func4 = funcType(params4);
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
	Type complex_func = funcType(func_params);

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

BOOST_AUTO_TEST_CASE(FuncTypeOutput) {
	std::vector<Type> params;

	// Test function with no parameters
	params.push_back(voidType()); // return type
	BOOST_CHECK_EQUAL(typeToString(funcType(params)), "void ()");

	// Test function with basic parameters
	params.push_back(intType(32));
	params.push_back(floatType());
	BOOST_CHECK_EQUAL(typeToString(funcType(params)), "void (i32, float)");

	// Test function returning non-void
	params[0] = ptrType();
	BOOST_CHECK_EQUAL(typeToString(funcType(params)), "ptr (i32, float)");

	// Test function with complex parameter types
	params.push_back(arrayType(4, intType(8)));
	BOOST_CHECK_EQUAL(typeToString(funcType(params)), "ptr (i32, float, [4 x i8])");
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

	Type complexType = funcType(funcParams);

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

BOOST_AUTO_TEST_CASE(FuncTypeMapping) {
	std::unordered_map<Type, std::string> typeMap;

	// Function type: int32 (float, bool)
	std::vector<Type> params1 = {intType(32), floatType(), boolType()};
	Type func1 = funcType(params1);

	// Same function type
	std::vector<Type> params2 = {intType(32), floatType(), boolType()};
	Type func2 = funcType(params2);

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
	const std::string input = "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(this->target.datalayout, "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128");
}

BOOST_AUTO_TEST_CASE(ParseBothTargets) {
	const std::string input = "target triple = \"x86_64-pc-linux-gnu\"\n"
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
	const std::string input1 = "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
	const std::string input2 = "target datalayout = \"e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
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

BOOST_AUTO_TEST_SUITE(ParserTests)

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
BOOST_AUTO_TEST_CASE(FuncTypeIterators) {
	std::vector<Type> params = {intType(32), floatType(), ptrType()};
	Type rty = voidType();
	std::vector<Type> funcTypes = params;
	funcTypes.insert(funcTypes.begin(), rty);
	Type funcT = funcType(funcTypes);

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

Term createMockVar(const string& name) {
	return var(floatType(), name);
}

BOOST_AUTO_TEST_SUITE(ParserTestSuite)

BOOST_AUTO_TEST_CASE(ParseAddInst) {
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

BOOST_AUTO_TEST_SUITE(ParseRefTests)

// Test basic numeric references
BOOST_AUTO_TEST_CASE(BasicNumericRefs) {
	// Test simple numeric references
	auto ref1 = parseRef("%0");
	BOOST_CHECK(std::holds_alternative<size_t>(ref1));
	BOOST_CHECK_EQUAL(std::get<size_t>(ref1), 0);

	auto ref2 = parseRef("%42");
	BOOST_CHECK(std::holds_alternative<size_t>(ref2));
	BOOST_CHECK_EQUAL(std::get<size_t>(ref2), 42);
}

// Test string references
BOOST_AUTO_TEST_CASE(StringRefs) {
	// Test basic string reference
	auto ref1 = parseRef("%foo");
	BOOST_CHECK(std::holds_alternative<std::string>(ref1));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref1), "foo");

	// Test string reference with underscore
	auto ref2 = parseRef("%my_var");
	BOOST_CHECK(std::holds_alternative<std::string>(ref2));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref2), "my_var");
}

// Test quoted references
BOOST_AUTO_TEST_CASE(QuotedRefs) {
	// Test quoted string that looks like a number
	auto ref1 = parseRef("%\"42\"");
	BOOST_CHECK(std::holds_alternative<std::string>(ref1));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref1), "42");

	// Test quoted string with spaces
	auto ref2 = parseRef("%\"hello world\"");
	BOOST_CHECK(std::holds_alternative<std::string>(ref2));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref2), "hello world");
}

// Test escaped sequences in quoted strings
BOOST_AUTO_TEST_CASE(EscapedRefs) {
	// Test string with hex escape
	auto ref2 = parseRef("%\"hello\\20world\"");
	BOOST_CHECK(std::holds_alternative<std::string>(ref2));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref2), "hello world");
}

// Test error cases
BOOST_AUTO_TEST_CASE(ErrorCases) {
	// Empty string
	BOOST_CHECK_THROW(parseRef(""), std::runtime_error);

	// Just sigil
	BOOST_CHECK_THROW(parseRef("%"), std::runtime_error);

	// Invalid number format
	BOOST_CHECK_THROW(parseRef("%42a"), std::runtime_error);

	// Unclosed quote
	BOOST_CHECK_THROW(parseRef("%\"unclosed"), std::runtime_error);
}

// Test edge cases
BOOST_AUTO_TEST_CASE(EdgeCases) {
	// Test maximum numeric value
	auto ref1 = parseRef("%18446744073709551615"); // max size_t
	BOOST_CHECK(std::holds_alternative<size_t>(ref1));
	BOOST_CHECK_EQUAL(std::get<size_t>(ref1), 18446744073709551615ULL);

	// Test empty quoted string
	auto ref2 = parseRef("%\"\"");
	BOOST_CHECK(std::holds_alternative<std::string>(ref2));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref2), "");

	// Test string with just spaces
	auto ref3 = parseRef("%\"   \"");
	BOOST_CHECK(std::holds_alternative<std::string>(ref3));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref3), "   ");
}

BOOST_AUTO_TEST_SUITE_END()

BOOST_AUTO_TEST_SUITE(HashVectorTests)

BOOST_AUTO_TEST_CASE(EmptyVectorTest) {
	vector<int> empty;
	BOOST_CHECK_EQUAL(hashVector(empty), 0);
}

BOOST_AUTO_TEST_CASE(SingleElementVectorTest) {
	vector<int> v{42};
	// Store the hash value calculated by hashVector
	size_t actual = hashVector(v);
	// Verify the hash is non-zero and consistent
	BOOST_CHECK_NE(actual, 0);
	BOOST_CHECK_EQUAL(hashVector(v), actual);
}

BOOST_AUTO_TEST_CASE(MultipleElementsVectorTest) {
	vector<int> v{1, 2, 3, 4, 5};
	size_t actual = hashVector(v);
	// Verify the hash is non-zero and consistent
	BOOST_CHECK_NE(actual, 0);
	BOOST_CHECK_EQUAL(hashVector(v), actual);
}

BOOST_AUTO_TEST_CASE(StringVectorTest) {
	vector<string> v{"hello", "world"};
	size_t actual = hashVector(v);
	// Verify the hash is non-zero and consistent
	BOOST_CHECK_NE(actual, 0);
	BOOST_CHECK_EQUAL(hashVector(v), actual);
}

BOOST_AUTO_TEST_CASE(OrderDependencyTest) {
	vector<int> v1{1, 2, 3};
	vector<int> v2{3, 2, 1};
	// Hashes should be different for different orders
	BOOST_CHECK_NE(hashVector(v1), hashVector(v2));
}

BOOST_AUTO_TEST_CASE(ConsistencyTest) {
	vector<int> v{1, 2, 3, 4, 5};
	size_t hash1 = hashVector(v);
	size_t hash2 = hashVector(v);
	// Same vector should produce same hash
	BOOST_CHECK_EQUAL(hash1, hash2);
}

BOOST_AUTO_TEST_CASE(DifferentTypesTest) {
	vector<int> v1{1, 2, 3};
	vector<double> v2{1.0, 2.0, 3.0};
	// Different types should produce different hashes even with "same" values
	BOOST_CHECK_NE(hashVector(v1), hashVector(v2));
}

BOOST_AUTO_TEST_CASE(LargeVectorTest) {
	vector<int> large(1000);
	for (int i = 0; i < 1000; ++i) {
		large[i] = i;
	}
	// Just verify it doesn't crash and returns non-zero
	BOOST_CHECK_NE(hashVector(large), 0);
}

BOOST_AUTO_TEST_SUITE_END()

// Test suite for cons function
BOOST_AUTO_TEST_SUITE(ConsTests)

BOOST_AUTO_TEST_CASE(cons_empty_vector) {
	vector<int> empty;
	auto result = cons(1, empty);

	BOOST_CHECK_EQUAL(result.size(), 1);
	BOOST_CHECK_EQUAL(result[0], 1);
}

BOOST_AUTO_TEST_CASE(cons_nonempty_vector) {
	vector<int> v{2, 3, 4};
	auto result = cons(1, v);

	BOOST_CHECK_EQUAL(result.size(), 4);
	BOOST_CHECK_EQUAL(result[0], 1);
	BOOST_CHECK_EQUAL(result[1], 2);
	BOOST_CHECK_EQUAL(result[2], 3);
	BOOST_CHECK_EQUAL(result[3], 4);
}

BOOST_AUTO_TEST_CASE(cons_preserves_original) {
	vector<int> original{2, 3, 4};
	vector<int> originalCopy = original;
	auto result = cons(1, original);

	BOOST_CHECK_EQUAL_COLLECTIONS(original.begin(), original.end(), originalCopy.begin(), originalCopy.end());
}

BOOST_AUTO_TEST_CASE(cons_with_string) {
	vector<string> v{"world", "!"};
	auto result = cons(string("hello"), v);

	BOOST_CHECK_EQUAL(result.size(), 3);
	BOOST_CHECK_EQUAL(result[0], "hello");
	BOOST_CHECK_EQUAL(result[1], "world");
	BOOST_CHECK_EQUAL(result[2], "!");
}

BOOST_AUTO_TEST_SUITE_END()

// Test suite for call function
BOOST_AUTO_TEST_SUITE(CallTests)

BOOST_AUTO_TEST_CASE(call_no_args) {
	Type returnType = intType(32);
	Term func = var(funcType(returnType, {}), Ref("main"));
	vector<Term> emptyArgs;

	Term result = call(returnType, func, emptyArgs);

	BOOST_CHECK_EQUAL(result.tag(), Call);
	BOOST_CHECK_EQUAL(result.type(), returnType);
	BOOST_CHECK_EQUAL(result.size(), 1);
	BOOST_CHECK_EQUAL(result[0], func);
}

BOOST_AUTO_TEST_CASE(call_with_args) {
	Type returnType = intType(32);
	Type paramType = intType(32);
	vector<Type> paramTypes{paramType, paramType};

	Term func = var(funcType(returnType, paramTypes), Ref("add"));
	Term arg1 = intConst(paramType, cpp_int(1));
	Term arg2 = intConst(paramType, cpp_int(2));
	vector<Term> args{arg1, arg2};

	Term result = call(returnType, func, args);

	BOOST_CHECK_EQUAL(result.tag(), Call);
	BOOST_CHECK_EQUAL(result.type(), returnType);
	BOOST_CHECK_EQUAL(result.size(), 3);
	BOOST_CHECK_EQUAL(result[0], func);
	BOOST_CHECK_EQUAL(result[1], arg1);
	BOOST_CHECK_EQUAL(result[2], arg2);
}

BOOST_AUTO_TEST_CASE(call_preserves_args) {
	Type returnType = intType(32);
	Type paramType = intType(32);
	Term func = var(funcType(returnType, {paramType}), Ref("inc"));

	vector<Term> originalArgs{intConst(paramType, cpp_int(42))};
	vector<Term> argsCopy = originalArgs;

	Term result = call(returnType, func, originalArgs);

	BOOST_CHECK_EQUAL_COLLECTIONS(originalArgs.begin(), originalArgs.end(), argsCopy.begin(), argsCopy.end());
}

BOOST_AUTO_TEST_CASE(call_void_return) {
	Type voidTy = voidType();
	Term func = var(funcType(voidTy, {}), Ref("exit"));
	vector<Term> emptyArgs;

	Term result = call(voidTy, func, emptyArgs);

	BOOST_CHECK_EQUAL(result.tag(), Call);
	BOOST_CHECK_EQUAL(result.type(), voidTy);
	BOOST_CHECK_EQUAL(result.size(), 1);
	BOOST_CHECK_EQUAL(result[0], func);
}

BOOST_AUTO_TEST_SUITE_END()
