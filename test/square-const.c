#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>

uint64_t square(uint64_t n) { return n * n; }

int main(int argc, char **argv) {
  printf("%" PRIu64 "\n", square(9));
  return 0;
}
