// argv: $u64
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>

uint64_t mul(uint64_t n) {
	return n * 1024;
}

int main(int argc, char** argv) {
	if (argc != 2) {
		fprintf(stderr, "Usage: square n\n");
		return 1;
	}
	errno = 0;
	uint64_t n = strtoull(argv[1], 0, 10);
	if (errno) {
		perror(argv[1]);
		return 1;
	}
	printf("%" PRIu64 "\n", mul(n));
	return 0;
}
