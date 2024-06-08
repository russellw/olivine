// argv: $s
#include <stdio.h>
#include <string.h>

size_t fnv(const void* p, size_t bytes) {
	// Fowler-Noll-Vo-1a is slower than more sophisticated hash algorithms for
	// large chunks of data, but faster for tiny ones, so it still sees use.
	const unsigned char* q = p;
	size_t h = 2166136261u;
	while (bytes--) {
		h ^= *q++;
		h *= 16777619;
	}
	return h;
}

int main(int argc, char** argv) {
	if (argc != 2) {
		fprintf(stderr, "Usage: fnv string\n");
		return 1;
	}
	printf("%zu\n", fnv(argv[1], strlen(argv[1])));
	return 0;
}
