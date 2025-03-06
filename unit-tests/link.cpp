#include "all.h"
#include <boost/test/unit_test.hpp>

// Reset global state for tests
void resetTestState() {
	modules.clear();
	context = Module();
}

// Helper to create a simple module
Module* createSimpleModule(const string& name) {
	Module* module = new Module();
	module->triple = "x86_64-pc-linux-gnu";
	module->datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128";
	return module;
}

// Helper to create a global variable
Global createGlobal(Type ty, const Ref& name, bool hasValue = false) {
	if (hasValue) {
		return Global(ty, name, zeroVal(ty));
	}
	return Global(ty, name);
}

// Helper to create a function declaration
Fn createFnDecl(Type returnType, const Ref& name, const vector<Type>& paramTypes) {
	vector<Term> params;
	for (size_t i = 0; i < paramTypes.size(); ++i) {
		params.push_back(var(paramTypes[i], i));
	}
	return Fn(returnType, name, params);
}

// Helper to create a simple function definition
Fn createFnDef(Type returnType, const Ref& name, const vector<Type>& paramTypes) {
	vector<Term> params;
	for (size_t i = 0; i < paramTypes.size(); ++i) {
		params.push_back(var(paramTypes[i], i));
	}

	vector<Inst> body;
	body.push_back(block(Ref("entry")));

	if (returnType != voidTy()) {
		body.push_back(ret(zeroVal(returnType)));
	} else {
		body.push_back(ret());
	}

	return Fn(returnType, name, params, body);
}

BOOST_AUTO_TEST_CASE(TestLinkBasicModules) {
	resetTestState();

	// Create two simple modules with no conflicts
	Module* module1 = createSimpleModule("module1");
	module1->globals.push_back(createGlobal(intTy(32), Ref("global1"), true));
	module1->externals.insert(Ref("global1"));

	Module* module2 = createSimpleModule("module2");
	module2->globals.push_back(createGlobal(intTy(64), Ref("global2"), true));
	module2->externals.insert(Ref("global2"));

	modules.push_back(module1);
	modules.push_back(module2);

	link();

	// Verify context now has both globals
	BOOST_CHECK_EQUAL(context.globals.size(), 2);
	BOOST_CHECK_EQUAL(context.externals.size(), 2);

	bool foundGlobal1 = false;
	bool foundGlobal2 = false;

	for (const auto& global : context.globals) {
		if (global.ref() == Ref("global1")) {
			foundGlobal1 = true;
			BOOST_CHECK_EQUAL(global.ty().kind(), IntKind);
			BOOST_CHECK_EQUAL(global.ty().len(), 32);
		} else if (global.ref() == Ref("global2")) {
			foundGlobal2 = true;
			BOOST_CHECK_EQUAL(global.ty().kind(), IntKind);
			BOOST_CHECK_EQUAL(global.ty().len(), 64);
		}
	}

	BOOST_CHECK(foundGlobal1);
	BOOST_CHECK(foundGlobal2);

	// Clean up
	delete module1;
	delete module2;
}

BOOST_AUTO_TEST_CASE(TestLinkFunctionDeclarations) {
	resetTestState();

	// Create modules with function declarations
	Module* module1 = createSimpleModule("module1");
	module1->decls.push_back(createFnDecl(intTy(32), Ref("fn1"), {intTy(32), intTy(32)}));
	module1->externals.insert(Ref("fn1"));

	Module* module2 = createSimpleModule("module2");
	module2->decls.push_back(createFnDecl(intTy(32), Ref("fn2"), {intTy(64)}));
	module2->externals.insert(Ref("fn2"));

	// Module3 has a declaration for fn1 too (should be compatible)
	Module* module3 = createSimpleModule("module3");
	module3->decls.push_back(createFnDecl(intTy(32), Ref("fn1"), {intTy(32), intTy(32)}));
	module3->externals.insert(Ref("fn1"));

	modules.push_back(module1);
	modules.push_back(module2);
	modules.push_back(module3);

	link();

	// Verify context has the declarations
	BOOST_CHECK_EQUAL(context.decls.size(), 2);
	BOOST_CHECK_EQUAL(context.externals.size(), 2);

	bool foundFn1 = false;
	bool foundFn2 = false;

	for (const auto& decl : context.decls) {
		if (decl.ref() == Ref("fn1")) {
			foundFn1 = true;
			BOOST_CHECK_EQUAL(decl.rty().kind(), IntKind);
			BOOST_CHECK_EQUAL(decl.rty().len(), 32);
			BOOST_CHECK_EQUAL(decl.params().size(), 2);
		} else if (decl.ref() == Ref("fn2")) {
			foundFn2 = true;
			BOOST_CHECK_EQUAL(decl.rty().kind(), IntKind);
			BOOST_CHECK_EQUAL(decl.rty().len(), 32);
			BOOST_CHECK_EQUAL(decl.params().size(), 1);
			BOOST_CHECK_EQUAL(decl.params()[0].ty().len(), 64);
		}
	}

	BOOST_CHECK(foundFn1);
	BOOST_CHECK(foundFn2);

	// Clean up
	delete module1;
	delete module2;
	delete module3;
}

