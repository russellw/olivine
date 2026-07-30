/* Loops whose test is on the way in, which Olivine.Core.Pass.LoopRotation
   turns round so that the body is the block the loop is certain to run.  Every
   for loop in the rest of the corpus is one of those, so what is here is what
   the rest does not have: a body holding a read that can only come out of the
   loop once the body is the header, a test with a side effect that says how
   many times the test ran, and a do loop, which is the shape rotation produces
   and therefore must leave alone.

   The first two are wrong in ways the driver can see: a read taken further out
   than the block deciding whether to enter the loop faults, and a test copied
   as well as the original rather than instead of the first turn of it counts
   one too many. */

/* The read of *k is the same on every turn and cannot fault where the loop
   runs, but nothing says the address can be read when the loop does not run at
   all.  Rotated, the body is the header, so the read comes out as far as the
   block that decides whether the loop runs — and no further.  Called below
   with a null k and n = 0. */
int scale_all(const int *xs, int n, const int *k) {
  int total = 0;
  for (int i = 0; i < n; i++)
    total += xs[i] * *k;
  return total;
}

/* A test that does something as well as deciding, so what it leaves behind
   says how many times it ran.  Rotation copies the test into the block above
   the loop, where it has to run instead of the first turn of the header rather
   than as well as it. */
static int ticket;

int tickets_taken(void) { return ticket; }
void reset_tickets(void) { ticket = 0; }

static int next_ticket(void) { return ++ticket; }

int consume(int limit) {
  int total = 0;
  while (next_ticket() <= limit)
    total += ticket;
  return total;
}

/* A do loop, which already tests where rotation would have put the test.
   Turning it round would peel a turn off the front of it for nothing. */
int countdown(int n) {
  int steps = 0;
  do {
    steps++;
    n -= 3;
  } while (n > 0);
  return steps;
}
