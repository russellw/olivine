/* Drives test/ll/dead.ll for tools/check-behaviour.sh. */
#include <stdio.h>
int sift(int, int, int *);
int main(void) {
  int cell = 5;
  for (int a = 1; a <= 4; a++) printf("%d %d ", sift(a, a + 1, &cell), cell);
  printf("\n");
  return 0;
}
