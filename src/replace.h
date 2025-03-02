// Replace terms with other terms, according to the map
// Works recursively, first calling itself on subterms
// Intended for renaming variables and functions
// and for replacing variables with known values
// but can replace any atomic terms
Term replace(Term, const unordered_map<Term, Term>&);

// Transform an instruction by performing term replacement over all operands
Inst replace(Inst, const unordered_map<Term, Term>&);

// Transform a global variable by performing term replacement on the value, if present
Global replace(Global, const unordered_map<Term, Term>&);

// Transform a function by performing term replacement over all parameters and instructions
Fn replace(Fn, const unordered_map<Term, Term>&);

// Transform a module by changing the names of global variables and functions
// This involves both renaming global objects
// and using `replace` to update GlobalRefs in values and function bodies
void rename(Module* module, const unordered_map<Ref, Ref>&);

// In LLVM, globals (variables and functions) can be named or numbered
// Olivine reflects this by referring to them with the variant Ref type
// When generating new global references, it is most useful to do this by number
// it is efficient, and avoids the risk of generating a name with unintended significance
// This function checks all existing global numbers
// and returns a number one greater than the largest one
size_t nextGlobalNum(const Module* module);

// Rename all global variables and functions that have only internal visibility
// so that they won't conflict with globals in other modules when linked
// The new numbers for renamed globals are generated starting with nextGlobalNumber
void renameInternals(Module* module);
