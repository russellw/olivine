/* Exception handling: the constructs a C++ front end emits and a C one never
   does.  Everything here is extern "C" so that the corpus driver, which is C,
   can call it.

   What each function is for: a cleanup that has to run whichever way control
   leaves, a handler that catches a value and one that catches everything, a
   handler that throws the exception on again, and a loop with a try in it so
   that an invoke stands in a loop body. */

extern "C" {
extern int cleanups_run;
int caught_value(int x);
int caught_anything(int x);
int cleanup_on_both(int x);
int passed_on(int x);
int summed(const int *values, int count);
}

int cleanups_run;

/* An object whose destructor is a side effect, so that a cleanup that does not
   run is visible in what the driver prints rather than only in the IR. */
struct Tracker {
  Tracker() {}
  ~Tracker() { cleanups_run += 1; }
};

/* Kept out of line so that the call is a call: a front end inlines nothing at
   -O0, but -O1 and -O2 would fold the whole thing away if it could see the
   throw is never reached. */
static int may_throw(int x) {
  if (x < 0)
    throw x;
  return x * 2;
}

extern "C" int caught_value(int x) {
  try {
    return may_throw(x);
  } catch (int e) {
    return e - 1;
  }
}

extern "C" int caught_anything(int x) {
  try {
    return may_throw(x);
  } catch (...) {
    return -1;
  }
}

/* The destructor runs on the way out and on the way through, which is the
   shape that makes a landing pad a cleanup rather than a catch. */
extern "C" int cleanup_on_both(int x) {
  try {
    Tracker t;
    return may_throw(x);
  } catch (int e) {
    return e;
  }
}

/* Caught and thrown again, which is what a resume is written for. */
static int rethrowing(int x) {
  try {
    Tracker t;
    return may_throw(x);
  } catch (...) {
    throw;
  }
}

extern "C" int passed_on(int x) {
  try {
    return rethrowing(x);
  } catch (int e) {
    return e * 3;
  }
}

/* An invoke in a loop body, and a value carried round the loop past it. */
extern "C" int summed(const int *values, int count) {
  int total = 0;
  for (int i = 0; i < count; i++) {
    try {
      total += may_throw(values[i]);
    } catch (int e) {
      total -= e;
    }
  }
  return total;
}
