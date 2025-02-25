BOOST_AUTO_TEST_CASE(test_basic_parsing) {
	std::string input = "1A2B3C";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0x1A2B3C);
	BOOST_CHECK_EQUAL(pos, 6);
}

BOOST_AUTO_TEST_CASE(test_lowercase_hex) {
	std::string input = "deadbeef";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0xdeadbeef);
	BOOST_CHECK_EQUAL(pos, 8);
}

BOOST_AUTO_TEST_CASE(test_mixed_case) {
	std::string input = "AbCdEf";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0xABCDEF);
	BOOST_CHECK_EQUAL(pos, 6);
}

BOOST_AUTO_TEST_CASE(test_max_length_limit) {
	std::string input = "123456789";
	size_t pos = 0;
	unsigned result = parseHex(input, pos, 4);
	BOOST_CHECK_EQUAL(result, 0x1234);
	BOOST_CHECK_EQUAL(pos, 4);
}

BOOST_AUTO_TEST_CASE(test_partial_string) {
	std::string input = "12XY34";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0x12);
	BOOST_CHECK_EQUAL(pos, 2);
}

BOOST_AUTO_TEST_CASE(test_starting_position) {
	std::string input = "XX12AB";
	size_t pos = 2;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0x12AB);
	BOOST_CHECK_EQUAL(pos, 6);
}

BOOST_AUTO_TEST_CASE(test_empty_string) {
	std::string input = "";
	size_t pos = 0;
	BOOST_CHECK_THROW(parseHex(input, pos), std::runtime_error);
	BOOST_CHECK_EQUAL(pos, 0);
}

BOOST_AUTO_TEST_CASE(test_no_hex_digits) {
	std::string input = "XYZ";
	size_t pos = 0;
	BOOST_CHECK_THROW(parseHex(input, pos), std::runtime_error);
	BOOST_CHECK_EQUAL(pos, 0);
}

BOOST_AUTO_TEST_CASE(test_position_beyond_string) {
	std::string input = "123";
	size_t pos = 5;
	BOOST_CHECK_THROW(parseHex(input, pos), std::runtime_error);
	BOOST_CHECK_EQUAL(pos, 5);
}

BOOST_AUTO_TEST_CASE(test_zero) {
	std::string input = "0";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0x0);
	BOOST_CHECK_EQUAL(pos, 1);
}

BOOST_AUTO_TEST_CASE(test_max_value) {
	std::string input = "FFFFFFFF";
	size_t pos = 0;
	unsigned result = parseHex(input, pos);
	BOOST_CHECK_EQUAL(result, 0xFFFFFFFF);
	BOOST_CHECK_EQUAL(pos, 8);
}
