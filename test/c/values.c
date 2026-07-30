/* Aggregates held as values rather than in memory, which is what a struct
   small enough to travel in registers becomes above -O0 and what nothing else
   in the corpus contains.  Two fields of eight bytes each are returned as
   { double, double }, and a value of that type is built by insertvalue and
   read by extractvalue — instructions the grammar does not model, so a
   function holding one is a function the optimizer passes through whole.

   The point of the file is that the aggregate is incidental: every one of
   these does ordinary arithmetic as well, and what an unmodelled line costs is
   not the line but everything around it. */

struct point {
  double x;
  double y;
};

/* Built field by field and returned, which is the shape that arrives as
   insertvalue into an undef of the pair type. */
struct point scaled(struct point p, double k) {
  struct point r = {p.x * k, p.y * k};
  return r;
}

/* Two of them, so that the arithmetic between the reads is worth something to
   look at: four extractvalues and four multiplications. */
double dot(struct point a, struct point b) { return a.x * b.x + a.y * b.y; }

/* A returned aggregate read straight back apart, which is the pair of
   instructions that cancel: what insertvalue put in field zero is what
   extractvalue takes out of it. */
double sum_scaled(struct point p, double k) {
  struct point r = scaled(p, k);
  return r.x + r.y;
}

/* The same aggregate carried round a loop.  Everything here is loop invariant
   except the accumulation, and none of it is looked at while the function
   holds a line the grammar cannot read. */
double travelled(struct point step, int n) {
  struct point at = {0.0, 0.0};
  for (int i = 0; i < n; i++) {
    at.x = at.x + step.x * 2.0;
    at.y = at.y + step.y * 2.0;
  }
  return at.x + at.y;
}

/* Too big for registers, so it goes through memory with an sret pointer and
   stays an ordinary matter of loads and stores.  Here to say which side of the
   line a source is on: this one the optimizer does read. */
struct box {
  int a, b, c, d, e;
};

struct box spread(int n) {
  struct box b = {n, n + 1, n + 2, n + 3, n + 4};
  return b;
}

int fifth(struct box b) { return b.e; }

/* A complex multiply, which is the other place aggregate values turn up in C:
   the pair is the language's own and the arithmetic is written out by the
   front end. */
double _Complex turned(double _Complex z, double _Complex w) { return z * w; }
