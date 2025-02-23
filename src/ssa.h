// Converts LLVM-style phi nodes into equivalent code using mutable local variables
Func eliminatePhiNodes(const Func& func);

// Convert back to SSA form in preparation for LLVM output
Func convertToSSA(const Func& f);
