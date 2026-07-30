/* Drives test/ll/fold.ll for tools/check-behaviour.sh. */
#include <stdio.h>
int arithmetic(void); int bitwise(void); int wrapping(void);
int comparisons(void); long conversions(void); int chosen(void);
int identities(int); int reflexive(int); int chains(int);
int masked(int); int carried(int);
int bitfield(int); long unmasked(int);
int main(void) {
  printf("%d %d %d %d %ld %d\n", arithmetic(), bitwise(), wrapping(),
         comparisons(), conversions(), chosen());
  printf("%d %d %d %d %d\n", identities(7), reflexive(-3), chains(0x1234abcd),
         masked(0x1234abcd), carried(5));
  printf("%d %ld\n", bitfield(0x1234abcd), unmasked(0x1234abcd));
  return 0;
}
