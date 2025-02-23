#include "all.h"

struct ProgramImpl {
	const vector<Global> globals;
	const vector<Func> defines;

	ProgramImpl(const vector<Global>& globals, const vector<Func>& defines): globals(globals), defines(defines) {
	}
};

Program::Program(const vector<Global>& globals, const vector<Func>& defines) {
	p = new ProgramImpl(globals, defines);
}

vector<Global> Program::globals() const {
	return p->globals;
}

size_t Program::size() const {
	return p->defines.size();
}

Func Program::operator[](size_t i) const {
	ASSERT(i < size());
	return p->defines[i];
}

Program::const_iterator Program::begin() const {
	return p->defines.begin();
}

Program::const_iterator Program::end() const {
	return p->defines.end();
}

Program::const_iterator Program::cbegin() const {
	return p->defines.cbegin();
}

Program::const_iterator Program::cend() const {
	return p->defines.cend();
}
