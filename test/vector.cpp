#include <stdio.h>
#include <vector>

template <class T> void swap01(std::vector<T>& v) {
	auto a = v[0];
	v[0] = v[1];
	v[1] = a;
}

int main() {
	std::vector<int> v;
	v.push_back(1);
	v.push_back(2);
	v.push_back(3);
	swap01(v);
	for (auto a: v) printf("%d\n", a);
	return 0;
}
