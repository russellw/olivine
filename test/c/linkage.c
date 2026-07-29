/* Linkage, visibility and symbol forms the rest of the corpus does not
   produce: a weak definition, an alias, a tentative definition, and a symbol
   kept alive by nothing but an attribute.  Dead symbol elimination has to read
   all of them, and an alias is the awkward one — a symbol whose definition is
   a reference to another symbol, so removing what it names would leave it
   naming nothing. */

/* A tentative definition, which becomes a common symbol. */
int tentative;

__attribute__((weak)) int weak_count = 3;

int real_answer(void) { return 42; }

/* Not a call to real_answer but another name for it. */
int aliased_answer(void) __attribute__((alias("real_answer")));

__attribute__((visibility("hidden"))) int hidden_helper(int x) { return x + 1; }

/* Reached from nowhere in this file: the attribute is the whole reason it
   survives. */
__attribute__((used)) static int kept_by_attribute(int x) { return x * 3; }

__attribute__((used)) static const char version[] = "olivine 0.1";

__attribute__((noinline)) int never_inlined(int x) { return x ^ 0x5a; }

int uses_them(int x) {
  return hidden_helper(x) + never_inlined(x) + weak_count + tentative;
}
