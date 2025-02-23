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

// Helper to get string representation of a Ref
string refToString(const Ref& ref) {
	if (std::holds_alternative<string>(ref)) {
		return std::get<string>(ref);
	} else {
		return std::to_string(std::get<size_t>(ref));
	}
}

Func convertToAllocas(const Func& func) {
	// First pass: identify all mutable variables
	unordered_set<Ref> mutatedVars;
	for (const Inst& inst : func) {
		if (inst.opcode() == Assign && inst[0].tag() == Var) {
			mutatedVars.insert(inst[0].ref());
		}
	}

	// Start building new function body
	vector<Inst> newBody;

	// Create allocas upfront for all mutable variables
	for (const Ref& varRef : mutatedVars) {
		// Find first use to get type
		Type varType;
		for (const Inst& inst : func) {
			for (const Term& term : inst) {
				if (term.tag() == Var && term.ref() == varRef) {
					varType = term.ty();
					goto found_type;
				}
			}
		}
	found_type:

		// Create alloca for this variable
		Term ptr = var(ptrTy(), Ref(refToString(varRef) + ".ptr"));
		newBody.push_back(alloca(ptr, varType, intConst(intTy(64), 1)));
	}

	// Transform the function body
	for (const Inst& inst : func) {
		if (inst.opcode() == Assign && inst[0].tag() == Var) {
			// Convert assignment to store
			Ref varRef = inst[0].ref();
			if (mutatedVars.find(varRef) != mutatedVars.end()) {
				Term ptr = var(ptrTy(), Ref(refToString(varRef) + ".ptr"));
				newBody.push_back(store(inst[1], ptr));
			} else {
				// Non-mutable assignment, keep as is
				newBody.push_back(inst);
			}
		} else {
			// For all other instructions, replace variable uses with loads
			vector<Term> newOperands;
			bool needsReplacement = false;

			for (const Term& term : inst) {
				if (term.tag() == Var && mutatedVars.find(term.ref()) != mutatedVars.end()) {
					// Load from the alloca
					Term ptr = var(ptrTy(), Ref(refToString(term.ref()) + ".ptr"));
					Term loadDest = var(term.ty(), Ref(refToString(term.ref()) + ".load"));

					// Create load instruction with proper Opcode
					vector<Term> loadOperands = {loadDest, ptr};
					newBody.push_back(Inst(static_cast<Opcode>(Load), loadOperands));

					newOperands.push_back(loadDest);
					needsReplacement = true;
				} else {
					newOperands.push_back(term);
				}
			}

			// Add the transformed instruction
			if (needsReplacement) {
				newBody.push_back(Inst(inst.opcode(), newOperands));
			} else {
				newBody.push_back(inst);
			}
		}
	}

	return Func(func.rty(), func.ref(), func.params(), newBody);
}
