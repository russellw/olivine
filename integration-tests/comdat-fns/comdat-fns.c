/* comdat_example.c
 * Demonstrates creating COMDAT sections in C
 * Compile with: clang -O2 -c comdat_example.c
 */

/* Using __attribute__((weak)) creates COMDAT sections */
__attribute__((weak)) int weak_function(int x) {
	return x * x;
}

/* Using __attribute__((used)) ensures the symbol isn't eliminated
 * Note: We can't combine static with weak, so we make it global */
__attribute__((used, weak)) int another_weak_function(int x) {
	return x + 1;
}

/* Create a function-local static with an initializer
 * This generates a COMDAT section for the initializer */
int function_with_static(int input) {
	static const int lookup_table[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

	if (input >= 0 && input < 10) {
		return lookup_table[input];
	}
	return -1;
}

/* Functions marked as inline can generate COMDATs */
__attribute__((always_inline)) inline int inline_function(int x, int y) {
	return x + y;
}

/* Main function to call our other functions */
int main(void) {
	int result = 0;

	result += weak_function(5);
	result += another_weak_function(10);
	result += function_with_static(3);
	result += inline_function(7, 8);

	// 55
	return result;
}
