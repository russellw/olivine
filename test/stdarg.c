#include <stdarg.h>

double sum(int n, ...) {
	double r = 0;
	int i;
	va_list ap;
	va_start(ap, n);
	for (i = 0; i < n; i++) r += va_arg(ap, double);
	va_end(ap);
	return r;
}

double answer;

int main() {
	answer = sum(4, 1.0, 2.0, 3.0, 4.0);
	return answer != 10.0;
}
