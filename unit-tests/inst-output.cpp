#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(InstStreamOperatorTests)

// Helper function to compare instruction string output
std::string instToString(const Inst& inst) {
	std::ostringstream oss;
	oss << inst;
	return oss.str();
}

BOOST_AUTO_TEST_CASE(EmptyInstructions) {
	// Test ret void
	Inst retVoid(RetVoid);
	BOOST_CHECK_EQUAL(instToString(retVoid), "ret void");

	// Test unreachable
	Inst unreachableInst(Unreachable);
	BOOST_CHECK_EQUAL(instToString(unreachableInst), "unreachable");
}

BOOST_AUTO_TEST_CASE(AllocaInstruction) {
	// Test alloca with constant size
	Term var1 = var(ptrTy(), Ref("ptr"));
	Term type = zeroVal(intTy(32));
	Term size = intConst(intTy(32), 1);
	Inst allocaInst = alloca(var1, type.ty(), size);

	BOOST_CHECK_EQUAL(instToString(allocaInst), "%ptr = alloca i32");
}

BOOST_AUTO_TEST_CASE(AssignInstruction) {
	// Test simple assignment
	Term lhs = var(intTy(32), Ref("result"));
	Term rhs = intConst(intTy(32), 42);
	Inst assignInst = assign(lhs, rhs);

	BOOST_CHECK_EQUAL(instToString(assignInst), "%result = i32 42");
}

BOOST_AUTO_TEST_CASE(BlockInstruction) {
	// Test block label
	Inst blockInst = block(Ref("entry"));
	BOOST_CHECK_EQUAL(instToString(blockInst), "entry:");
}

BOOST_AUTO_TEST_CASE(BranchInstructions) {
	// Test conditional branch
	Term cond = var(boolTy(), Ref("cond"));
	Inst brInst = br(cond, Ref("true_bb"), Ref("false_bb"));
	BOOST_CHECK_EQUAL(instToString(brInst), "br i1 %cond, label %true_bb, label %false_bb");

	// Test unconditional branch
	Inst jmpInst = jmp(Ref("target_bb"));
	BOOST_CHECK_EQUAL(instToString(jmpInst), "br label %target_bb");
}

BOOST_AUTO_TEST_CASE(PhiInstruction) {
	// Test phi with two incoming values
	vector<Term> phiOps;
	phiOps.push_back(var(intTy(32), Ref("result"))); // Result variable
	phiOps.push_back(intConst(intTy(32), 1));		 // First value
	phiOps.push_back(label(Ref("bb1")));			 // First label
	phiOps.push_back(intConst(intTy(32), 2));		 // Second value
	phiOps.push_back(label(Ref("bb2")));			 // Second label

	Inst phiInst(Phi, phiOps);
	BOOST_CHECK_EQUAL(instToString(phiInst), "%result = phi i32 [ 1, %bb1 ], [ 2, %bb2 ]");
}

BOOST_AUTO_TEST_CASE(ReturnInstructions) {
	// Test return with value
	Term retVal = intConst(intTy(32), 42);
	Inst retInst = ret(retVal);
	BOOST_CHECK_EQUAL(instToString(retInst), "ret i32 42");
}

BOOST_AUTO_TEST_CASE(StoreInstruction) {
	// Test store instruction
	Term val = intConst(intTy(32), 42);
	Term ptr = var(ptrTy(), Ref("ptr"));
	Inst storeInst(Store, {val, ptr});

	BOOST_CHECK_EQUAL(instToString(storeInst), "store i32 42, ptr %ptr");
}

BOOST_AUTO_TEST_CASE(SwitchInstruction) {
	// Test switch with multiple cases
	Term switchVal = var(intTy(32), Ref("val"));
	Term defaultLabel = label(Ref("default"));
	Term case1Val = intConst(intTy(32), 1);
	Term case1Label = label(Ref("case1"));
	Term case2Val = intConst(intTy(32), 2);
	Term case2Label = label(Ref("case2"));

	vector<Term> switchOps = {switchVal, defaultLabel, case1Val, case1Label, case2Val, case2Label};

	Inst switchInst(Switch, switchOps);
	BOOST_CHECK_EQUAL(instToString(switchInst),
					  "switch i32 %val, label %default [\n"
					  "    i32 1, label %case1\n"
					  "    i32 2, label %case2\n"
					  "  ]");
}

