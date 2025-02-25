BOOST_AUTO_TEST_SUITE(TermChecker)

// Helper functions to create common test terms
Term makeIntTerm(int bits, cpp_int value) {
	return intConst(intTy(bits), value);
}

Term makeFloatTerm(const string& val) {
	return floatConst(floatTy(), val);
}

Term makeDoubleTerm(const string& val) {
	return floatConst(doubleTy(), val);
}

// Null tests
BOOST_AUTO_TEST_CASE(NullTermValid) {
	BOOST_CHECK_NO_THROW(check(nullConst));
}

BOOST_AUTO_TEST_CASE(NullTermInvalidType) {
	Term invalidNull(Null, intTy(32), Ref());
	BOOST_CHECK_THROW(check(invalidNull), runtime_error);
}

// Integer constant tests
BOOST_AUTO_TEST_CASE(IntConstValid) {
	BOOST_CHECK_NO_THROW(check(makeIntTerm(32, 42)));
}

BOOST_AUTO_TEST_CASE(IntConstInvalidType) {
	Term invalidInt(Int, floatTy(), Ref());
	BOOST_CHECK_THROW(check(invalidInt), runtime_error);
}

// Floating point constant tests
BOOST_AUTO_TEST_CASE(FloatConstValid) {
	BOOST_CHECK_NO_THROW(check(makeFloatTerm("3.14")));
	BOOST_CHECK_NO_THROW(check(makeDoubleTerm("3.14")));
}

BOOST_AUTO_TEST_CASE(FloatConstInvalidType) {
	Term invalidFloat(Float, intTy(32), Ref("3.14"));
	BOOST_CHECK_THROW(check(invalidFloat), runtime_error);
}

// Arithmetic operation tests
BOOST_AUTO_TEST_CASE(IntegerArithmeticValid) {
	auto a = makeIntTerm(32, 1);
	auto b = makeIntTerm(32, 2);

	BOOST_CHECK_NO_THROW(check(Term(Add, intTy(32), a, b)));
	BOOST_CHECK_NO_THROW(check(Term(Sub, intTy(32), a, b)));
	BOOST_CHECK_NO_THROW(check(Term(Mul, intTy(32), a, b)));
}

BOOST_AUTO_TEST_CASE(IntegerArithmeticTypeMismatch) {
	auto a = makeIntTerm(32, 1);
	auto b = makeIntTerm(64, 2);

	BOOST_CHECK_THROW(check(Term(Add, intTy(32), a, b)), runtime_error);
}

BOOST_AUTO_TEST_CASE(FloatingArithmeticValid) {
	auto a = makeFloatTerm("1.0");
	auto b = makeFloatTerm("2.0");

	BOOST_CHECK_NO_THROW(check(Term(FAdd, floatTy(), a, b)));
	BOOST_CHECK_NO_THROW(check(Term(FSub, floatTy(), a, b)));
	BOOST_CHECK_NO_THROW(check(Term(FMul, floatTy(), a, b)));
}

BOOST_AUTO_TEST_CASE(FloatingArithmeticTypeMismatch) {
	auto a = makeFloatTerm("1.0");
	auto b = makeDoubleTerm("2.0");

	BOOST_CHECK_THROW(check(Term(FAdd, floatTy(), a, b)), runtime_error);
}

// Comparison tests
BOOST_AUTO_TEST_CASE(IntegerComparisonValid) {
	auto a = makeIntTerm(32, 1);
	auto b = makeIntTerm(32, 2);

	BOOST_CHECK_NO_THROW(check(Term(ULt, boolTy(), a, b)));
	BOOST_CHECK_NO_THROW(check(Term(ULe, boolTy(), a, b)));
	BOOST_CHECK_NO_THROW(check(Term(SLt, boolTy(), a, b)));
	BOOST_CHECK_NO_THROW(check(Term(SLe, boolTy(), a, b)));
}

BOOST_AUTO_TEST_CASE(FloatComparisonValid) {
	auto a = makeFloatTerm("1.0");
	auto b = makeFloatTerm("2.0");

	BOOST_CHECK_NO_THROW(check(Term(FLt, boolTy(), a, b)));
	BOOST_CHECK_NO_THROW(check(Term(FLe, boolTy(), a, b)));
}

// Logical operation tests
BOOST_AUTO_TEST_CASE(LogicalOperationsValid) {
	auto a = Term(Int, boolTy(), Ref("1"));
	auto b = Term(Int, boolTy(), Ref("0"));

	BOOST_CHECK_NO_THROW(check(Term(And, boolTy(), a, b)));
	BOOST_CHECK_NO_THROW(check(Term(Or, boolTy(), a, b)));
	BOOST_CHECK_NO_THROW(check(Term(Not, boolTy(), a)));
}

