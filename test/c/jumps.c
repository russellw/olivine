/* Control flow the rest of the corpus does not build: a goto out of nested
   loops, a do-while, a switch that falls through, and a loop with two exits.
   The order clang writes the blocks of these in is not the order a value
   travels through them, which is why Olivine.Core.Blocks.reversePostorder
   exists. */

int search(const int *g, int w, int h, int needle) {
  int found = -1;
  for (int i = 0; i < h; i++) {
    for (int j = 0; j < w; j++) {
      if (g[i * w + j] < 0)
        continue;
      if (g[i * w + j] == needle) {
        found = i * w + j;
        goto done;
      }
    }
  }
done:
  return found;
}

int digits(unsigned n) {
  int d = 0;
  do {
    d++;
    n /= 10;
  } while (n);
  return d;
}

int falls_through(int c) {
  int acc = 0;
  switch (c) {
  case 3:
    acc += 8;
    /* fall through */
  case 2:
    acc += 4;
    /* fall through */
  case 1:
    acc += 2;
    break;
  case 9:
    acc = 99;
    break;
  default:
    acc = -1;
  }
  return acc;
}

int two_exits(const int *xs, int n, int cap) {
  int t = 0;
  for (int i = 0; i < n; i++) {
    t += xs[i];
    if (t > cap)
      return -t;
  }
  return t;
}

int nested_while(int a, int b) {
  int steps = 0;
  while (a > 0) {
    int inner = b;
    while (inner > 0) {
      if (inner == a)
        break;
      inner--;
      steps++;
    }
    a--;
  }
  return steps;
}
