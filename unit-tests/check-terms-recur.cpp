#include "all.h"
#include <boost/test/included/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(RecursiveTermChecker)

// Helper function to create test terms
Term makeIntTerm(int bits, cpp_int value) {
	return intConst(intTy(bits), value);
}

// Test deeply nested arithmetic expressions
BOOST_AUTO_TEST_CASE(NestedArithmeticValid) {
	// Build expression: ((1 + 2) * (3 + 4)) + 5
	auto one = makeIntTerm(32, 1);
	auto two = makeIntTerm(32, 2);
	auto three = makeIntTerm(32, 3);
	auto four = makeIntTerm(32, 4);
	auto five = makeIntTerm(32, 5);

	auto sum1 = Term(Add, intTy(32), one, two);
	auto sum2 = Term(Add, intTy(32), three, four);
	auto product = Term(Mul, intTy(32), sum1, sum2);
	auto final = Term(Add, intTy(32), product, five);

	BOOST_CHECK_NO_THROW(checkRecursive(final));
}

BOOST_AUTO_TEST_CASE(NestedArithmeticInvalid) {
	// Build expression with type mismatch: (32-bit + 64-bit)
	auto a = makeIntTerm(32, 1);
	auto b = makeIntTerm(64, 2);
	auto sum = Term(Add, intTy(32), a, b);

	BOOST_CHECK_THROW(checkRecursive(sum), runtime_error);
}

// Test nested arrays
BOOST_AUTO_TEST_CASE(NestedArrayValid) {
	// Create an array of arrays
	vector<Term> inner1 = {makeIntTerm(32, 1), makeIntTerm(32, 2)};
	vector<Term> inner2 = {makeIntTerm(32, 3), makeIntTerm(32, 4)};

	auto array1 = array(intTy(32), inner1);
	auto array2 = array(intTy(32), inner2);

	vector<Term> outer = {array1, array2};
	auto arrayOfArrays = Term(Array, arrayTy(2, arrayTy(2, intTy(32))), outer);

	BOOST_CHECK_NO_THROW(checkRecursive(arrayOfArrays));
}

BOOST_AUTO_TEST_CASE(NestedArrayInvalid) {
	// Create an array with inconsistent inner array types
	vector<Term> inner1 = {makeIntTerm(32, 1), makeIntTerm(32, 2)};
	vector<Term> inner2 = {makeIntTerm(64, 3), makeIntTerm(64, 4)}; // Different bit width

	auto array1 = array(intTy(32), inner1);
	auto array2 = array(intTy(64), inner2);

	vector<Term> outer = {array1, array2};
	auto arrayOfArrays = Term(Array, arrayTy(2, arrayTy(2, intTy(32))), outer);

	BOOST_CHECK_THROW(checkRecursive(arrayOfArrays), runtime_error);
}

// Test nested tuples
BOOST_AUTO_TEST_CASE(NestedTupleValid) {
	// Create a tuple containing another tuple
	vector<Type> innerTypes = {intTy(32), intTy(32)};
	vector<Term> innerElements = {makeIntTerm(32, 1), makeIntTerm(32, 2)};
	auto innerTuple = Term(Tuple, structTy(innerTypes), innerElements);

	vector<Type> outerTypes = {structTy(innerTypes), intTy(64)};
	vector<Term> outerElements = {innerTuple, makeIntTerm(64, 3)};
	auto outerTuple = Term(Tuple, structTy(outerTypes), outerElements);

	BOOST_CHECK_NO_THROW(checkRecursive(outerTuple));
}

BOOST_AUTO_TEST_CASE(NestedTupleInvalid) {
	// Create a tuple with type mismatch in inner tuple
	vector<Type> innerTypes = {intTy(32), intTy(32)};
	vector<Term> innerElements = {makeIntTerm(32, 1), makeIntTerm(64, 2)}; // Type mismatch
	auto innerTuple = Term(Tuple, structTy(innerTypes), innerElements);

	vector<Type> outerTypes = {structTy(innerTypes), intTy(64)};
	vector<Term> outerElements = {innerTuple, makeIntTerm(64, 3)};
	auto outerTuple = Term(Tuple, structTy(outerTypes), outerElements);

	BOOST_CHECK_THROW(checkRecursive(outerTuple), runtime_error);
}

