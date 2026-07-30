/* Loops with work in them that does not depend on going round, which is what
   Olivine.Core.Pass.LoopInvariants takes out.  The rest of the corpus has
   none: at -O0 everything a loop body computes is derived from the induction
   variable or from a load, so a pass that hoists only pure computations found
   nothing to do until these were here.

   Three of these are cases hoisting must decline, and two of them are wrong in
   a way the driver can see: a division that faults, and a variable read before
   it is assigned.  The third is a loop no block dominates the body of, which
   there is nowhere to hoist out of.

   The last two are the same pair for what a loop reads rather than what it
   computes: a symbol read in a loop that leaves it alone, and one read in a
   loop that writes it, where the driver hands the loop the symbol's own
   address so that a read wrongly taken out shows up in what it prints. */

int scaled_sum(const int *xs, int n, int k) {
  int total = 0;
  for (int i = 0; i < n; i++)
    total += xs[i] * (k * k + 3);
  return total;
}

/* Invariant in both loops, so it comes out one loop per round. */
int nested_squares(int a, int b, int rounds) {
  int acc = 0;
  for (int i = 0; i < rounds; i++)
    for (int j = 0; j < rounds; j++)
      acc += (a << 2) + (b ^ a);
  return acc;
}

/* Invariant, and in a block the loop only sometimes reaches.  Hoisting it
   makes it run where it would not have, which is free for arithmetic that
   only computes a value. */
int sometimes(const int *xs, int n, int k) {
  int total = 0;
  for (int i = 0; i < n; i++)
    if (xs[i] > 0)
      total += k * k;
  return total;
}

/* Invariant and not hoistable: dividing by zero is undefined behaviour, and
   the divisor is zero exactly when the loop does not run.  Called that way. */
int guarded_divide(int a, int b, int n) {
  int total = 0;
  for (int i = 0; i < n; i++)
    total += a / b;
  return total;
}

/* The other reason something stays, and it is the variable rather than the
   computation: `k + 1` is hoisted, and the assignment of it to `previous` is
   not, because `previous` is read above it and holds 0 the first time round.
   Moving the assignment as well would make the first iteration add k + 1. */
int carried_first(int n, int k) {
  int total = 0, previous = 0;
  for (int i = 0; i < n; i++) {
    total += previous;
    previous = k + 1;
  }
  return total;
}

/* What a loop reads out of memory and cannot change, which is the other half
   of what comes out of one.  A symbol is storage the program has for as long
   as it runs, so reading one cannot fault; that is what lets the read come out
   of a body the loop may never reach at all. */
static int scale = 3;

int scale_now(void) { return scale; }
void set_scale(int v) { scale = v; }

int scaled_by_symbol(const int *xs, int n) {
  int total = 0;
  for (int i = 0; i < n; i++)
    total += xs[i] * scale;
  return total;
}

/* The same read, in a loop that writes through a pointer it was handed.  The
   pointer may be where the symbol is, and 'bumping_symbol' makes it exactly
   that, so the read has to happen again every time round: hoisted, the loop
   would add the first iteration's value n times. */
int bumping(int *p, int n) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    total += scale;
    *p += 1;
  }
  return total;
}

int bumping_symbol(int n) { return bumping(&scale, n); }

/* A jump into the middle of a loop, so no block dominates the whole of it and
   there is no natural loop to hoist out of.  Here to be survived rather than
   optimized. */
int jumped_into(int n, int k) {
  int total = 0, i = 0;
  if (n & 1)
    goto step;
  while (i < n) {
    total += k * 5;
  step:
    i++;
  }
  return total;
}
