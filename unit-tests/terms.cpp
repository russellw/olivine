// Test construction and basic properties of constants
#include "all.h"
#include <boost/test/included/unit_test.hpp>
BOOST_AUTO_TEST_CASE(ConstantTerms) {
	// Test boolean constants
	BOOST_CHECK_EQUAL(trueConst.ty(), boolTy());
	BOOST_CHECK_EQUAL(trueConst.tag(), Int);
	BOOST_CHECK_EQUAL(trueConst.intVal(), 1);

	BOOST_CHECK_EQUAL(falseConst.ty(), boolTy());
	BOOST_CHECK_EQUAL(falseConst.tag(), Int);
	BOOST_CHECK_EQUAL(falseConst.intVal(), 0);

	// Test null constant
	BOOST_CHECK_EQUAL(nullConst.ty(), ptrTy());
	BOOST_CHECK_EQUAL(nullConst.tag(), Null);

	// Test integer constant creation
	Type int32Type = intTy(32);
	cpp_int val(42);
	Term intTerm = intConst(int32Type, val);
	BOOST_CHECK_EQUAL(intTerm.ty(), int32Type);
	BOOST_CHECK_EQUAL(intTerm.tag(), Int);
	BOOST_CHECK_EQUAL(intTerm.intVal(), val);

	// Test float constant creation
	Term floatTerm = floatConst(floatTy(), "3.14");
	BOOST_CHECK_EQUAL(floatTerm.ty(), floatTy());
	BOOST_CHECK_EQUAL(floatTerm.tag(), Float);
	BOOST_CHECK_EQUAL(floatTerm.str(), "3.14");
}

// Test variable creation and properties
BOOST_AUTO_TEST_CASE(Variables) {
	Type int64Type = intTy(64);
	Term var1 = var(int64Type, 1);
	Term var2 = var(int64Type, 2);

	BOOST_CHECK_EQUAL(var1.ty(), int64Type);
	BOOST_CHECK_EQUAL(var1.tag(), Var);
	BOOST_CHECK(var1 != var2);
}

Term compound(Tag tag, const vector<Term>& v) {
	ASSERT(v.size());
	auto ty = v[0].ty();
	return Term(tag, ty, v);
}

// Test arithmetic operations
BOOST_AUTO_TEST_CASE(ArithmeticOperations) {
	Type int32Type = intTy(32);
	Term a = var(int32Type, 1);
	Term b = var(int32Type, 2);

	// Test addition
	vector<Term> addOps = {a, b};
	Term add = compound(Add, addOps);
	BOOST_CHECK_EQUAL(add.ty(), int32Type);
	BOOST_CHECK_EQUAL(add.tag(), Add);
	BOOST_CHECK_EQUAL(add.size(), 2);
	BOOST_CHECK_EQUAL(add[0], a);
	BOOST_CHECK_EQUAL(add[1], b);

	// Test multiplication
	vector<Term> mulOps = {a, b};
	Term mul = compound(Mul, mulOps);
	BOOST_CHECK_EQUAL(mul.ty(), int32Type);
	BOOST_CHECK_EQUAL(mul.tag(), Mul);
	BOOST_CHECK_EQUAL(mul.size(), 2);

	// Test floating point operations
	Term f1 = var(floatTy(), 3);
	Term f2 = var(floatTy(), 4);
	vector<Term> faddOps = {f1, f2};
	Term fadd = compound(FAdd, faddOps);
	BOOST_CHECK_EQUAL(fadd.ty(), floatTy());
	BOOST_CHECK_EQUAL(fadd.tag(), FAdd);

	// Test unary operations
	vector<Term> fnegOps = {f1};
	Term fneg = compound(FNeg, fnegOps);
	BOOST_CHECK_EQUAL(fneg.ty(), floatTy());
	BOOST_CHECK_EQUAL(fneg.tag(), FNeg);
	BOOST_CHECK_EQUAL(fneg.size(), 1);
}

// Test equality comparison
BOOST_AUTO_TEST_CASE(TermEquality) {
	Type int32Type = intTy(32);
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
