#include <stdio.h>

struct IntCoPtr;
struct IntCoCoPtr;
struct IntCoCoCoPtr;
struct IntCo;
struct IntCoCo;
struct IntCoCoCo;

struct IntCoPtr {
	struct IntCo* p;
};

struct IntCoCoPtr {
	struct IntCoCo* p;
};

struct IntCoCoCoPtr {
	struct IntCoCoCo* p;
};

struct IntCo {
	int x, y;
};

struct IntCoCo {
	struct IntCo x, y;
};

struct IntCoCoCo {
	struct IntCoCo x, y;
};

struct IntCoPtr IntCoPtr;
struct IntCoCoPtr IntCoCoPtr;
struct IntCoCoCoPtr IntCoCoCoPtr;
struct IntCo IntCo;
struct IntCoCo IntCoCo;
struct IntCoCoCo IntCoCoCo;

int intfn(void) {
	return IntCoCoCo.y.y.y;
}

struct DoubleCo;
struct DoubleCoCo;
struct DoubleCoCoCo;
struct DoubleCoPtr;
struct DoubleCoCoPtr;
struct DoubleCoCoCoPtr;

struct DoubleCo {
	double x, y;
};

struct DoubleCoCo {
	struct DoubleCo x, y;
};

struct DoubleCoCoCo {
	struct DoubleCoCo x, y;
};

struct DoubleCoPtr {
	struct DoubleCo* p;
};

struct DoubleCoCoPtr {
	struct DoubleCoCo* p;
};

struct DoubleCoCoCoPtr {
	struct DoubleCoCoCo* p;
};

struct DoubleCo DoubleCo;
struct DoubleCoCo DoubleCoCo;
struct DoubleCoCoCo DoubleCoCoCo;
struct DoubleCoPtr DoubleCoPtr;
struct DoubleCoCoPtr DoubleCoCoPtr;
struct DoubleCoCoCoPtr DoubleCoCoCoPtr;

double doublefn(void) {
	return DoubleCoCoCo.y.y.y;
}

int main(int argc, char** argv) {
	printf("%d\n", intfn());
	printf("%f\n", doublefn());
	return 0;
}
