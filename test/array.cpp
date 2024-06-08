#include <stdio.h>

template <class T> void swap01(T* v) {
	auto a = v[0];
	v[0] = v[1];
	v[1] = a;
}

int main() {
	static int v[3] = {1, 2, 3};
	swap01(v);
	for (int i = 0; i < 3; ++i) printf("%d\n", v[i]);
	return 0;
}
