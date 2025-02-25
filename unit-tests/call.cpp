// Test suite for call function
#include "all.h"
#include <boost/test/included/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(CallTests)

BOOST_AUTO_TEST_CASE(call_no_args) {
	Type returnType = intTy(32);
	Term func = var(fnTy(returnType, {}), Ref("main"));
	vector<Term> emptyArgs;

	Term result = call(returnType, func, emptyArgs);

	BOOST_CHECK_EQUAL(result.tag(), Call);
	BOOST_CHECK_EQUAL(result.ty(), returnType);
	BOOST_CHECK_EQUAL(result.size(), 1);
	BOOST_CHECK_EQUAL(result[0], func);
}

BOOST_AUTO_TEST_CASE(call_with_args) {
	Type returnType = intTy(32);
	Type paramType = intTy(32);
	vector<Type> paramTypes{paramType, paramType};

	Term func = var(fnTy(returnType, paramTypes), Ref("add"));
	Term arg1 = intConst(paramType, cpp_int(1));
	Term arg2 = intConst(paramType, cpp_int(2));
	vector<Term> args{arg1, arg2};

	Term result = call(returnType, func, args);

	BOOST_CHECK_EQUAL(result.tag(), Call);
	BOOST_CHECK_EQUAL(result.ty(), returnType);
	BOOST_CHECK_EQUAL(result.size(), 3);
	BOOST_CHECK_EQUAL(result[0], func);
	BOOST_CHECK_EQUAL(result[1], arg1);
	BOOST_CHECK_EQUAL(result[2], arg2);
}

BOOST_AUTO_TEST_CASE(call_preserves_args) {
	Type returnType = intTy(32);
	Type paramType = intTy(32);
	Term func = var(fnTy(returnType, {paramType}), Ref("inc"));

	vector<Term> originalArgs{intConst(paramType, cpp_int(42))};
	vector<Term> argsCopy = originalArgs;

	Term result = call(returnType, func, originalArgs);

	BOOST_CHECK_EQUAL_COLLECTIONS(originalArgs.begin(), originalArgs.end(), argsCopy.begin(), argsCopy.end());
}

BOOST_AUTO_TEST_CASE(call_void_return) {
	Type vTy = voidTy();
	Term func = var(fnTy(vTy, {}), Ref("exit"));
	vector<Term> emptyArgs;

	Term result = call(vTy, func, emptyArgs);

	BOOST_CHECK_EQUAL(result.tag(), Call);
	BOOST_CHECK_EQUAL(result.ty(), vTy);
	BOOST_CHECK_EQUAL(result.size(), 1);
	BOOST_CHECK_EQUAL(result[0], func);
}

BOOST_AUTO_TEST_SUITE_END()
