#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_CASE(test_empty_vector) {
    std::vector<int> input;
    auto duplicateFunc = [](int x) -> std::vector<int> { return {x, x}; };
    
    std::vector<int> result = mapMulti(input, duplicateFunc);
    
    BOOST_CHECK(result.empty());
}

BOOST_AUTO_TEST_CASE(test_duplicate_elements) {
    std::vector<int> input = {1, 2, 3};
    auto duplicateFunc = [](int x) -> std::vector<int> { return {x, x}; };
    
    std::vector<int> result = mapMulti(input, duplicateFunc);
    std::vector<int> expected = {1, 1, 2, 2, 3, 3};
    
    BOOST_CHECK_EQUAL_COLLECTIONS(result.begin(), result.end(), expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_function_returning_empty_vector) {
    std::vector<int> input = {1, 2, 3};
    auto emptyFunc = [](int) -> std::vector<int> { return {}; };
    
    std::vector<int> result = mapMulti(input, emptyFunc);
    
    BOOST_CHECK(result.empty());
}

BOOST_AUTO_TEST_CASE(test_variable_sized_results) {
    std::vector<int> input = {1, 2, 3, 4};
    auto varSizeFunc = [](int x) -> std::vector<int> { 
        std::vector<int> result;
        for (int i = 0; i < x; ++i) {
            result.push_back(x);
        }
        return result;
    };
    
    std::vector<int> result = mapMulti(input, varSizeFunc);
    std::vector<int> expected = {1, 2, 2, 3, 3, 3, 4, 4, 4, 4};
    
    BOOST_CHECK_EQUAL_COLLECTIONS(result.begin(), result.end(), expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_string_type) {
    std::vector<std::string> input = {"a", "bc", "def"};
    auto repeatFunc = [](const std::string& s) -> std::vector<std::string> { 
        return {s, s + s}; 
    };
    
    std::vector<std::string> result = mapMulti(input, repeatFunc);
    std::vector<std::string> expected = {"a", "aa", "bc", "bcbc", "def", "defdef"};
    
    BOOST_CHECK_EQUAL_COLLECTIONS(result.begin(), result.end(), expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_filter_effect) {
    std::vector<int> input = {1, 2, 3, 4, 5, 6};
    auto filterEvenFunc = [](int x) -> std::vector<int> { 
        if (x % 2 == 0) {
            return {x};
        }
        return {};
    };
    
    std::vector<int> result = mapMulti(input, filterEvenFunc);
    std::vector<int> expected = {2, 4, 6};
    
    BOOST_CHECK_EQUAL_COLLECTIONS(result.begin(), result.end(), expected.begin(), expected.end());
}

BOOST_AUTO_TEST_CASE(test_expand_effect) {
    std::vector<int> input = {1, 2, 3};
    auto expandFunc = [](int x) -> std::vector<int> { 
        if (x == 2) {
            return {x - 1, x, x + 1}; 
        }
        return {x};
    };
    
    std::vector<int> result = mapMulti(input, expandFunc);
    std::vector<int> expected = {1, 1, 2, 3, 3};
    
    BOOST_CHECK_EQUAL_COLLECTIONS(result.begin(), result.end(), expected.begin(), expected.end());
}

// Test the composition of mapMulti with other transformations
BOOST_AUTO_TEST_CASE(test_composition_with_map) {
    std::vector<int> input = {1, 2, 3};
    
    // First map each element to its square
    auto squareFunc = [](int x) { return x * x; };
    std::vector<int> squares = map(input, squareFunc);
    
    // Then use mapMulti on the result
    auto duplicateFunc = [](int x) -> std::vector<int> { return {x, x}; };
    std::vector<int> result = mapMulti(squares, duplicateFunc);
    
    std::vector<int> expected = {1, 1, 4, 4, 9, 9};
    
    BOOST_CHECK_EQUAL_COLLECTIONS(result.begin(), result.end(), expected.begin(), expected.end());
}
