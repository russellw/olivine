/* Conditionals that decide a value rather than what happens: what
   if-conversion turns into a select, and what it must leave alone.

   The two that must be left alone are the point of the file.  A division on one
   side of a branch is undefined when the branch was what kept it from dividing
   by zero, and a load is undefined when the branch was what kept the pointer
   from being read; both are called here with the value that makes the branch
   the only thing standing between the program and undefined behaviour. */

int larger(int a, int b) { return a > b ? a : b; }

int sign(int x) { return x < 0 ? -1 : (x > 0 ? 1 : 0); }

/* One side and no other: the shape promotion leaves with nothing on the far
   side of the branch at all. */
int bumped(int x, int c) {
  int y = x;
  if (c)
    y = x + 1;
  return y;
}

/* A variable decided inside a loop, so the select stands in the body and the
   value goes round. */
int folded(const int *xs, int n) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    int v = xs[i];
    if (v > 0)
      total += v;
    else
      total -= v;
  }
  return total;
}

/* The branch is what stops the division by zero. */
int safe_divide(int a, int b) { return b == 0 ? -1 : a / b; }

/* The branch is what stops the read through a null pointer. */
int if_present(const int *p) { return p == 0 ? 0 : *p; }

/* Two calls, of which exactly one must be made. */
int counter;
static int bump(int by) {
  counter += by;
  return counter;
}
int one_call(int c) { return c ? bump(2) : bump(5); }
