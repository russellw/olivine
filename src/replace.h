// Replace terms with other terms, according to the map
// Works recursively, first calling itself on subterms
// Intended for renaming variables and functions
// and for replacing variables with known values
// but can replace any atomic terms
Term replace(Term, const unordered_map<Term, Term>&);

// Transform an instruction by performing term replacement over all operands
Inst replace(Inst, const unordered_map<Term, Term>&);

// Transform a function by performing term replacement over all parameters and instructions
Fn replace(Fn, const unordered_map<Term, Term>&);
