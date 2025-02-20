#include "all.h"

struct FuncImpl {
	const Type rty;
	const Ref ref;
	const vector<Term>& params;
	const vector<Inst>& insts;

	FuncImpl(Type rty, const Ref& ref, const vector<Term>& params, const vector<Inst>& insts)
		: rty(rty), ref(ref), params(params), insts(insts) {
	}
};

Func::Func(Type rty, const Ref& ref, const vector<Term>& params) {
	p = new FuncImpl(rty, ref, params, {});
}

Func::Func(Type rty, const Ref& ref, const vector<Term>& params, const vector<Inst>& insts) {
	p = new FuncImpl(rty, ref, params, insts);
}
