typedef unsigned long long u64;

u64 fact(u64 n) {
	if (n <= 1) {
		return n;
	}
	return n * fact(n - 1);
}

int main() {
	return fact(20) / fact(19);
}
