BOOST_AUTO_TEST_SUITE(PhiEliminationTests)

// Helper function to create a simple function with phi nodes
Fn createTestFunction(Type returnType, const vector<Term>& params, const vector<Inst>& body) {
	return Fn(returnType, Ref("test_func"), params, body);
}

BOOST_AUTO_TEST_CASE(EmptyFunction) {
	Fn empty;
	Fn transformed = eliminatePhiNodes(empty);
	BOOST_CHECK(transformed.empty());
}

BOOST_AUTO_TEST_CASE(FunctionWithoutPhi) {
	// Create a simple function that just returns a parameter
	Type i32 = intTy(32);
	vector<Term> params = {var(i32, Ref("param"))};
	vector<Inst> body = {block(Ref("entry")), ret(var(i32, Ref("param")))};

	Fn func = createTestFunction(i32, params, body);
	Fn transformed = eliminatePhiNodes(func);

	BOOST_CHECK_EQUAL(transformed.size(), func.size());
	for (size_t i = 0; i < func.size(); i++) {
		BOOST_CHECK(transformed[i] == func[i]);
	}
}

BOOST_AUTO_TEST_CASE(SimplePhiNode) {
	Type i32 = intTy(32);
	Type i1 = intTy(1);

	// Create variables and constants
	Term condVar = var(i1, Ref("cond"));
	Term paramA = var(i32, Ref("a"));
	Term paramB = var(i32, Ref("b"));
	Term resultVar = var(i32, Ref("result"));
	Term xVar = var(i32, Ref("x"));
	Term yVar = var(i32, Ref("y"));

	vector<Term> params = {condVar, paramA, paramB};
	vector<Inst> body = {// entry block
						 block(Ref("entry")), br(condVar, Ref("then"), Ref("else")),

						 // then block
						 block(Ref("then")), assign(xVar, Term(Add, i32, paramA, paramB)), jmp(Ref("merge")),

						 // else block
						 block(Ref("else")), assign(yVar, Term(Sub, i32, paramA, paramB)), jmp(Ref("merge")),

						 // merge block
						 block(Ref("merge")), Inst(Phi, {resultVar, xVar, label(Ref("then")), yVar, label(Ref("else"))}),
						 ret(resultVar)};

	Fn func = createTestFunction(i32, params, body);
	Fn transformed = eliminatePhiNodes(func);

	// Verify phi node was eliminated
	bool foundPhi = false;
	for (const auto& inst : transformed) {
		if (inst.opcode() == Phi) {
			foundPhi = true;
			break;
		}
	}
	BOOST_CHECK(!foundPhi);

	// Verify assignments were added before branches
	bool foundAssignmentBeforeBranch = false;
	for (size_t i = 0; i < transformed.size() - 1; i++) {
		if (transformed[i].opcode() == Assign && (transformed[i + 1].opcode() == Jmp || transformed[i + 1].opcode() == Br)) {
			foundAssignmentBeforeBranch = true;
			break;
		}
	}
	BOOST_CHECK(foundAssignmentBeforeBranch);
}

