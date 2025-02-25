BOOST_AUTO_TEST_SUITE(ParseRefTests)

// Test basic numeric references
BOOST_AUTO_TEST_CASE(BasicNumericRefs) {
	// Test simple numeric references
	auto ref1 = parseRef("%0");
	BOOST_CHECK(std::holds_alternative<size_t>(ref1));
	BOOST_CHECK_EQUAL(std::get<size_t>(ref1), 0);

	auto ref2 = parseRef("%42");
	BOOST_CHECK(std::holds_alternative<size_t>(ref2));
	BOOST_CHECK_EQUAL(std::get<size_t>(ref2), 42);
}

// Test string references
BOOST_AUTO_TEST_CASE(StringRefs) {
	// Test basic string reference
	auto ref1 = parseRef("%foo");
	BOOST_CHECK(std::holds_alternative<std::string>(ref1));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref1), "foo");

	// Test string reference with underscore
	auto ref2 = parseRef("%my_var");
	BOOST_CHECK(std::holds_alternative<std::string>(ref2));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref2), "my_var");
}

// Test quoted references
BOOST_AUTO_TEST_CASE(QuotedRefs) {
	// Test quoted string that looks like a number
	auto ref1 = parseRef("%\"42\"");
	BOOST_CHECK(std::holds_alternative<std::string>(ref1));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref1), "42");

	// Test quoted string with spaces
	auto ref2 = parseRef("%\"hello world\"");
	BOOST_CHECK(std::holds_alternative<std::string>(ref2));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref2), "hello world");
}

// Test escaped sequences in quoted strings
BOOST_AUTO_TEST_CASE(EscapedRefs) {
	// Test string with hex escape
	auto ref2 = parseRef("%\"hello\\20world\"");
	BOOST_CHECK(std::holds_alternative<std::string>(ref2));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref2), "hello world");
}

// Test error cases
BOOST_AUTO_TEST_CASE(ErrorCases) {
	// Empty string
	BOOST_CHECK_THROW(parseRef(""), std::runtime_error);

	// Just sigil
	BOOST_CHECK_THROW(parseRef("%"), std::runtime_error);

	// Invalid number format
	BOOST_CHECK_THROW(parseRef("%42a"), std::runtime_error);

	// Unclosed quote
	BOOST_CHECK_THROW(parseRef("%\"unclosed"), std::runtime_error);
}

// Test edge cases
BOOST_AUTO_TEST_CASE(EdgeCases) {
	// Test maximum numeric value
	auto ref1 = parseRef("%18446744073709551615"); // max size_t
	BOOST_CHECK(std::holds_alternative<size_t>(ref1));
	BOOST_CHECK_EQUAL(std::get<size_t>(ref1), 18446744073709551615ULL);

	// Test empty quoted string
	auto ref2 = parseRef("%\"\"");
	BOOST_CHECK(std::holds_alternative<std::string>(ref2));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref2), "");

	// Test string with just spaces
	auto ref3 = parseRef("%\"   \"");
	BOOST_CHECK(std::holds_alternative<std::string>(ref3));
	BOOST_CHECK_EQUAL(std::get<std::string>(ref3), "   ");
}

BOOST_AUTO_TEST_SUITE_END()
