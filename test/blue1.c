struct color {
  float red, green, blue;
};

float *f(struct color *c) { return &c->blue; }

int main() { return 0; }
