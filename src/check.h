// Check that a term is consistent
// for example, that all operands have valid types for the operation
// and throw an exception if not
// This function is not recursive; it only checks the top level of a compound type
void check(Term a);

// Recursive checker function that validates a term and all its nested subterms
void checkRecursive(Term a);
