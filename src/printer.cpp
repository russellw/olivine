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

ostream& operator<<(ostream& os, Tag tag) {
    switch (tag) {
        // Arithmetic operations
        case Add: return os << "add";
        case Sub: return os << "sub";
        case Mul: return os << "mul";
        case UDiv: return os << "udiv";
        case SDiv: return os << "sdiv";
        case URem: return os << "urem";
        case SRem: return os << "srem";
        
        // Floating point operations
        case FAdd: return os << "fadd";
        case FSub: return os << "fsub";
        case FMul: return os << "fmul";
        case FDiv: return os << "fdiv";
        case FRem: return os << "frem";
        case FNeg: return os << "fneg";
        
        // Bitwise operations
        case And: return os << "and";
        case Or: return os << "or";
        case Xor: return os << "xor";
        case Shl: return os << "shl";
        case LShr: return os << "lshr";
        case AShr: return os << "ashr";
        
        // Integer comparisons
        case Eq: return os << "icmp eq";
        case ULt: return os << "icmp ult";
        case ULe: return os << "icmp ule";
        case SLt: return os << "icmp slt";
        case SLe: return os << "icmp sle";
        
        // Floating point comparisons
        case FEq: return os << "fcmp oeq";
        case FLt: return os << "fcmp olt";
        case FLe: return os << "fcmp ole";
        
        // Logical operations
        case Not: return os << "not";
        
        // Conversion operations
        case Cast: return os << "bitcast";
        case SCast: return os << "sext";
        
        // Memory operations
        case Load: return os << "load";
        case ElementPtr: return os << "getelementptr";
        case FieldPtr: return os << "getelementptr";
        
        // Reference types
        case Null: return os << "null";
        case GlobalRef: return os << "global";
        case Var: return os << "var";
        case Label: return os << "label";
        
        // Compound types
        case Array: return os << "array";
        case Tuple: return os << "struct";
        case Vec: return os << "vector";
        
        // Constants
        case Int: return os << "i";
        case Float: return os << "float";
        
        // Function-related
        case Call: return os << "call";
        
        // Default case for any unhandled tags
        default: return os << "unknown_tag";
    }
}