BOOST_AUTO_TEST_CASE(DropInstruction) {
	// Test drop instruction
	Term callExpr = call(voidTy(), globalRef(fnTy(voidTy(), {}), Ref("func")), {});
	Inst dropInst(Drop, {callExpr});

	BOOST_CHECK_EQUAL(instToString(dropInst), "call void @func()");
}

// Test invalid instructions throw assertions
BOOST_AUTO_TEST_CASE(InvalidInstructions) {
	// Test invalid empty instruction
	BOOST_CHECK_THROW(instToString(Inst(Alloca)), std::runtime_error);

	// Test Alloca with wrong number of operands
	vector<Term> invalidAllocaOps = {var(ptrTy(), Ref("%ptr"))};
	BOOST_CHECK_THROW(instToString(Inst(Alloca, invalidAllocaOps)), std::runtime_error);
}

// Test assigning a simple integer constant
BOOST_AUTO_TEST_CASE(AssignSimpleIntConstant) {
	// Create a variable to assign to
	Term lhs = var(intTy(32), Ref("x"));

	// Create an integer constant to assign
	Term rhs = intConst(intTy(32), 42);

	// Create an assignment instruction
	Inst inst = assign(lhs, rhs);

	// Format the instruction as a string
	std::ostringstream oss;
	oss << inst;

	// Check the formatted output
	BOOST_CHECK_EQUAL(oss.str(), "%x = i32 42");
}

// Test assigning a variable
BOOST_AUTO_TEST_CASE(AssignVariable) {
	// Create variables
	Term lhs = var(intTy(32), Ref("x"));
	Term rhs = var(intTy(32), Ref("y"));

	// Create an assignment instruction
	Inst inst = assign(lhs, rhs);

	// Format the instruction as a string
	std::ostringstream oss;
	oss << inst;

	// Check the formatted output
	BOOST_CHECK_EQUAL(oss.str(), "%x = i32 %y");
}

// Test assigning the result of a binary operation
BOOST_AUTO_TEST_CASE(AssignBinaryOperation) {
	// Create variables
	Term lhs = var(intTy(32), Ref("result"));
	Term a = var(intTy(32), Ref("a"));
	Term b = var(intTy(32), Ref("b"));

	// Create an add expression
	Term rhs = Term(Add, intTy(32), a, b);

	// Create an assignment instruction
	Inst inst = assign(lhs, rhs);

	// Format the instruction as a string
	std::ostringstream oss;
	oss << inst;

	// Check the formatted output
	BOOST_CHECK_EQUAL(oss.str(), "%result = add i32 %a, %b");
}

// Test assigning a global reference
BOOST_AUTO_TEST_CASE(AssignGlobalRef) {
	// Create a variable to assign to
	Term lhs = var(ptrTy(), Ref("ptr"));

	// Create a global reference to assign
	Term rhs = globalRef(ptrTy(), Ref("global_var"));

	// Create an assignment instruction
	Inst inst = assign(lhs, rhs);

	// Format the instruction as a string
	std::ostringstream oss;
	oss << inst;

	// Check the formatted output
	BOOST_CHECK_EQUAL(oss.str(), "%ptr = ptr @global_var");
}

// Test assigning a null pointer
BOOST_AUTO_TEST_CASE(AssignNullPointer) {
	// Create a variable to assign to
	Term lhs = var(ptrTy(), Ref("ptr"));

	// Create a null pointer to assign
	Term rhs = nullPtrConst;

	// Create an assignment instruction
	Inst inst = assign(lhs, rhs);

	// Format the instruction as a string
	std::ostringstream oss;
	oss << inst;

	// Check the formatted output
	BOOST_CHECK_EQUAL(oss.str(), "%ptr = ptr null");
}