// Test nested function calls
BOOST_AUTO_TEST_CASE(NestedFunctionCallValid) {
	// Create a function call where one argument is the result of another function call
	vector<Type> innerParamTypes = {intTy(32), intTy(32)};
	Type innerFuncType = fnTy(intTy(32), innerParamTypes);
	Term innerFunc = Term(GlobalRef, innerFuncType, Ref("inner_func"));

	vector<Term> innerArgs = {innerFunc, makeIntTerm(32, 1), makeIntTerm(32, 2)};
	auto innerCall = Term(Call, intTy(32), innerArgs);

	vector<Type> outerParamTypes = {intTy(32)};
	Type outerFuncType = fnTy(intTy(64), outerParamTypes);
	Term outerFunc = Term(GlobalRef, outerFuncType, Ref("outer_func"));

	vector<Term> outerArgs = {outerFunc, innerCall};
	auto outerCall = Term(Call, intTy(64), outerArgs);

	BOOST_CHECK_NO_THROW(checkRecursive(outerCall));
}

BOOST_AUTO_TEST_CASE(NestedFunctionCallInvalid) {
	// Create nested function calls with type mismatch
	vector<Type> innerParamTypes = {intTy(32), intTy(32)};
	Type innerFuncType = fnTy(intTy(64), innerParamTypes); // Returns int64
	Term innerFunc = Term(GlobalRef, innerFuncType, Ref("inner_func"));

	vector<Term> innerArgs = {innerFunc, makeIntTerm(32, 1), makeIntTerm(32, 2)};
	auto innerCall = Term(Call, intTy(64), innerArgs);

	vector<Type> outerParamTypes = {intTy(32)}; // Expects int32
	Type outerFuncType = fnTy(intTy(64), outerParamTypes);
	Term outerFunc = Term(GlobalRef, outerFuncType, Ref("outer_func"));

	vector<Term> outerArgs = {outerFunc, innerCall}; // Type mismatch
	auto outerCall = Term(Call, intTy(64), outerArgs);

	BOOST_CHECK_THROW(checkRecursive(outerCall), runtime_error);
}

// Test complex nested expressions
BOOST_AUTO_TEST_CASE(ComplexNestedExpressionValid) {
	// Create a complex expression with multiple levels of nesting
	// ((array[i + 1] * 2) + func(x, y)) where array is a pointer to int32

	// Create array access
	auto ptr = Term(Var, ptrTy(), Ref("array"));
	auto i = Term(Var, intTy(32), Ref("i"));
	auto one = makeIntTerm(32, 1);
	auto index = Term(Add, intTy(32), i, one);
	auto elemPtr = elementPtr(intTy(32), ptr, index);
	auto arrayElem = Term(Load, intTy(32), elemPtr);

	// Create multiplication
	auto two = makeIntTerm(32, 2);
	auto product = Term(Mul, intTy(32), arrayElem, two);

	// Create function call
	vector<Type> paramTypes = {intTy(32), intTy(32)};
	Type fnType = fnTy(intTy(32), paramTypes);
	Term func = Term(GlobalRef, fnType, Ref("func"));
	Term x = Term(Var, intTy(32), Ref("x"));
	Term y = Term(Var, intTy(32), Ref("y"));
	vector<Term> args = {func, x, y};
	auto funcCall = Term(Call, intTy(32), args);

	// Add everything together
	auto final = Term(Add, intTy(32), product, funcCall);

	BOOST_CHECK_NO_THROW(checkRecursive(final));
}

BOOST_AUTO_TEST_SUITE_END()
