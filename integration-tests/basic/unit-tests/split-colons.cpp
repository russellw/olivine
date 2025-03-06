#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_CASE(test_empty_input) {
    vector<string> input = {};
    vector<string> expected = {};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_empty_line) {
    vector<string> input = {""};
    vector<string> expected = {""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_line_without_colons) {
    vector<string> input = {"PRINT \"Hello, World!\""};
    vector<string> expected = {"PRINT \"Hello, World!\""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_multiple_lines_without_colons) {
    vector<string> input = {"PRINT \"Hello\"", "PRINT \"World\""};
    vector<string> expected = {"PRINT \"Hello\"", "PRINT \"World\""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_simple_colon_split) {
    vector<string> input = {"PRINT \"Hello\":PRINT \"World\""};
    vector<string> expected = {"PRINT \"Hello\"", "PRINT \"World\""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_multiple_colon_splits) {
    vector<string> input = {"PRINT \"A\":PRINT \"B\":PRINT \"C\""};
    vector<string> expected = {"PRINT \"A\"", "PRINT \"B\"", "PRINT \"C\""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_colons_in_quotes) {
    vector<string> input = {"PRINT \"Hello: World\":PRINT \"Goodbye\""};
    vector<string> expected = {"PRINT \"Hello: World\"", "PRINT \"Goodbye\""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_colons_in_single_quote_comments) {
    vector<string> input = {"PRINT \"Hello\"' Comment: with colon"};
    vector<string> expected = {"PRINT \"Hello\"' Comment: with colon"};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_colons_in_rem_comments) {
    vector<string> input = {"PRINT \"Hello\" REM Comment: with colon"};
    vector<string> expected = {"PRINT \"Hello\" REM Comment: with colon"};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_colon_before_comment) {
    vector<string> input = {"PRINT \"Hello\":' Comment after colon"};
    vector<string> expected = {"PRINT \"Hello\"", "' Comment after colon"};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_colon_after_comment) {
    vector<string> input = {"' Comment:PRINT \"Hello\""};
    vector<string> expected = {"' Comment:PRINT \"Hello\""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_complex_mixed_case) {
    vector<string> input = {
        "PRINT \"Start\"",
        "PRINT \"A\":PRINT \"B: with colon\":PRINT \"C\"",
        "X = 10:Y = 20:Z = X + Y ' Comment: with colon",
        "PRINT \"End\": REM Finish program: now"
    };
    vector<string> expected = {
        "PRINT \"Start\"",
        "PRINT \"A\"", "PRINT \"B: with colon\"", "PRINT \"C\"",
        "X = 10", "Y = 20", "Z = X + Y ' Comment: with colon",
        "PRINT \"End\"", " REM Finish program: now"
    };
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_quoted_rem) {
    vector<string> input = {"PRINT \"REM not a comment\":PRINT \"after\""};
    vector<string> expected = {"PRINT \"REM not a comment\"", "PRINT \"after\""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_nested_quotes) {
    // BASIC typically doesn't support nested quotes, but the function should handle
    // alternating quote marks correctly
    vector<string> input = {"PRINT \"outer \"\"inner\"\" outer\":PRINT \"next\""};
    vector<string> expected = {"PRINT \"outer \"\"inner\"\" outer\"", "PRINT \"next\""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_leading_colons) {
    vector<string> input = {":PRINT \"After leading colon\""};
    vector<string> expected = {"", "PRINT \"After leading colon\""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_trailing_colons) {
    vector<string> input = {"PRINT \"Before trailing colon\":"};
    vector<string> expected = {"PRINT \"Before trailing colon\"", ""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_consecutive_colons) {
    vector<string> input = {"PRINT \"A\"::PRINT \"C\""};
    vector<string> expected = {"PRINT \"A\"", "", "PRINT \"C\""};
    BOOST_CHECK_EQUAL_COLLECTIONS(splitColons(input).begin(), splitColons(input).end(),
                                 expected.begin(), expected.end());
}