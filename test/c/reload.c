/* Reading one address more than once, which is what redundant load
   elimination is for and what the rest of the corpus turns out not to do.
   clang at -O0 emits one load per access written in the source, so a field read
   twice is read from memory twice; every function here reads something twice on
   purpose, and half of them must keep doing so.

   The interesting half is the negative one.  Answering a load from an earlier
   access is unsound wherever anything in between could have written that
   address, and what counts as in between is a question about pointers: a call
   may write everything it can name, a store through one pointer may be a store
   through another, and neither can be told from the load itself. */

struct pair {
  int a;
  int b;
};

/* Defined by the driver, which points it at a struct one of these is called
   with, so that a call really does change what a pointer reads. */
void sink(void);

/* Two reads with nothing at all in between. */
int square_b(const struct pair *p) { return p->b * p->b; }

/* A read of what was just written there. */
int written_then_read(struct pair *p, int n) {
  p->b = n;
  return p->b;
}

/* A write to one slot between two reads of another.  Two allocations are two
   objects however alike they look, which is what makes the second read the
   first one. */
int separate_slots(int n) {
  struct pair x = {n, n + 1};
  struct pair y = {0, 0};
  int first = x.b;
  y.a = 3;
  return first + x.b + y.a;
}

/* And a write to the other field of the same struct.  Telling one field from
   another is a question about which bytes each access touches, which is what
   the data layout answers and what Olivine.Core.Layout reads: the two are four
   bytes apart and four bytes wide, so the write is not to what was read and
   the second read is the first. */
int both_ways(struct pair *p) {
  int first = p->b;
  p->a = 7;
  return first + p->b;
}

/* The address was handed to the caller, so the call can write it and the second
   read has to happen. */
int around_call(struct pair *p) {
  int first = p->b;
  sink();
  return first + p->b;
}

/* Where the storage is this function's own and its address never leaves, no
   callee has a way to name it, and what was read stays read across the call. */
int confined_across_call(int n) {
  struct pair x = {n, n + 1};
  int first = x.b;
  sink();
  return first + x.b;
}

/* Two pointers that may be the same one, which they are on one of the driver's
   two calls.  Nothing here says they are not, so the write between the reads
   has to be taken for a write to both. */
int through_the_store(struct pair *p, struct pair *q) {
  int first = p->b;
  q->b = 100;
  return first + p->b;
}

/* The same read every time round a loop that writes no memory at all.  What the
   block above the loop read reaches the body along the back edge as well as
   from above, so this one is answered only because availability is iterated. */
int repeated(const struct pair *p, int n) {
  int s = p->b;
  for (int i = 0; i < n; i++) s += p->b;
  return s;
}

/* And the same in a loop that does write memory, through a pointer that may be
   the one being read.  The write goes round with the read, so the read cannot
   be carried past it. */
int accumulated(const struct pair *p, int *out, int n) {
  int s = 0;
  for (int i = 0; i < n; i++) {
    *out = i;
    s += p->b;
  }
  return s;
}
