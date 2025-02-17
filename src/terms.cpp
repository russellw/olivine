#include "all.h"

struct TermImpl {
	const Tag tag;
	const Type type;

	const string str;
	const cpp_int intVal;

	const vector<Term> v;

	TermImpl(Tag tag, Type type): tag(tag), type(type) {
	}

	TermImpl(Tag tag, Type type, const string& str): tag(tag), type(type), str(str) {
	}

	TermImpl(Tag tag, Type type, const cpp_int& intVal): tag(tag), type(type), intVal(intVal) {
	}

	TermImpl(Tag tag, Type type, const vector<Term>& v): tag(tag), type(type), v(v) {
	}
};

TermImpl trueImpl(Int, boolType(), 1);
TermImpl falseImpl(Int, boolType(), cpp_int(0));

TermImpl nullImpl(Null, ptrType());

Term::Term(): p(&nullImpl) {
}

Term::Term(Tag tag) {
	p = new TermImpl(tag, voidType());
}

Term::Term(Tag tag, Type type, Term a) {
	p = new TermImpl(tag, type, {a});
}

Term::Term(Tag tag, Type type, Term a, Term b) {
	p = new TermImpl(tag, type, {a, b});
}

Term ::Term(Tag tag, Type type, const vector<Term>& v) {
	p = new TermImpl(tag, type, v);
}

Tag Term::tag() const {
	return p->tag;
}

Type Term::type() const {
	return p->type;
}

bool Term::named() const {
	return p->str.size();
}

string Term::str() const {
	return p->str;
}

cpp_int Term::intVal() const {
	return p->intVal;
}

size_t Term::size() const {
	return p->v.size();
}

Term Term::operator[](size_t i) const {
	ASSERT(i < p->v.size());
	return p->v[i];
}

Term::const_iterator Term::begin() const {
	return p->v.begin();
}

Term::const_iterator Term::end() const {
	return p->v.end();
}

Term::const_iterator Term::cbegin() const {
	return p->v.cbegin();
}

Term::const_iterator Term::cend() const {
	return p->v.cend();
}

bool Term::operator==(Term b0) const {
	auto a = p;
	auto b = b0.p;
	if (a->tag != b->tag) {
		return false;
	}
	if (a->type != b->type) {
		return false;
	}
	if (a->str != b->str) {
		return false;
	}
	if (a->intVal != b->intVal) {
		return false;
	}
	return a->v == b->v;
}

bool Term::operator!=(Term b) const {
	return !(*this == b);
}

Term trueConst(&trueImpl);
Term falseConst(&falseImpl);

Term nullConst(&nullImpl);

Term intConst(Type type, const cpp_int& val) {
	ASSERT(type.kind() == IntKind);
	auto p = new TermImpl(Int, type, val);
	return Term(p);
}

Term floatConst(Type type, const string& val) {
	switch (type.kind()) {
	case DoubleKind:
	case FloatKind:
		break;
	default:
		ASSERT(false);
		break;
	}
	auto p = new TermImpl(Float, type, val);
	return Term(p);
}

Term var(Type type, const string& name) {
	ASSERT(type != voidType());
	auto p = new TermImpl(Var, type, name);
	return Term(p);
}

Term var(Type type, size_t i) {
	ASSERT(type != voidType());
	auto p = new TermImpl(Var, type, i);
	return Term(p);
}

Term globalRef(Type type, const string& name) {
	ASSERT(type != voidType());
	auto p = new TermImpl(GlobalRef, type, name);
	return Term(p);
}

Term globalRef(Type type, size_t i) {
	ASSERT(type != voidType());
	auto p = new TermImpl(GlobalRef, type, i);
	return Term(p);
}

Term array(Type elementType, const vector<Term>& elements) {
	for (auto element : elements) {
		ASSERT(element.type() == elementType);
	}
	return Term(Array, arrayType(elements.size(), elementType), elements);
}

Term tuple(const vector<Term>& elements) {
	auto types = map(elements, [](Term a) { return a.type(); });
	return Term(Tuple, structType(types), elements);
}

