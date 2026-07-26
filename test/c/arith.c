/* Signed and unsigned variants of the same operations, which LLVM
   distinguishes at the instruction rather than the type. */

int sdiv(int a, int b) { return a / b; }
unsigned udiv(unsigned a, unsigned b) { return a / b; }
int srem(int a, int b) { return a % b; }
unsigned urem(unsigned a, unsigned b) { return a % b; }
int ashr(int a, int b) { return a >> b; }
unsigned lshr(unsigned a, unsigned b) { return a >> b; }

long widen(int a) { return a; }
unsigned long zwiden(unsigned a) { return a; }
short narrow(long a) { return (short)a; }

int compare(int a, unsigned b) { return a < 0 && b > 7u; }
