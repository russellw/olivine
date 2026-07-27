/* Drives test/ll/unused.ll for tools/check-behaviour.sh. */
#include <stdio.h>
int run(int);
int main(void) {
  for (int x = 0; x < 4; x++) printf("%d ", run(x));
  printf("\n");
  return 0;
}