Term go(Term target) {
	auto p = new TermImpl(Goto, voidType(), vector<Term>{target});
	return Term(p);
}

Term go(size_t target) {
	return go(intConst(intType(64), target));
}

Term br(Term cond, Term ifTrue, Term ifFalse) {
	ASSERT(cond.type() == boolType());
	auto p = new TermImpl(If, voidType(), vector<Term>{cond, go(ifTrue), go(ifFalse)});
	return Term(p);
}

Term br(Term cond, size_t ifTrue, size_t ifFalse) {
	ASSERT(cond.type() == boolType());
	auto p = new TermImpl(If, voidType(), vector<Term>{cond, go(ifTrue), go(ifFalse)});
	return Term(p);
}

Term function(Type returnType, Term ref, const vector<Term>& params, const vector<Term>& instructions) {
	// Validate the function reference
	if (ref.tag() != GlobalRef) {
		throw invalid_argument("Function reference must be a GlobalRef");
	}

	// Validate return type matches function type
	Type functionTy = ref.type();
	if (functionTy.kind() != FuncKind || functionTy[0] != returnType) {
		throw invalid_argument("Return type mismatch with function type");
	}

	// Validate parameters
	vector<Type> paramTypes = map(params, [](Term a) { return a.type(); });
	if (paramTypes.size() != functionTy.size() - 1) {
		throw invalid_argument("Parameter count mismatch with function type");
	}

	for (size_t i = 0; i < paramTypes.size(); i++) {
		if (paramTypes[i] != functionTy[i + 1]) {
			throw invalid_argument("Parameter type mismatch at position " + to_string(i));
		}
	}

	// Validate parameter list structure
	Term paramList = tuple(params);
	if (paramList.tag() != Tuple) {
		throw invalid_argument("Invalid parameter list structure");
	}

	// Validate instructions
	for (const Term& instr : instructions) {
		// Check that each instruction has void type (as they are statements)
		if (instr.type().kind() != VoidKind && instr.tag() != Ret) {
			throw invalid_argument("Non-void instruction in function body");
		}

		// Validate return instructions match function return type
		if (instr.tag() == Ret) {
			if (returnType.kind() != VoidKind) {
				if (instr.size() != 1 || instr[0].type() != returnType) {
					throw invalid_argument("Return instruction type mismatch");
				}
			}
		} else if (instr.tag() == RetVoid) {
			if (returnType.kind() != VoidKind) {
				throw invalid_argument("Void return in non-void function");
			}
		}

		// Validate branch targets
		if (instr.tag() == Goto) {
			size_t target = instr.intVal().convert_to<size_t>();
			if (target >= instructions.size()) {
				throw invalid_argument("Invalid goto target: " + to_string(target));
			}
		}
		if (instr.tag() == If) {
			if (instr[0].type() != boolType()) {
				throw invalid_argument("If condition must be boolean type");
			}
			size_t trueTarget = instr[1].intVal().convert_to<size_t>();
			size_t falseTarget = instr[2].intVal().convert_to<size_t>();
			if (trueTarget >= instructions.size() || falseTarget >= instructions.size()) {
				throw invalid_argument("Invalid branch target in If instruction");
			}
		}
	}

	// Build the function term
	vector<Term> functionParts = {ref, paramList};
	functionParts.insert(functionParts.end(), instructions.begin(), instructions.end());

	return Term(Function, functionTy, functionParts);
}

vector<Term> getFunctionInstructions(Term f) {
	// Validate input
	if (f.tag() != Tag::Function) {
		throw invalid_argument("getFunctionInstructions: Expected a Function term");
	}

	// A function must have at least a reference and parameters
	if (f.size() < 2) {
		throw invalid_argument("getFunctionInstructions: Malformed function term");
	}

	// Create a vector to hold the instructions
	vector<Term> instructions;

	// Reserve space for efficiency (size - 2 since we skip ref and params)
	instructions.reserve(f.size() - 2);

	// Copy all elements after the reference and parameters
	for (size_t i = 2; i < f.size(); i++) {
		instructions.push_back(f[i]);
	}

	return instructions;
}
