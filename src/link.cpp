#include "all.h"

void link() {
	// Rename internal globals in each module to avoid conflicts
	for (auto module : modules) {
		renameInternals(module);
	}

	// Mapping for global variables and functions
	unordered_map<Ref, Ref> globalRefs;

	// Process each module
	for (auto module : modules) {
		// Merge comdats
		context.comdats.insert(context.comdats.end(), module->comdats.begin(), module->comdats.end());

		// Process global variables
		for (const auto& global : module->globals) {
			Ref originalRef = global.ref();

			// If this global is not in externals, it's already been renamed to be unique
			// Otherwise, if the name is already in context, map it
			if (module->externals.count(originalRef) &&
				any_of(context.globals.begin(), context.globals.end(),
					   [&originalRef](const Global& g) { return g.ref() == originalRef; })) {
				// Find the existing global in context
				for (const auto& g : context.globals) {
					if (g.ref() == originalRef) {
						// Check type compatibility
						if (g.ty() != global.ty()) {
							throw runtime_error("Type mismatch for global: " + wrap(originalRef.str()));
						}

						// Add to mapping
						globalRefs[originalRef] = g.ref();
						break;
					}
				}
			} else {
				// Add this global to context
				context.globals.push_back(global);

				// If it's external, add it to context's externals
				if (module->externals.count(originalRef)) {
					context.externals.insert(originalRef);
				}
			}
		}

		// Process function declarations
		for (const auto& decl : module->decls) {
			Ref originalRef = decl.ref();

			// Check if we already have this declaration
			bool exists = false;
			for (const auto& d : context.decls) {
				if (d.ref() == originalRef) {
					// Check return type and parameter compatibility
					if (d.rty() != decl.rty() || d.params().size() != decl.params().size()) {
						throw runtime_error("Function declaration mismatch: " + wrap(originalRef.str()));
					}

					// Check parameter types
					for (size_t i = 0; i < d.params().size(); i++) {
						if (d.params()[i].ty() != decl.params()[i].ty()) {
							throw runtime_error("Function parameter type mismatch: " + wrap(originalRef.str()));
						}
					}

					exists = true;
					globalRefs[originalRef] = d.ref();
					break;
				}
			}

			if (!exists) {
				// Add this declaration to context
				context.decls.push_back(decl);

				// If it's external, add it to context's externals
				if (module->externals.count(originalRef)) {
					context.externals.insert(originalRef);
				}
			}
		}

		// Process function definitions
		for (const auto& def : module->defs) {
			Ref originalRef = def.ref();

			// Check if we already have this definition
			bool exists = false;
			for (const auto& d : context.defs) {
				if (d.ref() == originalRef) {
					throw runtime_error("Duplicate function definition: " + wrap(originalRef.str()));
				}
			}

			// Add this definition to context
			context.defs.push_back(def);

			// If it's external, add it to context's externals
			if (module->externals.count(originalRef)) {
				context.externals.insert(originalRef);
			}
		}
	}

	// Replace references in globals and functions
	if (!globalRefs.empty()) {
		// Create a mapping from Term to Term for replacement
		unordered_map<Term, Term> termMap;
		for (const auto& [oldRef, newRef] : globalRefs) {
			// We need to find the type of this global
			Type ty;

			// Look in context globals
			for (const auto& g : context.globals) {
				if (g.ref() == oldRef) {
					ty = g.ty();
					break;
				}
			}

			// If not found, look in function declarations
			if (ty == Type()) {
				for (const auto& d : context.decls) {
					if (d.ref() == oldRef) {
						// Function type
						ty = fnTy(d.rty(), map(d.params(), [](Term t) { return t.ty(); }));
						break;
					}
				}
			}

			// If not found, look in function definitions
			if (ty == Type()) {
				for (const auto& d : context.defs) {
					if (d.ref() == oldRef) {
						// Function type
						ty = fnTy(d.rty(), map(d.params(), [](Term t) { return t.ty(); }));
						break;
					}
				}
			}

			// Create mapping from old Term to new Term
			if (ty != Type()) {
				termMap[globalRef(ty, oldRef)] = globalRef(ty, newRef);
			}
		}

		// Update globals
		for (auto& global : context.globals) {
			global = replace(global, termMap);
		}

		// Update function definitions
		for (auto& def : context.defs) {
			def = replace(def, termMap);
		}
	}
}
