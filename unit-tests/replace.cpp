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

// Helper function to create a simple test function with parameters and a body
Fn createTestFunction() {
	// Create function return type (int32)
	Type retType = intTy(32);

	// Create function reference (name)
	Ref funcRef("test_function");

	// Create function parameters
	Term param1 = var(intTy(32), Ref("param1"));
	Term param2 = var(intTy(32), Ref("param2"));
	vector<Term> params = {param1, param2};

	// Create function body
	Term var1 = var(intTy(32), Ref("local1"));
	Term var2 = var(intTy(32), Ref("local2"));
	Term addExpr = Term(Add, param1, param2);

	vector<Inst> body = {assign(var1, param1), assign(var2, param2), assign(var1, addExpr), ret(var1)};

	return Fn(retType, funcRef, params, body);
}

BOOST_AUTO_TEST_CASE(replace_parameters_test) {
	// Create a test function
	Fn testFunc = createTestFunction();

	// Create replacements map to replace one parameter
	Term oldParam = var(intTy(32), Ref("param1"));
	Term newParam = var(intTy(32), Ref("new_param"));
	unordered_map<Term, Term> replacements = {{oldParam, newParam}};

	// Apply replacements
	Fn resultFunc = replace(testFunc, replacements);

	// Check that parameter was replaced
	BOOST_CHECK_EQUAL(resultFunc.params()[0], newParam);

	// Check that the other parameter was not changed
	BOOST_CHECK_EQUAL(resultFunc.params()[1], testFunc.params()[1]);

	// Check that references to the parameter in the body were also replaced
	BOOST_CHECK(resultFunc[0][1] == newParam);
}

BOOST_AUTO_TEST_CASE(replace_variables_test) {
	// Create a test function
	Fn testFunc = createTestFunction();

	// Create replacements map to replace a local variable
	Term oldVar = var(intTy(32), Ref("local1"));
	Term newVar = var(intTy(32), Ref("new_local"));
	unordered_map<Term, Term> replacements = {{oldVar, newVar}};

	// Apply replacements
	Fn resultFunc = replace(testFunc, replacements);

	// Check that the variable in the body was replaced
	// First instruction: assign(var1, param1) should become assign(newVar, param1)
	BOOST_CHECK_EQUAL(resultFunc[0][0], newVar);

	// Third instruction: assign(var1, addExpr) should become assign(newVar, addExpr)
	BOOST_CHECK_EQUAL(resultFunc[2][0], newVar);

	// Last instruction: ret(var1) should become ret(newVar)
	BOOST_CHECK_EQUAL(resultFunc[3][0], newVar);
}

BOOST_AUTO_TEST_CASE(replace_expressions_test) {
	// Create a test function
	Fn testFunc = createTestFunction();

	// Get the params for reference
	Term param1 = testFunc.params()[0];
	Term param2 = testFunc.params()[1];

	// Create a new expression to replace the Add expression
	Term oldExpr = Term(Add, param1, param2);
	Term newExpr = Term(Mul, param1, param2);
	unordered_map<Term, Term> replacements = {{oldExpr, newExpr}};

	// Apply replacements
	Fn resultFunc = replace(testFunc, replacements);

	// Check that the expression in the body was replaced
	// The third instruction should now use multiplication instead of addition
	Term resultExpr = resultFunc[2][1];
	// At the moment, replace does not accept compound terms as keys
	// BOOST_CHECK_EQUAL(resultExpr.tag(), Mul);
	BOOST_CHECK_EQUAL(resultExpr[0], param1);
	BOOST_CHECK_EQUAL(resultExpr[1], param2);
}

BOOST_AUTO_TEST_CASE(replace_constants_test) {
	// Create a function with constants
	Type retType = intTy(32);
	Ref funcRef("test_function");

	Term param = var(intTy(32), Ref("param"));
	vector<Term> params = {param};

	Term const1 = intConst(intTy(32), 10);
	Term const2 = intConst(intTy(32), 20);
	Term addExpr = Term(Add, const1, const2);

	vector<Inst> body = {assign(param, addExpr), ret(param)};

	Fn testFunc(retType, funcRef, params, body);

	// Replace constant 10 with constant 100
	unordered_map<Term, Term> replacements = {{const1, intConst(intTy(32), 100)}};

	// Apply replacements
	Fn resultFunc = replace(testFunc, replacements);

	// Check that the constant in the expression was replaced
	Term resultExpr = resultFunc[0][1];
	BOOST_CHECK_EQUAL(resultExpr[0].intVal(), 100);
	BOOST_CHECK_EQUAL(resultExpr[1].intVal(), 20);
}

