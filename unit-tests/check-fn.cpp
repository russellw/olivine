#include "all.h"
#include <boost/test/unit_test.hpp>

// Helper functions to create test functions
namespace {
Term createIntVar(string name, size_t bits = 32) {
	return var(intTy(bits), Ref(name));
}

Term createBoolVar(string name) {
	return var(boolTy(), Ref(name));
}

Term createPtrVar(string name) {
	return var(ptrTy(), Ref(name));
}
} // namespace

BOOST_AUTO_TEST_CASE(ValidSimpleFunction) {
	// Create a simple function that takes an int and returns an int
	vector<Term> params = {createIntVar("x")};
	vector<Inst> body = {
		block(Ref("entry")),
		ret(params[0]) // Just return the parameter
	};

	Fn f(intTy(32), Ref("simple"), params, body);

	// Should not throw
	BOOST_CHECK_NO_THROW(check(f));
}

BOOST_AUTO_TEST_CASE(ValidVoidFunction) {
	vector<Term> params = {};
	vector<Inst> body = {block(Ref("entry")), ret()};

	Fn f(voidTy(), Ref("void_func"), params, body);

	BOOST_CHECK_NO_THROW(check(f));
}

BOOST_AUTO_TEST_CASE(ValidFunctionWithBranching) {
	vector<Term> params = {createBoolVar("cond")};
	vector<Inst> body = {block(Ref("entry")), br(params[0], Ref("then"), Ref("else")), block(Ref("then")),
		ret(intConst(intTy(32), 1)), block(Ref("else")), ret(intConst(intTy(32), 0))};

	Fn f(intTy(32), Ref("branching"), params, body);

	BOOST_CHECK_NO_THROW(check(f));
}

BOOST_AUTO_TEST_CASE(ValidFunctionWithAlloca) {
	vector<Term> params = {};
	vector<Inst> body = {block(Ref("entry")), alloca(createPtrVar("ptr"), intTy(32), intConst(intTy(32), 1)), ret()};

	Fn f(voidTy(), Ref("alloca_func"), params, body);

	BOOST_CHECK_NO_THROW(check(f));
}

BOOST_AUTO_TEST_CASE(InvalidReturnType) {
	vector<Term> params = {};
	vector<Inst> body = {
		block(Ref("entry")), ret(intConst(intTy(32), 0)) // Returning int from void function
	};

	Fn f(voidTy(), Ref("invalid_ret"), params, body);

	BOOST_CHECK_THROW(check(f), runtime_error);
}

BOOST_AUTO_TEST_CASE(InvalidBranchCondition) {
	vector<Term> params = {createIntVar("not_bool")};								   // Int instead of bool
	vector<Inst> body = {block(Ref("entry")), br(params[0], Ref("then"), Ref("else")), // Using int as condition
		block(Ref("then")), ret(intConst(intTy(32), 1)), block(Ref("else")), ret(intConst(intTy(32), 0))};

	Fn f(intTy(32), Ref("invalid_branch"), params, body);

	BOOST_CHECK_THROW(check(f), runtime_error);
}

BOOST_AUTO_TEST_CASE(UndefinedLabel) {
	vector<Term> params = {};
	vector<Inst> body = {
		block(Ref("entry")),
		jmp(Ref("nonexistent")) // Jump to undefined label
	};

	Fn f(voidTy(), Ref("undefined_label"), params, body);

	BOOST_CHECK_THROW(check(f), runtime_error);
}

BOOST_AUTO_TEST_CASE(InvalidPhiInstruction) {
	vector<Term> params = {};
	Term result = createIntVar("result");
	vector<Inst> body = {block(Ref("entry")),
		Inst(Phi, {result, intConst(intTy(32), 1), label(Ref("l1")), intConst(intTy(32), 2), label(Ref("l2"))}), ret(result)};

	Fn f(intTy(32), Ref("phi_func"), params, body);

	BOOST_CHECK_THROW(check(f), runtime_error);
}

BOOST_AUTO_TEST_CASE(InconsistentVariableTypes) {
	vector<Term> params = {createIntVar("x", 32)};
	vector<Inst> body = {block(Ref("entry")),
		// Try to assign 64-bit integer to 32-bit variable
		assign(params[0], intConst(intTy(64), 42)), ret(params[0])};

	Fn f(intTy(32), Ref("inconsistent_types"), params, body);

	BOOST_CHECK_THROW(check(f), runtime_error);
}

BOOST_AUTO_TEST_CASE(ValidStore) {
	vector<Term> params = {createPtrVar("ptr"), createIntVar("val")};
	vector<Inst> body = {block(Ref("entry")), store(params[1], params[0]), ret()};

	Fn f(voidTy(), Ref("valid_store"), params, body);

	BOOST_CHECK_NO_THROW(check(f));
}

BOOST_AUTO_TEST_CASE(InvalidStore) {
	vector<Term> params = {createIntVar("not_ptr"), createIntVar("val")};
	vector<Inst> body = {block(Ref("entry")), store(params[1], params[0]), // First param should be a pointer
		ret()};

	Fn f(voidTy(), Ref("invalid_store"), params, body);

	BOOST_CHECK_THROW(check(f), runtime_error);
}

BOOST_AUTO_TEST_CASE(ValidComplexFunction) {
	// Test a more complex function with multiple blocks, variables and operations
	vector<Term> params = {createIntVar("x"), createIntVar("y")};
	Term result = createIntVar("result");
	Term temp = createIntVar("temp");
	vector<Inst> body = {block(Ref("entry")), assign(temp, Term(Add, intTy(32), params[0], params[1])),
		br(Term(Eq, boolTy(), temp, intConst(intTy(32), 0)), Ref("zero"), Ref("nonzero")),

		block(Ref("zero")), assign(result, intConst(intTy(32), 42)), jmp(Ref("exit")),

		block(Ref("nonzero")), assign(result, temp), jmp(Ref("exit")),

		block(Ref("exit")), ret(result)};

	Fn f(intTy(32), Ref("complex"), params, body);

	BOOST_CHECK_NO_THROW(check(f));
}

BOOST_AUTO_TEST_CASE(EmptyFunction) {
	vector<Term> params = {};
	vector<Inst> body = {}; // Empty body

	Fn f(voidTy(), Ref("empty"), params, body);

	// Empty function should be invalid
	BOOST_CHECK_THROW(check(f), runtime_error);
}

BOOST_AUTO_TEST_CASE(MissingReturn) {
	vector<Term> params = {createIntVar("x")};
	vector<Inst> body = {
		block(Ref("entry")), assign(createIntVar("y"), params[0])
		// Missing return instruction
	};

	Fn f(intTy(32), Ref("no_return"), params, body);

	BOOST_CHECK_THROW(check(f), runtime_error);
}