// Array tests
BOOST_AUTO_TEST_CASE(ArrayValid) {
	vector<Term> elements = {makeIntTerm(32, 1), makeIntTerm(32, 2), makeIntTerm(32, 3)};
	BOOST_CHECK_NO_THROW(check(array(intTy(32), elements)));
}

BOOST_AUTO_TEST_CASE(ArrayTypeMismatch) {
	vector<Term> elements = {makeIntTerm(32, 1), makeFloatTerm("2.0")};
	BOOST_CHECK_THROW(check(array(intTy(32), elements)), runtime_error);
}

// Tuple tests
BOOST_AUTO_TEST_CASE(TupleValid) {
	vector<Term> elements = {makeIntTerm(32, 1), makeFloatTerm("2.0"), makeDoubleTerm("3.0")};
	vector<Type> types = {intTy(32), floatTy(), doubleTy()};
	BOOST_CHECK_NO_THROW(check(Term(Tuple, structTy(types), elements)));
}

BOOST_AUTO_TEST_CASE(TupleTypeMismatch) {
	vector<Term> elements = {makeIntTerm(32, 1), makeFloatTerm("2.0")};
	vector<Type> types = {intTy(64), floatTy()};
	BOOST_CHECK_THROW(check(Term(Tuple, structTy(types), elements)), runtime_error);
}

// Function call tests
BOOST_AUTO_TEST_CASE(FunctionCallValid) {
	// Create a function type: int32(float, double)
	vector<Type> paramTypes = {floatTy(), doubleTy()};
	Type funcType = funcTy(intTy(32), paramTypes);

	// Create function reference and arguments
	Term func = Term(GlobalRef, funcType, Ref("test_func"));
	Term arg1 = makeFloatTerm("1.0");
	Term arg2 = makeDoubleTerm("2.0");

	vector<Term> args = {func, arg1, arg2};
	BOOST_CHECK_NO_THROW(check(Term(Call, intTy(32), args)));
}

BOOST_AUTO_TEST_CASE(FunctionCallWrongArgCount) {
	vector<Type> paramTypes = {floatTy(), doubleTy()};
	Type funcType = funcTy(intTy(32), paramTypes);

	Term func = Term(GlobalRef, funcType, Ref("test_func"));
	Term arg1 = makeFloatTerm("1.0");

	vector<Term> args = {func, arg1}; // Missing one argument
	BOOST_CHECK_THROW(check(Term(Call, intTy(32), args)), runtime_error);
}

// Pointer operation tests
BOOST_AUTO_TEST_CASE(LoadValid) {
	Term ptr(Var, ptrTy(), Ref("ptr"));
	BOOST_CHECK_NO_THROW(check(Term(Load, intTy(32), ptr)));
}

BOOST_AUTO_TEST_CASE(LoadInvalidPointer) {
	Term nonPtr(Var, intTy(32), Ref("not_a_ptr"));
	BOOST_CHECK_THROW(check(Term(Load, intTy(32), nonPtr)), runtime_error);
}

BOOST_AUTO_TEST_CASE(ElementPtrValid) {
	Term ptr(Var, ptrTy(), Ref("array_ptr"));
	Term idx = makeIntTerm(32, 0);
	Term zero = zeroVal(intTy(32));
	BOOST_CHECK_NO_THROW(check(Term(ElementPtr, ptrTy(), zero, ptr, idx)));
}

BOOST_AUTO_TEST_CASE(ElementPtrInvalidIndex) {
	Term ptr(Var, ptrTy(), Ref("array_ptr"));
	Term invalidIdx = makeFloatTerm("0.0");
	Term zero = zeroVal(intTy(32));
	BOOST_CHECK_THROW(check(Term(ElementPtr, ptrTy(), zero, ptr, invalidIdx)), runtime_error);
}

// Cast operation tests
BOOST_AUTO_TEST_CASE(CastValid) {
	auto intVal = makeIntTerm(32, 42);
	BOOST_CHECK_NO_THROW(check(Term(Cast, floatTy(), intVal)));
	BOOST_CHECK_NO_THROW(check(Term(SCast, doubleTy(), intVal)));
}

BOOST_AUTO_TEST_CASE(CastInvalidTypes) {
	Term ptr(Var, ptrTy(), Ref("ptr"));
	BOOST_CHECK_THROW(check(Term(Cast, intTy(32), ptr)), runtime_error);
}

BOOST_AUTO_TEST_SUITE_END()
