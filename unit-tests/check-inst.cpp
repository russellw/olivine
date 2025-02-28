#include "all.h"
#include <boost/test/unit_test.hpp>

// Helper functions to create test values
Term makeIntVar(const string& name, size_t bits = 32) {
	return var(intTy(bits), Ref(name));
}

Term makePtrVar(const string& name) {
	return var(ptrTy(), Ref(name));
}

Term makeLabel(const string& name) {
	return label(Ref(name));
}

BOOST_AUTO_TEST_SUITE(InstructionCheckerTests)

BOOST_AUTO_TEST_CASE(test_alloca) {
	// Valid alloca
	Term ptr = makePtrVar("ptr");
	Term type = zeroVal(intTy(32));
	Term size = intConst(intTy(32), 1);
	Inst valid = alloca(ptr, intTy(32), size);
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands
	Inst tooFew(Alloca, {ptr, type});
	BOOST_CHECK_THROW(check(tooFew), runtime_error);

	// First operand not a variable
	Inst badFirst = alloca(intConst(intTy(32), 0), intTy(32), size);
	BOOST_CHECK_THROW(check(badFirst), runtime_error);

	// Second operand
	Inst badSecond = Inst(Alloca, ptr, intConst(intTy(32), 1), size);
	BOOST_CHECK_THROW(check(badSecond), runtime_error);

	// Third operand not an integer
	Term floatSize = floatConst(floatTy(), "1.0");
	Inst badThird = Inst(Alloca, ptr, type, floatSize);
	BOOST_CHECK_THROW(check(badThird), runtime_error);

	// Result not a pointer type
	Term intResult = makeIntVar("result");
	Inst badResult = Inst(Alloca, intResult, type, size);
	BOOST_CHECK_THROW(check(badResult), runtime_error);
}

BOOST_AUTO_TEST_CASE(test_assign) {
	// Valid assignment
	Term lhs = makeIntVar("x");
	Term rhs = intConst(intTy(32), 42);
	Inst valid(Assign, {lhs, rhs});
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands
	Inst tooFew(Assign, {lhs});
	BOOST_CHECK_THROW(check(tooFew), runtime_error);

	// Left hand side not a variable
	Inst badLhs(Assign, {intConst(intTy(32), 0), rhs});
	BOOST_CHECK_THROW(check(badLhs), runtime_error);

	// Mismatched types
	Term floatRhs = floatConst(floatTy(), "42.0");
	Inst mismatch(Assign, {lhs, floatRhs});
	BOOST_CHECK_THROW(check(mismatch), runtime_error);
}

BOOST_AUTO_TEST_CASE(test_block) {
	// Valid block
	Inst valid = block(Ref("L1"));
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands
	Inst tooMany(Block, {makeLabel("L1"), makeLabel("L2")});
	BOOST_CHECK_THROW(check(tooMany), runtime_error);

	// Not a label
	Inst notLabel(Block, {makeIntVar("x")});
	BOOST_CHECK_THROW(check(notLabel), runtime_error);
}

BOOST_AUTO_TEST_CASE(test_br) {
	// Valid branch
	Term cond = var(boolTy(), Ref("cond"));
	Term thenLabel = makeLabel("then");
	Term elseLabel = makeLabel("else");
	Inst valid = br(cond, thenLabel, elseLabel);
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands
	Inst tooFew(Br, {cond, thenLabel});
	BOOST_CHECK_THROW(check(tooFew), runtime_error);

	// Condition not boolean
	Term intCond = makeIntVar("x");
	Inst badCond = br(intCond, thenLabel, elseLabel);
	BOOST_CHECK_THROW(check(badCond), runtime_error);

	// Targets not labels
	Term notLabel = makeIntVar("x");
	Inst badTarget = br(cond, notLabel, elseLabel);
	BOOST_CHECK_THROW(check(badTarget), runtime_error);
}

BOOST_AUTO_TEST_CASE(test_jmp) {
	// Valid jump
	Inst valid = jmp(makeLabel("L1"));
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands
	Inst tooMany(Jmp, {makeLabel("L1"), makeLabel("L2")});
	BOOST_CHECK_THROW(check(tooMany), runtime_error);

	// Target not a label
	Inst badTarget = jmp(makeIntVar("x"));
	BOOST_CHECK_THROW(check(badTarget), runtime_error);
}

