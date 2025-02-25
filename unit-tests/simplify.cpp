// Helper function to create test environment
#include "all.h"
#include <boost/test/included/unit_test.hpp>
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
	Term intTerm = intConst(intTy(32), 42);
	Term floatTerm = floatConst(floatTy(), "3.14");

	unordered_map<Term, Term> emptyEnv;
	BOOST_CHECK_EQUAL(simplify(emptyEnv, nullTerm), nullTerm);
	BOOST_CHECK_EQUAL(simplify(emptyEnv, intTerm), intTerm);
	BOOST_CHECK_EQUAL(simplify(emptyEnv, floatTerm), floatTerm);

	// Variables should be looked up in environment
	Term var1 = var(intTy(32), 1);
	Term val1 = intConst(intTy(32), 123);
	auto env = makeEnv({{var1, val1}});

	BOOST_CHECK_EQUAL(simplify(env, var1), val1);
	BOOST_CHECK_EQUAL(simplify(emptyEnv, var1), var1); // Not in environment
}

BOOST_AUTO_TEST_CASE(basic_arithmetic) {
	unordered_map<Term, Term> emptyEnv;
	Type i32 = intTy(32);

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
	Type i32 = intTy(32);

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
	Type i32 = intTy(32);

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
	Type i32 = intTy(32);

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
	Type i32 = intTy(32);

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
	Term a = floatConst(floatTy(), "3.14");
	Term b = floatConst(floatTy(), "2.0");

	Term fadd = compound(FAdd, {a, b});
	BOOST_CHECK(simplify(emptyEnv, fadd).tag() == FAdd);

	Term fmul = compound(FMul, {a, b});
	BOOST_CHECK(simplify(emptyEnv, fmul).tag() == FMul);

	Term fneg = compound(FNeg, {a});
	BOOST_CHECK(simplify(emptyEnv, fneg).tag() == FNeg);
}

BOOST_AUTO_TEST_CASE(complex_expressions) {
	unordered_map<Term, Term> emptyEnv;
	Type i32 = intTy(32);

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
	Type i32 = intTy(32);

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
