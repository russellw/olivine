#include "all.h"
#include <boost/test/unit_test.hpp>

// Helper function to parse LLVM IR string
std::unique_ptr<Module> parseString(const std::string& input) {
	return std::unique_ptr<Module>(parse("test.ll", input));
}

BOOST_AUTO_TEST_SUITE(ParserTests)

// Test basic type parsing
BOOST_AUTO_TEST_CASE(BasicTypes) {
	auto module = parseString(R"(
define void @test() {
    ret void
}
)");

	BOOST_CHECK_EQUAL(module->defs[0].rty().kind(), VoidKind);
}

// Test integer types with different bit widths
BOOST_AUTO_TEST_CASE(IntegerTypes) {
	auto module = parseString(R"(
define i32 @test(i1 %cond, i64 %val) {
    ret i32 0
}
)");

	auto& func = module->defs[0];
	BOOST_CHECK_EQUAL(func.rty().kind(), IntKind);
	BOOST_CHECK_EQUAL(func.rty().len(), 32);
	BOOST_CHECK_EQUAL(func.params()[0].ty().len(), 1);
	BOOST_CHECK_EQUAL(func.params()[1].ty().len(), 64);
}

// Test floating point types
BOOST_AUTO_TEST_CASE(FloatingPointTypes) {
	auto module = parseString(R"(
define double @test(float %x) {
    ret double 0.0
}
)");

	auto& func = module->defs[0];
	BOOST_CHECK_EQUAL(func.rty().kind(), DoubleKind);
	BOOST_CHECK_EQUAL(func.params()[0].ty().kind(), FloatKind);
}

// Test pointer types
BOOST_AUTO_TEST_CASE(PointerTypes) {
	auto module = parseString(R"(
define ptr @allocate() {
    %ptr = alloca i32, i32 1
    ret ptr %ptr
}
)");

	auto& func = module->defs[0];
	BOOST_CHECK_EQUAL(func.rty().kind(), PtrKind);
}

// Test array types
BOOST_AUTO_TEST_CASE(ArrayTypes) {
	auto module = parseString(R"(
define void @test() {
    %arr = alloca [4 x i32], i32 1
    ret void
}
)");

	auto inst = module->defs[0][0]; // First instruction
	BOOST_CHECK_EQUAL(inst.opcode(), Alloca);
	auto arrayType = inst[1].ty();
	BOOST_CHECK_EQUAL(arrayType.kind(), ArrayKind);
	BOOST_CHECK_EQUAL(arrayType.len(), 4);
	BOOST_CHECK_EQUAL(arrayType[0].kind(), IntKind);
	BOOST_CHECK_EQUAL(arrayType[0].len(), 32);
}

// Test vector types
BOOST_AUTO_TEST_CASE(VectorTypes) {
	auto module = parseString(R"(
define void @test() {
    %vec = alloca <4 x float>, i32 1
    ret void
}
)");

	auto inst = module->defs[0][0];
	BOOST_CHECK_EQUAL(inst.opcode(), Alloca);
	auto vecType = inst[1].ty();
	BOOST_CHECK_EQUAL(vecType.kind(), VecKind);
	BOOST_CHECK_EQUAL(vecType.len(), 4);
	BOOST_CHECK_EQUAL(vecType[0].kind(), FloatKind);
}

// Test basic arithmetic expressions
BOOST_AUTO_TEST_CASE(ArithmeticExpressions) {
	auto module = parseString(R"(
define i32 @test(i32 %a, i32 %b) {
entry:
    %sum = add i32 %a, %b
    %diff = sub i32 %sum, %a
    %prod = mul i32 %diff, %b
    %quot = sdiv i32 %prod, %b
    ret i32 %quot
}
)");

	auto& func = module->defs[0];
	BOOST_CHECK_EQUAL(func[1][1].tag(), Add);
	BOOST_CHECK_EQUAL(func[2][1].tag(), Sub);
	BOOST_CHECK_EQUAL(func[3][1].tag(), Mul);
	BOOST_CHECK_EQUAL(func[4][1].tag(), SDiv);
}

// Test comparison expressions
BOOST_AUTO_TEST_CASE(ComparisonExpressions) {
	auto module = parseString(R"(
define i1 @test(i32 %a, i32 %b) {
entry:
    %eq = icmp eq i32 %a, %b
    %lt = icmp slt i32 %a, %b
    %gt = icmp sgt i32 %a, %b
    %result = and i1 %eq, %lt
    ret i1 %result
}
)");

	auto& func = module->defs[0];
	BOOST_CHECK_EQUAL(func[1][1].tag(), Eq);
	BOOST_CHECK_EQUAL(func[2][1].tag(), SLt);
	// Note: sgt is internally represented as SLt with swapped operands
	BOOST_CHECK_EQUAL(func[4][1].tag(), And);
}

// Test control flow instructions
BOOST_AUTO_TEST_CASE(ControlFlow) {
	auto module = parseString(R"(
define void @test(i1 %cond) {
entry:
    br i1 %cond, label %then, label %else
then:
    br label %merge
else:
    br label %merge
merge:
    ret void
}
)");

	auto& func = module->defs[0];
	BOOST_CHECK_EQUAL(func[0].opcode(), Block);
	BOOST_CHECK_EQUAL(func[1].opcode(), Br);
	BOOST_CHECK_EQUAL(func[2].opcode(), Block);
	BOOST_CHECK_EQUAL(func[3].opcode(), Jmp);
}

// Test memory operations
BOOST_AUTO_TEST_CASE(MemoryOperations) {
	auto module = parseString(R"(
define i32 @test() {
entry:
    %ptr = alloca i32, i32 1
    store i32 42, ptr %ptr
    %val = load i32, ptr %ptr
    ret i32 %val
}
)");

	auto& func = module->defs[0];
	BOOST_CHECK_EQUAL(func[1].opcode(), Alloca);
	BOOST_CHECK_EQUAL(func[2].opcode(), Store);
	BOOST_CHECK_EQUAL(func[3][1].tag(), Load);
}

// Test function declarations
BOOST_AUTO_TEST_CASE(FunctionDeclarations) {
	auto module = parseString(R"(
declare i32 @external_func(i32)
define i32 @test(i32 %x) {
    %result = call i32 @external_func(i32 %x)
    ret i32 %result
}
)");

	BOOST_CHECK_EQUAL(module->decls.size(), 1);
	BOOST_CHECK_EQUAL(module->defs.size(), 1);
	BOOST_CHECK_EQUAL(module->decls[0].size(), 0); // Declaration has no body
	BOOST_CHECK_EQUAL(module->defs[0].size(), 2);  // Definition has body
}

// Test error handling
BOOST_AUTO_TEST_CASE(ErrorHandling) {
	BOOST_CHECK_THROW(parseString("define"), std::runtime_error);
	BOOST_CHECK_THROW(parseString("define @invalid"), std::runtime_error);
}

BOOST_AUTO_TEST_SUITE_END()
