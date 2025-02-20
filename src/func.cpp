#include "all.h"

struct FunctionImpl {
	const Type returnType;
	const Ref ref;
	const vector<Term>& params;
	const vector<Instruction>& instructions;

	FunctionImpl(Type returnType, const Ref& ref, const vector<Term>& params, const vector<Instruction>& instructions)
		: returnType(returnType), ref(ref), params(params), instructions(instructions) {
	}
};

Function::Function(Type returnType, const Ref& ref, const vector<Term>& params) {
	p = new FunctionImpl(returnType, ref, params, {});
}

Function::Function(Type returnType, const Ref& ref, const vector<Term>& params, const vector<Instruction>& instructions) {
	p = new FunctionImpl(returnType, ref, params, instructions);
}
