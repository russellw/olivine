#include "all.h"

Term replace(Term term, const unordered_map<Term, Term>& replacements) {
	// First, check if the term itself is in the replacement map
	if (term.size() == 0) {
		auto it = replacements.find(term);
		if (it != replacements.end()) {
			return it->second;
		}
	}

	// If term is not a compound term (has no children), return it unchanged
	if (term.size() == 0) {
		return term;
	}

	// Process children recursively
	vector<Term> newOperands;
	newOperands.reserve(term.size());

	bool changed = false;
	for (const Term& operand : term) {
		Term newOperand = replace(operand, replacements);
		newOperands.push_back(newOperand);
		if (newOperand != operand) {
			changed = true;
		}
	}

	// If none of the operands changed, return the original term
	if (!changed) {
		return term;
	}

	// Create a new term with the same tag and type, but with the new operands
	return Term(term.tag(), term.ty(), newOperands);
}

Inst replace(Inst inst, const unordered_map<Term, Term>& replacements) {
	// If the instruction has no operands, return it as is
	if (inst.size() == 0) {
		return inst;
	}

	// Create a vector to hold the transformed operands
	vector<Term> newOperands;
	newOperands.reserve(inst.size());

	// Transform each operand
	for (size_t i = 0; i < inst.size(); ++i) {
		// Apply replacement recursively to each operand
		newOperands.push_back(replace(inst[i], replacements));
	}

	// Create a new instruction with the same opcode but with transformed operands
	return Inst(inst.opcode(), newOperands);
}

Global replace(Global global, const unordered_map<Term, Term>& replacements) {
	// Create a new Global with the same type and reference
	Global result(global.ty(), global.ref());

	// If the global has a value, replace it
	if (global.val().tag() != None) {
		// Apply term replacement to the value
		Term newVal = replace(global.val(), replacements);

		// Create a new Global with the replaced value
		return Global(global.ty(), global.ref(), newVal);
	}

	// If there's no value (just a declaration), return the original
	return result;
}

Fn replace(Fn func, const unordered_map<Term, Term>& replacements) {
	// Create a new function with the same return type and reference
	Type returnType = func.rty();
	Ref funcRef = func.ref();

	// Replace all parameters
	vector<Term> newParams;
	for (const Term& param : func.params()) {
		newParams.push_back(replace(param, replacements));
	}

	// Replace all instructions in the function body
	vector<Inst> newBody;
	for (const Inst& inst : func) {
		newBody.push_back(replace(inst, replacements));
	}

	// Create and return a new function with the replaced parameters and body
	return Fn(returnType, funcRef, newParams, newBody);
}

void rename(Module* module, const unordered_map<Ref, Ref>& renameMap) {
	// Create maps for converting global references
	unordered_map<Term, Term> termRenameMap;

	// Process globals
	vector<Global> newGlobals;
	for (const Global& global : module->globals) {
		Ref oldRef = global.ref();

		// Check if this global should be renamed
		auto it = renameMap.find(oldRef);
		if (it != renameMap.end()) {
			Ref newRef = it->second;

			// Create new global with renamed reference
			Global newGlobal = Global(global.ty(), newRef);

			// If global has a value, apply the same rename process
			if (global.val() != Term()) {
				newGlobal = Global(global.ty(), newRef, global.val());
			}

			// Add mapping for any references to this global
			termRenameMap[globalRef(global.ty(), oldRef)] = globalRef(global.ty(), newRef);

			newGlobals.push_back(newGlobal);
		} else {
			// Keep the global as is
			newGlobals.push_back(global);
		}
	}

	// Replace globals with renamed versions
	module->globals = newGlobals;

	// Process function declarations
	vector<Fn> newDecls;
	for (const Fn& decl : module->decls) {
		Ref oldRef = decl.ref();

		// Check if this function should be renamed
		auto it = renameMap.find(oldRef);
		if (it != renameMap.end()) {
			Ref newRef = it->second;

			// Create new declaration with renamed reference
			Fn newDecl = Fn(decl.rty(), newRef, decl.params());

			// Add mapping for any references to this function
			Type fnType = fnTy(decl.rty(), map(decl.params(), [](Term p) { return p.ty(); }));
			termRenameMap[globalRef(fnType, oldRef)] = globalRef(fnType, newRef);

			newDecls.push_back(newDecl);
		} else {
			// Keep the declaration as is
			newDecls.push_back(decl);
		}
	}

	// Replace declarations with renamed versions
	module->decls = newDecls;

	// Process function definitions
	vector<Fn> newDefs;
	for (const Fn& def : module->defs) {
		Ref oldRef = def.ref();

		// Check if this function should be renamed
		auto it = renameMap.find(oldRef);
		if (it != renameMap.end()) {
			Ref newRef = it->second;

			// Create new definition with renamed reference and body
			vector<Term> params = def.params();
			vector<Inst> body(def.begin(), def.end());

			Fn newDef = Fn(def.rty(), newRef, params, body);

			// Add mapping for any references to this function
			Type fnType = fnTy(def.rty(), map(def.params(), [](Term p) { return p.ty(); }));
			termRenameMap[globalRef(fnType, oldRef)] = globalRef(fnType, newRef);

			newDefs.push_back(newDef);
		} else {
			// Keep the definition as is
			newDefs.push_back(def);
		}
	}

	// Replace definitions with renamed versions
	module->defs = newDefs;

	// Apply the term replacements to all globals that have values
	for (auto& global : module->globals) {
		Term val = global.val();
		if (val != Term()) { // Check if global has a value
			global = replace(global, termRenameMap);
		}
	}

	// Apply the term replacements to all function bodies
	for (auto& def : module->defs) {
		def = replace(def, termRenameMap);
	}
}
