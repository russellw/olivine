import java.util.Map;

public final class Unification {
  static boolean match(Object a, Object b, Map<Variable, Object> map) {
    // equations would need to be matched both ways, which is handled separately in calling code
    assert !(a instanceof Eq);
    assert !(b instanceof Eq);

    // fast check for a common case
    if (a == b) return true;

    // Type mismatch
    if (!Type.of(a).equals(Type.of(b))) return false;

    // Variable
    if (a instanceof Variable a1) {
      // Existing mapping
      var aval = map.get(a1);
      if (aval != null) return Term.eq(aval, b);

      // New mapping
      map.put(a1, b);
      return true;
    }

    // symbols must match
    if (!Term.symbol(a).equals(Term.symbol(b))) return false;

    // and subterms
    var av = Term.args(a);
    var bv = Term.args(b);
    if (av.length != bv.length) return false;
    for (var i = 0; i < av.length; i++) if (!match(av[i], bv[i], map)) return false;
    return true;
  }

  static boolean unify(Object a, Object b, Map<Variable, Object> map) {
    // equations would need to be matched both ways, which is handled separately in calling code
    assert !(a instanceof Eq);
    assert !(b instanceof Eq);

    // fast check for a common case
    if (a == b) return true;

    // Type mismatch
    if (!Type.of(a).equals(Type.of(b))) return false;

    // Variable
    if (a instanceof Variable a1) return unifyVariable(a1, b, map);
    if (b instanceof Variable b1) return unifyVariable(b1, a, map);

    // symbols must match
    if (!Term.symbol(a).equals(Term.symbol(b))) return false;

    // and subterms
    var av = Term.args(a);
    var bv = Term.args(b);
    if (av.length != bv.length) return false;
    for (var i = 0; i < av.length; i++) if (!unify(av[i], bv[i], map)) return false;
    return true;
  }

  private static boolean unifyVariable(Variable a, Object b, Map<Variable, Object> map) {
    // Existing mapping
    var aval = map.get(a);
    if (aval != null) return unify(aval, b, map);

    // Variable
    if (b instanceof Variable) {
      var bval = map.get(b);
      if (bval != null) return unify(a, bval, map);
    }

    // Occurs check
    if (occurs(a, b, map)) return false;

    // New mapping
    map.put(a, b);
    return true;
  }

  private static boolean occurs(Variable a, Object b, Map<Variable, Object> map) {
    if (a == b) return true;
    if (b instanceof Variable) {
      var bval = map.get(b);
      if (bval != null) return occurs(a, bval, map);
    }
    for (var bi : Term.args(b)) if (occurs(a, bi, map)) return true;
    return false;
  }
}
