struct color {
  float red, green, blue;
};

struct colors {
  struct color foreground;
  struct color background;
};

float *f(struct colors *c) { return &c->background.blue; }

int main() { return 0; }
