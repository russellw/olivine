#include "all.h"

cpp_int truncate_to_bits(const cpp_int& value, std::size_t bits) {
	if (bits <= 0) {
		throw std::invalid_argument("Number of bits must be positive");
	}

	// Handle zero separately since msb() would throw
	if (value == 0) {
		return 0;
	}

	// Handle small values that don't need truncation
	if (msb(value) < bits) {
		return value;
	}

	// Create a mask with the desired number of 1s
	cpp_int mask = (cpp_int(1) << bits) - 1;

	// Apply the mask to get only the desired bits
	return value & mask;
}
