/* Narrow types and pointers promised not to overlap: two things the corpus
   has not contained.  trunc appears twice in the whole of the rest of it, and
   restrict not at all, so what a pass says about either has never been
   measured on anything.

   What restrict means here is that the parameter arrives with noalias on it,
   which is a promise about two pointers that nothing in the function body
   says.  Where the same loop is written without it the promise is not there
   and the accesses have to be taken for accesses to the same storage; both
   forms are below, so the difference is a difference between two functions in
   one file rather than between one file and another. */

/* A read and a write through pointers that do not overlap.  What the promise
   buys is that the write does not change what the next read answers, so the
   read of the scale need not happen again every time round. */
void scale_apart(int *restrict out, const int *restrict in, int n,
                 const int *restrict k) {
  for (int i = 0; i < n; i++) out[i] = in[i] * *k;
}

/* The same loop with no promise, where the write may be to the scale itself
   and the read has to stay in the loop.  The driver calls it both ways. */
void scale_together(int *out, const int *in, int n, const int *k) {
  for (int i = 0; i < n; i++) out[i] = in[i] * *k;
}

/* Bytes read and widened, which is a zext per element and the shape a checksum
   over anything takes. */
unsigned checksum(const unsigned char *p, int n) {
  unsigned total = 0;
  for (int i = 0; i < n; i++) total = total * 31u + p[i];
  return total;
}

/* Signed bytes, so the widening is a sext and the arithmetic happens at the
   wide type the language promotes to. */
int span(const signed char *p, int n) {
  int low = 127, high = -128;
  for (int i = 0; i < n; i++) {
    if (p[i] < low) low = p[i];
    if (p[i] > high) high = p[i];
  }
  return high - low;
}

/* Down to a byte and back up, which is a trunc and a zext with nothing in
   between that changes the bits: the pair is what a mask at the narrow width
   comes to. */
unsigned char low_bits(unsigned x) { return (unsigned char)(x >> 3); }

/* Two narrowings of the same value, and arithmetic at the narrow width that
   wraps where the wide would not. */
short folded_down(int a, int b) {
  short x = (short)a;
  short y = (short)b;
  return (short)(x * y + x);
}

/* A byte at a time until a zero, which is the loop every string function in C
   is: a load, a compare against zero, and no count to bound it. */
int length(const char *s) {
  int n = 0;
  while (s[n]) n++;
  return n;
}

/* And the same walk writing as it goes, through pointers promised apart.  A
   store of a byte read from elsewhere is where the widening disappears again:
   what is loaded at i8 is stored at i8. */
void copy_bytes(char *restrict dst, const char *restrict src) {
  while ((*dst++ = *src++));
}
