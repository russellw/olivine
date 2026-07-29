/* Unions, bit fields and a packed struct: field offsets the data layout
   decides rather than a stride, which is what Olivine.Core.Instruction.Field
   holds and Offset cannot.  A union is also the one case where two fields
   begin in the same place, and a bit field the case where a field is not a
   whole number of bytes and clang has to write the shifting itself. */

#include <stdbool.h>

union bits {
  int i;
  float f;
  unsigned char b[4];
};

struct flags {
  unsigned kind : 3;
  unsigned live : 1;
  signed delta : 12;
};

struct __attribute__((packed)) tight {
  char c;
  int n;
  short s;
};

enum colour { RED, GREEN = 7, BLUE };

int punned(float f) {
  union bits u;
  u.f = f;
  return u.i;
}

unsigned low_byte(int i) {
  union bits u;
  u.i = i;
  return u.b[0];
}

unsigned get_kind(struct flags f) { return f.kind; }

int get_delta(struct flags f) { return f.delta; }

struct flags set_live(struct flags f, bool on) {
  f.live = on;
  return f;
}

int tight_n(const struct tight *t) { return t->n; }

short tight_s(const struct tight *t) { return t->s; }

enum colour next_colour(enum colour c) {
  return c == BLUE ? RED : (enum colour)(c + 1);
}

bool truthy(int n) { return n != 0; }
