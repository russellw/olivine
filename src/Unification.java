import java.util.Map;

final class Unification {
  static boolean match(Object a0, Object b0, Map<Variable, Object> map) {
    // equations would need to be matched both ways, which is handled separately in calling code
    assert !(a0 instanceof Eq);
    assert !(b0 instanceof Eq);

    // fast check for a common case
    if (a0 == b0) return true;

    // Type mismatch
    if (!Type.of(a0).equals(Type.of(b0))) return false;

    // Variable
    if (a0 instanceof Variable a) {
      // Existing mapping
      var a1 = map.get(a);
      if (a1 != null) return Term.eq(a1, b0);

      // New mapping
      map.put(a, b0);
      return true;
    }

    // compound
    if (a0 instanceof Term a && b0 instanceof Term b) {
      if (a.getClass() != b.getClass()) return false;
      if (a instanceof Call a1 && a1.fn != ((Call) b).fn) return false;
      var n = a.size();
      if (n != b.size()) return false;
      for (var i = 0; i < n; i++) if (!match(a.get(i), b.get(i), map)) return false;
      return true;
    }

    // might be e.g. equal integers
    return a0.equals(b0);
  }

  static boolean unify(Object a0, Object b0, Map<Variable, Object> map) {
    // equations would need to be matched both ways, which is handled separately in calling code
    assert !(a0 instanceof Eq);
    assert !(b0 instanceof Eq);

    // fast check for a common case
    if (a0 == b0) return true;

    // Type mismatch
    if (!Type.of(a0).equals(Type.of(b0))) return false;

    // Variable
    if (a0 instanceof Variable a) return unifyVariable(a, b0, map);
    if (b0 instanceof Variable b) return unifyVariable(b, a0, map);

    // compound
    if (a0 instanceof Term a && b0 instanceof Term b) {
      if (a.getClass() != b.getClass()) return false;
      if (a instanceof Call a1 && a1.fn != ((Call) b).fn) return false;
      var n = a.size();
      if (n != b.size()) return false;
      for (var i = 0; i < n; i++) if (!unify(a.get(i), b.get(i), map)) return false;
      return true;
    }

    // might be e.g. equal integers
    return a0.equals(b0);
  }

  private static boolean unifyVariable(Variable a, Object b, Map<Variable, Object> map) {
    // Existing mapping
    var a1 = map.get(a);
    if (a1 != null) return unify(a1, b, map);

    // Variable
    if (b instanceof Variable) {
      var b1 = map.get(b);
      if (b1 != null) return unify(a, b1, map);
    }

    // Occurs check
    if (occurs(a, b, map)) return false;

    // New mapping
    map.put(a, b);
    return true;
  }

  private static boolean occurs(Variable a, Object b0, Map<Variable, Object> map) {
    if (a == b0) return true;
    switch (b0) {
      case Variable b -> {
        var b1 = map.get(b);
        if (b1 != null) return occurs(a, b1, map);
      }
      case Term b -> {
        for (var bi : b) if (occurs(a, bi, map)) return true;
      }
      default -> {}
    }
    return false;
  }
}
