#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_CASE(test_parse_alloca_instruction) {
	// The test input: a function with a single alloca instruction.
	// Note: the alloca instruction has three operands:
	//  - The LHS variable (%1) which is a Var (with type ptrTy()),
	//  - The allocated type (here, i32),
	//  - And the number of elements (the constant 1, of type i32).
	std::string input = "define void @test() {\n"
						"%1 = alloca i32, i64 1\n"
						"}\n";

	// Construct the parser with the input
	auto mod = parse("test.ll", input);

	// Retrieve the parsed module
	BOOST_REQUIRE_EQUAL(mod->defs.size(), 1);

	// Get the function @test and check its instruction count
	const Fn& func = mod->defs[0];
	BOOST_REQUIRE_EQUAL(func.size(), 1);

	// Get the parsed instruction, which should be the alloca instruction.
	const Inst& inst = func[0];
	BOOST_CHECK_EQUAL(inst.opcode(), Alloca);
	BOOST_REQUIRE_EQUAL(inst.size(), 3);

	// Check operand 0: the left-hand side variable.
	// It should be a Var term with type ptrTy().
	const Term& lval = inst[0];
	BOOST_CHECK_EQUAL(lval.tag(), Var);
	BOOST_CHECK(lval.ty() == ptrTy());

	// Check operand 1:
	// Compare with type i32.
	BOOST_CHECK_EQUAL(inst[1], none(intTy(32)));

	// Check operand 2: the number of elements (should be constant 1 of type i32).
	const Term& numElem = inst[2];
	BOOST_CHECK_EQUAL(numElem.intVal(), 1);
	BOOST_CHECK(numElem.ty() == intTy(64));
}
