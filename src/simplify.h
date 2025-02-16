// Simplify expressions
// This includes constant folding
// but also trivial arithmetic and logic simplification like a+0 = a
// For now, it does not attempt to evaluate floating-point arithmetic or comparison
// The environment parameter may specify values for some but not all variables
Term simplify(const unordered_map<Term, Term>& env, Term a);