BOOST_AUTO_TEST_CASE(MultiplePhiNodes) {
	Type i32 = intTy(32);
	Type i1 = intTy(1);

	// Create variables
	Term condVar = var(i1, Ref("cond"));
	Term resultA = var(i32, Ref("resultA"));
	Term resultB = var(i32, Ref("resultB"));
	Term x1 = var(i32, Ref("x1"));
	Term x2 = var(i32, Ref("x2"));
	Term y1 = var(i32, Ref("y1"));
	Term y2 = var(i32, Ref("y2"));

	vector<Term> params = {condVar};
	vector<Inst> body = {block(Ref("entry")),
						 br(condVar, Ref("then"), Ref("else")),

						 block(Ref("then")),
						 assign(x1, intConst(i32, 1)),
						 assign(x2, intConst(i32, 2)),
						 jmp(Ref("merge")),

						 block(Ref("else")),
						 assign(y1, intConst(i32, 3)),
						 assign(y2, intConst(i32, 4)),
						 jmp(Ref("merge")),

						 block(Ref("merge")),
						 Inst(Phi, {resultA, x1, label(Ref("then")), y1, label(Ref("else"))}),
						 Inst(Phi, {resultB, x2, label(Ref("then")), y2, label(Ref("else"))}),
						 ret(Term(Add, i32, resultA, resultB))};

	Fn func = createTestFunction(i32, params, body);
	Fn transformed = eliminatePhiNodes(func);

	// Verify all phi nodes were eliminated
	bool foundPhi = false;
	for (const auto& inst : transformed) {
		if (inst.opcode() == Phi) {
			foundPhi = true;
			break;
		}
	}
	BOOST_CHECK(!foundPhi);

	// Verify both assignments were added for each branch
	int assignmentCount = 0;
	for (size_t i = 0; i < transformed.size() - 1; i++) {
		if (transformed[i].opcode() == Assign && (transformed[i + 1].opcode() == Jmp || transformed[i + 1].opcode() == Br)) {
			assignmentCount++;
		}
	}
	BOOST_CHECK_GT(assignmentCount, 2);
}

BOOST_AUTO_TEST_CASE(NestedBranches) {
	Type i32 = intTy(32);
	Type i1 = intTy(1);

	Term cond1 = var(i1, Ref("cond1"));
	Term cond2 = var(i1, Ref("cond2"));
	Term resultVar = var(i32, Ref("result"));

	vector<Term> params = {cond1, cond2};
	vector<Inst> body = {block(Ref("entry")),
						 br(cond1, Ref("then1"), Ref("else1")),

						 block(Ref("then1")),
						 br(cond2, Ref("then2"), Ref("else2")),

						 block(Ref("then2")),
						 jmp(Ref("merge")),

						 block(Ref("else2")),
						 jmp(Ref("merge")),

						 block(Ref("else1")),
						 jmp(Ref("merge")),

						 block(Ref("merge")),
						 Inst(Phi, {resultVar, intConst(i32, 1), label(Ref("then2")), intConst(i32, 2), label(Ref("else2")),
									intConst(i32, 3), label(Ref("else1"))}),
						 ret(resultVar)};

	Fn func = createTestFunction(i32, params, body);
	Fn transformed = eliminatePhiNodes(func);

	// Verify phi nodes were eliminated
	bool foundPhi = false;
	for (const auto& inst : transformed) {
		if (inst.opcode() == Phi) {
			foundPhi = true;
			break;
		}
	}
	BOOST_CHECK(!foundPhi);
}

BOOST_AUTO_TEST_CASE(SelfLoop) {
	Type i32 = intTy(32);
	Type i1 = intTy(1);

	Term cond = var(i1, Ref("cond"));
	Term n = var(i32, Ref("n"));
	Term i = var(i32, Ref("i"));

	vector<Term> params = {n};
	vector<Inst> body = {block(Ref("entry")),
						 assign(i, intConst(i32, 0)),
						 jmp(Ref("loop")),

						 block(Ref("loop")),
						 Inst(Phi, {i, i, label(Ref("entry")), Term(Add, i32, i, intConst(i32, 1)), label(Ref("loop"))}),
						 assign(cond, cmp(ULt, i, n)),
						 br(cond, Ref("loop"), Ref("exit")),

						 block(Ref("exit")),
						 ret(i)};

	Fn func = createTestFunction(i32, params, body);
	Fn transformed = eliminatePhiNodes(func);

	// Verify phi nodes were eliminated
	bool foundPhi = false;
	for (const auto& inst : transformed) {
		if (inst.opcode() == Phi) {
			foundPhi = true;
			break;
		}
	}
	BOOST_CHECK(!foundPhi);
}

BOOST_AUTO_TEST_SUITE_END()
