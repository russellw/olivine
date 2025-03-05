#include "all.h"

string wrap(string s) {
	// Empty string needs quotes
	if (s.empty()) {
		return "\"\"";
	}

	// Check if the string can be used as an unquoted identifier
	bool needsQuotes = false;

	// First character has stricter rules - must be a letter, _, or .
	if (!isAlpha(s[0]) && s[0] != '_' && s[0] != '.') {
		needsQuotes = true;
	} else {
		// Check remaining characters
		for (size_t i = 1; i < s.size(); i++) {
			if (!isIdPart(s[i])) {
				needsQuotes = true;
				break;
			}
		}
	}

	// If it's a valid unquoted identifier, return as is
	if (!needsQuotes) {
		return s;
	}

	// Need to wrap in quotes and handle special characters
	string result = "\"";
	for (char c : s) {
		if (c == '\"' || c < 32 || c > 126) {
			// Quotes and non-printable characters get hex escape
			char hex[3];
			snprintf(hex, sizeof(hex), "%02x", (unsigned char)c);
			result += '\\';
			result += hex;
		} else if (c == '\\') {
			// Single backslashes remain as backslashes
			result += "\\\\";
		} else {
			// Normal characters added as-is
			result += c;
		}
	}
	result += '\"';
	return result;
}

ostream& operator<<(ostream& os, const Ref& ref) {
	// For numeric variants, output directly
	if (ref.numeric()) {
		return os << ref.num();
	}
	// For string variants, use wrap() to properly escape and quote
	return os << wrap(ref.str());
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
	case Add:
		return os << "add";
	case Mul:
		return os << "mul";
	case SDiv:
		return os << "sdiv";
	case SRem:
		return os << "srem";
	case Sub:
		return os << "sub";
	case UDiv:
		return os << "udiv";
	case URem:
		return os << "urem";

	// Floating point operations
	case FAdd:
		return os << "fadd";
	case FDiv:
		return os << "fdiv";
	case FMul:
		return os << "fmul";
	case FNeg:
		return os << "fneg";
	case FRem:
		return os << "frem";
	case FSub:
		return os << "fsub";

	// Bitwise operations
	case AShr:
		return os << "ashr";
	case And:
		return os << "and";
	case LShr:
		return os << "lshr";
	case Or:
		return os << "or";
	case Shl:
		return os << "shl";
	case Xor:
		return os << "xor";

	// Integer comparisons
	case Eq:
		return os << "icmp eq";
	case SLe:
		return os << "icmp sle";
	case SLt:
		return os << "icmp slt";
	case ULe:
		return os << "icmp ule";
	case ULt:
		return os << "icmp ult";

	// Floating point comparisons
	case FEq:
		return os << "fcmp oeq";
	case FLe:
		return os << "fcmp ole";
	case FLt:
		return os << "fcmp olt";

	// Logical operations
	case Not:
		return os << "not";

	// Conversion operations
	case Cast:
		return os << "bitcast";
	case SCast:
		return os << "sext";

	// Memory operations
	case ElementPtr:
		return os << "getelementptr";
	case FieldPtr:
		return os << "getelementptr";
	case Load:
		return os << "load";

	// Reference types
	case GlobalRef:
		return os << "global";
	case Label:
		return os << "label";
	case NullPtr:
		return os << "null";
	case Var:
		return os << "var";

	// Compound types
	case Array:
		return os << "array";
	case Tuple:
		return os << "struct";
	case Vec:
		return os << "vector";

	// Constants
	case Float:
		return os << "float";
	case Int:
		return os << "i";

	// Function-related
	case Call:
		return os << "call";

	// Default case for any unhandled tags
	default:
		return os << "unknown_tag";
	}
}

