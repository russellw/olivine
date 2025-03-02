/**
 * Truncates a cpp_int to the specified number of bits
 *
 * @param value The cpp_int value to truncate
 * @param bits Number of bits to keep (must be > 0)
 * @return A new cpp_int containing only the specified number of least significant bits
 * @throws std::invalid_argument if bits <= 0
 */
cpp_int truncate_to_bits(const cpp_int& value, std::size_t bits);

/**
 * Common utilities for fixed-width operations
 */
namespace detail {
// Create bit mask for given width
inline cpp_int create_mask(std::size_t bits) {
	return (cpp_int(1) << bits) - 1;
}

// Convert unsigned to signed, assuming value is within bits width
inline cpp_int to_signed(const cpp_int& value, std::size_t bits) {
	cpp_int sign_bit = cpp_int(1) << (bits - 1);
	if ((value & sign_bit) == 0) {
		return value;
	}
	return value - (sign_bit << 1);
}

// Convert signed to unsigned, assuming value fits in bits width
inline cpp_int to_unsigned(const cpp_int& value, std::size_t bits) {
	if (value >= 0) {
		return value;
	}
	return value + (cpp_int(1) << bits);
}

// Validate bit width
inline void validate_bits(std::size_t bits) {
	if (bits <= 0) {
		throw std::invalid_argument("Number of bits must be positive");
	}
}
} // namespace detail

/**
 * Fixed-width arithmetic operations following LLVM semantics.
 * All values are stored as unsigned integers internally.
 */
namespace fixed_width_ops {
// Arithmetic operations
static cpp_int add(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a + b) & detail::create_mask(bits);
}

static cpp_int sub(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a - b) & detail::create_mask(bits);
}

static cpp_int mul(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a * b) & detail::create_mask(bits);
}

static cpp_int udiv(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	if (b == 0) {
		throw std::domain_error("Division by zero");
	}
	return (a / b) & detail::create_mask(bits);
}

static cpp_int sdiv(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	if (b == 0) {
		throw std::domain_error("Division by zero");
	}

	// Convert to signed, perform division, convert back
	cpp_int sa = detail::to_signed(a, bits);
	cpp_int sb = detail::to_signed(b, bits);
	cpp_int result = sa / sb; // Signed division
	return detail::to_unsigned(result, bits);
}

static cpp_int urem(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	if (b == 0) {
		throw std::domain_error("Division by zero");
	}
	return (a % b) & detail::create_mask(bits);
}

static cpp_int srem(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	if (b == 0) {
		throw std::domain_error("Division by zero");
	}

	// Convert to signed, perform remainder, convert back
	cpp_int sa = detail::to_signed(a, bits);
	cpp_int sb = detail::to_signed(b, bits);
	cpp_int result = sa % sb; // Signed remainder
	return detail::to_unsigned(result, bits);
}

// Bitwise operations
static cpp_int and_(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a & b) & detail::create_mask(bits);
}

static cpp_int or_(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a | b) & detail::create_mask(bits);
}

static cpp_int xor_(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return (a ^ b) & detail::create_mask(bits);
}

// Shift operations
static cpp_int shl(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	// Convert shift amount to size_t
	std::size_t shift = static_cast<std::size_t>(b);
	// LLVM treats shifts >= width as producing poison
	if (shift >= bits) {
		return 0;
	}
	return (a << shift) & detail::create_mask(bits);
}

static cpp_int lshr(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	unsigned long shift = b.convert_to<unsigned long>();
	if (shift >= bits) {
		return 0;
	}
	return a >> shift & detail::create_mask(bits);
}

static cpp_int ashr(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	unsigned long shift = b.convert_to<unsigned long>();
	if (shift >= bits) {
		// Arithmetic shift fills with sign bit
		cpp_int sa = detail::to_signed(a, bits);
		return detail::to_unsigned(sa >= 0 ? 0 : -1, bits);
	}

	// Convert to signed, shift, convert back
	cpp_int sa = detail::to_signed(a, bits);
	cpp_int result = sa >> shift; // Arithmetic shift
	return detail::to_unsigned(result, bits);
}

// Comparison operations (return 1 for true, 0 for false)
static cpp_int eq(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return cpp_int(a == b);
}

static cpp_int ne(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return cpp_int(a != b);
}

static cpp_int ult(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return cpp_int(a < b);
}

static cpp_int ule(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	return cpp_int(a <= b);
}

static cpp_int slt(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	cpp_int sa = detail::to_signed(a, bits);
	cpp_int sb = detail::to_signed(b, bits);
	return cpp_int(sa < sb);
}

static cpp_int sle(const cpp_int& a, const cpp_int& b, std::size_t bits) {
	detail::validate_bits(bits);
	cpp_int sa = detail::to_signed(a, bits);
	cpp_int sb = detail::to_signed(b, bits);
	return cpp_int(sa <= sb);
}
}; // namespace fixed_width_ops
