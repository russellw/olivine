// argv: $u64 $u64
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>

static uint64_t tou64(const char* s) {
	errno = 0;
	uint64_t n = strtoull(s, 0, 10);
	if (errno) {
		perror(s);
		exit(1);
	}
	return n;
}

int main(int argc, char** argv) {
	if (argc != 3) {
		fprintf(stderr, "Usage: ops a b\n");
		return 1;
	}
	uint64_t a = tou64(argv[1]);
	uint64_t b = tou64(argv[2]);

	printf("++\t%" PRIu64 "\n", a++);
	printf("--\t%" PRIu64 "\n", a--);

	printf("++\t%" PRIu64 "\n", ++a);
	printf("--\t%" PRIu64 "\n", --a);
	printf("unary+\t%" PRIu64 "\n", +a);
	printf("unary-\t%" PRIu64 "\n", -a);
	printf("!\t%d\n", !a);
	printf("~\t%" PRIu64 "\n", ~a);
	printf("(u32)\t%u\n", (unsigned)a);
	printf("sizeof\t%zu\n", sizeof a);

	printf("*\t%" PRIu64 "\n", a * b);
	if (b) {
		printf("/\t%" PRIu64 "\n", a / b);
		printf("%%\t%" PRIu64 "\n", a % b);
	}

	printf("+\t%" PRIu64 "\n", a + b);
	printf("-\t%" PRIu64 "\n", a - b);

	printf("<<\t%" PRIu64 "\n", a << b % 64);
	printf(">>\t%" PRIu64 "\n", a >> b % 64);

	printf("<\t%d\n", a < b);
	printf("<=\t%d\n", a <= b);
	printf(">\t%d\n", a > b);
	printf(">=\t%d\n", a >= b);

	printf("==\t%d\n", a == b);
	printf("!=\t%d\n", a != b);

	printf("&\t%" PRIu64 "\n", a & b);

	printf("^\t%" PRIu64 "\n", a ^ b);

	printf("|\t%" PRIu64 "\n", a | b);

	printf("&&\t%d\n", a && b);

	printf("||\t%d\n", a || b);

	printf("?:\t%" PRIu64 "\n", a ? a : b);

	printf("+=\t%" PRIu64 "\n", a += b);
	printf("-=\t%" PRIu64 "\n", a -= b);
	printf("*=\t%" PRIu64 "\n", a *= b);
	if (b) {
		printf("/=\t%" PRIu64 "\n", a /= b);
		printf("%%=\t%" PRIu64 "\n", a %= b);
	}
	printf("<<=\t%" PRIu64 "\n", a <<= b % 64);
	printf(">>=\t%" PRIu64 "\n", a >>= b % 64);
	printf("&=\t%" PRIu64 "\n", a &= b);
	printf("^=\t%" PRIu64 "\n", a ^= b);
	printf("|=\t%" PRIu64 "\n", a |= b);

	printf(",\t%" PRIu64 "\n", (a++, b));

	return 0;
}
