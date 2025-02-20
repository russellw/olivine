#include "all.h"

struct FuncImpl {
	const Type returnType;
	const Ref ref;
	const vector<Term>& params;
	const vector<Inst>& insts;

	FuncImpl(Type returnType, const Ref& ref, const vector<Term>& params, const vector<Inst>& insts)
		: returnType(returnType), ref(ref), params(params), insts(insts) {
	}
};

Func::Func(Type returnType, const Ref& ref, const vector<Term>& params) {
	p = new FuncImpl(returnType, ref, params, {});
}

Func::Func(Type returnType, const Ref& ref, const vector<Term>& params, const vector<Inst>& insts) {
	p = new FuncImpl(returnType, ref, params, insts);
}