BOOST_AUTO_TEST_CASE(TestLinkFunctionDefinitions) {
	resetTestState();

	// Create modules with function definitions
	Module* module1 = createSimpleModule("module1");
	module1->defs.push_back(createFnDef(intTy(32), Ref("fn1"), {intTy(32), intTy(32)}));
	module1->externals.insert(Ref("fn1"));

	Module* module2 = createSimpleModule("module2");
	module2->defs.push_back(createFnDef(voidTy(), Ref("fn2"), {intTy(64)}));
	module2->externals.insert(Ref("fn2"));

	modules.push_back(module1);
	modules.push_back(module2);

	link();

	// Verify context has the definitions
	BOOST_CHECK_EQUAL(context.defs.size(), 2);
	BOOST_CHECK_EQUAL(context.externals.size(), 2);

	bool foundFn1 = false;
	bool foundFn2 = false;

	for (const auto& def : context.defs) {
		if (def.ref() == Ref("fn1")) {
			foundFn1 = true;
			BOOST_CHECK_EQUAL(def.rty().kind(), IntKind);
			BOOST_CHECK_EQUAL(def.rty().len(), 32);
			BOOST_CHECK_EQUAL(def.params().size(), 2);
			BOOST_CHECK(!def.empty());
		} else if (def.ref() == Ref("fn2")) {
			foundFn2 = true;
			BOOST_CHECK_EQUAL(def.rty().kind(), VoidKind);
			BOOST_CHECK_EQUAL(def.params().size(), 1);
			BOOST_CHECK(!def.empty());
		}
	}

	BOOST_CHECK(foundFn1);
	BOOST_CHECK(foundFn2);

	// Clean up
	delete module1;
	delete module2;
}

BOOST_AUTO_TEST_CASE(TestLinkInternalRenaming) {
	resetTestState();

	// Create modules with internal (non-external) globals and functions
	Module* module1 = createSimpleModule("module1");
	module1->globals.push_back(createGlobal(intTy(32), Ref("internal_var"), true));
	module1->defs.push_back(createFnDef(voidTy(), Ref("internal_fn"), {}));
	// Not adding them to externals

	Module* module2 = createSimpleModule("module2");
	module2->globals.push_back(createGlobal(intTy(32), Ref("internal_var"), true));
	module2->defs.push_back(createFnDef(voidTy(), Ref("internal_fn"), {}));
	// Not adding them to externals

	modules.push_back(module1);
	modules.push_back(module2);

	link();

	// Verify context has the globals and functions with renamed internals
	BOOST_CHECK_EQUAL(context.globals.size(), 2);
	BOOST_CHECK_EQUAL(context.defs.size(), 2);
	BOOST_CHECK_EQUAL(context.externals.size(), 0);

	// Make sure the internal symbols were renamed
	auto refs = vector<Ref>();
	for (const auto& global : context.globals) {
		refs.push_back(global.ref());
	}
	for (const auto& def : context.defs) {
		refs.push_back(def.ref());
	}

	// Check that we have 4 unique references (no duplicates)
	std::sort(refs.begin(), refs.end());
	auto last = std::unique(refs.begin(), refs.end());
	BOOST_CHECK_EQUAL(std::distance(refs.begin(), last), 4);

	// Clean up
	delete module1;
	delete module2;
}

