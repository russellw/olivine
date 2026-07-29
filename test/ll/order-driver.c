/* Drives test/ll/order.ll for tools/check-behaviour.sh. */
#include <stdio.h>
int accumulate(int);
int main(void) {
  for (int n = 0; n <= 8; n++) printf("%d ", accumulate(n));
  printf("\n");
  return 0;
}
