// Helper: Create a function that includes a phi node.
Fn createFunctionWithPhi() {
	// Create a function with one parameter (of type int32)
	vector<Term> params;
	params.push_back(var(intTy(32), "p"));

	vector<Inst> body;
	// Entry block for the function.
	body.push_back(block("entry"));

	// Construct the phi node.
	// The first operand is the variable that will receive the phi value.
	Term phiVar = var(intTy(32), "x");
	// Two possible incoming values.
	Term valL1 = intConst(intTy(32), 10);
	Term valL2 = intConst(intTy(32), 20);
	// Corresponding labels.
	Term lblL1 = label("L1");
	Term lblL2 = label("L2");
	vector<Term> phiOperands = {phiVar, valL1, lblL1, valL2, lblL2};
	Inst phiInst(Phi, phiOperands);
	body.push_back(phiInst);

	// Instead of trying to assign the phi instruction to phiVar (which is not allowed),
	// simply use phiVar directly. The phi elimination pass is expected to remove phi nodes.
	body.push_back(ret(phiVar));

	// Add additional basic blocks corresponding to the labels referenced.
	body.push_back(block("L1"));
	body.push_back(ret(intConst(intTy(32), 10)));
	body.push_back(block("L2"));
	body.push_back(ret(intConst(intTy(32), 20)));

	return Fn(intTy(32), "testPhi", params, body);
}

BOOST_AUTO_TEST_CASE(test_eliminatePhiNodes_removes_phi) {
	// Build a function that contains a phi node.
	Fn f = createFunctionWithPhi();

	// Verify that the original function indeed contains a phi instruction.
	bool containsPhi = false;
	for (const auto& inst : f) {
		if (inst.opcode() == Phi) {
			containsPhi = true;
			break;
		}
	}
	BOOST_CHECK_MESSAGE(containsPhi, "Original function should contain at least one phi node");

	// Run the phi elimination pass.
	Fn fNoPhi = eliminatePhiNodes(f);

	// Check that the resulting function has no phi nodes.
	for (const auto& inst : fNoPhi) {
		BOOST_CHECK_MESSAGE(inst.opcode() != Phi, "Phi node found after elimination");
	}
}

BOOST_AUTO_TEST_CASE(test_eliminatePhiNodes_no_change_without_phi) {
	// Build a function that does not contain any phi nodes.
	vector<Term> params;
	params.push_back(var(intTy(32), "p"));

	vector<Inst> body;
	body.push_back(block("entry"));
	body.push_back(ret(intConst(intTy(32), 42))); // Simply return a constant.

	Fn f = Fn(intTy(32), "noPhi", params, body);

	// Run the phi elimination pass.
	Fn fNoPhi = eliminatePhiNodes(f);

	// Ensure no phi instructions appear in the output.
	for (const auto& inst : fNoPhi) {
		BOOST_CHECK_MESSAGE(inst.opcode() != Phi, "Unexpected phi node found");
	}

	// Optionally, if your pass should leave non-phi functions unchanged,
	// check that the overall structure (number of instructions) remains the same.
	BOOST_CHECK_EQUAL(fNoPhi.size(), f.size());
}

BOOST_AUTO_TEST_CASE(test_convert_to_ssa) {
	// Create a simple function:
	//   int foo(int x, int y) {
	//       x = add(x, y);
	//       return x;
	//   }
	//
	// In our IR, function parameters are represented as Var terms.
	Type int32 = intTy(32);
	Ref x_ref("x");
	Ref y_ref("y");

	// Parameters (as Var terms).
	Term x = var(int32, x_ref);
	Term y = var(int32, y_ref);
	vector<Term> params = {x, y};

	// Build the function body:
	// 1. Assignment: x = add(x, y)
	// 2. Return: ret(x)
	vector<Inst> body;
	// Create an add term: add(x, y)
	Term addExpr = Term(Add, int32, x, y);
	// The assign instruction writes to x.
	body.push_back(assign(x, addExpr));
	// Return x.
	body.push_back(ret(x));

	// Create the function 'foo'
	Fn foo = Fn(int32, Ref("foo"), params, body);

	// Convert the function to SSA form (lowering mutable variables into allocas).
	Fn ssa = convertToSSA(foo);

	// Now verify the following expected properties:
	// - There is an alloca for each parameter (x and y) inserted at the beginning.
	// - The assign to x has been converted into a store (storing the new value into x’s alloca).
	// - The return instruction uses a load from x’s alloca instead of x directly.
	bool foundAllocaX = false;
	bool foundAllocaY = false;
	bool foundStoreForX = false;
	bool retUsesLoadForX = false;

	for (size_t i = 0; i < ssa.size(); ++i) {
		Inst inst = ssa[i];
		switch (inst.opcode()) {
		case Alloca: {
			// The first operand of an alloca is the pointer variable.
			Term ptr = inst[0];
			if (ptr.ref() == x_ref) {
				foundAllocaX = true;
			}
			if (ptr.ref() == y_ref) {
				foundAllocaY = true;
			}
			break;
		}
		case Store: {
			// In our convention, a store's second operand is the pointer.
			Term ptr = inst[1];
			if (ptr.ref() == x_ref) {
				foundStoreForX = true;
			}
			break;
		}
		case Ret: {
			// For a return, the operand should now be a load (if it was a variable usage).
			Term retOp = inst[0];
			if (retOp.tag() == Load) {
				retUsesLoadForX = true;
			}
			break;
		}
		default:
			break;
		}
	}

	BOOST_CHECK(foundAllocaX);
	BOOST_CHECK(foundAllocaY);
	BOOST_CHECK(foundStoreForX);
	BOOST_CHECK(retUsesLoadForX);
}
