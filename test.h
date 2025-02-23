
namespace {
// Helper to check if a term matches a specific reference string
bool hasRef(const Term& term, const string& name) {
    if (!std::holds_alternative<string>(term.ref())) {
        return false;
    }
    return std::get<string>(term.ref()) == name;
}

// Helper to check if a term is a variable with specific reference
bool hasVarRef(const Term& term, const string& name) {
    return term.tag() == Var && hasRef(term, name);
}

// Helper to check if a term is a label with specific reference
bool hasLabelRef(const Term& term, const string& name) {
    return term.tag() == Label && hasRef(term, name);
}

// Helper to count instructions of a specific type
int countOpcode(const Func& func, Opcode op) {
    int count = 0;
    for (const Inst& inst : func) {
        if (inst.opcode() == op) count++;
    }
    return count;
}

// Helper to find an instruction by opcode and index
const Inst* findNthInst(const Func& func, Opcode op, int n) {
    for (const Inst& inst : func) {
        if (inst.opcode() == op) {
            if (n == 0) return &inst;
            n--;
        }
    }
    return nullptr;
}
}

BOOST_AUTO_TEST_SUITE(AllocaTransformationTests)

// Test simple assignment is converted to alloca + store
BOOST_AUTO_TEST_CASE(SimpleAssignment) {
    vector<Inst> body = {
        assign(var(intTy(32), Ref("x")), intConst(intTy(32), 42))
    };
    
    Func input(intTy(32), Ref("test"), {}, body);
    Func result = convertToAllocas(input);
    
    BOOST_REQUIRE_EQUAL(result.size(), 2);
    BOOST_CHECK_EQUAL(result[0].opcode(), Alloca);
    BOOST_CHECK_EQUAL(result[1].opcode(), Store);
    
    // Check alloca
    BOOST_CHECK(hasVarRef(result[0][0], "x.ptr"));
    
    // Check store
    BOOST_CHECK_EQUAL(result[1][0].intVal(), 42);
    BOOST_CHECK(hasVarRef(result[1][1], "x.ptr"));
}

// Test that variable use is converted to load
BOOST_AUTO_TEST_CASE(VariableUse) {
    vector<Inst> body = {
        assign(var(intTy(32), Ref("x")), intConst(intTy(32), 42)),
        assign(var(intTy(32), Ref("y")), 
               Term(Add, intTy(32), var(intTy(32), Ref("x")), intConst(intTy(32), 1)))
    };
    
    Func input(intTy(32), Ref("test"), {}, body);
    Func result = convertToAllocas(input);
    
    // Check instruction counts
    BOOST_CHECK_EQUAL(countOpcode(result, Alloca), 2);
    BOOST_CHECK_EQUAL(countOpcode(result, Store), 2);
    BOOST_CHECK_EQUAL(countOpcode(result, static_cast<Opcode>(Load)), 1);
    
    // Find the load instruction
    const Inst* loadInst = findNthInst(result, static_cast<Opcode>(Load), 0);
    BOOST_REQUIRE(loadInst != nullptr);
    BOOST_CHECK(hasVarRef((*loadInst)[0], "x.load"));
    BOOST_CHECK(hasVarRef((*loadInst)[1], "x.ptr"));
}

// Test that non-mutable variables aren't transformed
BOOST_AUTO_TEST_CASE(NonMutableVariable) {
    vector<Inst> body = {
        assign(var(intTy(32), Ref("x")), 
               Term(Add, intTy(32), var(intTy(32), Ref("z")), intConst(intTy(32), 1)))
    };
    
    Func input(intTy(32), Ref("test"), {}, body);
    Func result = convertToAllocas(input);
    
    // Only x should have an alloca
    BOOST_CHECK_EQUAL(countOpcode(result, Alloca), 1);
    
    // Find the add instruction and check z is untouched
    bool found_z = false;
    for (const Inst& inst : result) {
        for (const Term& term : inst) {
            if (hasVarRef(term, "z")) {
                found_z = true;
            }
        }
    }
    BOOST_CHECK(found_z);
}

// Test multiple assignments to same variable
BOOST_AUTO_TEST_CASE(MultipleAssignments) {
    vector<Inst> body = {
        assign(var(intTy(32), Ref("x")), intConst(intTy(32), 1)),
        assign(var(intTy(32), Ref("x")), 
               Term(Add, intTy(32), var(intTy(32), Ref("x")), intConst(intTy(32), 1))),
        assign(var(intTy(32), Ref("x")), 
               Term(Add, intTy(32), var(intTy(32), Ref("x")), intConst(intTy(32), 2)))
    };
    
    Func input(intTy(32), Ref("test"), {}, body);
    Func result = convertToAllocas(input);
    
    BOOST_CHECK_EQUAL(countOpcode(result, Alloca), 1);
    BOOST_CHECK_EQUAL(countOpcode(result, Store), 3);
    BOOST_CHECK_EQUAL(countOpcode(result, static_cast<Opcode>(Load)), 2);
}

// Test branching code
BOOST_AUTO_TEST_CASE(Branching) {
    vector<Inst> body = {
        block(Ref("entry")),
        assign(var(intTy(32), Ref("x")), intConst(intTy(32), 1)),
        br(var(intTy(1), Ref("cond")), Ref("then"), Ref("else")),
        
        block(Ref("then")),
        assign(var(intTy(32), Ref("x")), intConst(intTy(32), 2)),
        jmp(Ref("end")),
        
        block(Ref("else")),
        assign(var(intTy(32), Ref("x")), intConst(intTy(32), 3)),
        jmp(Ref("end")),
        
        block(Ref("end")),
        ret(var(intTy(32), Ref("x")))
    };
    
    Func input(intTy(32), Ref("test"), {}, body);
    Func result = convertToAllocas(input);
    
    // Check basic structure
    BOOST_CHECK_EQUAL(countOpcode(result, Block), 4);
    BOOST_CHECK_EQUAL(countOpcode(result, Alloca), 1);
    BOOST_CHECK_EQUAL(countOpcode(result, Store), 3);
    BOOST_CHECK_EQUAL(countOpcode(result, static_cast<Opcode>(Load)), 1);
    
    // Check alloca comes first
    BOOST_CHECK_EQUAL(result[0].opcode(), Alloca);
    
    // Check block order
    vector<string> expected_blocks = {"entry", "then", "else", "end"};
    int block_idx = 0;
    for (const Inst& inst : result) {
        if (inst.opcode() == Block) {
            BOOST_REQUIRE_LT(block_idx, expected_blocks.size());
            BOOST_CHECK(hasLabelRef(inst[0], expected_blocks[block_idx]));
            block_idx++;
        }
    }
}

BOOST_AUTO_TEST_SUITE_END()