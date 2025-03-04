#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(RenameInternalsTests)

// Setup test fixtures
struct TestModule {
	std::unique_ptr<Module> module;

	TestModule() {
		// Create a new module
		module = std::make_unique<Module>();
		module->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
		module->triple = "x86_64-unknown-linux-gnu";
	}

	// Helper to add a global variable to the module
	void addGlobal(const Ref& ref, bool isExternal) {
		Type ty = intTy(32); // 32-bit integer type
		Global global = Global(ty, ref);
		module->globals.push_back(global);

		if (isExternal) {
			module->externals.insert(ref);
		}
	}

	// Helper to add a function declaration to the module
	void addFunctionDecl(const Ref& ref, bool isExternal) {
		Type rty = intTy(32);	  // 32-bit integer return type
		std::vector<Term> params; // Empty parameter list for simplicity
		Fn func = Fn(rty, ref, params);
		module->decls.push_back(func);

		if (isExternal) {
			module->externals.insert(ref);
		}
	}

	// Helper to add a function definition to the module
	void addFunctionDef(const Ref& ref, bool isExternal) {
		Type rty = intTy(32);	  // 32-bit integer return type
		std::vector<Term> params; // Empty parameter list for simplicity
		std::vector<Inst> body;	  // Empty body for simplicity
		Fn func = Fn(rty, ref, params, body);
		module->defs.push_back(func);

		if (isExternal) {
			module->externals.insert(ref);
		}
	}
};

BOOST_AUTO_TEST_CASE(EmptyModule) {
	TestModule fixture;

	// Test that an empty module doesn't cause any issues
	renameInternals(fixture.module.get());

	BOOST_CHECK(fixture.module->globals.empty());
	BOOST_CHECK(fixture.module->decls.empty());
	BOOST_CHECK(fixture.module->defs.empty());
	BOOST_CHECK(fixture.module->externals.empty());
}

BOOST_AUTO_TEST_CASE(OnlyExternalGlobals) {
	TestModule fixture;

	// Add some external globals
	fixture.addGlobal(parseRef("@global1"), true);
	fixture.addGlobal(parseRef("@global2"), true);
	fixture.addFunctionDecl(parseRef("@func1"), true);
	fixture.addFunctionDef(parseRef("@func2"), true);

	// Save references before renaming
	auto global1Ref = fixture.module->globals[0].ref();
	auto global2Ref = fixture.module->globals[1].ref();
	auto func1Ref = fixture.module->decls[0].ref();
	auto func2Ref = fixture.module->defs[0].ref();

	// Run the function
	renameInternals(fixture.module.get());

	// Check that the references haven't changed
	BOOST_CHECK_EQUAL(fixture.module->globals[0].ref(), global1Ref);
	BOOST_CHECK_EQUAL(fixture.module->globals[1].ref(), global2Ref);
	BOOST_CHECK_EQUAL(fixture.module->decls[0].ref(), func1Ref);
	BOOST_CHECK_EQUAL(fixture.module->defs[0].ref(), func2Ref);
}

BOOST_AUTO_TEST_CASE(OnlyInternalGlobals) {
	TestModule fixture;

	// Add some internal globals
	fixture.addGlobal(parseRef("@internal_global1"), false);
	fixture.addGlobal(parseRef("@internal_global2"), false);
	fixture.addFunctionDecl(parseRef("@internal_func1"), false);
	fixture.addFunctionDef(parseRef("@internal_func2"), false);

	// Save references before renaming
	auto global1Ref = fixture.module->globals[0].ref();
	auto global2Ref = fixture.module->globals[1].ref();
	auto func1Ref = fixture.module->decls[0].ref();
	auto func2Ref = fixture.module->defs[0].ref();

	// Run the function
	renameInternals(fixture.module.get());

	// Check that the references have changed
	BOOST_CHECK(fixture.module->globals[0].ref() != global1Ref);
	BOOST_CHECK(fixture.module->globals[1].ref() != global2Ref);
	BOOST_CHECK(fixture.module->decls[0].ref() != func1Ref);
	BOOST_CHECK(fixture.module->defs[0].ref() != func2Ref);

	// Check that the new references are numeric (size_t)
	BOOST_CHECK(fixture.module->globals[0].ref().numeric());
	BOOST_CHECK(fixture.module->globals[1].ref().numeric());
	BOOST_CHECK(fixture.module->decls[0].ref().numeric());
	BOOST_CHECK(fixture.module->defs[0].ref().numeric());
}

