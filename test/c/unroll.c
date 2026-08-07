/* Loops whose turns can be counted, and loops whose turns cannot.
 *
 * Written in pairs wherever there is a pair to write: the same loop with a
 * bound the compiler knows and with one only the caller knows, so that what
 * the counting buys is the difference between the two rather than a number on
 * its own.  Every function is read back through what it computed, so a turn
 * written out wrongly — the counter a turn behind, a store to the wrong slot,
 * a body run once too often — shows up as a different number and not as a
 * shorter file. */

#include <stddef.h>

/* The plainest one: four turns, a constant bound, a body of two instructions.
   Every index is a constant once the turns are written out, so the address
   arithmetic goes with them. */
int total4(const int *p) {
  int s = 0;
  for (int i = 0; i < 4; i++)
    s += p[i];
  return s;
}

/* The same loop with a bound the caller supplies.  Nothing here is countable
   and the loop stays a loop: this is the one that says the pass is deciding
   rather than unrolling whatever it is given. */
int total_n(const int *p, int n) {
  int s = 0;
  for (int i = 0; i < n; i++)
    s += p[i];
  return s;
}

/* A step that is not one.  There is no rule here for what the closed form of
   this recurrence is, and none is wanted: the turns are counted by running
   them, so a step of three costs exactly what a step of one costs. */
int every_third(const int *p) {
  int s = 0;
  for (int i = 0; i < 12; i += 3)
    s += p[i];
  return s;
}

/* Counting down rather than up, which is the other comparison and the other
   sign of step. */
int count_back(const int *p) {
  int s = 0;
  for (int i = 4; i > 0; i--)
    s += p[i - 1];
  return s;
}

/* Storing rather than loading.  Each turn writes a different slot from a
   different value, so this is the one that fails loudly if the turns are
   written out sharing what they should not: all four stores landing on one
   slot is what a reconstruction that finds an instruction by value rather than
   by position does. */
void fill4(int *p, int base) {
  for (int i = 0; i < 4; i++)
    p[i] = base + i;
}

/* Turns enough to be worth counting and too many to be worth writing out.  The
   bound is a constant, so the count is there to be had; what declines this is
   the budget, and the loop must come back a loop. */
int total64(const int *p) {
  int s = 0;
  for (int i = 0; i < 64; i++)
    s += p[i];
  return s;
}

/* A body big enough that four copies of it cost more than the branch they
   save.  The count is four and the budget is what refuses it. */
int wide4(const int *p, int k) {
  int s = 0;
  for (int i = 0; i < 4; i++) {
    int a = p[i] * k;
    int b = a + p[i];
    int c = b * b;
    int d = c - a;
    int e = d * k;
    int f = e + c;
    int g = f * f;
    int h = g - e;
    s += h;
  }
  return s;
}

/* A loop the body of which decides something.  This one is countable and it is
   not in one block when unrolling first looks at it — if-conversion stands
   below unrolling in the order, so the two sides become selects on the round
   after, and the round after that has a single block to write out.  Six turns
   of it come to more than the budget, so what actually refuses it is the size;
   raise the budget and it is written out.  Both facts are worth having in one
   function: the shape a pass sees depends on which round it is. */
int alternating(const int *p) {
  int s = 0;
  for (int i = 0; i < 6; i++) {
    if (p[i] > 0)
      s += p[i];
    else
      s -= p[i];
  }
  return s;
}

/* A loop whose turns depend on what it read, so no arithmetic in it settles
   how many there are. */
int until_zero(const int *p) {
  int s = 0;
  int i = 0;
  while (p[i] != 0) {
    s += p[i];
    i++;
  }
  return s;
}

/* Two counted loops one inside the other.  The inner one is written out — the
   loops come innermost first — and the outer one then has a body three times
   the size, which is what puts it over the budget.  So this comes back as one
   loop of three turns around three copies of the inner body, which is the
   trade the budget exists to make: the turns that are cheap to write out are
   written out and the ones that are not are left as a loop. */
int grid(const int *p) {
  int s = 0;
  for (int i = 0; i < 3; i++)
    for (int j = 0; j < 3; j++)
      s += p[i * 3 + j];
  return s;
}

/* A counted loop that leaves early.  The count is there to be had, but the
   loop keeps two blocks however cheap it is — the block that returns cannot be
   merged into the one that tests, and if-conversion has nothing to make a
   select of where one side leaves the function.  So this is the shape the pass
   declines for being more than one block, and it is the common one: an early
   exit is what most counted loops in real code have. */
int first_negative(const int *p) {
  for (int i = 0; i < 4; i++)
    if (p[i] < 0)
      return i;
  return -1;
}
