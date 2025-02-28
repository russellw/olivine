#include "all.h"

void check(Term a) {
	// Helper function to check if a type is integral
	auto isIntegral = [](Type t) { return t.kind() == IntKind; };

	// Helper function to check if types match
	auto checkTypesMatch = [](Term a, Term b) {
		if (a.ty() != b.ty()) {
			throw runtime_error("Type mismatch between operands");
		}
	};

	// Helper function to check number of operands
	auto checkOperandCount = [](Term a, size_t expected) {
		if (a.size() != expected) {
			throw runtime_error("Incorrect number of operands");
		}
	};

	switch (a.tag()) {
	case NullPtr:
		if (a.ty().kind() != PtrKind) {
			throw runtime_error("NullPtr must have pointer type");
		}
		break;

	case Int:
		if (!isIntegral(a.ty())) {
			throw runtime_error("Int constant must have integer type");
		}
		break;

	case Float: {
		auto k = a.ty().kind();
		if (k != FloatKind && k != DoubleKind) {
			throw runtime_error("Float constant must have float or double type");
		}
	} break;

	case Add:
	case And:
	case Mul:
	case Or:
	case Sub:
	case Xor: {
		checkOperandCount(a, 2);
		checkTypesMatch(a[0], a[1]);
		if (!isIntegral(a.ty()) || a.ty() != a[0].ty()) {
			throw runtime_error("Invalid types for integer arithmetic");
		}
	} break;

	case SDiv:
	case SRem:
	case UDiv:
	case URem: {
		checkOperandCount(a, 2);
		checkTypesMatch(a[0], a[1]);
		if (!isIntegral(a.ty()) || a.ty() != a[0].ty()) {
			throw runtime_error("Invalid types for division");
		}
	} break;

	case FAdd:
	case FDiv:
	case FMul:
	case FRem:
	case FSub: {
		checkOperandCount(a, 2);
		checkTypesMatch(a[0], a[1]);
		auto k = a.ty().kind();
		if ((k != FloatKind && k != DoubleKind) || a.ty() != a[0].ty()) {
			throw runtime_error("Invalid types for floating-point arithmetic");
		}
	} break;

	case FNeg: {
		checkOperandCount(a, 1);
		auto k = a.ty().kind();
		if ((k != FloatKind && k != DoubleKind) || a.ty() != a[0].ty()) {
			throw runtime_error("Invalid types for floating-point negation");
		}
	} break;

	case Eq: {
		checkOperandCount(a, 2);
		checkTypesMatch(a[0], a[1]);
		if (a.ty().kind() != IntKind || a.ty().len() != 1) {
			throw runtime_error("Equality must return bool type");
		}
	} break;

	case FEq: {
		checkOperandCount(a, 2);
		checkTypesMatch(a[0], a[1]);
		auto k = a[0].ty().kind();
		if (k != FloatKind && k != DoubleKind) {
			throw runtime_error("FEq requires floating-point operands");
		}
		if (a.ty().kind() != IntKind || a.ty().len() != 1) {
			throw runtime_error("FEq must return bool type");
		}
	} break;

	case SLe:
	case SLt:
	case ULe:
	case ULt: {
		checkOperandCount(a, 2);
		checkTypesMatch(a[0], a[1]);
		if (!isIntegral(a[0].ty())) {
			throw runtime_error("Comparison requires integer operands");
		}
		if (a.ty().kind() != IntKind || a.ty().len() != 1) {
			throw runtime_error("Comparison must return bool type");
		}
	} break;

	case FLe:
	case FLt: {
		checkOperandCount(a, 2);
		checkTypesMatch(a[0], a[1]);
		auto k = a[0].ty().kind();
		if (k != FloatKind && k != DoubleKind) {
			throw runtime_error("FLt/FLe requires floating-point operands");
		}
		if (a.ty().kind() != IntKind || a.ty().len() != 1) {
			throw runtime_error("Floating comparison must return bool type");
		}
	} break;

	case Not: {
		checkOperandCount(a, 1);
		if (a[0].ty().kind() != IntKind || a[0].ty().len() != 1) {
			throw runtime_error("Not requires bool operand");
		}
		if (a.ty() != a[0].ty()) {
			throw runtime_error("Not must return bool type");
		}
	} break;

	case Cast:
	case SCast: {
		checkOperandCount(a, 1);
		// Allow any type conversion between numeric types
		auto sk = a[0].ty().kind();
		auto dk = a.ty().kind();
		if ((sk != IntKind && sk != FloatKind && sk != DoubleKind) || (dk != IntKind && dk != FloatKind && dk != DoubleKind)) {
			throw runtime_error("Cast requires numeric types");
		}
	} break;

	case Load: {
		checkOperandCount(a, 1);
		if (a[0].ty().kind() != PtrKind) {
			throw runtime_error("Load requires pointer operand");
		}
	} break;

	case ElementPtr: {
		checkOperandCount(a, 3);
		if (a[1].ty().kind() != PtrKind) {
			throw runtime_error("ElementPtr requires pointer base");
		}
		if (!isIntegral(a[2].ty())) {
			throw runtime_error("ElementPtr requires integer index");
		}
		if (a.ty().kind() != PtrKind) {
			throw runtime_error("ElementPtr must return pointer type");
		}
	} break;

	case FieldPtr: {
		checkOperandCount(a, 3);
		if (a[1].ty().kind() != PtrKind) {
			throw runtime_error("FieldPtr requires pointer base");
		}
		if (!isIntegral(a[2].ty())) {
			throw runtime_error("FieldPtr requires integer index");
		}
		if (a.ty().kind() != PtrKind) {
			throw runtime_error("FieldPtr must return pointer type");
		}
	} break;

	case Array: {
		if (a.ty().kind() != ArrayKind) {
			throw runtime_error("Array term must have array type");
		}
		Type elementType = a.ty()[0];
		for (const auto& element : a) {
			if (element.ty() != elementType) {
				throw runtime_error("Array elements must have consistent type");
			}
		}
	} break;

	case Tuple: {
		if (a.ty().kind() != StructKind) {
			throw runtime_error("Tuple term must have struct type");
		}
		if (a.size() != a.ty().size()) {
			throw runtime_error("Tuple size must match type size");
		}
		for (size_t i = 0; i < a.size(); ++i) {
			if (a[i].ty() != a.ty()[i]) {
				throw runtime_error("Tuple element type mismatch");
			}
		}
	} break;

	case Call: {
		if (a.size() < 1) {
			throw runtime_error("Call must have at least one operand (function)");
		}
		if (a[0].ty().kind() != FuncKind) {
			throw runtime_error("First operand of Call must be a function");
		}

		// Check return type matches
		if (a.ty() != a[0].ty()[0]) {
			throw runtime_error("Call return type must match function return type");
		}

		// Check parameter types match
		if (a.size() - 1 != a[0].ty().size() - 1) {
			throw runtime_error("Call argument count must match function parameter count");
		}
		for (size_t i = 1; i < a.size(); ++i) {
			if (a[i].ty() != a[0].ty()[i]) {
				throw runtime_error("Call argument type mismatch");
			}
		}
	} break;

	case GlobalRef:
	case Label:
	case Var:
		// These are valid with any type
		break;

	default:
		throw runtime_error("Unknown term tag");
	}
}

