#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>

static uint64_t f(uint64_t n) {
	if (n % 2 == 0) return n / 2;
	uint64_t n1 = n * 3 + 1;
	if (n1 < n) {
		fprintf(stderr, "overflow\n");
		exit(1);
	}
	return n1;
}

static uint64_t steps(uint64_t n) {
	uint64_t i = 0;
	while (n != 1) {
		n = f(n);
		++i;
	}
	return i;
}

int main(int argc, char** argv) {
	uint64_t limit = 1000;
	uint64_t maxn = 0;
	uint64_t maxsteps = 0;
	for (uint64_t n = 1; n < limit; ++n) {
		uint64_t i = steps(n);
		if (i > maxsteps) {
			maxn = n;
			maxsteps = i;
		}
	}
	printf("%" PRIu64 "\t%" PRIu64 "\n", maxn, maxsteps);
	return 0;
}