// Test assigning the result of a load operation
BOOST_AUTO_TEST_CASE(AssignLoadOperation) {
	// Create variables
	Term lhs = var(intTy(32), Ref("value"));
	Term ptr = var(ptrTy(), Ref("ptr"));

	// Create a load expression
	Term rhs = Term(Load, intTy(32), ptr);

	// Create an assignment instruction
	Inst inst = assign(lhs, rhs);

	// Format the instruction as a string
	std::ostringstream oss;
	oss << inst;

	// Check the formatted output
	BOOST_CHECK_EQUAL(oss.str(), "%value = load i32, ptr %ptr");
}

// Test assigning a Boolean constant
BOOST_AUTO_TEST_CASE(AssignBoolConstant) {
	// Create a variable to assign to
	Term lhs = var(boolTy(), Ref("flag"));

	// Create Boolean constants
	Term rhsTrue = trueConst;
	Term rhsFalse = falseConst;

	// Create assignment instructions
	Inst instTrue = assign(lhs, rhsTrue);
	Inst instFalse = assign(lhs, rhsFalse);

	// Format the instructions as strings
	std::ostringstream ossTrue, ossFalse;
	ossTrue << instTrue;
	ossFalse << instFalse;

	// Check the formatted outputs
	BOOST_CHECK_EQUAL(ossTrue.str(), "%flag = i1 true");
	BOOST_CHECK_EQUAL(ossFalse.str(), "%flag = i1 false");
}

// Helper function to capture output of an instruction
std::string captureInstructionOutput(const Inst& inst) {
	std::ostringstream oss;
	oss << inst;
	return oss.str();
}

// Test unsigned integer cast operations (Cast)
BOOST_AUTO_TEST_CASE(UnsignedIntegerCastTests) {
	// Variable to assign to
	Term destVar = var(intTy(32), Ref("dest"));

	// Widening cast (i8 -> i32)
	Term sourceTerm8 = var(intTy(8), Ref("source8"));
	Term wideCast = Term(Cast, intTy(32), sourceTerm8);
	Inst wideAssign = assign(destVar, wideCast);

	// Narrowing cast (i64 -> i32)
	Term sourceTerm64 = var(intTy(64), Ref("source64"));
	Term narrowCast = Term(Cast, intTy(32), sourceTerm64);
	Inst narrowAssign = assign(destVar, narrowCast);

	// Same-size cast (i32 -> i32)
	Term sourceTerm32 = var(intTy(32), Ref("source32"));
	Term sameSizeCast = Term(Cast, intTy(32), sourceTerm32);
	Inst sameSizeAssign = assign(destVar, sameSizeCast);

	// Check the output
	BOOST_CHECK_EQUAL(captureInstructionOutput(wideAssign), "%dest = zext i8 %source8 to i32");

	BOOST_CHECK_EQUAL(captureInstructionOutput(narrowAssign), "%dest = trunc i64 %source64 to i32");

	BOOST_CHECK_EQUAL(captureInstructionOutput(sameSizeAssign), "%dest = bitcast i32 %source32 to i32");
}

// Test signed integer cast operations (SCast)
BOOST_AUTO_TEST_CASE(SignedIntegerCastTests) {
	// Variable to assign to
	Term destVar = var(intTy(32), Ref("dest"));

	// Widening signed cast (i8 -> i32)
	Term sourceTerm8 = var(intTy(8), Ref("source8"));
	Term wideSCast = Term(SCast, intTy(32), sourceTerm8);
	Inst wideAssign = assign(destVar, wideSCast);

	// Narrowing signed cast (i64 -> i32)
	Term sourceTerm64 = var(intTy(64), Ref("source64"));
	Term narrowSCast = Term(SCast, intTy(32), sourceTerm64);
	Inst narrowAssign = assign(destVar, narrowSCast);

	// Check the output
	BOOST_CHECK_EQUAL(captureInstructionOutput(wideAssign), "%dest = sext i8 %source8 to i32");

	BOOST_CHECK_EQUAL(captureInstructionOutput(narrowAssign), "%dest = trunc i64 %source64 to i32");
}

