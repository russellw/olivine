#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(FuncOperatorTests)

// Helper function to get string output of a Func
string toString(const Fn& f) {
	std::ostringstream oss;
	oss << f;
	return oss.str();
}

BOOST_AUTO_TEST_CASE(EmptyFunctionDeclaration) {
	// Test a simple void function declaration with no parameters
	auto f = Fn(voidTy(), Ref("empty"), vector<Term>{});
	BOOST_CHECK_EQUAL(toString(f), "declare void @empty()");
}

BOOST_AUTO_TEST_CASE(SimpleIntFunctionDeclaration) {
	// Test an int32 function declaration with one parameter
	vector<Term> params = {var(intTy(32), Ref(0))};
	auto f = Fn(intTy(32), Ref("simple"), params);
	BOOST_CHECK_EQUAL(toString(f), "declare i32 @simple(i32 %0)");
}

BOOST_AUTO_TEST_CASE(MultiParamFunctionDeclaration) {
	// Test function with multiple parameters of different types
	vector<Term> params = {var(intTy(32), Ref(0)), var(ptrTy(), Ref(1)), var(doubleTy(), Ref(2))};
	auto f = Fn(intTy(64), Ref("multi"), params);
	BOOST_CHECK_EQUAL(toString(f), "declare i64 @multi(i32 %0, ptr %1, double %2)");
}

BOOST_AUTO_TEST_CASE(EmptyFunctionDefinition) {
	// Test a function definition with no parameters and empty body
	vector<Term> params;
	vector<Inst> body;
	auto f = Fn(voidTy(), Ref("empty_def"), params, body);
	BOOST_CHECK_EQUAL(toString(f), "declare void @empty_def()");
}

BOOST_AUTO_TEST_CASE(SimpleFunctionDefinition) {
	// Test a function definition with one parameter and simple body
	vector<Term> params = {var(intTy(32), Ref(0))};
	vector<Inst> body = {alloca(var(ptrTy(), Ref(1)), intTy(32), intConst(intTy(32), 1)), store(params[0], var(ptrTy(), Ref(1))),
						 ret()};
	auto f = Fn(voidTy(), Ref("simple_def"), params, body);

	string expected = "define void @simple_def(i32 %0) {\n"
					  "  %1 = alloca i32\n"
					  "  store i32 %0, ptr %1\n"
					  "  ret void\n"
					  "}";

	BOOST_CHECK_EQUAL(toString(f), expected);
}

BOOST_AUTO_TEST_CASE(ComplexFunctionDefinition) {
	// Test a function with control flow and multiple blocks
	vector<Term> params = {var(intTy(32), Ref(0))};
	vector<Inst> body = {block(Ref("entry")),
						 alloca(var(ptrTy(), Ref(1)), intTy(32), intConst(intTy(32), 1)),
						 store(params[0], var(ptrTy(), Ref(1))),
						 br(trueConst, Ref("then"), Ref("else")),

						 block(Ref("then")),
						 ret(intConst(intTy(32), 1)),

						 block(Ref("else")),
						 ret(intConst(intTy(32), 0))};

	auto f = Fn(intTy(32), Ref("complex_def"), params, body);

	string expected = "define i32 @complex_def(i32 %0) {\n"
					  "entry:\n"
					  "  %1 = alloca i32\n"
					  "  store i32 %0, ptr %1\n"
					  "  br i1 true, label %then, label %else\n"
					  "then:\n"
					  "  ret i32 1\n"
					  "else:\n"
					  "  ret i32 0\n"
					  "}";

	BOOST_CHECK_EQUAL(toString(f), expected);
}

BOOST_AUTO_TEST_CASE(QuotedFunctionName) {
	// Test function with a name that needs quoting
	auto f = Fn(voidTy(), Ref("1invalid"), vector<Term>{});
	BOOST_CHECK_EQUAL(toString(f), "declare void @\"1invalid\"()");
}

BOOST_AUTO_TEST_CASE(EscapedFunctionName) {
	// Test function with a name that needs escaping
	auto f = Fn(voidTy(), Ref("name\\with\"quotes"), vector<Term>{});
	BOOST_CHECK_EQUAL(toString(f), "declare void @\"name\\\\with\\22quotes\"()");
}

BOOST_AUTO_TEST_SUITE_END()
