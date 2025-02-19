inline Term jmp(Ref target) {
	return Term(Jmp, voidType(), var(ptrType(), target));
}

inline Term br(Term cond, Ref ifTrue, Ref ifFalse) {
	ASSERT(cond.type() == boolType());
	return Term(Br, voidType(), {cond, jmp(ifTrue), jmp(ifFalse)});
}