// Forward declaration
bool isIntegral(Type t);

void checkRecursive(Term a) {
	// First check the term itself
	check(a);

	// Special cases for terms that might have nested structure in non-operand fields
	switch (a.tag()) {
	case Float:
	case GlobalRef:
	case Int:
	case Label:
	case NullPtr:
	case Var:
		// These are leaf nodes with no nested terms to check
		return;

	case Array:
		// For arrays, we need to check that all elements have the same type
		// This is in addition to checking each element recursively
		if (a.size() > 0) {
			Type elementType = a[0].ty();
			for (const auto& element : a) {
				if (element.ty() != elementType) {
					throw runtime_error("Array elements must all have the same type");
				}
				checkRecursive(element);
			}
		}
		return;

	case Tuple:
		// For tuples, ensure the structure matches the type
		if (a.ty().kind() != StructKind) {
			throw runtime_error("Tuple must have struct type");
		}
		if (a.size() != a.ty().size()) {
			throw runtime_error("Tuple size must match type");
		}
		for (size_t i = 0; i < a.size(); ++i) {
			if (a[i].ty() != a.ty()[i]) {
				throw runtime_error("Tuple element type mismatch");
			}
			checkRecursive(a[i]);
		}
		return;

	case Call:
		// For function calls, validate the function and all arguments
		if (a.size() < 1) {
			throw runtime_error("Call must have at least function argument");
		}
		if (a[0].ty().kind() != FuncKind) {
			throw runtime_error("First operand of call must be a function");
		}

		// Check return type
		if (a.ty() != a[0].ty()[0]) {
			throw runtime_error("Call return type must match function type");
		}

		// Check argument types and recursively validate each argument
		if (a.size() - 1 != a[0].ty().size() - 1) {
			throw runtime_error("Call argument count mismatch");
		}
		for (size_t i = 0; i < a.size(); ++i) {
			if (i > 0 && a[i].ty() != a[0].ty()[i]) {
				throw runtime_error("Call argument type mismatch");
			}
			checkRecursive(a[i]);
		}
		return;

	case ElementPtr:
	case FieldPtr:
		// These operations require additional validation beyond their operands
		if (a.size() != 3) {
			throw runtime_error("ElementPtr/FieldPtr must have exactly 3 operands");
		}
		if (a[1].ty().kind() != PtrKind) {
			throw runtime_error("Second operand of ElementPtr/FieldPtr must be a pointer");
		}
		if (!isIntegral(a[2].ty())) {
			throw runtime_error("Third operand of ElementPtr/FieldPtr must be an integer");
		}
		if (a.ty().kind() != PtrKind) {
			throw runtime_error("ElementPtr/FieldPtr must return a pointer");
		}
		// Fall through to check operands recursively

	default:
		// For all other terms, recursively check their operands
		for (const auto& operand : a) {
			checkRecursive(operand);
		}
	}
}

