// Replace terms with other terms, according to the map
// Works recursively, first calling itself on subterms
// Intended for renaming variables and functions
// and for replacing variables with known values
// but works for any terms
Term replace(Term, const unordered_map<Term, Term>&);

// Transform an instruction by performing term replacement over all operands
Inst replace(Inst, const unordered_map<Term, Term>&);
