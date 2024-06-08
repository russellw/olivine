// argv: $f $f
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

static double tod(const char* s) {
	errno = 0;
	double a = strtod(s, 0);
	if (errno) {
		perror(s);
		exit(1);
	}
	return a;
}

int main(int argc, char** argv) {
	if (argc != 3) {
		fprintf(stderr, "Usage: fops a b\n");
		return 1;
	}
	double a = tod(argv[1]);
	double b = tod(argv[2]);

	printf("++\t%f\n", a++);
	printf("--\t%f\n", a--);

	printf("++\t%f\n", ++a);
	printf("--\t%f\n", --a);
	printf("unary+\t%f\n", +a);
	printf("unary-\t%f\n", -a);
	printf("!\t%d\n", !a);
	printf("(u32)\t%u\n", (unsigned)a);
	printf("sizeof\t%zu\n", sizeof a);

	printf("*\t%f\n", a * b);
	if (b) {
		printf("/\t%f\n", a / b);
		// this generates a call to the library fmod;  I still know of nothing that
		// generates the instruction frem
		printf("%%\t%f\n", __builtin_fmod(a, b));
	}

	printf("+\t%f\n", a + b);
	printf("-\t%f\n", a - b);

	printf("<\t%d\n", a < b);
	printf("<=\t%d\n", a <= b);
	printf(">\t%d\n", a > b);
	printf(">=\t%d\n", a >= b);

	printf("==\t%d\n", a == b);
	printf("!=\t%d\n", a != b);

	printf("&&\t%d\n", a && b);

	printf("||\t%d\n", a || b);

	printf("?:\t%f\n", a ? a : b);

	printf("+=\t%f\n", a += b);
	printf("-=\t%f\n", a -= b);
	printf("*=\t%f\n", a *= b);
	if (b) { printf("/=\t%f\n", a /= b); }

	printf(",\t%f\n", (a++, b));

	double zero = 0.0;
	double mzero = -zero;
	assert(zero == zero);
	assert(mzero == mzero);
	assert(mzero == zero);
	assert(mzero <= zero);

	double inf = 1.0 / 0.0;
	double minf = -inf;
	assert(inf == inf);
	assert(minf == minf);
	assert(minf != inf);
	assert(minf < inf);

	double nan = minf + inf;
	assert(nan != zero);
	assert(nan != mzero);
	assert(nan != inf);
	assert(nan != minf);
	assert(nan != nan);
	assert(!(nan <= zero));
	assert(!(nan >= zero));

	return 0;
}
