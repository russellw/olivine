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
