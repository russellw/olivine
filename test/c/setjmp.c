/* The one call in C that comes back more than once.
 *
 * setjmp saves the frame it is called in and longjmp restores it, so control
 * arrives at the same call a second time with the frame as the longjmp left
 * it.  What C promises about that is scoped to the function holding the call:
 * its own local variables have indeterminate values afterwards unless they are
 * volatile, and nobody else's are mentioned.  That is why a body holding a
 * setjmp may not be copied into a caller — see Olivine.Core.Pass.Inline — and
 * why every local read after the second return here is volatile.
 *
 * Everything below is written to the letter of the rule about where a call to
 * setjmp may appear: the whole controlling expression of an if, compared
 * against a constant.  Assigning its result to a variable is undefined even
 * though every compiler accepts it, and a corpus source that did would be
 * measuring the wrong thing.
 */
#include <setjmp.h>

static jmp_buf env;

/* Not a local, so no longjmp can rewind it: this counts second returns across
 * the whole run. */
int landings;

/* Small enough that every other rule in the inliner would let it be copied
 * into its caller — no locals at all, so nothing here is under the second
 * return's rule and nothing needs to be volatile.  What keeps it where it is
 * is the setjmp and nothing else, which is what makes it the case worth
 * having: at any larger size the size threshold would be what refused it and
 * the file would prove nothing. */
static int guarded(int n)
{
    if (setjmp(env) != 0)
        return -1;
    if (n > 2)
        longjmp(env, 1);
    return n;
}

/* The caller whose locals the rule protects.  It does not hold the setjmp, so
 * total and i are ordinary locals a compiler may keep wherever it likes;
 * copying guarded in here would put them under a rule they were never
 * compiled for. */
int over(const int *xs, int n)
{
    int total = 0;
    for (int i = 0; i < n; i++) {
        int got = guarded(xs[i]);
        if (got < 0)
            landings++;
        total += got;
    }
    return total;
}

static int twice(int n)
{
    return n + n;
}

/* Inlining into a function that calls setjmp is allowed, and this is where
 * that is exercised: twice belongs in the body, the body stays where it is. */
int with_helper(int n)
{
    volatile int out = 0;
    if (setjmp(env) != 0)
        return out;
    out = twice(n);
    if (out > 8)
        longjmp(env, 1);
    return out + 100;
}

/* The setjmp and the longjmp in one function, so the second return is reached
 * without anything having to be copied anywhere. */
int depth(int n)
{
    volatile int steps = 0;
    if (setjmp(env) == 0) {
        while (steps < n) {
            steps = steps + 1;
            if (steps == 3)
                longjmp(env, 1);
        }
    }
    return steps;
}
