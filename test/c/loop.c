/* At -O2 these become the phi nodes that the non-SSA core has to eliminate
   on the way in and rebuild on the way out. */

int sum(const int *xs, int n) {
  int total = 0;
  for (int i = 0; i < n; i++)
    total += xs[i];
  return total;
}

int count_down(int n) {
  int steps = 0;
  while (n > 1) {
    n = (n % 2 == 0) ? n / 2 : 3 * n + 1;
    steps++;
  }
  return steps;
}

void fill(int *xs, int n, int v) {
  for (int i = 0; i < n; i++)
    xs[i] = v;
}
