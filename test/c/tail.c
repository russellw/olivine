/* Functions whose last act is to call themselves, which
   Olivine.Core.Pass.TailRecursion turns into loops, and the neighbouring
   shapes it has to leave alone.  Nothing else in the corpus had more than one
   of these: indirect.c writes gcd and stops there, so what a second argument,
   a second call site, or a frame with anything in it does to the edit was
   never exercised by a program that runs.

   Most of these are wrong in ways the driver can see.  Handing the arguments
   over one at a time rather than all at once gives the next turn a parameter
   the value it is about to have instead of the one it has, which alternate()
   and gcd_of() are chosen to show; entering the loop below the assignments
   that give the parameters their first values loses the arguments the caller
   passed; and reusing the frame for storage somebody else still points at is
   what via_local() would print the wrong answer for. */

/* The classic.  Two parameters exchanged on every turn, so an assignment in
   order gives both of them what the second one had. */
int gcd_of(int a, int b) { return b == 0 ? a : gcd_of(b, a % b); }

/* The same trap with nothing else in the way: the arguments are the parameters
   swapped, and the answer says which of them ended up where. */
int alternate(int a, int b, int n) {
  if (n == 0)
    return a * 10 + b;
  return alternate(b, a, n - 1);
}

/* Two tail calls in one function, so the block made in front of the loop is
   branched back to from two places at once. */
int steps(int n, int acc) {
  if (n <= 0)
    return acc;
  if (n % 2)
    return steps(n - 1, acc + 1);
  return steps(n / 2, acc + 2);
}

/* Nothing given back, so nothing to check about what is given back: the
   recursion is the loop and the writes are what it leaves behind. */
void walk_down(int *cell, int n) {
  if (n == 0)
    return;
  *cell += n;
  walk_down(cell, n - 1);
}

/* A frame with something in it.  The array's address stays inside, so every
   turn may share the one allocation — which is the whole reason the frame is
   worth reusing, and which is only sound because nothing outside can be
   looking at it. */
int buffered(int n, int acc) {
  int window[4];
  if (n <= 0)
    return acc;
  for (int i = 0; i < 4; i++)
    window[i] = n + i;
  return buffered(n - 1, acc + window[n & 3]);
}

/* The same frame with its address let out.  The next turn would be handed a
   pointer into storage it is about to write over, so this one keeps its
   recursion: the answer says whether it did. */
int via_local(int n, const int *seen) {
  int here = n * 3;
  if (n == 0)
    return seen ? *seen : -1;
  return via_local(n - 1, &here);
}

/* Not a tail call: the multiplication happens after the call comes back. */
int product_to(int n) { return n <= 1 ? 1 : n * product_to(n - 1); }

/* A tail call to somebody else, which is the code generator's business and not
   this pass's. */
static int plus_one(int n) { return n + 1; }
int forwards(int n) { return plus_one(n); }

/* Mutually tail recursive, which is a cycle no self call is on. */
static int ping(int n);
static int pong(int n) { return n == 0 ? 20 : ping(n - 1); }
static int ping(int n) { return n == 0 ? 10 : pong(n - 1); }
int bounced(int n) { return ping(n); }

/* A tail call reached out of a loop, so what branches back to the top of the
   function is a block inside one. */
int skipping(const int *xs, int n, int total) {
  int i = 0;
  while (i < n && xs[i] > 0) {
    total += xs[i];
    i++;
  }
  if (i == n)
    return total;
  return skipping(xs + i + 1, n - i - 1, total - 1);
}
