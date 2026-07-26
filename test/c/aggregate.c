/* Structs, nested arrays and by-value aggregate returns: the source of the
   pointer arithmetic that Olivine represents one offset at a time. */

struct point {
  int x;
  int y;
};

struct body {
  struct point pos;
  struct point vel;
  double mass;
  char name[8];
};

int get_x(const struct body *b) { return b->pos.x; }

void advance(struct body *b) {
  b->pos.x += b->vel.x;
  b->pos.y += b->vel.y;
}

struct point make(int x, int y) {
  struct point p = {x, y};
  return p;
}

int grid_at(int g[4][8], int i, int j) { return g[i][j]; }

char first_letter(const struct body *b) { return b->name[0]; }
