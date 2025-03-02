#include "all.h"

Term replace(Term term, const unordered_map<Term, Term>& replacements) {
	// First, check if the term itself is in the replacement map
	auto it = replacements.find(term);
	if (it != replacements.end()) {
		return it->second;
	}

	// If term is not a compound term (has no children), return it unchanged
	if (term.size() == 0) {
		return term;
	}

	// Process children recursively
	vector<Term> newOperands;
	newOperands.reserve(term.size());

	bool changed = false;
	for (const Term& operand : term) {
		Term newOperand = replace(operand, replacements);
		newOperands.push_back(newOperand);
		if (newOperand != operand) {
			changed = true;
		}
	}

	// If none of the operands changed, return the original term
	if (!changed) {
		return term;
	}

	// Create a new term with the same tag and type, but with the new operands
	return Term(term.tag(), term.ty(), newOperands);
}

Inst replace(Inst inst, const unordered_map<Term, Term>& replacements) {
	// If the instruction has no operands, return it as is
	if (inst.size() == 0) {
		return inst;
	}

	// Create a vector to hold the transformed operands
	vector<Term> newOperands;
	newOperands.reserve(inst.size());

	// Transform each operand
	for (size_t i = 0; i < inst.size(); ++i) {
		// Apply replacement recursively to each operand
		newOperands.push_back(replace(inst[i], replacements));
	}

	// Create a new instruction with the same opcode but with transformed operands
	return Inst(inst.opcode(), newOperands);
}
