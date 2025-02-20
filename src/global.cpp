#include "all.h"

struct GlobalImpl {
	const Type type;
	const Ref ref;

	GlobalImpl(Type type, const Ref& ref): type(type), ref(ref) {
	}
};

Global::Global(Type type, const Ref& ref) {
	p = new GlobalImpl(type, ref);
}
