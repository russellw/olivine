struct Marble {
	double r;

	Marble(double r): r(r) {
	}

	double volume() {
		return 4.0 / 3.0 * 3.14159265359 * r * r * r;
	}
};

Marble m(10.0);

int main() {
	return !(4188.0 < m.volume() && m.volume() < 4189.0);
}