BOOST_AUTO_TEST_CASE(TestLinkWithReferences) {
	resetTestState();

	// Create modules with references to each other's globals
	Module* module1 = createSimpleModule("module1");

	// Create a global variable that module2 will reference
	Global var1 = createGlobal(intTy(32), Ref("shared_var"), true);
	module1->globals.push_back(var1);
	module1->externals.insert(Ref("shared_var"));

	// Create a function that references a global from module2
	vector<Term> params = {};
	vector<Inst> body = {block(Ref("entry")),
		// Reference to a global that will be in module2
		Inst(Store, intConst(42), globalRef(ptrTy(), Ref("module2_var"))),
		ret()};
	Fn fn1 = Fn(voidTy(), Ref("fn_with_ref"), params, body);
	module1->defs.push_back(fn1);
	module1->externals.insert(Ref("fn_with_ref"));

	Module* module2 = createSimpleModule("module2");

	// Create the global that module1 references
	Global var2 = createGlobal(intTy(32), Ref("module2_var"), true);
	module2->globals.push_back(var2);
	module2->externals.insert(Ref("module2_var"));

	// Create a function that references the global from module1
	vector<Inst> body2 = {block(Ref("entry")),
		// Reference to a global from module1
		Inst(Store, intConst(24), globalRef(ptrTy(), Ref("shared_var"))),
		ret()};
	Fn fn2 = Fn(voidTy(), Ref("fn_with_ref2"), params, body2);
	module2->defs.push_back(fn2);
	module2->externals.insert(Ref("fn_with_ref2"));

	modules.push_back(module1);
	modules.push_back(module2);

	link();

	// Verify references were preserved
	BOOST_CHECK_EQUAL(context.globals.size(), 2);
	BOOST_CHECK_EQUAL(context.defs.size(), 2);
	BOOST_CHECK_EQUAL(context.externals.size(), 4);

	// Find the functions and check their bodies
	bool foundFn1 = false;
	bool foundFn2 = false;

	for (const auto& def : context.defs) {
		if (def.ref() == Ref("fn_with_ref")) {
			foundFn1 = true;
			// Check that it still references module2_var
			BOOST_CHECK(!def.empty());
			BOOST_CHECK_EQUAL(def.size(), 3); // block, store, ret

			Inst storeInst = def[1];
			BOOST_CHECK_EQUAL(storeInst.opcode(), Store);
			BOOST_CHECK_EQUAL(storeInst[1].tag(), GlobalRef);
			BOOST_CHECK_EQUAL(storeInst[1].ref(), Ref("module2_var"));
		} else if (def.ref() == Ref("fn_with_ref2")) {
			foundFn2 = true;
			// Check that it still references shared_var
			BOOST_CHECK(!def.empty());
			BOOST_CHECK_EQUAL(def.size(), 3); // block, store, ret

			Inst storeInst = def[1];
			BOOST_CHECK_EQUAL(storeInst.opcode(), Store);
			BOOST_CHECK_EQUAL(storeInst[1].tag(), GlobalRef);
			BOOST_CHECK_EQUAL(storeInst[1].ref(), Ref("shared_var"));
		}
	}

	BOOST_CHECK(foundFn1);
	BOOST_CHECK(foundFn2);

	// Clean up
	delete module1;
	delete module2;
}

BOOST_AUTO_TEST_CASE(TestLinkTypeErrorMismatch) {
	resetTestState();

	// Create modules with conflicting types for the same global
	Module* module1 = createSimpleModule("module1");
	module1->globals.push_back(createGlobal(intTy(32), Ref("conflict_var"), true));
	module1->externals.insert(Ref("conflict_var"));

	Module* module2 = createSimpleModule("module2");
	module2->globals.push_back(createGlobal(intTy(64), Ref("conflict_var"), true));
	module2->externals.insert(Ref("conflict_var"));

	modules.push_back(module1);
	modules.push_back(module2);

	// Linking should throw an exception due to type mismatch
	BOOST_CHECK_THROW(link(), runtime_error);

	// Clean up
	delete module1;
	delete module2;
}

BOOST_AUTO_TEST_CASE(TestLinkFunctionDuplicateDefinition) {
	resetTestState();

	// Create modules with duplicate function definitions
	Module* module1 = createSimpleModule("module1");
	module1->defs.push_back(createFnDef(intTy(32), Ref("duplicate_fn"), {intTy(32)}));
	module1->externals.insert(Ref("duplicate_fn"));

	Module* module2 = createSimpleModule("module2");
	module2->defs.push_back(createFnDef(intTy(32), Ref("duplicate_fn"), {intTy(32)}));
	module2->externals.insert(Ref("duplicate_fn"));

	modules.push_back(module1);
	modules.push_back(module2);

	// Linking should throw an exception due to duplicate definition
	BOOST_CHECK_THROW(link(), runtime_error);

	// Clean up
	delete module1;
	delete module2;
}

BOOST_AUTO_TEST_CASE(TestLinkFunctionDeclarationMismatch) {
	resetTestState();

	// Create modules with mismatched function declarations
	Module* module1 = createSimpleModule("module1");
	module1->decls.push_back(createFnDecl(intTy(32), Ref("mismatch_fn"), {intTy(32), intTy(32)}));
	module1->externals.insert(Ref("mismatch_fn"));

	Module* module2 = createSimpleModule("module2");
	module2->decls.push_back(createFnDecl(intTy(32), Ref("mismatch_fn"), {intTy(32)})); // Different param count
	module2->externals.insert(Ref("mismatch_fn"));

	modules.push_back(module1);
	modules.push_back(module2);

	// Linking should throw an exception due to declaration mismatch
	BOOST_CHECK_THROW(link(), runtime_error);

	// Clean up
	delete module1;
	delete module2;
}
