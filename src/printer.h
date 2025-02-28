// Output a reference in format suitable for an LLVM identifier
// That is, an index number is printed unchanged
// A string that is already a valid LLVM identifier is printed unchanged
// A string that begins with a digit, or is otherwise not a valid identifier, is wrapped in quotes
// and special characters are escaped as a pair of hex digits
// with the single exception of `\` which is converted to `\\`
ostream& operator<<(ostream&, const Ref&);

// Output a type in LLVM format
ostream& operator<<(ostream&, Type);

// Output a tag as an LLVM mnemonic
// e.g.
// Add -> add
// Eq -> icmp eq
ostream& operator<<(ostream&, Tag);

// Output a term in LLVM format
// Compound terms are printed in constant expression format
// LLVM itself now only supports constant expressions for basic arithmetic operations
// but extending it to other operators is still useful for debugging
// Note that when printing instructions, this function can only be used for atomic terms
// as instructions have a different format for operator with operands
ostream& operator<<(ostream&, Term);

// Output an instruction in LLVM format
ostream& operator<<(ostream&, Inst);

// Output a global variable in LLVM format
ostream& operator<<(ostream&, Global);

// Output a function in LLVM format
// with `declare` or `define` depending on whether the function has a body
ostream& operator<<(ostream&, Fn);

// Output a module in LLVM format
// starting with target platform information from context, if present
ostream& operator<<(ostream&, Module*);
