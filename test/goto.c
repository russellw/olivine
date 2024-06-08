#include <stdio.h>

int main(int argc, char** argv) {
	puts("begin");
	goto a;
a:
	puts("a");
	goto b;
b:
	puts("b");
	goto c;
c:
	puts("c");
	return 0;
}
