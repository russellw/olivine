/* Drives test/ll/fold.ll for tools/check-behaviour.sh. */
#include <stdio.h>
int arithmetic(void); int bitwise(void); int wrapping(void);
int comparisons(void); long conversions(void); int chosen(void);
int main(void) {
  printf("%d %d %d %d %ld %d\n", arithmetic(), bitwise(), wrapping(),
         comparisons(), conversions(), chosen());
  return 0;
}
