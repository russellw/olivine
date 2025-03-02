#include "all.h"
#include <boost/test/unit_test.hpp>

// Assuming necessary headers are included and Term-related functions are available

BOOST_AUTO_TEST_SUITE(ReplaceTestSuite)

// Test replacing a simple variable
BOOST_AUTO_TEST_CASE(ReplaceVariable) {
	// Create test data
	Type intType = intTy(32);
	Term var1 = var(intType, "x");
	Term var2 = var(intType, "y");

	// Create replacement map
	unordered_map<Term, Term> replacements;
	replacements[var1] = var2;

	// Apply replacement
	Term result = replace(var1, replacements);

	// Verify result
	BOOST_CHECK_EQUAL(result, var2);
}

// Test replacing in an arithmetic expression
BOOST_AUTO_TEST_CASE(ReplaceInExpression) {
	// Create test data
	Type intType = intTy(32);
	Term var1 = var(intType, "x");
	Term var2 = var(intType, "y");
	Term constant = intConst(intType, 5);

	// Create an expression: x + 5
	Term expr = Term(Add, intType, var1, constant);

	// Create replacement map: x -> y
	unordered_map<Term, Term> replacements;
	replacements[var1] = var2;

	// Apply replacement
	Term result = replace(expr, replacements);

	// Expected result: y + 5
	Term expected = Term(Add, intType, var2, constant);

	// Verify result
	BOOST_CHECK_EQUAL(result, expected);
}

// Test multiple replacements in a nested expression
BOOST_AUTO_TEST_CASE(MultipleReplacements) {
	// Create test data
	Type intType = intTy(32);
	Term var1 = var(intType, "x");
	Term var2 = var(intType, "y");
	Term var3 = var(intType, "z");
	Term constant = intConst(intType, 10);

	// Create a nested expression: (x + y) * z
	Term sum = Term(Add, intType, var1, var2);
	Term expr = Term(Mul, intType, sum, var3);

	// Create replacement map: x -> 10, z -> y
	unordered_map<Term, Term> replacements;
	replacements[var1] = constant;
	replacements[var3] = var2;

	// Apply replacement
	Term result = replace(expr, replacements);

	// Expected result: (10 + y) * y
	Term expectedSum = Term(Add, intType, constant, var2);
	Term expected = Term(Mul, intType, expectedSum, var2);

	// Verify result
	BOOST_CHECK_EQUAL(result, expected);
}

// Test replacing a term with a more complex term
BOOST_AUTO_TEST_CASE(ReplaceWithComplexTerm) {
	// Create test data
	Type intType = intTy(32);
	Term var1 = var(intType, "x");
	Term var2 = var(intType, "y");
	Term var3 = var(intType, "z");

	// Create a complex term to replace with: y + z
	Term complexTerm = Term(Add, intType, var2, var3);

	// Create an expression using var1: x * x
	Term expr = Term(Mul, intType, var1, var1);

	// Create replacement map: x -> (y + z)
	unordered_map<Term, Term> replacements;
	replacements[var1] = complexTerm;

	// Apply replacement
	Term result = replace(expr, replacements);

	// Expected result: (y + z) * (y + z)
	Term expected = Term(Mul, intType, complexTerm, complexTerm);

	// Verify result
	BOOST_CHECK_EQUAL(result, expected);
}

// Test replacing in a function call
BOOST_AUTO_TEST_CASE(ReplaceInFunctionCall) {
	// Create test data
	Type intType = intTy(32);
	Type fnType = fnTy(intType, {intType, intType});

	Term func = globalRef(fnType, "add_func");
	Term var1 = var(intType, "x");
	Term var2 = var(intType, "y");
	Term constant = intConst(intType, 42);

	// Create function call: add_func(x, y)
	vector<Term> args = {var1, var2};
	Term call_expr = call(intType, func, args);

	// Create replacement map: y -> 42
	unordered_map<Term, Term> replacements;
	replacements[var2] = constant;

	// Apply replacement
	Term result = replace(call_expr, replacements);

	// Expected result: add_func(x, 42)
	vector<Term> expected_args = {var1, constant};
	Term expected = call(intType, func, expected_args);

	// Verify result
	BOOST_CHECK_EQUAL(result, expected);
}

// Test that no replacement occurs when no match is found
BOOST_AUTO_TEST_CASE(NoReplacementWhenNoMatch) {
	// Create test data
	Type intType = intTy(32);
	Term var1 = var(intType, "x");
	Term var2 = var(intType, "y");
	Term var3 = var(intType, "z");

	// Create expression: x + z
	Term expr = Term(Add, intType, var1, var3);

	// Create replacement map that doesn't match any variables in the expression
	unordered_map<Term, Term> replacements;
	replacements[var2] = intConst(intType, 5);

	// Apply replacement
	Term result = replace(expr, replacements);

	// Expected result: Original expression unchanged
	BOOST_CHECK_EQUAL(result, expr);
}

// Test replacing with null/none terms
BOOST_AUTO_TEST_CASE(ReplaceWithNoneTerm) {
	// Create test data
	Type intType = intTy(32);
	Term var1 = var(intType, "x");
	Term noneTerm = none(intType);

	// Create an expression: x + x
	Term expr = Term(Add, intType, var1, var1);

	// Create replacement map: x -> none
	unordered_map<Term, Term> replacements;
	replacements[var1] = noneTerm;

	// Apply replacement
	Term result = replace(expr, replacements);

	// Expected result: none + none
	Term expected = Term(Add, intType, noneTerm, noneTerm);

	// Verify result
	BOOST_CHECK_EQUAL(result, expected);
}

// Test replacing in a more complex data structure (array)
BOOST_AUTO_TEST_CASE(ReplaceInArray) {
	// Create test data
	Type intType = intTy(32);
	Term var1 = var(intType, "x");
	Term var2 = var(intType, "y");
	Term constant = intConst(intType, 7);

	// Create an array: [x, y, x]
	vector<Term> elements = {var1, var2, var1};
	Term arrayTerm = array(intType, elements);

	// Create replacement map: x -> 7
	unordered_map<Term, Term> replacements;
	replacements[var1] = constant;

	// Apply replacement
	Term result = replace(arrayTerm, replacements);

	// Expected result: [7, y, 7]
	vector<Term> expectedElements = {constant, var2, constant};
	Term expected = array(intType, expectedElements);

	// Verify result
	BOOST_CHECK_EQUAL(result, expected);
}

// Test efficiency by verifying that we don't recreate a term unnecessarily
BOOST_AUTO_TEST_CASE(EfficientNoChangeOptimization) {
	// Create test data
	Type intType = intTy(32);
	Term var1 = var(intType, "x");
	Term var2 = var(intType, "y");

	// Create expression: x + y
	Term expr = Term(Add, intType, var1, var2);

	// Create replacement map that doesn't affect this expression
	unordered_map<Term, Term> replacements;
	replacements[var(intType, "z")] = intConst(intType, 5);

	// Apply replacement
	Term result = replace(expr, replacements);

	// Not just checking equality but checking they are the same object
	// This would ideally check that result and expr have the same address,
	// but since Term uses opaque pointers we rely on equality instead
	BOOST_CHECK_EQUAL(result, expr);
}

BOOST_AUTO_TEST_SUITE_END()
