/* comdat_example.c
 * Creates explicit COMDAT sections using section attributes
 * Compile with: clang -c comdat_example.c
 */

/* Create a variable in a named section with COMDAT group */
__attribute__((section(".gnu.linkonce.r.my_data"))) const int my_data = 42;

/* Another variable in a COMDAT section */
__attribute__((section(".gnu.linkonce.d.another_var"))) int another_var = 100;

/* Function in a COMDAT section */
__attribute__((section(".gnu.linkonce.t.my_function"))) int my_function(int x) {
	return x * x + my_data;
}

/* Create a table in a COMDAT section */
__attribute__((section(".gnu.linkonce.d.my_table"))) const int lookup_table[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

/* Main function to use our COMDAT symbols */
int main(void) {
	int result = 0;

	result += my_function(5);
	result += another_var;

	for (int i = 0; i < 10; i++) {
		result += lookup_table[i];
	}

	// 222
	return result;
}
