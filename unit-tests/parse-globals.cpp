#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_CASE(test_empty_module) {
	// Test parsing an empty module
	auto module=parse("");

	BOOST_CHECK(module->globals.empty());
	BOOST_CHECK(module->decls.empty());
	BOOST_CHECK(module->defs.empty());
}

BOOST_AUTO_TEST_CASE(test_simple_global_int) {
	// Test parsing a module with a single global integer
	std::string input = "@global_int = global i32 42";
	auto module=parse(input);

	BOOST_CHECK_EQUAL(module->globals.size(), 1);
	BOOST_CHECK(module->globals[0].ty() == intTy(32));
	BOOST_CHECK(module->globals[0].ref() == Ref("global_int"));
}

BOOST_AUTO_TEST_CASE(test_global_pointer) {
	// Test parsing a module with a global pointer
	std::string input = "@global_ptr = global ptr null";
	auto module=parse(input);

	BOOST_CHECK_EQUAL(module->globals.size(), 1);
	BOOST_CHECK(module->globals[0].ty() == ptrTy());
	BOOST_CHECK(module->globals[0].ref() == Ref("global_ptr"));
}

BOOST_AUTO_TEST_CASE(test_global_array) {
	// Test parsing a module with a global array
	std::string input = "@global_array = global [10 x i64] zeroinitializer";
	auto module=parse(input);

	BOOST_CHECK_EQUAL(module->globals.size(), 1);
	BOOST_CHECK(module->globals[0].ty() == arrayTy(10, intTy(64)));
	BOOST_CHECK(module->globals[0].ref() == Ref("global_array"));
}

BOOST_AUTO_TEST_CASE(test_multiple_globals) {
	// Test parsing a module with multiple globals
	std::string input = "@global_int = global i32 42\n"
						"@global_ptr = global ptr null\n"
						"@global_array = global [10 x i64] zeroinitializer";

	auto module=parse(input);

	BOOST_CHECK_EQUAL(module->globals.size(), 3);
}

BOOST_AUTO_TEST_CASE(test_globals_with_declarations) {
	// Test parsing a module with globals and function declarations
	std::string input = "@global_int = global i32 42\n"
						"declare void @some_function()\n";

	auto module=parse(input);

	BOOST_CHECK_EQUAL(module->globals.size(), 1);
	BOOST_CHECK_EQUAL(module->decls.size(), 1);
}

BOOST_AUTO_TEST_CASE(test_context_datalayout_and_triple) {
	// Set up test data
	context.datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	context.triple = "x86_64-pc-linux-gnu";

	// Verify the data is set correctly
	BOOST_CHECK_EQUAL(context.datalayout, "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128");
	BOOST_CHECK_EQUAL(context.triple, "x86_64-pc-linux-gnu");

	// Clear context for other tests
	context = Module();
}

BOOST_AUTO_TEST_CASE(test_module_output) {
	// Test if a module with globals can be output correctly
	std::string input = "@global_int = global i32 42\n"
						"@global_ptr = global ptr null\n";

	auto module=parse(input);

	// Setup context for output testing
	module->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	module->triple = "x86_64-pc-linux-gnu";

	// Test outputting the module
	std::ostringstream oss;
	oss << module;
	std::string output = oss.str();

	// Check if output contains expected strings
	BOOST_CHECK(output.find("target datalayout") != std::string::npos);
	BOOST_CHECK(output.find("target triple") != std::string::npos);
	BOOST_CHECK(output.find("@global_int") != std::string::npos);
	BOOST_CHECK(output.find("@global_ptr") != std::string::npos);

	// Clear context for other tests
	context = Module();
}

// Test for global variable equality comparison
BOOST_AUTO_TEST_CASE(test_global_equality) {
	Global a(intTy(32), Ref("global_a"));
	Global b(intTy(32), Ref("global_a"));
	Global c(intTy(64), Ref("global_a"));
	Global d(intTy(32), Ref("global_d"));

	BOOST_CHECK(a == b);
	BOOST_CHECK(a != c); // Different types
	BOOST_CHECK(a != d); // Different references
}

// Test for Program class constructing with globals
BOOST_AUTO_TEST_CASE(test_program_with_globals) {
	std::vector<Global> globals;
	globals.push_back(Global(intTy(32), Ref("global_int")));
	globals.push_back(Global(ptrTy(), Ref("global_ptr")));

	std::vector<Fn> defs;

	Program program(globals, defs);

	BOOST_CHECK_EQUAL(program.globals().size(), 2);
	BOOST_CHECK(program.empty()); // Should be empty as no function definitions
}
