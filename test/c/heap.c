/* Buffers a function allocates for itself, which is where a C program keeps
   almost everything and which nothing else in the corpus reads twice.  A slot
   is an alloca and a field of a handed-in struct is measured from a parameter,
   and both were pointers the aliasing could place; a buffer out of malloc is
   neither, so every access to one was an access to somewhere unknown and no
   two of them were ever the same place or different places.

   Two things say what such a local holds, and they are worth keeping apart.
   It is assigned in one place, so it holds one address wherever it is read and
   two accesses written as steps from it are that far apart — which is what a
   parameter says too, and says nothing about where the buffer is.  And the
   noalias on malloc's result says the buffer is nothing else the caller can
   reach, which makes it an object: apart from another buffer, from a slot of
   this frame, and from anything handed in.  What is still unknown is whether a
   stranger can reach it, and the functions below that must keep reloading are
   the ones that turn on that. */

#include <stdlib.h>

/* Defined by the driver, which points it at a buffer one of these hands over,
   so that a call really does change what a pointer reads. */
void sink(void);
extern int *watched_heap;

/* Two elements written and read straight back.  Nothing writes anything the
   reads could be, so both are answered by the stores above them and the buffer
   is written and never read. */
int filled_then_read(int n) {
  int *p = malloc(4 * sizeof(int));
  p[0] = n;
  p[1] = n + 1;
  int s = p[0] + p[1];
  free(p);
  return s;
}

/* The read is of the element the store above did not write.  Which element a
   step reaches is what the layout measures, exactly as it does for two fields
   of a struct, so this one is answered by the store two lines above it. */
int other_element(int n) {
  int *p = malloc(4 * sizeof(int));
  p[0] = n;
  p[1] = n + 1;
  p[2] = 0;
  int s = p[0];
  free(p);
  return s;
}

/* And the same with a variable index, which says nothing about where in the
   buffer it lands: the store may be the store to the element being read, so
   the read has to happen. */
int somewhere_in_it(int n, int i) {
  int *p = malloc(4 * sizeof(int));
  p[0] = n;
  p[i & 3] = 0;
  int s = p[0];
  free(p);
  return s;
}

/* Two buffers, told apart by the noalias on malloc's result: each call
   promises the pointer it hands back reaches nothing reachable otherwise, and
   the other call's buffer is reachable when the second promise is made.  So
   both reads are answered by the stores above them. */
int two_buffers(int n) {
  int *p = malloc(4 * sizeof(int));
  int *q = malloc(4 * sizeof(int));
  p[0] = n;
  q[0] = n + 1;
  int s = p[0] + q[0];
  free(p);
  free(q);
  return s;
}

/* A pointer this function was handed is a pointer the caller holds, and the
   promise is that what malloc returned is not one of those.  So the write
   between the stores and the read is a write to somewhere else, and the read
   is answered.  This is the one the promise buys that the distance between two
   accesses never could. */
int through_a_parameter(int *q, int n) {
  int *p = malloc(4 * sizeof(int));
  p[0] = n;
  *q = 0;
  int s = p[0];
  free(p);
  return s;
}

/* The address went into a global before the call, so the callee has a way to
   name the buffer and the second read has to happen.  The driver's sink()
   writes through that global, which is what makes a read that did not happen
   show up in what the program prints. */
int around_a_call(int n) {
  int *p = malloc(4 * sizeof(int));
  p[0] = n;
  watched_heap = p;
  sink();
  int s = p[0];
  watched_heap = 0;
  free(p);
  return s;
}

/* A buffer allocated again each time round the loop is a new one each time, so
   what the last turn left in it is not what this one finds there.  The reads
   within one turn are still answered by the stores above them. */
int allocated_each_turn(int n) {
  int s = 0;
  for (int i = 0; i < n; i++) {
    int *p = malloc(4 * sizeof(int));
    p[0] = i;
    p[1] = s;
    s += p[0] + p[1];
    free(p);
  }
  return s;
}

/* One buffer walked by a loop that reads back what it wrote a turn ago.  The
   address is a step from a local the loop assigns, so no fact about it crosses
   the back edge, and what makes the sum right is that the load below the store
   is answered while the one carrying the previous turn's value is not. */
int carried_along(int n) {
  int *p = malloc(16 * sizeof(int));
  p[0] = 1;
  for (int i = 1; i < n && i < 16; i++) {
    p[i] = p[i - 1] + i;
  }
  int s = 0;
  for (int i = 0; i < n && i < 16; i++) s += p[i];
  free(p);
  return s;
}
