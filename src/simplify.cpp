#include "all.h"

Term simplify(const unordered_map<Term, Term>& env, Term a) {
	// Base cases: constants and environmental lookups
	switch (a.tag()) {
	case Float:
	case Int:
	case Null:
		return a;
	case Var:
		auto it = env.find(a);
		if (it != env.end()) {
			return it->second;
		}
		return a;
	}

	// Recursively simplify all components
	vector<Term> simplified;
	for (size_t i = 0; i < a.size(); i++) {
		simplified.push_back(simplify(env, a[i]));
	}

	// Always attempt simplification, even if components didn't change
	// Note: removed incorrect optimization that skipped simplification when components were unchanged

	// Try to evaluate constant expressions
	if (a.size() == 2 && simplified[0].tag() == Int && simplified[1].tag() == Int) {
		cpp_int v0 = simplified[0].intVal();
		cpp_int v1 = simplified[1].intVal();
		Type ty = simplified[0].type();

		switch (a.tag()) {
		case AShr:
			if (v1 >= 0 && v1 < ty.len()) {
				// Implement arithmetic right shift
				bool sign = (v0 < 0);
				cpp_int result = v0 >> v1.convert_to<unsigned>();
				if (sign) {
					cpp_int mask = (cpp_int(1) << (ty.len() - v1.convert_to<unsigned>())) - 1;
					mask = ~mask;
					result |= mask;
				}
				return intConst(ty, result);
			}
			break;
		case Add:
			return intConst(ty, v0 + v1);
		case And:
			return intConst(ty, v0 & v1);
		case Eq:
			return v0 == v1 ? trueConst : falseConst;
		case LShr:
			if (v1 >= 0 && v1 < ty.len()) {
				return intConst(ty, v0 >> v1.convert_to<unsigned>());
			}
			break;
		case Mul:
			return intConst(ty, v0 * v1);
		case Or:
			return intConst(ty, v0 | v1);
		case SDiv:
			if (v1 != 0) {
				return intConst(ty, v0 / v1); // Assuming cpp_int handles signed division
			}
			break;
		case SLe:
			return v0 <= v1 ? trueConst : falseConst;
		case SLt:
			return v0 < v1 ? trueConst : falseConst; // cpp_int handles signed comparison
		case SRem:
			if (v1 != 0) {
				return intConst(ty, v0 % v1); // Assuming cpp_int handles signed remainder
			}
			break;
		case Shl:
			if (v1 >= 0 && v1 < ty.len()) {
				return intConst(ty, v0 << v1.convert_to<unsigned>());
			}
			break;
		case Sub:
			return intConst(ty, v0 - v1);
		case UDiv:
			if (v1 != 0) {
				return intConst(ty, v0 / v1);
			}
			break;
		case ULe:
			return v0 <= v1 ? trueConst : falseConst;
		case ULt:
			return v0 < v1 ? trueConst : falseConst;
		case URem:
			if (v1 != 0) {
				return intConst(ty, v0 % v1);
			}
			break;
		case Xor:
			return intConst(ty, v0 ^ v1);
		}
	}

	// Algebraic simplifications
	switch (a.tag()) {
	case Add: {
		// x + 0 = x
		if (simplified[1].tag() == Int && simplified[1].intVal() == 0) {
			return simplified[0];
		}
		// 0 + x = x
		if (simplified[0].tag() == Int && simplified[0].intVal() == 0) {
			return simplified[1];
		}
		break;
	}
	case Sub: {
		// x - 0 = x
		if (simplified[1].tag() == Int && simplified[1].intVal() == 0) {
			return simplified[0];
		}
		// x - x = 0
		if (simplified[0] == simplified[1]) {
			return intConst(simplified[0].type(), 0);
		}
		break;
	}
	case Mul: {
		// x * 0 = 0
		if ((simplified[0].tag() == Int && simplified[0].intVal() == 0) ||
			(simplified[1].tag() == Int && simplified[1].intVal() == 0)) {
			return intConst(simplified[0].type(), 0);
		}
		// x * 1 = x
		if (simplified[1].tag() == Int && simplified[1].intVal() == 1) {
			return simplified[0];
		}
		// 1 * x = x
		if (simplified[0].tag() == Int && simplified[0].intVal() == 1) {
			return simplified[1];
		}
		break;
	}
	case And: {
		// x & 0 = 0
		if (simplified[1].tag() == Int && simplified[1].intVal() == 0) {
			return intConst(simplified[0].type(), 0);
		}
		// 0 & x = 0
		if (simplified[0].tag() == Int && simplified[0].intVal() == 0) {
			return intConst(simplified[1].type(), 0);
		}
		// x & x = x
		if (simplified[0] == simplified[1]) {
			return simplified[0];
		}
		break;
	}
	case Or: {
		// x | 0 = x
		if (simplified[1].tag() == Int && simplified[1].intVal() == 0) {
			return simplified[0];
		}
		// 0 | x = x
		if (simplified[0].tag() == Int && simplified[0].intVal() == 0) {
			return simplified[1];
		}
		// x | x = x
		if (simplified[0] == simplified[1]) {
			return simplified[0];
		}
		break;
	}
	case Xor: {
		// x ^ 0 = x
		if (simplified[1].tag() == Int && simplified[1].intVal() == 0) {
			return simplified[0];
		}
		// 0 ^ x = x
		if (simplified[0].tag() == Int && simplified[0].intVal() == 0) {
			return simplified[1];
		}
		// x ^ x = 0
		if (simplified[0] == simplified[1]) {
			return intConst(simplified[0].type(), 0);
		}
		break;
	}
	case FAdd:
	case FDiv:
	case FMul:
	case FRem:
	case FSub:
		// Skip floating-point evaluation as specified
		break;
	case FNeg:
		// Skip floating-point evaluation as specified
		break;
	}

	// If no simplification was possible, return a new term with simplified components
	return Term(a.tag(), a.type(), simplified);
}
