
Term createMockVar(const string& name) {
	return var(floatTy(), name);
}

BOOST_AUTO_TEST_SUITE(ParserTestSuite)

BOOST_AUTO_TEST_CASE(ParseAddInst) {
	// Test error cases
	{
		// Mismatched types
		const string badInput = R"(
define i32 @test() {
    %1 = add i32 %2, i64 %3
    ret i32 %1
}
)";
		BOOST_CHECK_THROW(Parser("test.ll", badInput), runtime_error);

		// Missing operand
		const string missingOperand = R"(
define i32 @test() {
    %1 = add i32 %2
    ret i32 %1
}
)";
		BOOST_CHECK_THROW(Parser("test.ll", missingOperand), runtime_error);

		// Missing type
		const string missingType = R"(
define i32 @test() {
    %1 = add %2, %3
    ret i32 %1
}
)";
		BOOST_CHECK_THROW(Parser("test.ll", missingType), runtime_error);
	}
}

BOOST_AUTO_TEST_SUITE_END()
