/* Operand bundles, which nothing in the corpus had held at any level.  A
   bundle is what a call carries beside its arguments — written after the
   attributes, between brackets — and the one clang emits without being asked
   for it is the alignment behind __builtin_assume_aligned:

     call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 16) ]

   That line appears at every level including -O0, and while it was unread it
   took the whole function with it: the probe this file was written from came
   back byte for byte as clang wrote it, loop, allocas and all.

   Both spellings of the same construct are here, since __builtin_assume
   writes an assumption with no bundle on it and is the control: where the two
   differ, what made the difference is the bundle and not the call. */

#include <stdlib.h>

/* A loop over a pointer promised aligned.  Everything worth doing to it —
   promoting the slots, rotating the loop, keeping the count in a local — has
   nothing to do with the assumption, which is the point: the bundle stands in
   the entry block and the rest of the function is ordinary. */
int sum_aligned(const int *p, int n) {
  const int *q = (const int *)__builtin_assume_aligned(p, 16);
  int total = 0;
  for (int i = 0; i < n; i++) total += q[i];
  return total;
}

/* The same loop with nothing promised, so the two can be read side by side. */
int sum_plain(const int *p, int n) {
  int total = 0;
  for (int i = 0; i < n; i++) total += p[i];
  return total;
}

/* An assumption made every time round rather than once at the top, which puts
   the bundled call in the body where the passes are working. */
int sum_each(const int *p, int n) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    const int *q = (const int *)__builtin_assume_aligned(p + i, 4);
    total += *q;
  }
  return total;
}

/* A promise about a pointer that is written through, so the bundle names
   storage the loop stores to and not only storage it reads. */
void scale_aligned(int *out, const int *in, int n, int k) {
  int *o = (int *)__builtin_assume_aligned(out, 16);
  const int *i2 = (const int *)__builtin_assume_aligned(in, 16);
  for (int i = 0; i < n; i++) o[i] = i2[i] * k;
}

/* Two promises about two pointers, which is two bundled calls in one entry
   block, and a use of both afterwards. */
int dot_aligned(const int *a, const int *b, int n) {
  const int *x = (const int *)__builtin_assume_aligned(a, 16);
  const int *y = (const int *)__builtin_assume_aligned(b, 16);
  int total = 0;
  for (int i = 0; i < n; i++) total += x[i] * y[i];
  return total;
}

/* An assumption with no bundle: __builtin_assume writes the same intrinsic
   with the condition as an ordinary argument.  The control for all of the
   above. */
int halved(int x) {
  __builtin_assume(x > 0);
  return x / 2;
}

/* An aligned pointer handed to another function, so the promise is made in one
   frame and the storage used in another. */
int through_call(const int *p, int n) {
  const int *q = (const int *)__builtin_assume_aligned(p, 16);
  return sum_plain(q, n) + sum_aligned(q, n);
}

/* Storage this function allocates and promises about, rather than one handed
   in: the assumption is about an address the function computed. */
int local_aligned(int n) {
  int *p = (int *)aligned_alloc(16, 64 * sizeof(int));
  if (!p) return 0;
  int *q = (int *)__builtin_assume_aligned(p, 16);
  for (int i = 0; i < 64; i++) q[i] = i * n;
  int total = 0;
  for (int i = 0; i < 64; i++) total += q[i];
  free(p);
  return total;
}
