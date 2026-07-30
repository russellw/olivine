/* Atomic accesses, which the grammar does not model and which therefore leave
   the function they stand in exactly as it arrived — every load and store the
   front end wrote for the ordinary code around them included.

   Being conservative about an atomic is right: it is an ordering constraint as
   much as an access, so nothing may be carried across one without asking what
   the ordering says.  Being conservative about the whole function is the part
   worth measuring, and every function here surrounds its one atomic line with
   arithmetic that has nothing to do with it. */

#include <stdatomic.h>

/* One read-modify-write and a good deal of arithmetic on the result, none of
   which the atomic has anything to say about. */
int fetched(_Atomic int *counter, int n) {
  int step = n * 2 + 1;
  int before = atomic_fetch_add(counter, step);
  return before * 3 + step;
}

/* A compare-and-swap loop, which is the shape lock-free code is written in:
   the cmpxchg answers with a pair, and the pair is read apart by
   extractvalue — an aggregate value as well as an atomic. */
int raised_to(_Atomic int *cell, int floor) {
  int seen = atomic_load(cell);
  while (seen < floor) {
    if (atomic_compare_exchange_weak(cell, &seen, floor)) return 1;
  }
  return 0;
}

/* A relaxed load in a loop over storage the loop also reads ordinarily.  What
   the atomic constrains is the ordering of the accesses either side of it, not
   the arithmetic on what they answer. */
int weighted(_Atomic int *scale, const int *xs, int n) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    int k = atomic_load_explicit(scale, memory_order_relaxed);
    total += xs[i] * k;
  }
  return total;
}

/* A fence, which is an ordering constraint and no access at all.  The
   arithmetic on either side of it is not about memory in any way. */
int fenced(int a, int b) {
  int left = a * a + b;
  atomic_thread_fence(memory_order_seq_cst);
  int right = b * b + a;
  return left + right;
}

/* An atomic store, and a slot of this function's own that no callee could
   name.  Promotion would take the slot away if it read this function at all. */
int published(_Atomic int *out, int n) {
  int held = n;
  held = held + held;
  atomic_store(out, held);
  return held;
}
