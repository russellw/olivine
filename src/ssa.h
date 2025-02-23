// Converts LLVM-style phi nodes into equivalent code using mutable local variables
Fn eliminatePhiNodes(const Fn& func);

// Convert back to SSA form in preparation for LLVM output
Fn convertToSSA(const Fn& f);
