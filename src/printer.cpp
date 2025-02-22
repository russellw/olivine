#include "all.h"

ostream& operator<<(ostream& os, const Ref& ref) {
	// For string variants, use wrap() to properly escape and quote
	if (std::holds_alternative<string>(ref)) {
		return os << wrap(std::get<string>(ref));
	}
	// For numeric variants, output directly
	return os << std::get<size_t>(ref);
}

ostream& operator<<(ostream& os, Type ty) {
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic push
#pragma GCC diagnostic warning "-Wswitch"
#endif
	switch (ty.kind()) {
	case ArrayKind:
		os << '[' << ty.len() << " x " << ty[0] << ']';
		break;
	case DoubleKind:
		os << "double";
		break;
	case FloatKind:
		os << "float";
		break;
	case FuncKind:
		os << ty[0] << " (";
		for (size_t i = 1; i < ty.size(); i++) {
			if (i > 1) {
				os << ", ";
			}
			os << ty[i];
		}
		os << ')';
		break;
	case IntKind:
		os << 'i' << ty.len();
		break;
	case PtrKind:
		os << "ptr";
		break;
	case StructKind:
		os << '{';
		for (size_t i = 0; i < ty.size(); i++) {
			if (i) {
				os << ", ";
			}
			os << ty[i];
		}
		os << '}';
		break;
	case VecKind:
		os << '<' << ty.len() << " x " << ty[0] << '>';
		break;
	case VoidKind:
		os << "void";
		break;
	}
	return os;
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic pop
#endif
}

ostream& operator<<(ostream& os, Term a) {
	// Handle special cases first
	switch (a.tag()) {
	case Float:
		os << a.str();
		return os;
	case Int:
		if (a.ty() == boolTy()) {
			os << (a.intVal() ? "true" : "false");
			return os;
		}
		os << a.intVal();
		return os;
	case Null:
		os << "null";
		return os;
	case Var:
		os << '%' << a.ref();
		return os;
	}

	// For compound expressions, we need to print in LLVM constant expression format
	// Format: op (type operand1, operand2, ...)

	// First determine the operation name
	string opName;
	switch (a.tag()) {
	case AShr:
		opName = "ashr";
		break;
	case Add:
		opName = "add";
		break;
	case And:
		opName = "and";
		break;
	case Eq:
		opName = "icmp eq";
		break;
	case FAdd:
		opName = "fadd";
		break;
	case FDiv:
		opName = "fdiv";
		break;
	case FMul:
		opName = "fmul";
		break;
	case FNeg:
		opName = "fneg";
		break;
	case FRem:
		opName = "frem";
		break;
	case FSub:
		opName = "fsub";
		break;
	case LShr:
		opName = "lshr";
		break;
	case Mul:
		opName = "mul";
		break;
	case Or:
		opName = "or";
		break;
	case SDiv:
		opName = "sdiv";
		break;
	case SLe:
		opName = "icmp sle";
		break;
	case SLt:
		opName = "icmp slt";
		break;
	case SRem:
		opName = "srem";
		break;
	case Shl:
		opName = "shl";
		break;
	case Sub:
		opName = "sub";
		break;
	case UDiv:
		opName = "udiv";
		break;
	case ULe:
		opName = "icmp ule";
		break;
	case ULt:
		opName = "icmp ult";
		break;
	case URem:
		opName = "urem";
		break;
	case Xor:
		opName = "xor";
		break;
	default:
		throw runtime_error("unknown tag");
	}

	os << opName << " (";

	// Print all operands
	for (size_t i = 0; i < a.size(); ++i) {
		if (i) {
			os << ", ";
		}
		os << a[i].ty() << " " << a[i];
	}

	os << ")";
	return os;
}