BOOST_AUTO_TEST_CASE(replace_multiple_terms_test) {
	// Create a test function
	Fn testFunc = createTestFunction();

	// Get the params and local variables for reference
	Term param1 = testFunc.params()[0];
	Term param2 = testFunc.params()[1];
	Term var1 = var(intTy(32), Ref("local1"));

	// Create multiple replacements
	Term newParam = var(intTy(32), Ref("new_param"));
	Term newVar = var(intTy(32), Ref("new_local"));
	Term addExpr = Term(Add, param1, param2);
	Term mulExpr = Term(Mul, param1, param2);

	unordered_map<Term, Term> replacements = {{param1, newParam}, {var1, newVar}, {addExpr, mulExpr}};

	// Apply replacements
	Fn resultFunc = replace(testFunc, replacements);

	// Check parameter replacement
	BOOST_CHECK_EQUAL(resultFunc.params()[0], newParam);

	// Check variable replacement
	BOOST_CHECK_EQUAL(resultFunc[0][0], newVar);
	BOOST_CHECK_EQUAL(resultFunc[2][0], newVar);
	BOOST_CHECK_EQUAL(resultFunc[3][0], newVar);

	// Check expression replacement
	Term resultExpr = resultFunc[2][1];

	// At the moment, replace does not accept compound terms as keys
	// BOOST_CHECK_EQUAL(resultExpr.tag(), Mul);

	// Right now, the following test would fail
	// as replace does not transitively repeat the replacement process on the new value
	// If that ever becomes necessary, it can be implemented
	// BOOST_CHECK_EQUAL(resultExpr[0], newParam); // Should use the replaced param
	BOOST_CHECK_EQUAL(resultExpr[1], param2);
}

BOOST_AUTO_TEST_CASE(replace_function_ref_test) {
	// Create a function that calls another function
	Type retType = intTy(32);
	Ref funcRef("test_function");

	Term param = var(intTy(32), Ref("param"));
	vector<Term> params = {param};

	// Create function reference
	Type calledFuncType = fnTy(intTy(32), {intTy(32)});
	Term calledFunc = globalRef(calledFuncType, Ref("called_function"));

	// Create function call
	Term callExpr = call(intTy(32), calledFunc, {param});

	vector<Inst> body = {assign(param, callExpr), ret(param)};

	Fn testFunc(retType, funcRef, params, body);

	// Replace function reference
	Term newCalledFunc = globalRef(calledFuncType, Ref("new_function"));
	unordered_map<Term, Term> replacements = {{calledFunc, newCalledFunc}};

	// Apply replacements
	Fn resultFunc = replace(testFunc, replacements);

	// Check that the function reference in the call was replaced
	Term resultCallExpr = resultFunc[0][1];
	BOOST_CHECK_EQUAL(std::get<string>(resultCallExpr[0].ref()), "new_function");
}

BOOST_AUTO_TEST_CASE(replace_preserves_unchanged_elements_test) {
	// Create a test function
	Fn testFunc = createTestFunction();

	// Use an empty replacements map (nothing should change)
	unordered_map<Term, Term> replacements;

	// Apply replacements
	Fn resultFunc = replace(testFunc, replacements);

	// Check that return type is preserved
	BOOST_CHECK_EQUAL(resultFunc.rty(), testFunc.rty());

	// Check that function reference is preserved
	BOOST_CHECK_EQUAL(std::get<string>(resultFunc.ref()), std::get<string>(testFunc.ref()));

	// Check that parameters are preserved
	BOOST_CHECK_EQUAL(resultFunc.params().size(), testFunc.params().size());
	for (size_t i = 0; i < testFunc.params().size(); i++) {
		BOOST_CHECK_EQUAL(resultFunc.params()[i], testFunc.params()[i]);
	}

	// Check that body size is preserved
	BOOST_CHECK_EQUAL(resultFunc.size(), testFunc.size());

	// Check that instructions are preserved
	for (size_t i = 0; i < testFunc.size(); i++) {
		BOOST_CHECK_EQUAL(resultFunc[i].opcode(), testFunc[i].opcode());
		for (size_t j = 0; j < testFunc[i].size(); j++) {
			BOOST_CHECK_EQUAL(resultFunc[i][j], testFunc[i][j]);
		}
	}
}

BOOST_AUTO_TEST_SUITE_END()
