// argv: the quick brown fox jumped over the lazy dog
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char* v[100];

int strpcmp(const void* a, const void* b) {
	char* a1 = *(char**)a;
	char* b1 = *(char**)b;
	return strcmp(a1, b1);
}

int main(int argc, char** argv) {
	int n = argc - 1;
	if (n > sizeof v / sizeof *v) {
		fprintf(stderr, "Too many args\n");
		return 1;
	}
	for (int i = 0; i < n; i++) v[i] = argv[i + 1];
	qsort(v, n, sizeof *v, strpcmp);
	for (int i = 0; i < n; i++) puts(v[i]);
	return 0;
}
