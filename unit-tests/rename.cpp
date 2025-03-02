#include "all.h"
#include <boost/test/unit_test.hpp>

// Helper function to create a simple test module
Module createTestModule() {
	Module module;

	// Add some global variables
	module.globals.push_back(Global(intTy(32), Ref("global1")));
	module.globals.push_back(Global(ptrTy(), Ref("global_ptr"), nullPtrConst));
	module.globals.push_back(Global(intTy(8), Ref("byte_var"), intConst(intTy(8), 42)));

	// Add some function declarations
	vector<Term> emptyParams;
	module.decls.push_back(Fn(voidTy(), Ref("external_func"), emptyParams));

	vector<Term> intParam = {var(intTy(32), Ref("param1"))};
	module.decls.push_back(Fn(intTy(32), Ref("math_func"), intParam));

	// Add a function definition
	vector<Term> params = {var(intTy(32), Ref("x")), var(intTy(32), Ref("y"))};
	vector<Inst> body;

	// Function body: add x and y, return the result
	Term xVar = var(intTy(32), Ref("x"));
	Term yVar = var(intTy(32), Ref("y"));
	Term resultVar = var(intTy(32), Ref("result"));
	Term addResult = Term(Add, intTy(32), xVar, yVar);

	body.push_back(block(Ref("entry")));
	body.push_back(assign(resultVar, addResult));
	body.push_back(ret(resultVar));

	module.defs.push_back(Fn(intTy(32), Ref("add_func"), params, body));

	// Add a function that calls another function
	vector<Term> callerParams;
	vector<Inst> callerBody;

	// Create a GlobalRef to the target function
	Type fnType = fnTy(intTy(32), {intTy(32)});
	Term mathFuncRef = globalRef(fnType, Ref("math_func"));

	// Call the function with constant 5
	Term constArg = intConst(intTy(32), 5);
	vector<Term> callArgs = {constArg};
	Term callResult = call(intTy(32), mathFuncRef, callArgs);

	callerBody.push_back(block(Ref("entry")));
	callerBody.push_back(ret(callResult));

	module.defs.push_back(Fn(intTy(32), Ref("caller_func"), callerParams, callerBody));

	return module;
}

// Helper function to check if a global with specific reference exists
bool hasGlobalWithRef(const Module& module, const Ref& ref) {
	for (const auto& global : module.globals) {
		if (global.ref() == ref) {
			return true;
		}
	}
	return false;
}

// Helper function to check if a function (declaration or definition) with specific reference exists
bool hasFunctionWithRef(const Module& module, const Ref& ref, bool isDef) {
	const auto& functions = isDef ? module.defs : module.decls;
	for (const auto& func : functions) {
		if (func.ref() == ref) {
			return true;
		}
	}
	return false;
}

// Helper function to find a function by reference
Fn findFunction(const Module& module, const Ref& ref, bool isDef) {
	const auto& functions = isDef ? module.defs : module.decls;
	for (const auto& func : functions) {
		if (func.ref() == ref) {
			return func;
		}
	}
	throw runtime_error("Function not found");
}

BOOST_AUTO_TEST_CASE(test_rename_globals) {
	Module module = createTestModule();

	// Create rename mapping
	unordered_map<Ref, Ref> renameMap;
	renameMap[Ref("global1")] = Ref("renamed_global1");
	renameMap[Ref("byte_var")] = Ref("renamed_byte_var");

	// Apply rename
	rename(&module, renameMap);

	// Check if globals were renamed
	BOOST_CHECK(!hasGlobalWithRef(module, Ref("global1")));
	BOOST_CHECK(hasGlobalWithRef(module, Ref("renamed_global1")));

	BOOST_CHECK(!hasGlobalWithRef(module, Ref("byte_var")));
	BOOST_CHECK(hasGlobalWithRef(module, Ref("renamed_byte_var")));

	// Check that unrenamed globals remain unchanged
	BOOST_CHECK(hasGlobalWithRef(module, Ref("global_ptr")));
}

BOOST_AUTO_TEST_CASE(test_rename_functions) {
	Module module = createTestModule();

	// Create rename mapping
	unordered_map<Ref, Ref> renameMap;
	renameMap[Ref("external_func")] = Ref("renamed_external_func");
	renameMap[Ref("add_func")] = Ref("renamed_add_func");

	// Apply rename
	rename(&module, renameMap);

	// Check if function declarations were renamed
	BOOST_CHECK(!hasFunctionWithRef(module, Ref("external_func"), false));
	BOOST_CHECK(hasFunctionWithRef(module, Ref("renamed_external_func"), false));

	// Check if function definitions were renamed
	BOOST_CHECK(!hasFunctionWithRef(module, Ref("add_func"), true));
	BOOST_CHECK(hasFunctionWithRef(module, Ref("renamed_add_func"), true));

	// Check that unrenamed functions remain unchanged
	BOOST_CHECK(hasFunctionWithRef(module, Ref("math_func"), false));
	BOOST_CHECK(hasFunctionWithRef(module, Ref("caller_func"), true));
}

