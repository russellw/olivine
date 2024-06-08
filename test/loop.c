#include <stdio.h>

double a[1000];

int main(int argc, char** argv) {
	double x = 0.0;
	for (int i = 0; i < 1000; ++i) x += a[i];
	printf("%f\n", x);
	return 0;
}
