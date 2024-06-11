#include <stdio.h>

int a[100];
int *b = a + 30;

int main() {
  printf("%zu\n", b - a);
  return 0;
}
