/* Locals whose addresses go somewhere, which is the question the promotion
   pass has to answer before it may turn a slot into a local.  Everywhere else
   in the corpus a local is either plainly promotable or plainly not; each of
   these is a different reason for the answer, and clang at -O0 writes them all
   as an alloca with the same shape. */

static void writeback(int *p, int v) { *p = v; }

int through_pointer(int v) {
  int kept = v;
  int given = v + 1;
  /* &given goes to a function that writes through it, so what the slot holds
     afterwards is not what any store here put there. */
  writeback(&given, kept + 2);
  return kept + given;
}

int volatile_local(int v) {
  /* Each access has to happen, and an assignment happens nowhere. */
  volatile int x = v;
  x = x + 1;
  return x + x;
}

int addressed_pair(int a, int b) {
  int xs[2] = {a, b};
  /* The address is computed rather than only read, so the slot is stepped into
     and not merely loaded from. */
  int *p = xs + (a > b);
  return *p;
}

long counted(int n) {
  /* An alloca with a count: not one object, whatever the count turns out to
     be. */
  int vla[n];
  for (int i = 0; i < n; i++)
    vla[i] = i * i - n;
  long total = 0;
  for (int i = 0; i < n; i++)
    total += vla[i];
  return total;
}

int only_stored(int v) {
  /* Nothing reads it, so promotion leaves an assignment nothing reads, and the
     dead code pass is what finally takes the store away. */
  int unread = v * 7;
  (void)unread;
  return v;
}
