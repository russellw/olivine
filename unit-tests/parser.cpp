// Test fixture for Parser tests
class ParserFixture {
protected:
	void parseFiles(const std::string& content1, const std::string& content2 = "") {
		if (!content1.empty()) {
			Parser("test1.ll", content1);
		}
		if (!content2.empty()) {
			Parser("test2.ll", content2);
		}
	}

	void expectError(const std::string& content1, const std::string& content2, const std::string& expectedError) {
		try {
			Parser("test1.ll", content1);
			Parser("test2.ll", content2);
			BOOST_FAIL("Expected error was not thrown");
		} catch (const std::runtime_error& e) {
			BOOST_CHECK_EQUAL(std::string(e.what()), expectedError);
		}
	}

	void expectError(const std::string& content, const std::string& expectedError) {
		try {
			Parser("test.ll", content);
			BOOST_FAIL("Expected error was not thrown");
		} catch (const std::runtime_error&) {
		}
	}
};

BOOST_FIXTURE_TEST_SUITE(ParserTests, ParserFixture)

BOOST_AUTO_TEST_CASE(ParseTargetTriple) {
	const std::string input = "target triple = \"x86_64-pc-linux-gnu\"\n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(context::triple, "x86_64-pc-linux-gnu");
}

BOOST_AUTO_TEST_CASE(ParseTargetDatalayout) {
	const std::string input = "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(context::datalayout, "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128");
}

BOOST_AUTO_TEST_CASE(ParseBothTargets) {
	const std::string input = "target triple = \"x86_64-pc-linux-gnu\"\n"
							  "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(context::triple, "x86_64-pc-linux-gnu");
	BOOST_CHECK_EQUAL(context::datalayout, "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128");
}

BOOST_AUTO_TEST_CASE(ConsistentTargetsAcrossFiles) {
	const std::string input1 = "target triple = \"x86_64-pc-linux-gnu\"\n";
	const std::string input2 = "target triple = \"x86_64-pc-linux-gnu\"\n";
	this->parseFiles(input1, input2);
	BOOST_CHECK_EQUAL(context::triple, "x86_64-pc-linux-gnu");
}

BOOST_AUTO_TEST_CASE(InconsistentTriple) {
	const std::string input1 = "target triple = \"x86_64-pc-linux-gnu\"\n";
	const std::string input2 = "target triple = \"aarch64-apple-darwin\"\n";
	this->expectError(input1, input2, "test2.ll:1: inconsistent triple");
}

BOOST_AUTO_TEST_CASE(InconsistentDatalayout) {
	const std::string input1 = "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
	const std::string input2 = "target datalayout = \"e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n";
	this->expectError(input1, input2, "test2.ll:1: inconsistent datalayout");
}

BOOST_AUTO_TEST_CASE(MissingQuotes) {
	const std::string input = "target triple = x86_64-pc-linux-gnu\n";
	this->expectError(input, "test.ll:1: expected string");
}

BOOST_AUTO_TEST_CASE(UnclosedQuote) {
	const std::string input = "target triple = \"x86_64-pc-linux-gnu\n";
	this->expectError(input, "test.ll:1: unclosed quote");
}

BOOST_AUTO_TEST_CASE(MissingEquals) {
	const std::string input = "target triple \"x86_64-pc-linux-gnu\"\n";
	this->expectError(input, "test.ll:1: expected '='");
}

BOOST_AUTO_TEST_CASE(IgnoreComments) {
	const std::string input = "; This is a comment\n"
							  "target triple = \"x86_64-pc-linux-gnu\" ; Another comment\n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(context::triple, "x86_64-pc-linux-gnu");
}

BOOST_AUTO_TEST_CASE(IgnoreWhitespace) {
	const std::string input = "   \t  target    triple    =    \"x86_64-pc-linux-gnu\"   \n";
	this->parseFiles(input);
	BOOST_CHECK_EQUAL(context::triple, "x86_64-pc-linux-gnu");
}

BOOST_AUTO_TEST_SUITE_END()