// Test float-to-int and int-to-float cast operations
BOOST_AUTO_TEST_CASE(FloatIntCastTests) {
	// Variables to assign to
	Term intDestVar = var(intTy(32), Ref("int_dest"));
	Term floatDestVar = var(floatTy(), Ref("float_dest"));

	// Float to int cast
	Term floatSource = var(floatTy(), Ref("float_source"));
	Term floatToIntCast = Term(Cast, intTy(32), floatSource);
	Inst floatToIntAssign = assign(intDestVar, floatToIntCast);

	// Int to float cast
	Term intSource = var(intTy(32), Ref("int_source"));
	Term intToFloatCast = Term(Cast, floatTy(), intSource);
	Inst intToFloatAssign = assign(floatDestVar, intToFloatCast);

	// Check the output
	BOOST_CHECK_EQUAL(captureInstructionOutput(floatToIntAssign), "%int_dest = fptosi float %float_source to i32");

	BOOST_CHECK_EQUAL(captureInstructionOutput(intToFloatAssign), "%float_dest = sitofp i32 %int_source to float");
}

// Test pointer cast operations
BOOST_AUTO_TEST_CASE(PointerCastTests) {
	// Variables to assign to
	Term intDestVar = var(intTy(64), Ref("int_dest"));
	Term ptrDestVar = var(ptrTy(), Ref("ptr_dest"));

	// Pointer to int cast
	Term ptrSource = var(ptrTy(), Ref("ptr_source"));
	Term ptrToIntCast = Term(Cast, intTy(64), ptrSource);
	Inst ptrToIntAssign = assign(intDestVar, ptrToIntCast);

	// Int to pointer cast
	Term intSource = var(intTy(64), Ref("int_source"));
	Term intToPtrCast = Term(Cast, ptrTy(), intSource);
	Inst intToPtrAssign = assign(ptrDestVar, intToPtrCast);

	// Check the output
	BOOST_CHECK_EQUAL(captureInstructionOutput(ptrToIntAssign), "%int_dest = ptrtoint ptr %ptr_source to i64");

	BOOST_CHECK_EQUAL(captureInstructionOutput(intToPtrAssign), "%ptr_dest = inttoptr i64 %int_source to ptr");
}

// Test more complex casting scenarios
BOOST_AUTO_TEST_CASE(ComplexCastTests) {
	// Test double to i32 cast
	Term doubleSource = var(doubleTy(), Ref("double_source"));
	Term intDestVar = var(intTy(32), Ref("int_dest"));
	Term doubleToIntCast = Term(Cast, intTy(32), doubleSource);
	Inst doubleToIntAssign = assign(intDestVar, doubleToIntCast);

	// Test float to double cast
	Term floatSource = var(floatTy(), Ref("float_source"));
	Term doubleDestVar = var(doubleTy(), Ref("double_dest"));
	Term floatToDoubleCast = Term(Cast, doubleTy(), floatSource);
	Inst floatToDoubleAssign = assign(doubleDestVar, floatToDoubleCast);

	// Test i1 (bool) to i8 signed cast
	Term boolSource = var(boolTy(), Ref("bool_source"));
	Term charDestVar = var(intTy(8), Ref("char_dest"));
	Term boolToCharSCast = Term(SCast, intTy(8), boolSource);
	Inst boolToCharAssign = assign(charDestVar, boolToCharSCast);

	// Check the outputs
	BOOST_CHECK_EQUAL(captureInstructionOutput(doubleToIntAssign), "%int_dest = fptosi double %double_source to i32");

	BOOST_CHECK_EQUAL(captureInstructionOutput(floatToDoubleAssign), "%double_dest = bitcast float %float_source to double");

	BOOST_CHECK_EQUAL(captureInstructionOutput(boolToCharAssign), "%char_dest = sext i1 %bool_source to i8");
}

BOOST_AUTO_TEST_SUITE_END()