BOOST_AUTO_TEST_CASE(test_phi) {
	// Valid phi
	Term result = makeIntVar("x");
	Term val1 = intConst(intTy(32), 1);
	Term val2 = intConst(intTy(32), 2);
	Term label1 = makeLabel("L1");
	Term label2 = makeLabel("L2");
	Inst valid(Phi, {result, val1, label1, val2, label2});
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands (must be 1 + 2n where n >= 1)
	Inst tooFew(Phi, {result, val1});
	BOOST_CHECK_THROW(check(tooFew), runtime_error);

	// First operand not a variable
	Inst badFirst(Phi, {intConst(intTy(32), 0), val1, label1, val2, label2});
	BOOST_CHECK_THROW(check(badFirst), runtime_error);

	// Value type mismatch
	Term floatVal = floatConst(floatTy(), "1.0");
	Inst typeMismatch(Phi, {result, floatVal, label1, val2, label2});
	BOOST_CHECK_THROW(check(typeMismatch), runtime_error);

	// Label operand not a label
	Inst badLabel(Phi, {result, val1, makeIntVar("x"), val2, label2});
	BOOST_CHECK_THROW(check(badLabel), runtime_error);
}

BOOST_AUTO_TEST_CASE(test_ret) {
	// Valid return
	Term val = intConst(intTy(32), 42);
	Inst valid(Ret, {val});
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands
	Inst tooMany(Ret, {val, val});
	BOOST_CHECK_THROW(check(tooMany), runtime_error);
}

BOOST_AUTO_TEST_CASE(test_ret_void) {
	// Valid void return
	Inst valid(RetVoid);
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands
	Inst tooMany(RetVoid, {intConst(intTy(32), 0)});
	BOOST_CHECK_THROW(check(tooMany), runtime_error);
}

BOOST_AUTO_TEST_CASE(test_store) {
	// Valid store
	Term val = intConst(intTy(32), 42);
	Term ptr = makePtrVar("ptr");
	Inst valid(Store, {val, ptr});
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands
	Inst tooFew(Store, {val});
	BOOST_CHECK_THROW(check(tooFew), runtime_error);

	// Second operand not a pointer
	Term notPtr = makeIntVar("x");
	Inst badPtr(Store, {val, notPtr});
	BOOST_CHECK_THROW(check(badPtr), runtime_error);
}

BOOST_AUTO_TEST_CASE(test_switch) {
	// Valid switch
	Term val = makeIntVar("x");
	Term defaultLabel = makeLabel("default");
	Term case1 = intConst(intTy(32), 1);
	Term label1 = makeLabel("L1");
	Term case2 = intConst(intTy(32), 2);
	Term label2 = makeLabel("L2");
	Inst valid(Switch, {val, defaultLabel, case1, label1, case2, label2});
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands (must be 2 + 2n where n >= 0)
	Inst tooFew(Switch, {val});
	BOOST_CHECK_THROW(check(tooFew), runtime_error);

	// Default target not a label
	Inst badDefault(Switch, {val, makeIntVar("x"), case1, label1});
	BOOST_CHECK_THROW(check(badDefault), runtime_error);

	// Case value type mismatch
	Term floatCase = floatConst(floatTy(), "1.0");
	Inst typeMismatch(Switch, {val, defaultLabel, floatCase, label1});
	BOOST_CHECK_THROW(check(typeMismatch), runtime_error);

	// Case target not a label
	Inst badTarget(Switch, {val, defaultLabel, case1, makeIntVar("x")});
	BOOST_CHECK_THROW(check(badTarget), runtime_error);
}

BOOST_AUTO_TEST_CASE(test_unreachable) {
	// Valid unreachable
	Inst valid(Unreachable);
	BOOST_CHECK_NO_THROW(check(valid));

	// Wrong number of operands
	Inst tooMany(Unreachable, {makeIntVar("x")});
	BOOST_CHECK_THROW(check(tooMany), runtime_error);
}

BOOST_AUTO_TEST_SUITE_END()
