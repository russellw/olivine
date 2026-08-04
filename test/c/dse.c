/* Stores whose value nothing can ever read, and the ones that only look like
   it.

   Nothing else in the corpus asks.  A store has always stayed here however
   plainly unread: the dead code pass decides by whether anything reads the
   local an instruction assigns, and a store assigns none, so the question of
   whether anything reads the bytes it writes was one no pass was putting.
   Every function below is a store that should now go, or one that must not.

   The helpers are static, small and noinline, so the addresses handed to them
   really do leave the function and the calls really are calls.  What decides
   each case is what stands between the store and the next thing that could
   read it, which is why they are written in pairs: the same shape with and
   without the one line that makes the difference.  */

volatile int beacon;

__attribute__((noinline)) static int peek(const int *p) { return *p; }
__attribute__((noinline)) static int head(const int *p) { return p[0] + p[1]; }

/* Written twice with nothing in between: the first write is not readable by
   anything, whoever owns the storage.  */
int overwritten(int *p, int a) {
  *p = a;
  *p = a + 1;
  return *p;
}

/* The same, with a call in between that may read through the pointer it was
   handed.  Both writes stay.  */
int guarded(int *p, int a) {
  *p = a;
  int seen = peek(p);
  *p = a + 1;
  return seen;
}

/* Overwritten on one way on and not the other, which is not overwritten: the
   answer has to hold on every path from the store.  */
int one_way(int *p, int a, int c) {
  *p = a;
  if (c) *p = a + 1;
  return *p;
}

/* A local array a helper is given the address of, so it stays in memory rather
   than becoming locals.  What is written into it after the last read is
   written into storage the frame takes away.  */
int filled(int a) {
  int room[4];
  room[0] = a;
  room[1] = a + 1;
  int s = head(room);
  room[2] = s;
  room[3] = s + 1;
  return s;
}

/* And the same with something that reads them: a call handed an address into
   the array, after the writes.  */
int refilled(int a) {
  int room[4];
  room[0] = a;
  room[1] = a + 1;
  int s = head(room);
  room[2] = s;
  room[3] = s + 1;
  return s + peek(room + 2) + peek(room + 3);
}

/* A field set and never read, in a struct whose address leaves the function so
   that the field is really a store.  Above -O0 the lifetime markers around the
   struct are what says the storage has gone, rather than the return.  */
struct triple {
  int x, y, z;
};

__attribute__((noinline)) static int flatten(const struct triple *t) {
  return t->x + t->y;
}

int built(int a) {
  struct triple t;
  t.x = a;
  t.y = a * 2;
  int s = flatten(&t);
  t.z = s;
  return s;
}

/* The write happens because the program said it happens, twice over.  */
void announce(int a) {
  beacon = a;
  beacon = a + 1;
}

/* A store whose only overwrite is itself, next time round the loop.  What is
   left in the storage at the end is the last turn's, so the write cannot go —
   and telling this from a loop nothing observes is not something the aliasing
   can do.  */
void each_turn(int *p, int n) {
  for (int i = 0; i < n; i++) *p = i;
}

/* A frame slot written on every turn of a loop and read after it: the store is
   dead going round and alive coming out, which is the same intersection over
   the ways on that one_way asks with a branch.  */
int last_seen(int n) {
  int room[2];
  room[0] = 0;
  room[1] = 0;
  for (int i = 0; i < n; i++) {
    room[0] = i;
    room[1] = i * 2;
  }
  return head(room);
}
