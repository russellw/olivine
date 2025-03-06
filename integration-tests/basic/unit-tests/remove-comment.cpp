#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(RemoveCommentTests)

// Test no comments
BOOST_AUTO_TEST_CASE(NoComment) {
    BOOST_CHECK_EQUAL(removeComment("PRINT \"Hello World\""), "PRINT \"Hello World\"");
    BOOST_CHECK_EQUAL(removeComment("x = 5 + 3"), "x = 5 + 3");
    BOOST_CHECK_EQUAL(removeComment(""), "");
}

// Test REM comments
BOOST_AUTO_TEST_CASE(BasicREMComment) {
    BOOST_CHECK_EQUAL(removeComment("PRINT \"Hello\" REM This is a comment"), "PRINT \"Hello\" ");
    BOOST_CHECK_EQUAL(removeComment("REM This entire line is a comment"), "");
    BOOST_CHECK_EQUAL(removeComment("   REM Comment with leading spaces"), "   ");
}

// Test apostrophe comments
BOOST_AUTO_TEST_CASE(ApostropheComment) {
    BOOST_CHECK_EQUAL(removeComment("PRINT \"Hello\" ' This is a comment"), "PRINT \"Hello\" ");
    BOOST_CHECK_EQUAL(removeComment("' This entire line is a comment"), "");
    BOOST_CHECK_EQUAL(removeComment("   ' Comment with leading spaces"), "   ");
}

// Test REM as part of a word
BOOST_AUTO_TEST_CASE(REMAsPartOfWord) {
    BOOST_CHECK_EQUAL(removeComment("SUPREME COMMANDER"), "SUPREME COMMANDER");
    BOOST_CHECK_EQUAL(removeComment("REMINDER tomorrow"), "REMINDER tomorrow");
    BOOST_CHECK_EQUAL(removeComment("PRINTER = 5 REM comment"), "PRINTER = 5 ");
}

// Test REM in quoted strings
BOOST_AUTO_TEST_CASE(REMInQuotedString) {
    BOOST_CHECK_EQUAL(removeComment("PRINT \"This is not a REM comment\""), "PRINT \"This is not a REM comment\"");
    BOOST_CHECK_EQUAL(removeComment("MSG$ = \"REM\" REM But this is"), "MSG$ = \"REM\" ");
    BOOST_CHECK_EQUAL(removeComment("PRINT \"REM inside\" + \" quotes\" REM outside"), "PRINT \"REM inside\" + \" quotes\" ");
}

// Test apostrophe in quoted strings
BOOST_AUTO_TEST_CASE(ApostropheInQuotedString) {
    BOOST_CHECK_EQUAL(removeComment("PRINT \"This isn't a comment\""), "PRINT \"This isn't a comment\"");
    BOOST_CHECK_EQUAL(removeComment("MSG$ = \"'\" ' But this is"), "MSG$ = \"'\" ");
    BOOST_CHECK_EQUAL(removeComment("PRINT \"'inside'\" + \" quotes\" ' outside"), "PRINT \"'inside'\" + \" quotes\" ");
}

// Test escaped quotes
BOOST_AUTO_TEST_CASE(EscapedQuotes) {
    BOOST_CHECK_EQUAL(removeComment("PRINT \"He said, \"\"Hello\"\"\" REM comment"), "PRINT \"He said, \"\"Hello\"\"\" ");
    BOOST_CHECK_EQUAL(removeComment("PRINT \"Quote \"\" inside\" REM This should be removed"), "PRINT \"Quote \"\" inside\" ");
}

// Test mixed scenarios
BOOST_AUTO_TEST_CASE(MixedScenarios) {
    BOOST_CHECK_EQUAL(removeComment("IF x = 5 THEN PRINT \"REM\" ELSE REM comment"), "IF x = 5 THEN PRINT \"REM\" ELSE ");
    BOOST_CHECK_EQUAL(removeComment("PRINT \"Text with ' apostrophe\" ' Comment"), "PRINT \"Text with ' apostrophe\" ");
    BOOST_CHECK_EQUAL(removeComment("REM$ = \"This variable name looks like a comment but isn't\""), 
                      "REM$ = \"This variable name looks like a comment but isn't\"");
}

// Test edge cases
BOOST_AUTO_TEST_CASE(EdgeCases) {
    // REM at the end of the line
    BOOST_CHECK_EQUAL(removeComment("PRINT REM"), "PRINT ");
    
    // Multiple REM (only first one counts)
    BOOST_CHECK_EQUAL(removeComment("REM This is a comment REM this isn't a second comment"), "");
    
    // Comment after an unclosed string (the function should handle this gracefully)
    BOOST_CHECK_EQUAL(removeComment("PRINT \"Unclosed string REM not a comment"), 
                      "PRINT \"Unclosed string REM not a comment");
    
    // REM with no trailing space
    BOOST_CHECK_EQUAL(removeComment("PRINT x REM"), "PRINT x ");
}

BOOST_AUTO_TEST_SUITE_END()