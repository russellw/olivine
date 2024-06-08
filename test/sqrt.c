// argv: $f
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {
	if (argc != 2) {
		fprintf(stderr, "Usage: sqrt x\n");
		return 1;
	}
	errno = 0;
	double x = strtod(argv[1], 0);
	if (errno) {
		perror(argv[1]);
		return 1;
	}
	printf("%f\n", sqrt(x));
	return 0;
}
