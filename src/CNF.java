import java.util.*;

public final class CNF {
  private static final int MANY = 50;
  private final List<Object> defs = new ArrayList<>();
  private final List<Object> negative = new ArrayList<>();
  private final List<Object> positive = new ArrayList<>();
  final List<Clause> clauses = new ArrayList<>();

  // How many clauses a term will expand into, for the purpose of deciding when subformulas need to
  // be renamed. The answer could
  // exceed the range of a fixed-size integer, but then we don't actually need the number, we only
  // need to know whether it went over
  // the threshold.
  private static int clauseCountAdd(boolean pol, Term a) {
    var n = 0;
    for (var b : a.args) {
      n += clauseCount(pol, b);
      if (n >= MANY) return MANY;
    }
    return n;
  }

  private static int clauseCountMultiply(boolean pol, Term a) {
    var n = 1;
    for (var b : a.args) {
      n *= clauseCount(pol, b);
      if (n >= MANY) return MANY;
    }
    return n;
  }

  private static int clauseCount(boolean pol, Object a) {
    return switch (a) {
      case Quantifier a1 -> clauseCount(pol, a1.body);
      case Not a1 -> clauseCount(!pol, a1.args[0]);
      case Or a1 -> pol ? clauseCountMultiply(true, a1) : clauseCountAdd(false, a1);
      case And a1 -> pol ? clauseCountAdd(true, a1) : clauseCountMultiply(false, a1);
      case Eqv a1 -> {
        var x = a1.args[0];
        var y = a1.args[1];

        // Recur twice into each argument. This would cause a problem of exponential blowup in the
        // time taken to calculate the
        // number of clauses that would be generated by nested equivalences. We solve this problem
        // by returning early if the number
        // is becoming large.
        int n;
        if (pol) {
          n = clauseCount(false, x) * clauseCount(true, y);
          if (n >= MANY) yield MANY;
          n += clauseCount(true, x) * clauseCount(false, y);
        } else {
          n = clauseCount(false, x) * clauseCount(false, y);
          if (n >= MANY) yield MANY;
          n += clauseCount(true, x) * clauseCount(true, y);
        }
        yield Math.min(n, MANY);
      }
      default -> 1;
    };
  }

  // The function to calculate the number of clauses generated by a formula in a positive or
  // negative context, returns a
  // mathematically defined result (up to a ceiling). However, when it comes to actually trying to
  // rename formulas, we may be dealing
  // with both positive and negative contexts. In particular, this may happen in nested
  // equivalences, where the total number of
  // formulas cannot be calculated without the full context, but would in any case be unreasonably
  // large, so it is neither feasible
  // nor necessary to calculate the number. What we actually need to do is make a heuristic
  // decision. To that end, if we have a
  // context that is both positive and negative, we add the two values for the number of clauses;
  // this doesn't have a clear
  // mathematical justification, but seems as reasonable as anything else, and simple enough that
  // there are hopefully few ways it can
  // go wrong.
  private static int clauseCountApprox(int pol, Object a) {
    var n = 0;
    if (pol >= 0) n += clauseCount(true, a);
    if (pol <= 0) n += clauseCount(false, a);
    return n;
  }

  // Skolem functions replace existentially quantified variables, also formulas that are renamed to
  // avoid exponential expansion.
  private static Object skolem(Type rtype, Collection<?> args) {
    if (args.isEmpty()) return new Fn(rtype, null);
    var params = new Variable[args.size()];
    var i = 0;
    for (var a : args) params[i++] = new Variable(Type.of(a));
    return new Call(new Fn(rtype, null, params), args.toArray());
  }

  // Rename formulas to avoid exponential expansion. It's tricky to do this while in the middle of
  // doing other things, easier to
  // be sure of the logic if it's done as a separate pass first.
  private Object rename(int pol, Object a) {
    var b = skolem(Type.of(a), Variable.freeVariables(a));
    if (pol > 0)
      // If this formula is only being used with positive polarity, the new name only needs to imply
      // the original formula.
      a = Term.implies(b, a);
    else if (pol < 0)
      // And the reverse for negative polarity.
      a = Term.implies(a, b);
    else
      // In the general case, full equivalence is needed; the new name implies and is implied by the
      // original formula.
      a = new And(Term.implies(b, a), Term.implies(a, b));
    defs.add(All.quantify(a));
    return b;
  }

