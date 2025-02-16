#include "all.h"

ostream& operator<<(ostream& os, Type type) {
	switch (type.kind()) {
	case VoidKind:
		os << "void";
		break;
	case IntKind:
		os << 'i' << type.len();
		break;
	case FloatKind:
		os << "float";
		break;
	case DoubleKind:
		os << "double";
		break;
	case PtrKind:
		os << "ptr";
		break;
	case ArrayKind:
		os << '[' << type.len() << " x " << type[0] << ']';
		break;
	case VecKind:
		os << '<' << type.len() << " x " << type[0] << '>';
		break;
	case StructKind:
		os << '{';
		for (size_t i = 0; i < type.size(); i++) {
			if (i) {
				os << ", ";
			}
			os << type[i];
		}
		os << '}';
		break;
	case FuncKind:
		os << type[0] << " (";
		for (size_t i = 1; i < type.size(); i++) {
			if (i > 1) {
				os << ", ";
			}
			os << type[i];
		}
		os << ')';
		break;
	}
	return os;
}

ostream& operator<<(ostream& os, Term a) {
	// Handle special cases first
	switch (a.tag()) {
	case Null:
		os << "null";
		return os;
	case Float:
		os << a.str();
		return os;
	case Int:
		if (a.type() == boolType()) {
			os << (a.intVal() ? "true" : "false");
			return os;
		}
		os << a.intVal();
		return os;
	case Var:
		os << '%';
		if (a.named()) {
			os << a.str();
		} else {
			os << a.intVal();
		}
		return os;
	}

	// For compound expressions, we need to print in LLVM constant expression format
	// Format: op (type operand1, operand2, ...)

	// First determine the operation name
	string opName;
	switch (a.tag()) {
	case FNeg:
		opName = "fneg";
		break;
	case Add:
		opName = "add";
		break;
	case FAdd:
		opName = "fadd";
		break;
	case Sub:
		opName = "sub";
		break;
	case FSub:
		opName = "fsub";
		break;
	case Mul:
		opName = "mul";
		break;
	case FMul:
		opName = "fmul";
		break;
	case UDiv:
		opName = "udiv";
		break;
	case SDiv:
		opName = "sdiv";
		break;
	case FDiv:
		opName = "fdiv";
		break;
	case URem:
		opName = "urem";
		break;
	case SRem:
		opName = "srem";
		break;
	case FRem:
		opName = "frem";
		break;
	case Shl:
		opName = "shl";
		break;
	case LShr:
		opName = "lshr";
		break;
	case AShr:
		opName = "ashr";
		break;
	case And:
		opName = "and";
		break;
	case Or:
		opName = "or";
		break;
	case Xor:
		opName = "xor";
		break;
	case Eq:
		opName = "icmp eq";
		break;
	case ULt:
		opName = "icmp ult";
		break;
	case ULe:
		opName = "icmp ule";
		break;
	case SLt:
		opName = "icmp slt";
		break;
	case SLe:
		opName = "icmp sle";
		break;
	default:
		// This should never happen due to the earlier switch
		return os;
	}

	os << opName << " (";

	// For comparison operations, operands must have the same type
	// but the result is always i1 (bool)
	bool isComparison = (a.tag() >= Eq && a.tag() <= SLe);

	// Print the type of the expression
	if (!isComparison) {
		os << a.type();
	}

	// Print all operands
	for (size_t i = 0; i < a.size(); ++i) {
		if (i || !isComparison) {
			os << ", ";
		}

		// For nested expressions, we need to print both type and value
		if (isComparison && i == 0) {
			os << a[i].type() << " ";
		}

		os << a[i];
	}

	os << ")";
	return os;
}
