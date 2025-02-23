#include "all.h"

struct ProgramImpl {
	const vector<Global> globals;
	const vector<Func> defs;

	ProgramImpl(const vector<Global>& globals, const vector<Func>& defs): globals(globals), defs(defs) {
	}
};

Program::Program(const vector<Global>& globals, const vector<Func>& defs) {
	p = new ProgramImpl(globals, defs);
}

vector<Global> Program::globals() const {
	return p->globals;
}

size_t Program::size() const {
	return p->defs.size();
}

Func Program::operator[](size_t i) const {
	ASSERT(i < size());
	return p->defs[i];
}

Program::const_iterator Program::begin() const {
	return p->defs.begin();
}

Program::const_iterator Program::end() const {
	return p->defs.end();
}

Program::const_iterator Program::cbegin() const {
	return p->defs.cbegin();
}

Program::const_iterator Program::cend() const {
	return p->defs.cend();
}
