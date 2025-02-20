#include "all.h"

struct TypeImpl {
	const Kind kind;
	const size_t len;
	const vector<Type> v;

	explicit TypeImpl(Kind kind): kind(kind), len(0) {
	}

	TypeImpl(Kind kind, size_t len): kind(kind), len(len) {
	}

	TypeImpl(Kind kind, size_t len, Type element): kind(kind), len(len), v(1, element) {
	}

	TypeImpl(Kind kind, const vector<Type>& v): kind(kind), len(0), v(v) {
	}
};

TypeImpl voidImpl(VoidKind);

TypeImpl boolImpl(IntKind, 1);

TypeImpl floatImpl(FloatKind);
TypeImpl doubleImpl(DoubleKind);

TypeImpl ptrImpl(PtrKind);

class TypeInterner {
	struct TypeHash {
		size_t operator()(const TypeImpl* p) const {
			size_t h = hash<Kind>()(p->kind);
			h ^= hash<size_t>()(p->len) + 0x9e3779b9 + (h << 6) + (h >> 2);
			for (const auto& t : p->v) {
				h ^= hash<Type>()(t) + 0x9e3779b9 + (h << 6) + (h >> 2);
			}
			return h;
		}
	};

	struct TypeEqual {
		bool operator()(const TypeImpl* a, const TypeImpl* b) const {
			return a->kind == b->kind && a->len == b->len && a->v == b->v;
		}
	};

	unordered_set<TypeImpl*, TypeHash, TypeEqual> types;

public:
	TypeInterner() {
		// Insert the primitive types
		types.insert(&voidImpl);

		types.insert(&boolImpl);

		types.insert(&floatImpl);
		types.insert(&doubleImpl);

		types.insert(&ptrImpl);
	}

	TypeImpl* intern(TypeImpl* type) {
		auto it = types.find(type);
		if (it != types.end()) {
			delete type; // Delete the duplicate
			return *it;
		}
		types.insert(type);
		return type;
	}
};

TypeInterner typeInterner;

Type::Type(): p(&voidImpl) {
}

Kind Type::kind() const {
	return p->kind;
}

size_t Type::len() const {
	return p->len;
}

size_t Type::size() const {
	return p->v.size();
}

Type Type::operator[](size_t i) const {
	ASSERT(i < p->v.size());
	return p->v[i];
}

Type::const_iterator Type::begin() const {
	return p->v.begin();
}

Type::const_iterator Type::end() const {
	return p->v.end();
}

Type::const_iterator Type::cbegin() const {
	return p->v.cbegin();
}

Type::const_iterator Type::cend() const {
	return p->v.cend();
}

bool Type::operator==(Type b0) const {
	auto a = p;
	auto b = b0.p;
	if (a->kind != b->kind) {
		return false;
	}
	if (a->len != b->len) {
		return false;
	}
	return a->v == b->v;
}

bool Type::operator!=(Type b) const {
	return !(*this == b);
}

Type voidTy() {
	static Type type(&voidImpl);
	return type;
}

Type boolTy() {
	static Type type(&boolImpl);
	return type;
}

Type intTy(size_t len) {
	ASSERT(len);
	auto p = new TypeImpl(IntKind, len);
	return Type(typeInterner.intern(p));
}

Type floatTy() {
	static Type type(&floatImpl);
	return type;
}

Type doubleTy() {
	static Type type(&doubleImpl);
	return type;
}

Type ptrType() {
	static Type type(&ptrImpl);
	return type;
}

Type vecType(size_t len, Type element) {
	ASSERT(element != voidTy());
	auto p = new TypeImpl(VecKind, len, element);
	return Type(typeInterner.intern(p));
}

Type arrayType(size_t len, Type element) {
	ASSERT(element != voidTy());
	auto p = new TypeImpl(ArrayKind, len, element);
	return Type(typeInterner.intern(p));
}

Type structType(const vector<Type>& fields) {
	for (auto field : fields) {
		ASSERT(field != voidTy());
	}
	auto p = new TypeImpl(StructKind, fields);
	return Type(typeInterner.intern(p));
}

Type funcType(Type rty, const vector<Type>& params) {
	for (auto param : params) {
		ASSERT(param != voidTy());
	}
	vector<Type> v;
	v.push_back(rty);
	v.insert(v.end(), params.begin(), params.end());
	auto p = new TypeImpl(FuncKind, v);
	return Type(typeInterner.intern(p));
}
