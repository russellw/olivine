/* Drives test/ll/swap.ll for tools/check-behaviour.sh. */
#include <stdio.h>
int rotate(int, int, int);
int main(void) {
  for (int n = 0; n <= 8; n++) printf("%d ", rotate(11, 22, n));
  printf("\n");
  return 0;
}
