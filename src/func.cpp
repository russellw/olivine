#include "all.h"

struct FuncImpl {
	const Type retType;
	const Ref ref;
	const vector<Term>& params;
	const vector<Inst>& insts;

	FuncImpl(Type retType, const Ref& ref, const vector<Term>& params, const vector<Inst>& insts)
		: retType(retType), ref(ref), params(params), insts(insts) {
	}
};

Func::Func(Type retType, const Ref& ref, const vector<Term>& params) {
	p = new FuncImpl(retType, ref, params, {});
}

Func::Func(Type retType, const Ref& ref, const vector<Term>& params, const vector<Inst>& insts) {
	p = new FuncImpl(retType, ref, params, insts);
}
