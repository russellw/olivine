#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_CASE(EmptyModule) {
	// Create an empty module
	Module module;

	// For an empty module, the next number should be 1
	BOOST_CHECK_EQUAL(nextGlobalNum(&module), 1);
}

BOOST_AUTO_TEST_CASE(ModuleWithStringRefsOnly) {
	// Create a module with only string references
	Module module;

	// Add a global variable with a string reference
	Global strGlobal(intTy(32), Ref("variable"));
	module.globals.push_back(strGlobal);

	// Add a function declaration with a string reference
	Fn strFnDecl(voidTy(), Ref("function"), {});
	module.decls.push_back(strFnDecl);

	// Add a function definition with a string reference
	Fn strFnDef(voidTy(), Ref("main"), {}, {});
	module.defs.push_back(strFnDef);

	// For a module with only string references, the next number should still be 1
	BOOST_CHECK_EQUAL(nextGlobalNum(&module), 1);
}

BOOST_AUTO_TEST_CASE(ModuleWithNumericRefs) {
	// Create a module with numeric references
	Module module;

	// Add a global variable with a numeric reference
	Global numGlobal(intTy(32), Ref(size_t(5)));
	module.globals.push_back(numGlobal);

	// Add a function declaration with a numeric reference
	Fn numFnDecl(voidTy(), Ref(size_t(10)), {});
	module.decls.push_back(numFnDecl);

	// Add a function definition with a numeric reference
	Fn numFnDef(voidTy(), Ref(size_t(7)), {}, {});
	module.defs.push_back(numFnDef);

	// Next number should be max + 1, so 11 in this case
	BOOST_CHECK_EQUAL(nextGlobalNum(&module), 11);
}

BOOST_AUTO_TEST_CASE(ModuleWithMixedRefs) {
	// Create a module with mixed string and numeric references
	Module module;

	// Add global variables with mixed references
	module.globals.push_back(Global(intTy(32), Ref("global_str")));
	module.globals.push_back(Global(intTy(64), Ref(size_t(15))));

	// Add function declarations with mixed references
	module.decls.push_back(Fn(voidTy(), Ref("decl_str"), {}));
	module.decls.push_back(Fn(intTy(32), Ref(size_t(8)), {}));

	// Add function definitions with mixed references
	module.defs.push_back(Fn(voidTy(), Ref("def_str"), {}, {}));
	module.defs.push_back(Fn(intTy(32), Ref(size_t(12)), {}, {}));

	// Next number should be max + 1, so 16 in this case
	BOOST_CHECK_EQUAL(nextGlobalNum(&module), 16);
}

BOOST_AUTO_TEST_CASE(ModuleWithLargeGaps) {
	// Create a module with large gaps between numeric references
	Module module;

	// Add references with large gaps
	module.globals.push_back(Global(intTy(32), Ref(size_t(1000))));
	module.decls.push_back(Fn(voidTy(), Ref(size_t(2)), {}));
	module.defs.push_back(Fn(intTy(32), Ref(size_t(500)), {}, {}));

	// Next number should be max + 1, so 1001 in this case
	BOOST_CHECK_EQUAL(nextGlobalNum(&module), 1001);
}

BOOST_AUTO_TEST_CASE(ModuleWithDuplicateRefs) {
	// Create a module with duplicate numeric references
	// This shouldn't happen in practice, but the function should still work
	Module module;

	// Add duplicate references
	module.globals.push_back(Global(intTy(32), Ref(size_t(42))));
	module.globals.push_back(Global(intTy(64), Ref(size_t(42))));
	module.decls.push_back(Fn(voidTy(), Ref(size_t(42)), {}));

	// Next number should still be max + 1, so 43 in this case
	BOOST_CHECK_EQUAL(nextGlobalNum(&module), 43);
}

BOOST_AUTO_TEST_CASE(ZeroBasedRefs) {
	// Test with zero-based references
	Module module;

	// Add reference with value 0
	module.globals.push_back(Global(intTy(32), Ref(size_t(0))));

	// Next number should be 1
	BOOST_CHECK_EQUAL(nextGlobalNum(&module), 1);
}
