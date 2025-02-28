#include "all.h"
#include <boost/test/unit_test.hpp>

// Helper function to convert Type to string
std::string typeToString(Type ty) {
	std::ostringstream oss;
	oss << ty;
	return oss.str();
}

BOOST_AUTO_TEST_CASE(BasicTypeOutput) {
	// Test void type
	BOOST_CHECK_EQUAL(typeToString(voidTy()), "void");

	// Test float and double
	BOOST_CHECK_EQUAL(typeToString(floatTy()), "float");
	BOOST_CHECK_EQUAL(typeToString(doubleTy()), "double");

	// Test bool (1-bit integer)
	BOOST_CHECK_EQUAL(typeToString(boolTy()), "i1");

	// Test pointer
	BOOST_CHECK_EQUAL(typeToString(ptrTy()), "ptr");
}

BOOST_AUTO_TEST_CASE(IntegerTypeOutput) {
	// Test common integer sizes
	BOOST_CHECK_EQUAL(typeToString(intTy(8)), "i8");
	BOOST_CHECK_EQUAL(typeToString(intTy(16)), "i16");
	BOOST_CHECK_EQUAL(typeToString(intTy(32)), "i32");
	BOOST_CHECK_EQUAL(typeToString(intTy(64)), "i64");

	// Test unusual sizes
	BOOST_CHECK_EQUAL(typeToString(intTy(7)), "i7");
	BOOST_CHECK_EQUAL(typeToString(intTy(128)), "i128");
}

BOOST_AUTO_TEST_CASE(ArrayTypeOutput) {
	// Test arrays of basic types
	BOOST_CHECK_EQUAL(typeToString(arrayTy(4, intTy(32))), "[4 x i32]");
	BOOST_CHECK_EQUAL(typeToString(arrayTy(2, floatTy())), "[2 x float]");

	// Test nested arrays
	Type nestedArray = arrayTy(3, arrayTy(2, intTy(8)));
	BOOST_CHECK_EQUAL(typeToString(nestedArray), "[3 x [2 x i8]]");
}

BOOST_AUTO_TEST_CASE(VectorTypeOutput) {
	// Test vectors of basic types
	BOOST_CHECK_EQUAL(typeToString(vecTy(4, intTy(32))), "<4 x i32>");
	BOOST_CHECK_EQUAL(typeToString(vecTy(2, floatTy())), "<2 x float>");

	// Test unusual vector sizes
	BOOST_CHECK_EQUAL(typeToString(vecTy(3, intTy(1))), "<3 x i1>");
}

BOOST_AUTO_TEST_CASE(StructTypeOutput) {
	std::vector<Type> fields;

	// Test empty struct
	BOOST_CHECK_EQUAL(typeToString(structTy(fields)), "{}");

	// Test simple struct
	fields.push_back(intTy(32));
	fields.push_back(floatTy());
	BOOST_CHECK_EQUAL(typeToString(structTy(fields)), "{i32, float}");

	// Test nested struct
	std::vector<Type> innerFields;
	innerFields.push_back(intTy(8));
	innerFields.push_back(doubleTy());
	fields.push_back(structTy(innerFields));
	BOOST_CHECK_EQUAL(typeToString(structTy(fields)), "{i32, float, {i8, double}}");
}

BOOST_AUTO_TEST_CASE(FuncTypeOutput) {
	std::vector<Type> params;

	// Test function with no parameters
	params.push_back(voidTy()); // return type
	BOOST_CHECK_EQUAL(typeToString(fnTy(params)), "void ()");

	// Test function with basic parameters
	params.push_back(intTy(32));
	params.push_back(floatTy());
	BOOST_CHECK_EQUAL(typeToString(fnTy(params)), "void (i32, float)");

	// Test function returning non-void
	params[0] = ptrTy();
	BOOST_CHECK_EQUAL(typeToString(fnTy(params)), "ptr (i32, float)");

	// Test function with complex parameter types
	params.push_back(arrayTy(4, intTy(8)));
	BOOST_CHECK_EQUAL(typeToString(fnTy(params)), "ptr (i32, float, [4 x i8])");
}

BOOST_AUTO_TEST_CASE(ComplexTypeOutput) {
	// Test combination of various type constructs
	std::vector<Type> fields;
	fields.push_back(arrayTy(2, vecTy(4, intTy(32))));
	fields.push_back(ptrTy());

	std::vector<Type> funcParams;
	funcParams.push_back(structTy(fields)); // return type
	funcParams.push_back(doubleTy());
	funcParams.push_back(arrayTy(3, floatTy()));

	Type complexType = fnTy(funcParams);

	BOOST_CHECK_EQUAL(typeToString(complexType), "{[2 x <4 x i32>], ptr} (double, [3 x float])");
}
