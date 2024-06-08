#include <stdio.h>

int x = 7;

int f(int a) {
	return a * x;
}

int main(int argc, char** argv) {
	printf("%d\n", f(20));
	return 0;
}