ostream& operator<<(ostream& os, Term a) {
	// Handle special cases first
	switch (a.tag()) {
	case Call: {
		// Format: call returnType (functionType function)(args...)
		// Example: call i32 (i32, i32)* @sum(i32 %x, i32 %y)
		os << "call " << a.ty() << " ";

		// Print the function operand (first operand)
		Term func = a[0];
		os << func;

		// Print remaining operands (arguments) in parentheses
		os << "(";
		for (size_t i = 1; i < a.size(); ++i) {
			if (i > 1) {
				os << ", ";
			}
			os << a[i].ty() << " " << a[i];
		}
		os << ")";
		return os;
	}
	case Float:
		os << a.str();
		return os;
	case GlobalRef:
		os << '@' << a.ref();
		return os;
	case Int:
		if (a.ty() == boolTy()) {
			os << (a.intVal() ? "true" : "false");
			return os;
		}
		os << a.intVal();
		return os;
	case Label:
	case Var:
		os << '%' << a.ref();
		return os;
	case Null:
		os << "null";
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
		throw runtime_error(to_string(int(a.tag())) + ": unknown tag");
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

ostream& operator<<(ostream& os, Inst inst) {
	// Handle empty instructions
	if (!inst.size()) {
		switch (inst.opcode()) {
		case RetVoid:
			return os << "ret void";
		case Unreachable:
			return os << "unreachable";
		default:
			ASSERT(false && "Invalid empty instruction");
		}
	}

	switch (inst.opcode()) {
	case Alloca: {
		// Format: %var = alloca type, i32 count
		ASSERT(inst.size() == 3);
		os << inst[0] << " = alloca " << inst[1].ty();
		auto n = inst[2];
		if (n.tag() == Int && n.intVal() == 1) {
			break;
		}
		os << ", " << n.ty() << ' ' << n;
		break;
	}
	case Assign: {
		// Format: %var = expr
		ASSERT(inst.size() == 2);
		os << inst[0] << " = " << inst[1];
		break;
	}
	case Block: {
		// Format: label:
		ASSERT(inst.size() == 1);
		os << inst[0].ref() << ":";
		break;
	}
	case Br: {
		// Format: br i1 %cond, label %true, label %false
		ASSERT(inst.size() == 3);
		os << "br i1 " << inst[0] << ", label " << inst[1] << ", label " << inst[2];
		break;
	}
	case Drop: {
		// Format: expr
		ASSERT(inst.size() == 1);
		os << inst[0];
		break;
	}
	case Jmp: {
		// Format: br label %target
		ASSERT(inst.size() == 1);
		os << "br label " << inst[0];
		break;
	}
	case Phi: {
		// Format: %var = phi type [ val1, %label1 ], [ val2, %label2 ], ...
		ASSERT(inst.size() >= 3 && (inst.size() % 2) == 1);
		os << inst[0] << " = phi " << inst[1].ty() << ' ';
		for (size_t i = 1; i < inst.size(); i += 2) {
			if (i > 1) {
				os << ", ";
			}
			os << "[ " << inst[i] << ", " << inst[i + 1] << " ]";
		}
		break;
	}
	case Ret: {
		// Format: ret type value
		ASSERT(inst.size() == 1);
		os << "ret " << inst[0].ty() << " " << inst[0];
		break;
	}
	case Store: {
		// Format: store type value, ptr pointer
		ASSERT(inst.size() == 2);
		os << "store " << inst[0].ty() << " " << inst[0] << ", " << inst[1].ty() << " " << inst[1];
		break;
	}
	case Switch: {
		// Format: switch type value, label %default [ type val1, label %label1 ... ]
		ASSERT(inst.size() >= 2 && (inst.size() % 2) == 0);
		os << "switch " << inst[0].ty() << " " << inst[0] << ", label " << inst[1];
		if (inst.size() > 2) {
			os << " [";
			for (size_t i = 2; i < inst.size(); i += 2) {
				os << "\n    " << inst[i].ty() << " " << inst[i] << ", label " << inst[i + 1];
			}
			os << "\n  ]";
		}
		break;
	}
	default:
		ASSERT(false && "Unknown instruction type");
	}
	return os;
}

ostream& operator<<(ostream& os, Fn f) {
	// Output declare/define based on whether function has a body
	if (f.size() == 0) {
		os << "declare ";
	} else {
		os << "define ";
	}

	// Output return type
	os << f.rty() << ' ';

	// Output function name/reference
	os << '@' << f.ref();

	// Output parameter list
	os << '(';
	auto params = f.params();
	for (size_t i = 0; i < params.size(); ++i) {
		if (i > 0) {
			os << ", ";
		}
		os << params[i].ty();
		os << ' ' << params[i];
	}
	os << ')';

	// If this is just a declaration, end here
	if (f.size() == 0) {
		return os;
	}

	// Output function body
	os << " {\n";

	// Output each instruction in the function body
	for (const auto& inst : f) {
		if (inst.opcode() != Block) {
			os << "  ";
		}
		os << inst << '\n';
	}

	os << '}';

	return os;
}

ostream& operator<<(ostream& out, Module* module) {
	// Print target platform info
	if (context::datalayout.size()) {
		out << "target datalayout = \"" << context::datalayout << "\"\n";
	}
	if (context::triple.size()) {
		out << "target triple = \"" << context::triple << "\"\n\n";
	}

	// Print global variables
	for (const auto& global : module->globals) {
		out << "global " << global.ty() << " " << global.ref() << "\n";
	}

	// Print function declarations
	for (const auto& decl : module->decls) {
		out << decl << "\n";
	}

	// Print function definitions
	for (const auto& def : module->defs) {
		out << def << "\n";
	}

	return out;
}