BOOST_AUTO_TEST_CASE(test_rename_references_in_functions) {
	Module module = createTestModule();

	// Create rename mapping
	unordered_map<Ref, Ref> renameMap;
	renameMap[Ref("math_func")] = Ref("renamed_math_func");

	// Apply rename
	rename(&module, renameMap);

	// Find the caller function
	Fn callerFunc = findFunction(module, Ref("caller_func"), true);

	// Check that the function reference in the call has been updated
	// The return instruction should be the second instruction (index 1)
	Inst retInst = callerFunc[1];

	// The return value is the first operand of the Ret instruction
	Term callTerm = retInst[0];

	// The function being called is the first operand of the Call term
	Term funcRef = callTerm[0];

	// Check that the function reference is to the renamed function
	BOOST_CHECK(funcRef.tag() == GlobalRef);
	BOOST_CHECK(funcRef.ref() == Ref("renamed_math_func"));
}

BOOST_AUTO_TEST_CASE(test_rename_preserves_values) {
	Module module = createTestModule();

	// Create rename mapping
	unordered_map<Ref, Ref> renameMap;
	renameMap[Ref("byte_var")] = Ref("renamed_byte_var");

	// Apply rename
	rename(&module, renameMap);

	// Find the renamed global
	Global renamedGlobal;
	bool found = false;

	for (const auto& global : module.globals) {
		if (global.ref() == Ref("renamed_byte_var")) {
			renamedGlobal = global;
			found = true;
			break;
		}
	}

	BOOST_CHECK(found);

	// Check that the value is preserved
	Term val = renamedGlobal.val();
	BOOST_CHECK(val.tag() == Int);
	BOOST_CHECK(val.intVal() == 42);
}

BOOST_AUTO_TEST_CASE(test_rename_complex_references) {
	Module module = createTestModule();

	// Create a more complex module with nested references
	// Add a global that references another global
	Term globalRef1 = globalRef(intTy(8), Ref("byte_var"));
	module.globals.push_back(Global(intTy(8), Ref("ref_to_byte"), globalRef1));

	// Create rename mapping
	unordered_map<Ref, Ref> renameMap;
	renameMap[Ref("byte_var")] = Ref("renamed_byte_var");

	// Apply rename
	rename(&module, renameMap);

	// Find the global that had a reference
	Global refToByteGlobal;
	bool found = false;

	for (const auto& global : module.globals) {
		if (global.ref() == Ref("ref_to_byte")) {
			refToByteGlobal = global;
			found = true;
			break;
		}
	}

	BOOST_CHECK(found);

	// Check that the reference was updated
	Term valRef = refToByteGlobal.val();
	BOOST_CHECK(valRef.tag() == GlobalRef);
	BOOST_CHECK(valRef.ref() == Ref("renamed_byte_var"));
}

BOOST_AUTO_TEST_CASE(test_rename_function_body_references) {
	Module module = createTestModule();

	// Add a function that uses a global
	vector<Term> params;
	vector<Inst> body;

	// Create a GlobalRef to a global variable
	Term globalVarRef = globalRef(intTy(8), Ref("byte_var"));

	body.push_back(block(Ref("entry")));
	body.push_back(ret(globalVarRef));

	module.defs.push_back(Fn(intTy(8), Ref("use_global_func"), params, body));

	// Create rename mapping
	unordered_map<Ref, Ref> renameMap;
	renameMap[Ref("byte_var")] = Ref("renamed_byte_var");

	// Apply rename
	rename(&module, renameMap);

	// Find the function that uses the global
	Fn useGlobalFunc = findFunction(module, Ref("use_global_func"), true);

	// Check that the global reference in the function has been updated
	// The return instruction should be the second instruction (index 1)
	Inst retInst = useGlobalFunc[1];

	// The return value is the first operand of the Ret instruction
	Term globalRef = retInst[0];

	// Check that the global reference is to the renamed global
	BOOST_CHECK(globalRef.tag() == GlobalRef);
	BOOST_CHECK(globalRef.ref() == Ref("renamed_byte_var"));
}
