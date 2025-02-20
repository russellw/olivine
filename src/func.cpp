#include "all.h"

struct FuncImpl {
	const Type returnType;
	const Ref ref;
	const vector<Term>& params;
	const vector<Instruction>& instructions;

	FuncImpl(Type returnType, const Ref& ref, const vector<Term>& params, const vector<Instruction>& instructions)
		: returnType(returnType), ref(ref), params(params), instructions(instructions) {
	}
};

Func::Func(Type returnType, const Ref& ref, const vector<Term>& params) {
	p = new FuncImpl(returnType, ref, params, {});
}

Func::Func(Type returnType, const Ref& ref, const vector<Term>& params, const vector<Instruction>& instructions) {
	p = new FuncImpl(returnType, ref, params, instructions);
}
