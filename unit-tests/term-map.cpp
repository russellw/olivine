#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_CASE(BasicTermMapping) {
	std::unordered_map<Term, int> termMap;

	// Test constant terms
	termMap[trueConst] = 1;
	termMap[falseConst] = 2;
	termMap[nullConst] = 3;

	BOOST_CHECK_EQUAL(termMap[trueConst], 1);
	BOOST_CHECK_EQUAL(termMap[falseConst], 2);
	BOOST_CHECK_EQUAL(termMap[nullConst], 3);
}

BOOST_AUTO_TEST_CASE(IntegerTermMapping) {
	std::unordered_map<Term, std::string> termMap;

	// Create some integer constants
	Term int32_5 = intConst(intTy(32), 5);
	Term int32_10 = intConst(intTy(32), 10);
	Term int64_5 = intConst(intTy(64), 5); // Same value, different type

	termMap[int32_5] = "32-bit 5";
	termMap[int32_10] = "32-bit 10";
	termMap[int64_5] = "64-bit 5";

	BOOST_CHECK_EQUAL(termMap[int32_5], "32-bit 5");
	BOOST_CHECK_EQUAL(termMap[int32_10], "32-bit 10");
	BOOST_CHECK_EQUAL(termMap[int64_5], "64-bit 5");
}

BOOST_AUTO_TEST_CASE(FloatTermMapping) {
	std::unordered_map<Term, int> termMap;

	Term float1 = floatConst(floatTy(), "1.0");
	Term float2 = floatConst(floatTy(), "2.0");
	Term double1 = floatConst(doubleTy(), "1.0"); // Same value, different type

	termMap[float1] = 1;
	termMap[float2] = 2;
	termMap[double1] = 3;

	BOOST_CHECK_EQUAL(termMap[float1], 1);
	BOOST_CHECK_EQUAL(termMap[float2], 2);
	BOOST_CHECK_EQUAL(termMap[double1], 3);
}

BOOST_AUTO_TEST_CASE(VariableTermMapping) {
	std::unordered_map<Term, std::string> termMap;

	// Create some variables
	Term var1 = var(intTy(32), 1);
	Term var2 = var(intTy(32), 2);
	Term var1_float = var(floatTy(), 1); // Same index, different type

	termMap[var1] = "int var 1";
	termMap[var2] = "int var 2";
	termMap[var1_float] = "float var 1";

	BOOST_CHECK_EQUAL(termMap[var1], "int var 1");
	BOOST_CHECK_EQUAL(termMap[var2], "int var 2");
	BOOST_CHECK_EQUAL(termMap[var1_float], "float var 1");
}

BOOST_AUTO_TEST_CASE(CompoundTermMapping) {
	std::unordered_map<Term, std::string> termMap;

	// Create some arithmetic terms
	Term a = var(intTy(32), 1);
	Term b = var(intTy(32), 2);

	Term add = Term(Add, a, b);
	Term mul = Term(Mul, a, b);
	Term add_same = Term(Add, a, b); // Same as first add

	termMap[add] = "a + b";
	termMap[mul] = "a * b";

	BOOST_CHECK_EQUAL(termMap[add], "a + b");
	BOOST_CHECK_EQUAL(termMap[mul], "a * b");
	BOOST_CHECK_EQUAL(termMap[add_same], "a + b"); // Should map to same value
}

BOOST_AUTO_TEST_CASE(ComparisonTermMapping) {
	std::unordered_map<Term, std::string> termMap;

	Term a = var(intTy(32), 1);
	Term b = var(intTy(32), 2);

	Term eq = cmp(Eq, a, b);
	Term lt = cmp(SLt, a, b);
	Term eq_same = cmp(Eq, a, b); // Same as first eq

	termMap[eq] = "a == b";
	termMap[lt] = "a < b";

	BOOST_CHECK_EQUAL(termMap[eq], "a == b");
	BOOST_CHECK_EQUAL(termMap[lt], "a < b");
	BOOST_CHECK_EQUAL(termMap[eq_same], "a == b");
}

BOOST_AUTO_TEST_CASE(TermMapOperations) {
	std::unordered_map<Term, int> termMap;

	Term var1 = var(intTy(32), 1);

	// Test insert and lookup
	termMap[var1] = 1;
	BOOST_CHECK_EQUAL(termMap[var1], 1);

	// Test overwrite
	termMap[var1] = 2;
	BOOST_CHECK_EQUAL(termMap[var1], 2);

	// Test erase
	size_t eraseCount = termMap.erase(var1);
	BOOST_CHECK_EQUAL(eraseCount, 1);
	BOOST_CHECK_EQUAL(termMap.count(var1), 0);
}