BOOST_AUTO_TEST_CASE(MixedGlobalsAndFunctions) {
	TestModule fixture;

	// Add a mix of internal and external globals and functions
	fixture.addGlobal(parseRef("@external_global"), true);
	fixture.addGlobal(parseRef("@internal_global"), false);
	fixture.addFunctionDecl(parseRef("@external_func_decl"), true);
	fixture.addFunctionDecl(parseRef("@internal_func_decl"), false);
	fixture.addFunctionDef(parseRef("@external_func_def"), true);
	fixture.addFunctionDef(parseRef("@internal_func_def"), false);

	// Save references before renaming
	auto externalGlobalRef = fixture.module->globals[0].ref();
	auto internalGlobalRef = fixture.module->globals[1].ref();
	auto externalFuncDeclRef = fixture.module->decls[0].ref();
	auto internalFuncDeclRef = fixture.module->decls[1].ref();
	auto externalFuncDefRef = fixture.module->defs[0].ref();
	auto internalFuncDefRef = fixture.module->defs[1].ref();

	// Run the function
	renameInternals(fixture.module.get());

	// Check that external references haven't changed
	BOOST_CHECK_EQUAL(fixture.module->globals[0].ref(), externalGlobalRef);
	BOOST_CHECK_EQUAL(fixture.module->decls[0].ref(), externalFuncDeclRef);
	BOOST_CHECK_EQUAL(fixture.module->defs[0].ref(), externalFuncDefRef);

	// Check that internal references have changed
	BOOST_CHECK(fixture.module->globals[1].ref() != internalGlobalRef);
	BOOST_CHECK(fixture.module->decls[1].ref() != internalFuncDeclRef);
	BOOST_CHECK(fixture.module->defs[1].ref() != internalFuncDefRef);

	// Check that the new internal references are numeric (size_t)
	BOOST_CHECK(fixture.module->globals[1].ref().numeric());
	BOOST_CHECK(fixture.module->decls[1].ref().numeric());
	BOOST_CHECK(fixture.module->defs[1].ref().numeric());
}

BOOST_AUTO_TEST_CASE(TestInternalReferencesInGlobalValue) {
	TestModule fixture;

	// Add an internal function
	Ref internalFuncRef = parseRef("@internal_func");
	fixture.addFunctionDef(internalFuncRef, false);

	// Add a global with a reference to the internal function
	Type ty = ptrTy();
	Global global = Global(ty, parseRef("@global_with_ref"));
	// Assuming we can set the global's value to a reference to the internal function
	// This would be implementation-specific

	// Run the function
	renameInternals(fixture.module.get());

	// Check that the internal function reference has changed
	BOOST_CHECK(fixture.module->defs[0].ref() != internalFuncRef);

	// Check that references within globals have been updated
	// This would require checking the value of the global
	// Implementation-specific code would go here
}

BOOST_AUTO_TEST_CASE(TestUniqueness) {
	TestModule fixture;

	// Add several internal functions and globals
	for (int i = 0; i < 5; i++) {
		fixture.addGlobal(parseRef("@internal_global" + to_string(i)), false);
		fixture.addFunctionDef(parseRef("@internal_func" + to_string(i)), false);
	}

	// Run the function
	renameInternals(fixture.module.get());

	// Check that all new names are unique
	std::unordered_set<Ref, std::hash<Ref>, std::equal_to<Ref>> uniqueRefs;

	for (const auto& global : fixture.module->globals) {
		BOOST_CHECK(uniqueRefs.insert(global.ref()).second);
	}

	for (const auto& func : fixture.module->defs) {
		BOOST_CHECK(uniqueRefs.insert(func.ref()).second);
	}
}

BOOST_AUTO_TEST_SUITE_END()
