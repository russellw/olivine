/* Structs a function makes on its own stack.  A front end writes one of these
   as an allocation the program reads a field at a time, which is storage
   nothing could promote until the fields became storage of their own.

   The type names are its own because the driver has to declare every
   by-value aggregate the same way, and values.c already has a point. */

struct corner {
  int x;
  int y;
};

struct frame {
  struct corner lo;
  struct corner hi;
};

struct label {
  int n;
  char tag[4];
};

/* Every field named by name, and one struct inside another: splitting the
   outer one leaves the inner one a slot, which splits in turn. */
int area(int lx, int ly, int hx, int hy) {
  struct frame r;
  r.lo.x = lx;
  r.lo.y = ly;
  r.hi.x = hx;
  r.hi.y = hy;
  return (r.hi.x - r.lo.x) * (r.hi.y - r.lo.y);
}

/* Written on one side of a branch and read after it, so the fields have to
   survive being assigned in two places. */
int pick_corner(int a, int b, int which) {
  struct corner p;
  if (which) {
    p.x = a;
    p.y = b;
  } else {
    p.x = b;
    p.y = a;
  }
  return p.x * 10 + p.y;
}

/* Fresh storage each time round the loop, which is what the split has to leave
   still true. */
int walk(int n) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    struct corner p;
    p.x = i;
    p.y = n - i;
    total += p.x * p.y;
  }
  return total;
}

/* The address of one field handed to something else.  A pointer to a field is
   a pointer into the whole allocation, so nothing here may be separated. */
int add_into(int *p, int v);

int through_field(int a, int b) {
  struct corner p;
  p.x = a;
  p.y = b;
  return add_into(&p.x, b) + p.y;
}

/* Returned by value, which a front end writes as a read of the whole thing at
   a type of its own: a question about bytes rather than about fields. */
struct corner make_corner(int x, int y) {
  struct corner p;
  p.x = x;
  p.y = y;
  return p;
}

int diagonal(int x, int y) {
  struct corner p = make_corner(x, y);
  return p.x - p.y;
}

/* A field that is an array is reached by striding along it, and how far a
   stride goes is a number of bytes.  The whole slot stays, the integer beside
   the array with it. */
int tag_at(int n, int i) {
  struct label s;
  s.n = n;
  s.tag[0] = 'o';
  s.tag[1] = 'l';
  s.tag[2] = 'i';
  s.tag[3] = 0;
  return s.n + s.tag[i & 3];
}

/* One struct assigned to another, which a front end writes as a memcpy of a
   constant size: a question about bytes again, and the count is what has to be
   shown to cover the whole of the slot.  Both ends are slots of the same
   struct, so the copy is a copy per field. */
int copied(int x, int y) {
  struct corner p;
  p.x = x;
  p.y = y;
  struct corner q;
  q = p;
  return q.x * 1000 + q.y;
}

/* And the same where one end escapes, so neither slot goes: the copy has to be
   left as it was rather than written out as several. */
int copied_out(int x, int y, struct corner *out) {
  struct corner p;
  p.x = x;
  p.y = y;
  *out = p;
  return add_into(&p.x, y);
}
