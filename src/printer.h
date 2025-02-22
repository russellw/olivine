// Output a reference in format suitable for an LLVM identifier
// That is, an index number is printed unchanged
// A string that is already a valid LLVM identifier is printed unchanged
// A string that begins with a digit, or is otherwise not a valid identifier, is wrapped in quotes
// and special characters are escaped as a pair of hex digits
// with the single exception of `\` which is converted to `\\`
ostream& operator<<(ostream& os, const Ref& ref);

// Output a type in LLVM format
ostream& operator<<(ostream& os, Type ty);

// Output a term in LLVM format
// Compound terms are printed in constant expression format
// LLVM itself now only supports constant expressions for basic arithmetic operations
// but extending it to other operators is still useful for debugging
// Note that when printing instructions, this function can only be used for atomic terms
// as instructions have a different format for operator with operands
ostream& operator<<(ostream& os, Term a);

// Output an instruction in LLVM format
ostream& operator<<(ostream& os, Inst inst);

// Output a function in LLVM format
// with `declare` or `define` depending on whether the function has a body
ostream& operator<<(ostream& os, Func);
