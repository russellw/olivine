#include "all.h"

struct GlobalVarImpl {
	const Type type;
	const Ref ref;

	GlobalVarImpl(Type type, const Ref& ref): type(type), ref(ref) {
	}
};

GlobalVar::GlobalVar(Type type, const Ref& ref) {
	p = new GlobalVarImpl(type, ref);
}
