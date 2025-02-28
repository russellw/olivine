#include "all.h"
#include <boost/test/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(ArrayBytesTests)

// Test with empty array
BOOST_AUTO_TEST_CASE(EmptyArray) {
	unsigned char empty[] = {};
	Term result = arrayBytes(empty, 0);

	// Verify the result is an Array type
	BOOST_CHECK_EQUAL(result.tag(), Array);

	// Verify array type is intTy(8)
	BOOST_CHECK_EQUAL(result.ty().kind(), ArrayKind);
	BOOST_CHECK_EQUAL(result.ty().len(), 0);
	BOOST_CHECK_EQUAL(result.ty()[0].kind(), IntKind);
	BOOST_CHECK_EQUAL(result.ty()[0].len(), 8);

	// Verify it has zero elements
	BOOST_CHECK_EQUAL(result.size(), 0);
}

// Test with single byte
BOOST_AUTO_TEST_CASE(SingleByte) {
	unsigned char bytes[] = {42};
	Term result = arrayBytes(bytes, 1);

	// Verify the result is an Array type
	BOOST_CHECK_EQUAL(result.tag(), Array);

	// Verify array type is intTy(8)
	BOOST_CHECK_EQUAL(result.ty().kind(), ArrayKind);
	BOOST_CHECK_EQUAL(result.ty().len(), 1);
	BOOST_CHECK_EQUAL(result.ty()[0].kind(), IntKind);
	BOOST_CHECK_EQUAL(result.ty()[0].len(), 8);

	// Verify it has one element
	BOOST_CHECK_EQUAL(result.size(), 1);

	// Verify element value
	BOOST_CHECK_EQUAL(result[0].tag(), Int);
	BOOST_CHECK_EQUAL(result[0].ty().kind(), IntKind);
	BOOST_CHECK_EQUAL(result[0].ty().len(), 8);
	BOOST_CHECK_EQUAL(result[0].intVal(), 42);
}

// Test with multiple bytes
BOOST_AUTO_TEST_CASE(MultipleBytes) {
	unsigned char bytes[] = {0, 127, 255};
	Term result = arrayBytes(bytes, 3);

	// Verify the result is an Array type
	BOOST_CHECK_EQUAL(result.tag(), Array);

	// Verify array type is intTy(8)
	BOOST_CHECK_EQUAL(result.ty().kind(), ArrayKind);
	BOOST_CHECK_EQUAL(result.ty().len(), 3);
	BOOST_CHECK_EQUAL(result.ty()[0].kind(), IntKind);
	BOOST_CHECK_EQUAL(result.ty()[0].len(), 8);

	// Verify it has three elements
	BOOST_CHECK_EQUAL(result.size(), 3);

	// Verify element values
	BOOST_CHECK_EQUAL(result[0].intVal(), 0);
	BOOST_CHECK_EQUAL(result[1].intVal(), 127);
	BOOST_CHECK_EQUAL(result[2].intVal(), 255);
}

// Test with a byte sequence representing ASCII text
BOOST_AUTO_TEST_CASE(AsciiText) {
	const char* text = "Hello";
	unsigned char* bytes = reinterpret_cast<unsigned char*>(const_cast<char*>(text));
	Term result = arrayBytes(bytes, 5);

	// Verify the array has correct length
	BOOST_CHECK_EQUAL(result.size(), 5);

	// Verify element values match ASCII codes
	BOOST_CHECK_EQUAL(result[0].intVal(), 'H');
	BOOST_CHECK_EQUAL(result[1].intVal(), 'e');
	BOOST_CHECK_EQUAL(result[2].intVal(), 'l');
	BOOST_CHECK_EQUAL(result[3].intVal(), 'l');
	BOOST_CHECK_EQUAL(result[4].intVal(), 'o');
}

// Test with larger data
BOOST_AUTO_TEST_CASE(LargerData) {
	// Create a vector with values 0 through 255
	std::vector<unsigned char> largeData(256);
	for (int i = 0; i < 256; i++) {
		largeData[i] = static_cast<unsigned char>(i);
	}

	Term result = arrayBytes(largeData.data(), largeData.size());

	// Verify the array has correct length
	BOOST_CHECK_EQUAL(result.size(), 256);

	// Verify correct element values at selected indices
	BOOST_CHECK_EQUAL(result[0].intVal(), 0);
	BOOST_CHECK_EQUAL(result[10].intVal(), 10);
	BOOST_CHECK_EQUAL(result[100].intVal(), 100);
	BOOST_CHECK_EQUAL(result[255].intVal(), 255);

	// Check all values
	for (int i = 0; i < 256; i++) {
		BOOST_CHECK_EQUAL(result[i].intVal(), i);
	}
}

BOOST_AUTO_TEST_SUITE_END()
