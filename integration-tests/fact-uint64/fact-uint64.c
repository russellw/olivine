#include <stdint.h>

uint64_t fact(uint64_t n) {
	if (n <= 1) {
		return n;
	}
	return n * fact(n - 1);
}

int main() {
	return fact(20) / fact(19);
}
