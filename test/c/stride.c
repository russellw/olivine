/* Loops whose work is a fixed amount further along each turn.
 *
 * None of these is countable — every bound is a parameter — which is the
 * point: what a counter is worth is not the same question as how many times
 * the loop goes round, and these are the loops the second question has no
 * answer for.  Written in pairs where there is a pair to write, and every
 * function is read back through what it computed, so an address stepped along
 * wrongly shows up as a different number rather than as a shorter file.
 *
 * Two things happen to these and the pairs are for both: the address is
 * counted instead of computed, and — where the counter steps by one and so
 * nothing else is left reading it — the loop stops testing the counter and
 * tests the address, which is what lets the counter go entirely. */

#include <stddef.h>

/* The plain walk.  Every turn widens the counter and computes an address
   from it; neither is needed once the address itself is what is counted. */
int stride_walk(const int *p, int n) {
  int s = 0;
  for (int i = 0; i < n; i++)
    s += p[i];
  return s;
}

/* Two arrays walked together off one counter, which is two addresses counted
   beside it.  The counter stays, because the loop still tests it. */
int stride_dot(const int *a, const int *b, int n) {
  int s = 0;
  for (int i = 0; i < n; i++)
    s += a[i] * b[i];
  return s;
}

/* A stride that is not one.  The address advances three elements a turn and
   the multiply that worked out where to go disappears with the widening — but
   the loop keeps its counter and its own test, because the test is only
   rewritten to ask about the address for a step of one.  With a larger step
   the last address computed can land further past the end than one place,
   which is where the argument that the addresses run in the order the indices
   do gives out. */
int stride_third(const int *p, int n) {
  int s = 0;
  for (int i = 0; i < n; i += 3)
    s += p[i];
  return s;
}

/* Walking backwards, which is a step of minus one: the address is counted the
   same way and the test stays on the counter, a step of one being what the
   replacement asks for. */
int backwards(const int *p, int n) {
  int s = 0;
  for (int i = n - 1; i >= 0; i--)
    s += p[i];
  return s;
}

/* Writing rather than reading: the address written through is counted the same
   way, and getting it wrong writes the wrong slots. */
void scale(int *out, const int *in, int n, int k) {
  for (int i = 0; i < n; i++)
    out[i] = in[i] * k;
}

/* A counter used for arithmetic as well as for an address.  The multiply
   becomes an addition of the product, and the counter is still needed for the
   test, so this is the case where both kinds of reduction happen at once. */
int stride_weighted(const int *p, int n) {
  int s = 0;
  for (int i = 0; i < n; i++)
    s += p[i] * 5 + i * 7;
  return s;
}

/* An unsigned counter, which is the refusal that pairs with the walk above.
   C says unsigned arithmetic wraps, so clang writes the increment with no nsw
   on it and widens the index with zext rather than sext — and a zext of a
   count that wraps is not the zext of the last count one step on.  Both halves
   of the refusal are visible in the output: the increment carries no flag and
   the widening stays where it is. */
unsigned stride_unsigned(const unsigned *p, unsigned n) {
  unsigned s = 0;
  for (unsigned i = 0; i < n; i++)
    s += p[i];
  return s;
}

/* The base is loaded inside the loop.  That is not the end of it: hoisting
   takes the load out first — the handle is not written through here, so the
   load is invariant — and once the base is computed above the loop the address
   is counted like any other.  So this one does get reduced, and what it
   records is that the two passes have to happen in that order, which they do
   because the pipeline comes round again.  What is left is the widening of the
   counter's first value in the preheader, computed once. */
int through_handle(int *const *handle, int n) {
  int s = 0;
  for (int i = 0; i < n; i++)
    s += (*handle)[i];
  return s;
}

/* An index that is not the counter: it is read out of another array each turn.
   Both halves are here at once, which is why this one is worth having — the
   walk over the index array is a fixed amount further along and is counted,
   and the gather it feeds is not and keeps its widening and its step.  A pass
   that reduced the second would be wrong. */
int gathered(const int *p, const int *index, int n) {
  int s = 0;
  for (int i = 0; i < n; i++)
    s += p[index[i]];
  return s;
}

/* A two dimensional walk.  The inner loop is a counter of its own inside
   the outer one, and the outer one's own address arithmetic depends on it, so this
   is where the two interact. */
int grid_total(const int *p, int rows, int cols) {
  int s = 0;
  for (int i = 0; i < rows; i++)
    for (int j = 0; j < cols; j++)
      s += p[i * 8 + j];
  return s;
}