// Helper function to check if a type is integral
bool isIntegral(Type t) {
	return t.kind() == IntKind;
}

void check(Inst inst) {
	// First validate all operands recursively
	for (const Term& term : inst) {
		checkRecursive(term);
	}

	// Now check opcode-specific requirements
	switch (inst.opcode()) {
	case Alloca: {
		if (inst.size() != 3) {
			throw runtime_error("Alloca must have exactly 3 operands");
		}

		// First operand must be a variable
		if (inst[0].tag() != Var) {
			throw runtime_error("First operand of Alloca must be a variable");
		}

		// Second operand must be the type to allocate
		Term typeSpec = inst[1];
		if (typeSpec != none(typeSpec.ty())) {
			throw runtime_error("Second operand of Alloca must be the type to allocate");
		}

		// Third operand must be an integer for number of elements
		if (inst[2].ty().kind() != IntKind) {
			throw runtime_error("Third operand of Alloca must be an integer");
		}

		// Result variable must be a pointer type
		if (inst[0].ty().kind() != PtrKind) {
			throw runtime_error("Result of Alloca must be a pointer type");
		}
		break;
	}

	case Assign: {
		if (inst.size() != 2) {
			throw runtime_error("Assign must have exactly 2 operands");
		}

		// Left hand side must be a variable
		if (inst[0].tag() != Var) {
			throw runtime_error("Left hand side of assignment must be a variable");
		}

		// Types must match
		if (inst[0].ty() != inst[1].ty()) {
			throw runtime_error("Assignment operands must have matching types");
		}
		break;
	}

	case Block: {
		if (inst.size() != 1) {
			throw runtime_error("Block must have exactly 1 operand");
		}

		// Operand must be a label
		if (inst[0].tag() != Label) {
			throw runtime_error("Block operand must be a label");
		}
		break;
	}

	case Br: {
		if (inst.size() != 3) {
			throw runtime_error("Br must have exactly 3 operands");
		}

		// Condition must be boolean
		if (inst[0].ty() != boolTy()) {
			throw runtime_error("Branch condition must be boolean");
		}

		// True and false targets must be labels
		if (inst[1].tag() != Label || inst[2].tag() != Label) {
			throw runtime_error("Branch targets must be labels");
		}
		break;
	}

	case Drop: {
		if (inst.size() != 1) {
			throw runtime_error("Drop must have exactly 1 operand");
		}
		break;
	}

	case Jmp: {
		if (inst.size() != 1) {
			throw runtime_error("Jmp must have exactly 1 operand");
		}

		// Target must be a label
		if (inst[0].tag() != Label) {
			throw runtime_error("Jump target must be a label");
		}
		break;
	}

	case Phi: {
		if (inst.size() < 3 || (inst.size() - 1) % 2 != 0) {
			throw runtime_error("Phi must have 1 + 2n operands where n >= 1");
		}

		// First operand must be a variable
		if (inst[0].tag() != Var) {
			throw runtime_error("First operand of Phi must be a variable");
		}

		// Check pairs of value and label
		Type resultType = inst[0].ty();
		for (size_t i = 1; i < inst.size(); i += 2) {
			// Value must match result type
			if (inst[i].ty() != resultType) {
				throw runtime_error("Phi incoming value types must match result type");
			}

			// Even-numbered operands must be labels
			if (inst[i + 1].tag() != Label) {
				throw runtime_error("Phi label operands must be labels");
			}
		}
		break;
	}

	case Ret: {
		if (inst.size() != 1) {
			throw runtime_error("Ret must have exactly 1 operand");
		}
		break;
	}

	case RetVoid: {
		if (inst.size() != 0) {
			throw runtime_error("RetVoid must have no operands");
		}
		break;
	}

	case Store: {
		if (inst.size() != 2) {
			throw runtime_error("Store must have exactly 2 operands");
		}

		// Second operand must be a pointer
		if (inst[1].ty().kind() != PtrKind) {
			throw runtime_error("Store target must be a pointer");
		}
		break;
	}

	case Switch: {
		if (inst.size() < 2 || (inst.size() - 2) % 2 != 0) {
			throw runtime_error("Switch must have 2 + 2n operands where n >= 0");
		}

		// First operand is the value to switch on
		Type switchType = inst[0].ty();

		// Second operand must be the default label
		if (inst[1].tag() != Label) {
			throw runtime_error("Switch default target must be a label");
		}

		// Check pairs of case value and label
		for (size_t i = 2; i < inst.size(); i += 2) {
			// Case value must match switch type
			if (inst[i].ty() != switchType) {
				throw runtime_error("Switch case value types must match switch type");
			}

			// Case labels must be labels
			if (inst[i + 1].tag() != Label) {
				throw runtime_error("Switch case targets must be labels");
			}
		}
		break;
	}

	case Unreachable: {
		if (inst.size() != 0) {
			throw runtime_error("Unreachable must have no operands");
		}
		break;
	}

	default:
		throw runtime_error("Unknown instruction opcode");
	}
}

