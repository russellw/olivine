#include <inttypes.h>
#include <stdio.h>

uint64_t fib(uint64_t n) {
	if (n <= 1) return n;
	return fib(n - 2) + fib(n - 1);
}

int main(int argc, char** argv) {
	printf("%" PRIu64 "\n", fib(10));
	return 0;
}
