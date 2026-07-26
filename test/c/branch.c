/* Conditional branches and a switch, which lowers to the switch terminator
   with its own operand syntax. */

int classify(int c) {
  switch (c) {
  case 0:
    return 10;
  case 1:
  case 2:
    return 20;
  case 100:
    return 30;
  default:
    return -1;
  }
}

int clamp(int x, int lo, int hi) {
  if (x < lo)
    return lo;
  else if (x > hi)
    return hi;
  return x;
}

int select_or(int a, int b) { return a ? a : b; }