void check(Fn f) {
	// Check that function has at least one instruction
	ASSERT(f.size() > 0 && "Function body cannot be empty");

	// Check that function return type matches return instructions
	Type returnType = f.rty();

	// Check that all parameters have valid types
	for (const Term& param : f.params()) {
		// Parameter must be a variable
		ASSERT(param.tag() == Var);
		// Check parameter term itself is valid
		checkRecursive(param);
	}

	// Track defined labels to ensure all jump targets are valid
	unordered_set<Ref> definedLabels;

	// Track if we've seen any Phi instructions
	bool foundPhi = false;

	// Track variables to ensure they are used with consistent types
	unordered_map<Ref, Type> varTypes;

	// Initialize varTypes with function parameters
	for (const Term& param : f.params()) {
		varTypes[param.ref()] = param.ty();
	}

	// Track the current basic block for validation
	bool inBlock = false;

	// Check each instruction
	for (const Inst& inst : f) {
		// Check all operands recursively
		for (const Term& term : inst) {
			checkRecursive(term);
		}

		switch (inst.opcode()) {
		case Block: {
			// Block must have exactly one operand which is a label
			ASSERT(inst.size() == 1);
			ASSERT(inst[0].tag() == Label);

			// Add label to defined set
			definedLabels.insert(inst[0].ref());

			inBlock = true;
			break;
		}

		case Phi: {
			// Phi instructions are not allowed in internal representation
			foundPhi = true;
			break;
		}

		case Assign: {
			// Must have exactly two operands
			ASSERT(inst.size() == 2);

			// First operand must be a variable
			ASSERT(inst[0].tag() == Var);

			// Check type compatibility
			Type lhsType = inst[0].ty();
			Type rhsType = inst[1].ty();
			ASSERT(lhsType == rhsType);

			// Track variable type
			varTypes[inst[0].ref()] = lhsType;
			break;
		}

		case Ret: {
			// Must have exactly one operand matching function return type
			ASSERT(inst.size() == 1);
			ASSERT(inst[0].ty() == returnType);
			break;
		}

		case RetVoid: {
			// Must have no operands and void return type
			ASSERT(inst.size() == 0);
			ASSERT(returnType.kind() == VoidKind);
			break;
		}

		case Br: {
			// Must have exactly three operands
			ASSERT(inst.size() == 3);

			// First operand must be boolean
			ASSERT(inst[0].ty() == boolTy());

			// Second and third operands must be labels
			ASSERT(inst[1].tag() == Label);
			ASSERT(inst[2].tag() == Label);
			break;
		}

		case Jmp: {
			// Must have exactly one operand which is a label
			ASSERT(inst.size() == 1);
			ASSERT(inst[0].tag() == Label);
			break;
		}

		case Store: {
			// Must have exactly two operands
			ASSERT(inst.size() == 2);

			// Second operand must be a pointer
			ASSERT(inst[1].ty().kind() == PtrKind);
			break;
		}

		case Alloca: {
			// Must have three operands
			ASSERT(inst.size() == 3);

			// First operand must be variable
			ASSERT(inst[0].tag() == Var);

			// Third operand must be integer type
			ASSERT(isInt(inst[2].ty()));
			break;
		}

		default:
			// For other instructions, rely on the instruction-level check
			check(inst);
			break;
		}

		// Check variable type consistency
		for (const Term& term : inst) {
			if (term.tag() == Var) {
				auto it = varTypes.find(term.ref());
				if (it != varTypes.end()) {
					ASSERT(term.ty() == it->second);
				}
			}
		}
	}

	// Check that we found no Phi instructions
	ASSERT(!foundPhi);

	// Check that last instruction is a return or unreachable
	bool hasTerminator = false;
	if (!f.empty()) {
		Inst lastInst = f[f.size() - 1];
		hasTerminator = (lastInst.opcode() == Ret || lastInst.opcode() == RetVoid || lastInst.opcode() == Unreachable);
	}
	ASSERT(hasTerminator && "Function must end with return or unreachable");

	// Check that all jump targets refer to defined labels
	for (const Inst& inst : f) {
		if (inst.opcode() == Br) {
			ASSERT(definedLabels.count(inst[1].ref()));
			ASSERT(definedLabels.count(inst[2].ref()));
		} else if (inst.opcode() == Jmp) {
			ASSERT(definedLabels.count(inst[0].ref()));
		}
	}
}
