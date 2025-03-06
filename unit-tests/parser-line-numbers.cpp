#include "all.h"
#include <boost/test/unit_test.hpp>

// Helper function to check if a parser error contains the expected line number
bool error_contains_line_number(const std::string& ir_code, int expected_line) {
	try {
		// Call your parse function
		parse("test.ll", ir_code);

		// If we get here, parsing succeeded, but we expected an error
		return false;
	} catch (const std::runtime_error& e) {
		// Check if the error message contains the expected line number
		std::string error_message = e.what();
		std::string expected_line_str = ":" + std::to_string(expected_line) + ":";

		// Adjust this based on your actual error format
		return error_message.find(expected_line_str) != std::string::npos;
	}
}

BOOST_AUTO_TEST_CASE(test_invalid_type_error) {
	std::string ir_code = "define i32 @test() {\n"				  // Line 1
						  "    %x = alloca i32\n"				  // Line 2
						  "    %y = load invalid_type, i32* %x\n" // Line 3 - invalid type
						  "    ret i32 %y\n"					  // Line 4
						  "}\n";								  // Line 5

	BOOST_CHECK_MESSAGE(error_contains_line_number(ir_code, 3), "Parser should report error at line 3 for invalid type");
}

BOOST_AUTO_TEST_CASE(test_invalid_instruction_error) {
	std::string ir_code = "define i32 @test() {\n"		 // Line 1
						  "    %x = alloca i32\n"		 // Line 2
						  "    invalid_instruction %x\n" // Line 3 - invalid instruction
						  "    ret i32 0\n"				 // Line 4
						  "}\n";						 // Line 5

	BOOST_CHECK_MESSAGE(error_contains_line_number(ir_code, 3), "Parser should report error at line 3 for invalid instruction");
}

BOOST_AUTO_TEST_CASE(test_malformed_function_signature) {
	std::string ir_code = "define @broken_func() {\n" // Line 1 - missing return type
						  "    ret void\n"			  // Line 2
						  "}\n";					  // Line 3

	BOOST_CHECK_MESSAGE(
		error_contains_line_number(ir_code, 1), "Parser should report error at line 1 for malformed function signature");
}

BOOST_AUTO_TEST_CASE(test_invalid_operand_count) {
	std::string ir_code = "define i32 @test() {\n" // Line 1
						  "    %x = add i32 42\n"  // Line 2 - missing second operand
						  "    ret i32 %x\n"	   // Line 3
						  "}\n";				   // Line 4

	BOOST_CHECK_MESSAGE(error_contains_line_number(ir_code, 2), "Parser should report error at line 2 for invalid operand count");
}

BOOST_AUTO_TEST_CASE(test_invalid_global_variable) {
	std::string ir_code = "@global_var = global\n" // Line 1 - missing type
						  "define i32 @main() {\n" // Line 2
						  "    ret i32 0\n"		   // Line 3
						  "}\n";				   // Line 4

	BOOST_CHECK_MESSAGE(
		error_contains_line_number(ir_code, 1), "Parser should report error at line 1 for invalid global variable declaration");
}

BOOST_AUTO_TEST_CASE(test_invalid_block_label) {
	std::string ir_code = "define i32 @test() {\n"		 // Line 1
						  "entry:\n"					 // Line 2
						  "    %x = alloca i32\n"		 // Line 3
						  "    br label invalid_label\n" // Line 4 - invalid label format
						  "    ret i32 0\n"				 // Line 5
						  "}\n";						 // Line 6

	BOOST_CHECK_MESSAGE(error_contains_line_number(ir_code, 4), "Parser should report error at line 4 for invalid block label");
}

BOOST_AUTO_TEST_CASE(test_invalid_phi_node) {
	std::string ir_code = "define i32 @test(i1 %cond) {\n"				// Line 1
						  "entry:\n"									// Line 2
						  "    br i1 %cond, label %then, label %else\n" // Line 3
						  "then:\n"										// Line 4
						  "    br label %merge\n"						// Line 5
						  "else:\n"										// Line 6
						  "    br label %merge\n"						// Line 7
						  "merge:\n"									// Line 8
						  "    %result = phi i32 [42, %then] []\n"		// Line 9 - invalid phi node
						  "    ret i32 %result\n"						// Line 10
						  "}\n";										// Line 11

	BOOST_CHECK_MESSAGE(error_contains_line_number(ir_code, 9), "Parser should report error at line 9 for invalid phi node");
}

BOOST_AUTO_TEST_CASE(test_invalid_array_type) {
	std::string ir_code = "define i32 @test() {\n"												 // Line 1
						  "    %arr = alloca [5 x i32]\n"										 // Line 2
						  "    %ptr = getelementptr [5 x i32], [5 x i32]* %arr, i32 0, i32 -1\n" // Line 3 - invalid index
						  "    ret i32 0\n"														 // Line 4
						  "}\n";																 // Line 5

	BOOST_CHECK_MESSAGE(error_contains_line_number(ir_code, 3), "Parser should report error at line 3 for invalid array index");
}

BOOST_AUTO_TEST_CASE(test_multiple_errors) {
	// Test that the first error is reported correctly
	std::string ir_code = "define i32 @test() {\n"	 // Line 1
						  "    %x = undefined_op\n"	 // Line 2 - first error
						  "    %y = another_error\n" // Line 3 - second error
						  "    ret i32 0\n"			 // Line 4
						  "}\n";					 // Line 5

	BOOST_CHECK_MESSAGE(error_contains_line_number(ir_code, 2), "Parser should report the first error at line 2");
}

// Advanced test case with nested functions and complex control flow
BOOST_AUTO_TEST_CASE(test_complex_function_with_error) {
	std::string ir_code = "define i32 @outer() {\n"							   // Line 1
						  "entry:\n"										   // Line 2
						  "    %x = alloca i32\n"							   // Line 3
						  "    store i32 42, i32* %x\n"						   // Line 4
						  "    %cond = icmp eq i32 42, 42\n"				   // Line 5
						  "    br i1 %cond, label %true_bb, label %false_bb\n" // Line 6
						  "true_bb:\n"										   // Line 7
						  "    call void @inner()\n"						   // Line 8
						  "    br label %end\n"								   // Line 9
						  "false_bb:\n"										   // Line 10
						  "    ; This line has a syntax error\n"			   // Line 11
						  "    %y = bad syntax here\n"						   // Line 12 - error here
						  "    br label %end\n"								   // Line 13
						  "end:\n"											   // Line 14
						  "    ret i32 0\n"									   // Line 15
						  "}\n"												   // Line 16
						  "\n"												   // Line 17
						  "define void @inner() {\n"						   // Line 18
						  "    ret void\n"									   // Line 19
						  "}\n";											   // Line 20

	BOOST_CHECK_MESSAGE(error_contains_line_number(ir_code, 12), "Parser should report error at line 12 in complex function");
}
