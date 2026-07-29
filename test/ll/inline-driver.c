/* Drives test/ll/inline.ll for tools/check-behaviour.sh.
 *
 * @sink is left undefined by the module so that the slot @through_slot passes
 * to it is one promotion may not take, and so is still there for inlining to
 * move.  Writing through the pointer is what makes that observable. */
#include <stdio.h>
int run(int);
void sink(int *p) { *p += 1; }
int main(void) {
  for (int n = 0; n <= 6; n++) printf("%d ", run(n));
  printf("\n");
  return 0;
}