  // Maybe rename some of the arguments to an OR-over-AND (taking polarity into account), where the
  // number of clauses generated
  // would be the product of the arguments.
  private void maybeRenames(int pol, Object[] v) {
    // Sorting the arguments doesn't change the meaning of the formula, because AND and OR are
    // commutative. The effect is that
    // if only some of them are to be renamed, we will leave the simple ones alone and end up
    // renaming the complicated ones,
    // which is probably what we want.
    Arrays.sort(v, Comparator.comparingInt(a -> clauseCountApprox(pol, a)));
    var n = 1;
    for (var i = 0; i < v.length; i++) {
      var m = clauseCountApprox(pol, v[i]);
      if (n * m < MANY) {
        n *= m;
        continue;
      }
      v[i] = rename(pol, v[i]);
    }
  }

  // Given a formula, and whether it is used for positive polarity, negative or both (i.e. under an
  // equivalence), maybe rename
  // some of its subformulas. If a subformula occurs many times (whether under the same formula, or
  // different ones), it is
  // considered in isolation each time, so that each occurrence could end up with a different name.
  // In principle, it would be more
  // efficient (in terms of simplicity of the resulting clauses) to rename on a global basis, but in
  // practice, nontrivial subformulas are rarely duplicated (e.g. less than 1% of
  // the nontrivial formulas in the TPTP), so this is probably not worth doing (in terms of code
  // complexity
  // and of the memory traffic for the extra iteration through the formula set)
  private Object maybeRename(int pol, Object a) {
    return switch (a) {
      case All a1 -> new All(a1.variables, maybeRename(pol, a1.body));
      case Exists a1 -> new Exists(a1.variables, maybeRename(pol, a1.body));
      case Not a1 -> new Not(maybeRename(-pol, a1.args[0]));
      case Or a1 -> {
        var v = new Object[a1.args.length];
        for (var i = 0; i < v.length; i++) v[i] = maybeRename(pol, a1.args[i]);

        // If this formula will be used with positive polarity (including the case where it will be
        // used both ways), we are
        // looking at OR over possible ANDs, which would produce exponential expansion at the
        // distribution stage, so may need to
        // rename some arguments.
        if (pol >= 0) maybeRenames(pol, v);
        yield new Or(v);
      }
      case And a1 -> {
        var v = new Object[a1.args.length];
        for (var i = 0; i < v.length; i++) v[i] = maybeRename(pol, a1.args[i]);

        // NOT-AND yields OR, so mirror the OR case.
        if (pol <= 0) maybeRenames(pol, v);
        yield new And(v);
      }
      case Eqv a1 -> {
        var x = maybeRename(0, a1.args[0]);
        var y = maybeRename(0, a1.args[1]);
        if (clauseCountApprox(0, x) >= MANY) x = rename(0, x);
        if (clauseCountApprox(0, y) >= MANY) y = rename(0, y);
        yield new Eqv(x, y);
      }
      default -> a;
    };
  }

  // For-all doesn't need much work to convert. Clauses contain variables with implied for-all. The
  // tricky part is that quantifier
  // binds variables to local scope, so the same variable name used in two for-all's corresponds to
  // two different logical
  // variables. So we rename each quantified variable to a new variable of the same type.
  private Map<Variable, Object> all(Map<Variable, Object> map, Quantifier a) {
    map = new LinkedHashMap<>(map);
    for (var x : a.variables) {
      var y = new Variable(x.type);
      map.put(x, y);
    }
    return map;
  }

  // Each existentially quantified variable is replaced with a Skolem function whose parameters are
  // all the surrounding
  // universally quantified variables.
  private Map<Variable, Object> exists(Map<Variable, Object> map, Quantifier a) {
    // Get the surrounding universally quantified variables that will be arguments to the Skolem
    // functions.
    var args = new ArrayList<>();
    for (var x : map.values()) if (x instanceof Variable) args.add(x);

    // Make a replacement for each existentially quantified variable.
    map = new LinkedHashMap<>(map);
    for (var x : a.variables) {
      var y = skolem(x.type, args);
      map.put(x, y);
    }
    return map;
  }

  // Negation normal form consists of several transformations that are as easy to do at the same
  // time: Move NOTs inward to the
  // literal layer, flipping things around on the way, while simultaneously resolving quantifiers.
  private Object[] nnf1(Map<Variable, Object> map, boolean pol, Term a) {
    var v = new Object[a.args.length];
    for (var i = 0; i < v.length; i++) v[i] = nnf(map, pol, a.args[i]);
    return v;
  }

