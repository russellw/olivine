/* Drives test/ll/promote.ll for tools/check-behaviour.sh. */
#include <stdio.h>
int total(int);
int main(void) {
  for (int n = 0; n <= 5; n++) printf("%d ", total(n));
  printf("\n");
  return 0;
}
