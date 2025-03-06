#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(StringLiteralsTests)

// Test simple case with a single string literal
BOOST_AUTO_TEST_CASE(SingleStringLiteral) {
    vector<Line> input = {Line("10", "PRINT \"FOO\"")};
    vector<Line> output = extractStringLiterals(input);
    
    BOOST_REQUIRE_EQUAL(output.size(), 2);
    BOOST_CHECK_EQUAL(output[0].label, "");
    BOOST_CHECK_EQUAL(output[0].text, "LET STRING_LITERAL_0$ = \"FOO\"");
    BOOST_CHECK_EQUAL(output[1].label, "10");
    BOOST_CHECK_EQUAL(output[1].text, "PRINT STRING_LITERAL_0$");
}

// Test with multiple string literals in one line
BOOST_AUTO_TEST_CASE(MultipleStringLiterals) {
    vector<Line> input = {Line("10", "PRINT \"FOO\"+\"BAR\"")};
    vector<Line> output = extractStringLiterals(input);
    
    BOOST_REQUIRE_EQUAL(output.size(), 3);
    BOOST_CHECK_EQUAL(output[0].label, "");
    BOOST_CHECK_EQUAL(output[0].text, "LET STRING_LITERAL_0$ = \"FOO\"");
    BOOST_CHECK_EQUAL(output[1].label, "");
    BOOST_CHECK_EQUAL(output[1].text, "LET STRING_LITERAL_1$ = \"BAR\"");
    BOOST_CHECK_EQUAL(output[2].label, "10");
    BOOST_CHECK_EQUAL(output[2].text, "PRINT STRING_LITERAL_0$+STRING_LITERAL_1$");
}

// Test with string literals across multiple lines
BOOST_AUTO_TEST_CASE(MultipleLinesWithStrings) {
    vector<Line> input = {
        Line("10", "PRINT \"FOO\""),
        Line("20", "PRINT \"BAR\"")
    };
    vector<Line> output = extractStringLiterals(input);
    
    BOOST_REQUIRE_EQUAL(output.size(), 4);
    BOOST_CHECK_EQUAL(output[0].label, "");
    BOOST_CHECK_EQUAL(output[0].text, "LET STRING_LITERAL_0$ = \"FOO\"");
    BOOST_CHECK_EQUAL(output[1].label, "");
    BOOST_CHECK_EQUAL(output[1].text, "LET STRING_LITERAL_1$ = \"BAR\"");
    BOOST_CHECK_EQUAL(output[2].label, "10");
    BOOST_CHECK_EQUAL(output[2].text, "PRINT STRING_LITERAL_0$");
    BOOST_CHECK_EQUAL(output[3].label, "20");
    BOOST_CHECK_EQUAL(output[3].text, "PRINT STRING_LITERAL_1$");
}

// Test with no string literals
BOOST_AUTO_TEST_CASE(NoStringLiterals) {
    vector<Line> input = {Line("10", "PRINT X + Y")};
    vector<Line> output = extractStringLiterals(input);
    
    BOOST_REQUIRE_EQUAL(output.size(), 1);
    BOOST_CHECK_EQUAL(output[0].label, "10");
    BOOST_CHECK_EQUAL(output[0].text, "PRINT X + Y");
}

// Test with empty lines
BOOST_AUTO_TEST_CASE(EmptyLines) {
    vector<Line> input = {Line("", "")};
    vector<Line> output = extractStringLiterals(input);
    
    BOOST_REQUIRE_EQUAL(output.size(), 1);
    BOOST_CHECK_EQUAL(output[0].label, "");
    BOOST_CHECK_EQUAL(output[0].text, "");
}

// Test with complex string content including quotes and special characters
BOOST_AUTO_TEST_CASE(ComplexStringContent) {
    vector<Line> input = {Line("30", "PRINT \"String with spaces and \"\"quotes\"\" inside\"")};
    vector<Line> output = extractStringLiterals(input);
    
    BOOST_REQUIRE_EQUAL(output.size(), 2);
    BOOST_CHECK_EQUAL(output[0].label, "");
    BOOST_CHECK_EQUAL(output[0].text, "LET STRING_LITERAL_0$ = \"String with spaces and \"\"quotes\"\" inside\"");
    BOOST_CHECK_EQUAL(output[1].label, "30");
    BOOST_CHECK_EQUAL(output[1].text, "PRINT STRING_LITERAL_0$");
}

// Test with multiple occurrences of the same string literal
BOOST_AUTO_TEST_CASE(DuplicateStringLiterals) {
    vector<Line> input = {Line("40", "PRINT \"HELLO\"+\"WORLD\"+\"HELLO\"")};
    vector<Line> output = extractStringLiterals(input);
    
    BOOST_REQUIRE_EQUAL(output.size(), 4);
    BOOST_CHECK_EQUAL(output[0].label, "");
    BOOST_CHECK_EQUAL(output[0].text, "LET STRING_LITERAL_0$ = \"HELLO\"");
    BOOST_CHECK_EQUAL(output[1].label, "");
    BOOST_CHECK_EQUAL(output[1].text, "LET STRING_LITERAL_1$ = \"WORLD\"");
    BOOST_CHECK_EQUAL(output[2].label, "");
    BOOST_CHECK_EQUAL(output[2].text, "LET STRING_LITERAL_2$ = \"HELLO\"");
    BOOST_CHECK_EQUAL(output[3].label, "40");
    BOOST_CHECK_EQUAL(output[3].text, "PRINT STRING_LITERAL_0$+STRING_LITERAL_1$+STRING_LITERAL_2$");
}

// Edge case: String at the beginning and end of line
BOOST_AUTO_TEST_CASE(StringsAtLineEdges) {
    vector<Line> input = {Line("50", "\"START\" + X + \"END\"")};
    vector<Line> output = extractStringLiterals(input);
    
    BOOST_REQUIRE_EQUAL(output.size(), 3);
    BOOST_CHECK_EQUAL(output[0].label, "");
    BOOST_CHECK_EQUAL(output[0].text, "LET STRING_LITERAL_0$ = \"START\"");
    BOOST_CHECK_EQUAL(output[1].label, "");
    BOOST_CHECK_EQUAL(output[1].text, "LET STRING_LITERAL_1$ = \"END\"");
    BOOST_CHECK_EQUAL(output[2].label, "50");
    BOOST_CHECK_EQUAL(output[2].text, "STRING_LITERAL_0$ + X + STRING_LITERAL_1$");
}

BOOST_AUTO_TEST_SUITE_END()