  private Object nnf(Map<Variable, Object> map, boolean pol, Object a) {
    return switch (a) {
      case Boolean a1 -> pol == a1;
      case And a1 -> {
        var v = nnf1(map, pol, a1);
        yield pol ? new And(v) : new Or(v);
      }
      case Or a1 -> {
        var v = nnf1(map, pol, a1);
        yield pol ? new Or(v) : new And(v);
      }
      case Not a1 -> nnf(map, !pol, a1.args[0]);
      case Variable ignored -> {
        var aval = map.get(a);
        assert aval != null;
        yield aval;
      }
      case All a1 -> nnf(pol ? all(map, a1) : exists(map, a1), pol, a1.body);
      case Exists a1 -> nnf(pol ? exists(map, a1) : all(map, a1), pol, a1.body);
      case Eqv a1 -> {
        var x = a1.args[0];
        var y = a1.args[1];
        var x0 = nnf(map, false, x);
        var x1 = nnf(map, true, x);
        var y0 = nnf(map, false, y);
        var y1 = nnf(map, true, y);

        // x <=> y means x => y & y => x. We could just construct the conjunction of implications
        // and recur on the NNF of that.
        // However, in case it needs to be negated first, that would turn into OR over AND, which
        // would go through distribute
        // generating four clauses, of which two would then be discarded as tautologies.
        // performance is improved by doing that translation in the code here
        yield pol
            ? new And(new Or(x0, y1), new Or(x1, y0))
            : new And(new Or(x0, y0), new Or(x1, y1));
      }
      default -> {
        // none of the above apply, so at first glance we are looking at a term that has no special
        // significance to NNF,
        // and it suffices to ground out the procedure by translating negative polarity to a NOT.
        // but
        // there is one last thing to deal with:
        // this could be a nested expression that contains variables, perhaps several levels deep,
        // that
        // need to be translated.
        // So we need to recur again, down to atomic terms, looking for variables to translate. at
        // the
        // same time, we need to keep
        // the polarity at the predicate layer, to put a NOT (when necessary) in the right place. So
        // the
        // recursive calls
        // are all made with positive polarity.
        a =
            Term.mapLeaves(
                b -> {
                  if (b instanceof Variable) {
                    b = map.get(b);
                    assert b != null;
                  }
                  return b;
                },
                a);
        yield pol ? a : new Not(a);
      }
    };
  }

  // AND is associative, so several layers thereof are equivalent to a single layer.
  // For distribution of OR, it is useful to do this
  private static void flattenAnd(Object a, List<Object> v) {
    if (a instanceof And a1) {
      for (var b : a1.args) flattenAnd(b, v);
      return;
    }
    v.add(a);
  }

  // Distribute OR down into AND, completing the layering of the operators for CNF. This is the
  // second place where exponential
  // expansion would occur, had selected formulas not already been renamed.
  private Object distribute(Object a) {
    return switch (a) {
      case And a1 -> {
        var v = new Object[a1.args.length];
        for (var i = 0; i < v.length; i++) v[i] = distribute(a1.args[i]);
        yield new And(v);
      }
      case Or a1 -> {
        // Flat layer of ANDs
        var ands = new ArrayList<List<Object>>(a1.args.length);
        for (var b : a1.args) {
          b = distribute(b);
          var v = new ArrayList<>();
          flattenAnd(b, v);
          ands.add(v);
        }

        // OR distributes over AND by Cartesian product.
        var ors = Etc.cartesianProduct(ands);
        var and = new Object[ors.size()];
        for (var i = 0; i < and.length; i++) and[i] = new Or(ors.get(i).toArray());
        yield new And(and);
      }
      default -> a;
    };
  }

  // Convert a suitably rearranged term into actual clauses.
  private void literals(Object a) {
    switch (a) {
      case Not a1 -> negative.add(a1.args[0]);
      case Or a1 -> {
        for (var b : a1.args) literals(b);
      }
      default -> positive.add(a);
    }
  }

  private void clausify(Object a) {
    if (a instanceof And a1) {
      for (var b : a1.args) clausify(b);
      return;
    }
    negative.clear();
    positive.clear();
    literals(a);
    // TODO: eliminate duplicate literals here?
    var c = new Clause(negative, positive);
    if (c.isTrue()) return;
    clauses.add(c);
  }

  void add(Object a) {
    // First run the input formula through the full process: Rename subformulas where necessary to
    // avoid exponential expansion,
    // then convert to negation normal form, distribute OR into AND, and convert to clauses.
    defs.clear();
    a = maybeRename(1, a);
    a = nnf(Map.of(), true, a);
    a = distribute(a);
    clausify(a);

    // Then convert all the definitions created by the renaming process. That process works by
    // bottom-up recursion, which means
    // each renamed subformula is simple, so there is no need to put the definitions through the
    // renaming process again; they
    // just need to go through the rest of the conversion steps.
    for (var b : defs) {
      b = nnf(Map.of(), true, b);
      b = distribute(b);
      clausify(b);
    }
  }
}
