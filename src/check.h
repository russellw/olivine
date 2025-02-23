// Check that a term is consistent
// for example, that all operands have valid types for the operation
// and throw an exception if not
// This function is not recursive; it only checks the top level of a compound type
void check(Term);

// Recursive checker function that validates a term and all its nested subterms
void checkRecursive(Term);

// Check that an instruction is consistent
// Run checkRecursive on all operands
// then perform additional checks to make sure every operand is valid for the instruction
void check(Inst);

// Check that a function definition is consistent
// Olivine does not use phi internally
// and this is meant to be used after converting freshly parsed modules to internal form
// so also checks for the absence of phi
void check(Func);
