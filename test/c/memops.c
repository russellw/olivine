/* Library calls that clang turns into intrinsics, plus indirect calls and
   varargs: the declaration forms with the most attribute clutter. */

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

void *duplicate(const void *src, unsigned long n) {
  void *dst = malloc(n);
  if (dst)
    memcpy(dst, src, n);
  return dst;
}

void clear(void *p, unsigned long n) { memset(p, 0, n); }

void release(void *p) { free(p); }

int apply(int (*f)(int), int x) { return f(x); }

int total(int count, ...) {
  va_list ap;
  va_start(ap, count);
  int sum = 0;
  for (int i = 0; i < count; i++)
    sum += va_arg(ap, int);
  va_end(ap);
  return sum;
}
