// Test atomic term outputs
#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_CASE(test_atomic_terms) {
	std::ostringstream os;

	// Test float constant
	Term floatTerm = Term(Float, floatTy(), Ref("3.14"));
	os << floatTerm;
	BOOST_CHECK_EQUAL(os.str(), "3.14");
	os.str("");

	// Test integer constant (bool)
	Term boolTerm = intConst(boolTy(), 1);
	os << boolTerm;
	BOOST_CHECK_EQUAL(os.str(), "true");
	os.str("");

	// Test integer constant (non-bool)
	Term intTerm = intConst(intTy(32), 42);
	os << intTerm;
	BOOST_CHECK_EQUAL(os.str(), "42");
	os.str("");

	// Test null constant
	os << nullConst;
	BOOST_CHECK_EQUAL(os.str(), "null");
	os.str("");

	// Test variable reference
	Term varTerm = var(intTy(32), Ref("x"));
	os << varTerm;
	BOOST_CHECK_EQUAL(os.str(), "%x");
}

// Test arithmetic operations
BOOST_AUTO_TEST_CASE(test_arithmetic_operations) {
	std::ostringstream os;

	// Setup operands
	Term a = var(intTy(32), Ref("a"));
	Term b = var(intTy(32), Ref("b"));

	// Test addition
	Term add = Term(Add, intTy(32), a, b);
	os << add;
	BOOST_CHECK_EQUAL(os.str(), "add (i32 %a, i32 %b)");
	os.str("");

	// Test subtraction
	Term sub = Term(Sub, intTy(32), a, b);
	os << sub;
	BOOST_CHECK_EQUAL(os.str(), "sub (i32 %a, i32 %b)");
	os.str("");

	// Test multiplication
	Term mul = Term(Mul, intTy(32), a, b);
	os << mul;
	BOOST_CHECK_EQUAL(os.str(), "mul (i32 %a, i32 %b)");
}

// Test floating-point operations
BOOST_AUTO_TEST_CASE(test_floating_point_operations) {
	std::ostringstream os;

	// Setup operands
	Term a = var(floatTy(), Ref("x"));
	Term b = var(floatTy(), Ref("y"));

	// Test floating-point addition
	Term fadd = Term(FAdd, floatTy(), a, b);
	os << fadd;
	BOOST_CHECK_EQUAL(os.str(), "fadd (float %x, float %y)");
	os.str("");

	// Test floating-point negation (unary)
	Term fneg = Term(FNeg, floatTy(), a);
	os << fneg;
	BOOST_CHECK_EQUAL(os.str(), "fneg (float %x)");
}

// Test comparison operations
BOOST_AUTO_TEST_CASE(test_comparison_operations) {
	std::ostringstream os;

	// Setup operands
	Term a = var(intTy(32), Ref("a"));
	Term b = var(intTy(32), Ref("b"));

	// Test equality comparison
	Term eq = Term(Eq, boolTy(), a, b);
	os << eq;
	BOOST_CHECK_EQUAL(os.str(), "icmp eq (i32 %a, i32 %b)");
	os.str("");

	// Test signed less than or equal
	Term sle = Term(SLe, boolTy(), a, b);
	os << sle;
	BOOST_CHECK_EQUAL(os.str(), "icmp sle (i32 %a, i32 %b)");
	os.str("");

	// Test unsigned less than
	Term ult = Term(ULt, boolTy(), a, b);
	os << ult;
	BOOST_CHECK_EQUAL(os.str(), "icmp ult (i32 %a, i32 %b)");
}

// Test bitwise operations
BOOST_AUTO_TEST_CASE(test_bitwise_operations) {
	std::ostringstream os;

	// Setup operands
	Term a = var(intTy(32), Ref("a"));
	Term b = var(intTy(32), Ref("b"));

	// Test AND
	Term and_op = Term(And, intTy(32), a, b);
	os << and_op;
	BOOST_CHECK_EQUAL(os.str(), "and (i32 %a, i32 %b)");
	os.str("");

	// Test OR
	Term or_op = Term(Or, intTy(32), a, b);
	os << or_op;
	BOOST_CHECK_EQUAL(os.str(), "or (i32 %a, i32 %b)");
	os.str("");

	// Test XOR
	Term xor_op = Term(Xor, intTy(32), a, b);
	os << xor_op;
	BOOST_CHECK_EQUAL(os.str(), "xor (i32 %a, i32 %b)");
	os.str("");

	// Test shift operations
	Term shl = Term(Shl, intTy(32), a, b);
	os << shl;
	BOOST_CHECK_EQUAL(os.str(), "shl (i32 %a, i32 %b)");
	os.str("");

	Term lshr = Term(LShr, intTy(32), a, b);
	os << lshr;
	BOOST_CHECK_EQUAL(os.str(), "lshr (i32 %a, i32 %b)");
}

// Test division operations
BOOST_AUTO_TEST_CASE(test_division_operations) {
	std::ostringstream os;

	// Setup operands
	Term a = var(intTy(32), Ref("a"));
	Term b = var(intTy(32), Ref("b"));

	// Test signed division
	Term sdiv = Term(SDiv, intTy(32), a, b);
	os << sdiv;
	BOOST_CHECK_EQUAL(os.str(), "sdiv (i32 %a, i32 %b)");
	os.str("");

	// Test unsigned division
	Term udiv = Term(UDiv, intTy(32), a, b);
	os << udiv;
	BOOST_CHECK_EQUAL(os.str(), "udiv (i32 %a, i32 %b)");
	os.str("");

	// Test signed remainder
	Term srem = Term(SRem, intTy(32), a, b);
	os << srem;
	BOOST_CHECK_EQUAL(os.str(), "srem (i32 %a, i32 %b)");
	os.str("");

	// Test unsigned remainder
	Term urem = Term(URem, intTy(32), a, b);
	os << urem;
	BOOST_CHECK_EQUAL(os.str(), "urem (i32 %a, i32 %b)");
}
