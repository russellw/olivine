/* Recursion, mutual recursion, and a call through a table of function
   pointers.  The table is the case Olivine.Syntax.Value.globalsIn recurses
   for: a function named from inside an initializer's aggregate rather than by
   any call instruction, and the only thing keeping dead symbol elimination
   from deciding those three functions are unreachable. */

static int add(int a, int b) { return a + b; }
static int sub(int a, int b) { return a - b; }
static int mul(int a, int b) { return a * b; }

static int (*const ops[3])(int, int) = {add, sub, mul};

int dispatch(int which, int a, int b) {
  return ops[(unsigned)which % 3](a, b);
}

int fib(int n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }

/* Tail recursive, so clang may turn it into a loop and leave phis where the
   arguments were. */
int gcd(int a, int b) { return b == 0 ? a : gcd(b, a % b); }

static int odd_(int n);
static int even_(int n) { return n == 0 ? 1 : odd_(n - 1); }
static int odd_(int n) { return n == 0 ? 0 : even_(n - 1); }

int parity(int n) { return n < 0 ? -1 : even_(n); }

int apply_twice(int (*f)(int, int), int a, int b) { return f(f(a, b), b); }
