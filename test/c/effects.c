/* What a call does besides handing back a result, which is what says whether
   the calls and the loads around it may be shared, moved or dropped.

   Nothing else in the corpus asks.  A call has always been a wall here: what a
   load found is forgotten across one, a computation may not pass one, and no
   call is ever removed however plainly unread its result — which is the right
   answer for a call to something nothing is known about and the wrong answer
   for most calls a program makes.  Every function below is one call around
   which one of those refusals should now lift, or one around which it must
   not.

   The helpers are static and small, and at -O0 clang writes noinline on
   everything, so the calls really are calls.  Above -O0 clang inlines them
   itself and what is left measures nothing in particular; that is true of most
   of the corpus.  */

int written_total;

/* Touches no memory, holds no loop, and cannot recur: a call to this is a
   computation with an odd spelling.  Everything the arithmetic does with its
   own frame stays in its own frame, which is the point of the array — a
   function that spills to the stack still writes nothing anybody outside can
   see, and LLVM's own inference says the same of it.  */
__attribute__((noinline)) static int mixed(int a, int b) {
  int scratch[4];
  scratch[0] = a + b;
  scratch[1] = a ^ b;
  scratch[2] = a * 3 - b;
  scratch[3] = (a << 2) + (b >> 1);
  return scratch[0] + scratch[1] * 2 + scratch[2] - scratch[3];
}

/* Reads memory and writes none.  A call to it may be dropped when nothing
   reads its result, but two of them are two calls: what it answers depends on
   what was in memory each time it was asked.  */
__attribute__((noinline)) static int first_two(const int *p) { return p[0] + p[1]; }

/* Writes.  Nothing may be shared across one of these, and one whose result is
   unread is not unread.  */
__attribute__((noinline)) static int record(int v) {
  written_total += v;
  return written_total;
}

/* Pure, and it comes back, though nothing about the function says so: C
   promises progress for a loop whose controlling expression is not a constant,
   and clang writes that promise on the loop rather than on the function.  So
   this is the pure function whose promise has to be read off its own back
   edge — !llvm.loop.mustprogress, one node further down than the node the
   branch names.  */
__attribute__((noinline)) static int weigh(int a, int b) {
  int s = 0;
  for (int i = 0; i < 8; i++) s += (a ^ (b + i)) * (i + 3);
  return s;
}

/* Pure, and may not come back: the controlling expression here is a constant,
   which is exactly where C stops promising, so clang writes no progress on
   this loop and there is nothing to read.  A call to it stays where it is.  */
__attribute__((noinline)) static int settle(int a) {
  int s = 0;
  for (;;) {
    s += a;
    if (s > 100) return s;
  }
}

/* Pure, and may not come back for the third reason: it can reach itself.  */
__attribute__((noinline)) static int chain(int n) { return n <= 0 ? 0 : n + chain(n - 1); }

/* One computation written twice.  */
int twice_over(int a, int b) { return mixed(a, b) + mixed(a, b); }

/* Two reads of one address with a call in between that cannot write it.  */
int across_call(const int *p, int a, int b) {
  int first = *p;
  int w = mixed(a, b);
  return first + *p + w;
}

/* The same call every turn of the loop, standing where the loop is certain to
   run it.  */
int in_loop(const int *p, int n, int a, int b) {
  int s = 0;
  for (int i = 0; i < n; i++) s += p[i] + mixed(a, b);
  return s;
}

/* A result nothing reads.  */
int unused_result(int a, int b) {
  mixed(a, b);
  return a + b;
}

/* And the same four with the refusals that have to stay.  A writer is shared
   with nothing, read across by nothing, and dropped never.  */
int writer_twice(int v) { return record(v) + record(v); }

int across_writer(const int *p, int v) {
  int first = *p;
  record(v);
  return first + *p;
}

int unused_writer(int v) {
  record(v);
  return v;
}

/* A reader answers out of memory rather than out of its arguments, so two of
   them are two calls although neither writes anything.  */
int reader_twice(const int *p) { return first_two(p) + first_two(p); }

/* A read across a write of the very thing it reads.  */
int reader_across_write(int *p, int v) {
  int first = first_two(p);
  *p = v;
  return first + first_two(p);
}

/* Pure, unread, and it does come back: the call goes, on a promise written a
   node away from the branch that closes the loop it is in.  */
int unused_loop(int a, int b) {
  weigh(a, b);
  return a + b;
}

/* And the loop that need not keep making it: once is what n of them come
   to.  */
int loop_of_loops(int n, int a, int b) {
  int s = 0;
  for (int i = 0; i < n; i++) s += weigh(a, b);
  return s;
}

/* The same two where nothing promised anything, which must stay as written:
   the call that may not come back is not unread, and the loop must keep
   making it.  */
int unused_spin(int a) {
  settle(a);
  return a;
}

int loop_of_spins(int n, int a) {
  int s = 0;
  for (int i = 0; i < n; i++) s += settle(a);
  return s;
}

int unused_recursion(int n) {
  chain(n);
  return n;
}
