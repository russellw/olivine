int fact(int n) {
	if (n <= 1) {
		return n;
	}
	return n * fact(n - 1);
}

int main() {
	return fact(7) / fact(6);
}
