/* Inline assembly: the instruction a C program cannot say, written where a
   call would stand.
 *
 * What this is here for is not that assembly gets optimized — nothing knows
 * what a template does, so nothing can.  It is that a function holding one
 * still gets optimized around it: before this was read, an `asm` line was an
 * unmodelled line, and an unmodelled line costs the whole function.  Every
 * slot below stayed in memory and every loop stayed as clang -O0 wrote it.
 *
 * The templates are x86-64, as the rest of the corpus already is by its data
 * layout.  They are kept to the two shapes that carry no instruction at all —
 * the empty template with a memory clobber, and the empty template tying a
 * value to a register — plus one real instruction, so that what is checked is
 * the optimizer and not the assembler.  */

/* An operand goes in and a result comes out, and nothing else happens: no
   `volatile`, no clobber.  The locals around it are ordinary and must be
   promoted; the assembly may not be. */
int swapped(int x) {
  int y;
  __asm__("bswapl %0" : "=r"(y) : "0"(x));
  return y;
}

/* Twice over the same operand.  Two runs of one template are two runs: what a
   register holds after the first is not what the second is handed, so nothing
   may share them however alike the lines. */
int swapped_twice(int x) {
  int a, b;
  __asm__("bswapl %0" : "=r"(a) : "0"(x));
  __asm__("bswapl %0" : "=r"(b) : "0"(a));
  return a + b;
}

/* The barrier every benchmark writes: it says memory changed without saying
   what, so a load before it does not answer a load after it. */
int reread(int *p) {
  int first = *p;
  __asm__ __volatile__("" ::: "memory");
  int second = *p;
  return first * 100 + second;
}

/* The same question asked of a loop.  Nothing here may be hoisted: the scale
   is read once an iteration because the barrier says it might have changed. */
int barrier_sum(const int *p, int n, const int *scale) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    total += p[i] * *scale;
    __asm__ __volatile__("" ::: "memory");
  }
  return total;
}

/* A local whose address the assembly is handed.  It escapes, and the slot has
   to stay in memory. */
int through_slot(int x) {
  int held = x;
  __asm__ __volatile__("addl $7, %0" : "+m"(held));
  return held;
}

/* The idiom that hides a value from the optimizer, in a function that has
   plenty else to fold.  What must survive is the assembly and the reads
   around it; the arithmetic on either side is ordinary. */
int hidden(int a, int b) {
  int s = (a + b) * 2;
  __asm__("" : "+r"(s));
  return s + s * 0 + (b - b);
}

/* Assembly that says it does nothing beyond what its constraints describe,
   standing in a loop whose operands do not change.  It stays where it is:
   asked directly, LLVM's own LICM declines to hoist one, early CSE declines
   to share two identical ones, and DCE declines to drop one nothing reads.
   Clang -O2 gets four instructions fewer here all the same, and not by moving
   it — indvars puts a closed form in for the sum, the loop is then dead, and
   the single remaining run of the assembly is left in the block that guarded
   it.  That is arithmetic Olivine does not do, and no reason to treat
   assembly as anything but a call. */
int each_time(int x, int n) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    int y;
    __asm__("bswapl %0" : "=r"(y) : "0"(x));
    total += y >> 24;
  }
  return total;
}

/* A slot the assembly never sees, in the same function as one it does: the
   first must promote although the second cannot. */
int both_kinds(int x) {
  int free_ = x * 3;
  int held = x;
  __asm__ __volatile__("addl $1, %0" : "+m"(held));
  return free_ + held;
}
