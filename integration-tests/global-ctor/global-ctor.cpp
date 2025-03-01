struct Num {
	int x;

	Num(int x): x(x) {
	}
};

Num num(42);

int main() {
	return num.x;
}
