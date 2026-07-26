/* Floating point, including the fcmp predicates and float/int conversions. */

double add(double a, double b) { return a + b; }
float fadd(float a, float b) { return a + b; }
double divide(double a, double b) { return a / b; }

int ordered(double a, double b) { return a < b; }
int equal(float a, float b) { return a == b; }

double to_double(int a) { return (double)a; }
int to_int(double a) { return (int)a; }
float demote(double a) { return (float)a; }

double negate(double a) { return -a; }
