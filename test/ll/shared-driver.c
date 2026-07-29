/* Drives test/ll/shared.ll for tools/check-behaviour.sh. */
#include <stdio.h>

int counted(void);
int reloaded(int *);
int stale(int);
int subscripted(int *, long, int);
int separate(void);

int main(void) {
  /* Called twice, so a shared call shows up as a sum that stopped growing. */
  printf("%d %d\n", counted(), counted());

  int cell = 5;
  printf("%d %d\n", reloaded(&cell), cell);

  for (int n = 0; n <= 4; n++) printf("%d ", stale(n));
  printf("\n");

  int grid[8] = {0, 1, 2, 3, 4, 5, 6, 7};
  printf("%d %d\n", subscripted(grid, 0, 1), subscripted(grid, 1, 0));

  printf("%d\n", separate());
  return 0;
}