ostream& operator<<(ostream& os, Term a) {
	// Handle special cases first
	switch (a.tag()) {
	case Array:
		os << '[';
		for (size_t i = 0; i < a.size(); ++i) {
			if (i) {
				os << ", ";
			}
			os << a[i].ty() << " " << a[i];
		}
		os << ']';
		return os;
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
	case NullPtr:
		os << "null";
		return os;
	}

	// For compound expressions, we need to print in LLVM constant expression format
	// Format: op (type operand1, operand2, ...)
	os << a.tag() << " (";

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
		Term lhs = inst[0];
		Term rhs = inst[1];

		os << lhs << " = ";

		// Handle different expression types with their specific syntax
		if (rhs.size() > 0) {
			switch (rhs.tag()) {
			case AShr:
			case Add:
			case And:
			case LShr:
			case Mul:
			case Or:
			case SDiv:
			case SRem:
			case Shl:
			case Sub:
			case UDiv:
			case URem:
			case Xor:
				// Format: <op> <type> <operand1>, <operand2>
				ASSERT(rhs.size() == 2);
				os << rhs.tag() << " " << rhs.ty() << " " << rhs[0] << ", " << rhs[1];
				break;
			case Call:
				// Format: call <return-type> <function>(<args...>)
				os << "call " << rhs.ty() << " " << rhs[0] << "(";
				for (size_t i = 1; i < rhs.size(); ++i) {
					if (i > 1) {
						os << ", ";
					}
					os << rhs[i].ty() << " " << rhs[i];
				}
				os << ")";
				break;
			case Cast:
			case SCast:
				// Format for cast operations: <cast-op> <src-type> <value> to <dst-type>
				ASSERT(rhs.size() == 1);

				// Determine the appropriate LLVM cast operation based on the types and cast kind
				if (rhs.tag() == Cast) {
					// Handle different bitcast variations based on source and destination types
					if (isInt(rhs[0].ty()) && isInt(rhs.ty())) {
						// Integer to integer bitcast
						if (rhs[0].ty().len() < rhs.ty().len()) {
							os << "zext "; // Zero extension for unsigned
						} else if (rhs[0].ty().len() > rhs.ty().len()) {
							os << "trunc "; // Truncation
						} else {
							os << "bitcast "; // Same-size conversion
						}
					} else if (isFloat(rhs[0].ty()) && isInt(rhs.ty())) {
						os << "fptosi "; // Float to signed integer
					} else if (isInt(rhs[0].ty()) && isFloat(rhs.ty())) {
						os << "sitofp "; // Signed integer to float
					} else if (rhs[0].ty().kind() == PtrKind && isInt(rhs.ty())) {
						os << "ptrtoint "; // Pointer to integer
					} else if (isInt(rhs[0].ty()) && rhs.ty().kind() == PtrKind) {
						os << "inttoptr "; // Integer to pointer
					} else {
						os << "bitcast "; // Default to bitcast for other cases
					}
				} else { // SCast
					// Handle signed cast operations
					if (isInt(rhs[0].ty()) && isInt(rhs.ty())) {
						if (rhs[0].ty().len() < rhs.ty().len()) {
							os << "sext "; // Sign extension
						} else if (rhs[0].ty().len() > rhs.ty().len()) {
							os << "trunc "; // Truncation (same as unsigned)
						} else {
							os << "bitcast "; // Same-size conversion
						}
					} else {
						// For other cases, default to appropriate conversions
						os << "bitcast ";
					}
				}

				os << rhs[0].ty() << " " << rhs[0] << " to " << rhs.ty();
				break;
			case ElementPtr:
				// Handle getelementptr with appropriate syntax
				os << "getelementptr ";
				if (rhs.size() >= 3) {
					os << "inbounds "; // Common in LLVM IR
					os << rhs[0].ty() << ", ptr " << rhs[1];
					for (size_t i = 2; i < rhs.size(); ++i) {
						os << ", " << rhs[i].ty() << " " << rhs[i];
					}
				}
				break;
			case Eq:
			case SLe:
			case SLt:
			case ULe:
			case ULt:
				// Format: icmp <predicate> <type> <operand1>, <operand2>
				ASSERT(rhs.size() == 2);
				os << rhs.tag() << " " << rhs[0].ty() << " " << rhs[0] << ", " << rhs[1];
				break;
			case FAdd:
			case FDiv:
			case FMul:
			case FRem:
			case FSub:
				// Format: <op> <type> <operand1>, <operand2>
				ASSERT(rhs.size() == 2);
				os << rhs.tag() << " " << rhs.ty() << " " << rhs[0] << ", " << rhs[1];
				break;
			case FEq:
			case FLe:
			case FLt:
				// Format: fcmp <predicate> <type> <operand1>, <operand2>
				ASSERT(rhs.size() == 2);
				os << rhs.tag() << " " << rhs[0].ty() << " " << rhs[0] << ", " << rhs[1];
				break;
			case FNeg:
				// Format: fneg <type> <operand>
				ASSERT(rhs.size() == 1);
				os << "fneg " << rhs.ty() << " " << rhs[0];
				break;
			case Load:
				// Format: load <type>, ptr <pointer>
				ASSERT(rhs.size() == 1);
				os << "load " << rhs.ty() << ", ptr " << rhs[0];
				break;
			default:
				// For other compound expressions, use a generic format
				os << rhs.tag() << " " << rhs.ty();
				for (size_t i = 0; i < rhs.size(); ++i) {
					os << (i == 0 ? " " : ", ") << rhs[i];
				}
				break;
			}
		} else {
			// For atomic terms, output with type
			os << rhs.ty() << " " << rhs;
		}
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

ostream& operator<<(ostream& os, Global a) {
	os << '@' << a.ref() << '=' << "global " << a.ty();
	if (a.val().tag() != None) {
		os << ' ' << a.val();
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
		if (params[i].tag() == Array) {
			os << "...";
			continue;
		}
		os << params[i].ty();
		if (params[i].tag() == Var) {
			os << ' ' << params[i];
		}
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
	if (module->datalayout.size()) {
		out << "target datalayout = \"" << module->datalayout << "\"\n";
	}
	if (module->triple.size()) {
		out << "target triple = \"" << module->triple << "\"\n";
	}

	// Print comdats
	for (const auto& ref : module->comdats) {
		out << '$' << ref << " = comdat any\n";
	}

	// Print global variables
	for (const auto& global : module->globals) {
		out << global << "\n";
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
