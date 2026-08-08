/* Control flow the rest of the corpus does not build: a goto out of nested
   loops, a do-while, a switch that falls through, and a loop with two exits.
   The order clang writes the blocks of these in is not the order a value
   travels through them, which is why Olivine.Core.Blocks.reversePostorder
   exists.

   And two shapes where control flow is not what the program means.  A dense
   switch every case of which yields a constant is a formula written as a jump
   table, which Olivine.Core.Pass.Switches reads back; the cases here are
   arranged so that each of the three answers that pass can give is exercised,
   and so are the shapes it must refuse.  A computed goto is the opposite —
   control flow the program means literally — and it is the only thing in the
   corpus that takes the address of a block, which is the one name the core
   keeps.  Both are also here to be run: what a jump table does when the
   value is out of range, and what a threaded dispatch loop does at every
   label, are what the driver checks. */

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

/* A dense switch whose cases run in step with their values: the answer is
   2*c + 3 in range and 0 outside it, and no branch is needed for either. */
int weight(int c) {
  switch (c) {
  case 0: return 3;
  case 1: return 5;
  case 2: return 7;
  case 3: return 9;
  case 4: return 11;
  default: return 0;
  }
}

/* The same shape with one answer for the whole range, which is the range test
   and nothing else.  The cases do not start at zero, so the index is counted
   from the lowest of them. */
int in_season(int month) {
  switch (month) {
  case 3:
  case 4:
  case 5:
  case 6:
    return 1;
  default:
    return 0;
  }
}

/* Descending, and through a variable rather than a return: still a formula,
   with a negative step. */
int step_down(int n) {
  int r = -1;
  switch (n) {
  case 10: r = 40; break;
  case 11: r = 30; break;
  case 12: r = 20; break;
  case 13: r = 10; break;
  }
  return r;
}

/* Three refusals, one for each reason.  The answers here are in no order, so
   nothing but a table in memory says what they are. */
int scattered(int c) {
  switch (c) {
  case 0: return 4;
  case 1: return 9;
  case 2: return 2;
  case 3: return 7;
  default: return -1;
  }
}

/* The case values have a hole in them, so the index is not the case. */
int sparse(int c) {
  switch (c) {
  case 1: return 2;
  case 2: return 4;
  case 4: return 8;
  default: return 0;
  }
}

/* A case that computes rather than yielding a constant. */
int case_works(int c, int x) {
  switch (c) {
  case 0: return x + 1;
  case 1: return x + 2;
  case 2: return x + 3;
  default: return 0;
  }
}

/* A computed goto: the classic threaded dispatch, where the table is a static
   global full of block addresses and the jump is the loop.  Nothing else in
   the corpus makes the lowering keep a block's name. */
int thread_ops(const unsigned char *code, int n) {
  static const void *ops[] = {&&op_add, &&op_double, &&op_stop};
  int acc = 0;
  int i = 0;
  if (i >= n)
    return acc;
  goto *ops[code[i] % 3];
op_add:
  acc += code[i];
  if (++i >= n)
    return acc;
  goto *ops[code[i] % 3];
op_double:
  acc *= 2;
  if (++i >= n)
    return acc;
  goto *ops[code[i] % 3];
op_stop:
  return acc;
}

/* The address of a block taken into a local rather than a global, and the
   jump made once.  It is the same construct with the table nowhere to be
   found, which is what says the address is an operand like any other. */
int jump_over(int c) {
  void *where = c > 0 ? &&high : &&low;
  int r = 0;
  goto *where;
high:
  r = 1;
  goto out;
low:
  r = -1;
out:
  return r;
}
