#include "all.h"

Func eliminatePhiNodes(const Func& func) {
	if (func.empty()) {
		return func;
	}

	// Step 1: Collect all phi instructions and their variables
	struct PhiInfo {
		Term targetVar;
		vector<pair<Term, Term>> valuesAndLabels; // pairs of (value, label)
	};

	unordered_map<Ref, PhiInfo> phiNodes;
	unordered_map<Ref, size_t> labelToIndex;
	vector<Inst> newBody;

	// First pass: collect phi nodes and build label index
	for (size_t i = 0; i < func.size(); i++) {
		const Inst& inst = func[i];
		if (inst.opcode() == Block) {
			labelToIndex[inst[0].ref()] = i;
		} else if (inst.opcode() == Phi) {
			PhiInfo info;
			info.targetVar = inst[0];

			// Collect value-label pairs from phi instruction
			for (size_t j = 1; j < inst.size(); j += 2) {
				info.valuesAndLabels.push_back({inst[j], inst[j + 1]});
			}

			phiNodes[info.targetVar.ref()] = info;
		}
	}

	if (phiNodes.empty()) {
		return func; // No phi nodes to eliminate
	}

	// Step 2: Process each block, handling phi assignments at the end of predecessors
	vector<Inst> result;
	size_t i = 0;
	while (i < func.size()) {
		const Inst& inst = func[i];

		if (inst.opcode() == Block) {
			result.push_back(inst);
			i++;

			// Skip any phi nodes
			while (i < func.size() && func[i].opcode() == Phi) {
				i++;
			}
			continue;
		}

		if (inst.opcode() == Br) {
			// For conditional branches, need to handle both targets
			Term cond = inst[0];
			Term trueLabel = inst[1];
			Term falseLabel = inst[2];

			// Add assignments for phi nodes in true target
			for (const auto& [ref, phi] : phiNodes) {
				for (const auto& [value, label] : phi.valuesAndLabels) {
					if (label.ref() == trueLabel.ref()) {
						result.push_back(assign(phi.targetVar, value));
						break;
					}
				}
			}

			// Add the branch instruction
			result.push_back(inst);
			i++;
			continue;
		}

		if (inst.opcode() == Jmp) {
			Term target = inst[0];

			// Add assignments for phi nodes in the target block
			for (const auto& [ref, phi] : phiNodes) {
				for (const auto& [value, label] : phi.valuesAndLabels) {
					if (label.ref() == target.ref()) {
						result.push_back(assign(phi.targetVar, value));
						break;
					}
				}
			}

			result.push_back(inst);
			i++;
			continue;
		}

		// Copy other instructions as-is
		result.push_back(inst);
		i++;
	}

	return Func(func.rty(), func.ref(), func.params(), result);
}

// Helper: create a load term from a pointer.
// (Assumes that Load takes a pointer operand and returns a value of type “ty”.)
inline Term loadFromAlloca(const Term& ptr, Type ty) {
	// Construct a load term. Here we use the Load tag and assume the first operand is the pointer.
	return Term(Load, ty, ptr);
}

// convertToSSA turns mutable variables into allocas.
Func convertToSSA(const Func& f) {
	vector<Inst> newBody;
	// Map from variable identifier (Ref) to the pointer (Term) returned by its alloca.
	unordered_map<Ref, Term> varAlloca;

	// --- Step 1. Insert allocas for all function parameters.
	// We assume parameters are declared as Var terms.
	for (Term param : f.params()) {
		Ref name = param.ref();
		Type ty = param.ty();
		// Create a pointer term to hold the allocated memory.
		Term ptr = var(ptrTy(), name);
		// Create an alloca instruction.
		// Note: we use intConst(intTy(64), 1) to represent the number of elements.
		newBody.push_back(alloca(ptr, ty, intConst(intTy(64), 1)));
		// Save the mapping.
		varAlloca[name] = ptr;
	}

	// --- Step 2. Process each instruction in the original function body.
	// For each instruction, we walk its operands: if an operand is a variable that was lowered,
	// we replace it by a load from its alloca.
	for (size_t i = 0; i < f.size(); ++i) {
		Inst inst = f[i];
		// Special handling for assignments:
		// We assume that an assign instruction has two operands:
		//   operand 0: the variable being written (a Var term)
		//   operand 1: the value to be stored.
		if (inst.opcode() == Assign) {
			Term lhs = inst[0];
			Term rhs = inst[1];
			// If lhs is a variable, ensure we have allocated storage for it.
			if (lhs.tag() == Var) {
				Ref name = lhs.ref();
				// If we haven’t seen this variable before, insert an alloca at the beginning.
				if (varAlloca.find(name) == varAlloca.end()) {
					Term ptr = var(ptrTy(), name);
					// Prepend the alloca instruction.
					newBody.insert(newBody.begin(), alloca(ptr, lhs.ty(), intConst(intTy(64), 1)));
					varAlloca[name] = ptr;
				}
				// Replace the assignment with a store into the allocated memory.
				newBody.push_back(store(rhs, varAlloca[name]));
			} else {
				// If not a Var, just copy the instruction.
				newBody.push_back(inst);
			}
		} else {
			// For all other instructions, rebuild the operands,
			// replacing any variable use (i.e. a Var whose ref is in varAlloca)
			// with a load from the corresponding alloca.
			vector<Term> newOps;
			for (size_t j = 0; j < inst.size(); ++j) {
				Term opnd = inst[j];
				if (opnd.tag() == Var && varAlloca.find(opnd.ref()) != varAlloca.end()) {
					// Replace with a load.
					newOps.push_back(loadFromAlloca(varAlloca[opnd.ref()], opnd.ty()));
				} else {
					newOps.push_back(opnd);
				}
			}
			// Rebuild the instruction with the new operands.
			// (Assumes Inst has a constructor that takes an Opcode and a vector of operands.)
			newBody.push_back(Inst(inst.opcode(), newOps));
		}
	}

	// --- Step 3. Return a new function with the same signature and new body.
	return Func(f.rty(), f.ref(), f.params(), newBody);
}
