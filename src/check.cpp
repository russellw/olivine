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
	case Null:
		if (a.ty().kind() != PtrKind) {
			throw runtime_error("Null must have pointer type");
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
	case SRem: {
	case UDiv:
	case URem:
		checkOperandCount(a, 2);
		checkTypesMatch(a[0], a[1]);
		if (!isIntegral(a.ty()) || a.ty() != a[0].ty()) {
			throw runtime_error("Invalid types for division");
		}
	} break;

	case FAdd:
	case FDiv:
	case FMul:
	case FRem: {
	case FSub:
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

	case SLe: {
	case SLt:
	case ULe:
	case ULt:
		checkOperandCount(a, 2);
		checkTypesMatch(a[0], a[1]);
		if (!isIntegral(a[0].ty())) {
			throw runtime_error("Comparison requires integer operands");
		}
		if (a.ty().kind() != IntKind || a.ty().len() != 1) {
			throw runtime_error("Comparison must return bool type");
		}
	} break;

	case FLe: {
	case FLt:
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
