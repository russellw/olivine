import java.util.*;

public final class Subsumption {
  // Time limit
  private int steps;

  private Map<Variable, Object> search(
      Map<Variable, Object> map, Object[] c, Object[] c2, Object[] d, Object[] d2) {
    if (steps-- == 0) throw new Fail();

    // Matched everything in one polarity
    if (c.length == 0) {
      // Already matched everything in the other polarity
      if (c2 == null) return map;

      // Try the other polarity
      return search(map, c2, null, d2, null);
    }

    // Try matching literals
    for (var ci = 0; ci < c.length; ci++) {
      Object[] c1 = null;
      var ce = new Equation(c[ci]);
      for (var di = 0; di < d.length; di++) {
        Object[] d1 = null;
        var de = new Equation(d[di]);

        // Search means preserve the original map
        // in case the search fails
        // and need to backtrack
        Map<Variable, Object> m;

        // Try orienting equation one way
        m = new HashMap<>(map);
        if (Unification.match(ce.left, de.left, m) && Unification.match(ce.right, de.right, m)) {
          if (c1 == null) c1 = Etc.remove(c, ci);
          d1 = Etc.remove(d, di);
          m = search(m, c1, c2, d1, d2);
          if (m != null) return m;
        }

        // And the other way
        m = new HashMap<>(map);
        if (Unification.match(ce.left, de.right, m) && Unification.match(ce.right, de.left, m)) {
          if (c1 == null) c1 = Etc.remove(c, ci);
          if (d1 == null) d1 = Etc.remove(d, di);
          m = search(m, c1, c2, d1, d2);
          if (m != null) return m;
        }
      }
    }

    // No match
    return null;
  }

  boolean subsumes(Clause c, Clause d) {
    assert Collections.disjoint(c.freeVariables(), d.freeVariables());

    // Negative and positive literals must subsume separately
    var c1 = c.negative();
    var c2 = c.positive();
    var d1 = d.negative();
    var d2 = d.positive();

    // Fewer literals typically fail faster
    if (c2.length < c1.length) {
      // Swap negative and positive
      var ct = c1;
      c1 = c2;
      c2 = ct;

      // And in the other clause
      var dt = d1;
      d1 = d2;
      d2 = dt;
    }

    try {
      // Search for nondeterministic matches.
      // Worst-case time is exponential,
      // so give up if taking too long
      steps = 1000;
      var map = search(Map.of(), c1, c2, d1, d2);
      return map != null;
    } catch (Fail e) {
      return false;
    }
  }

  boolean subsumesForward(List<Clause> clauses, Clause c) {
    for (var d : clauses) if (subsumes(d, c)) return true;
    return false;
  }

  List<Clause> subsumeBackward(Clause c, List<Clause> clauses) {
    var v = new ArrayList<Clause>(clauses.size());
    for (var d : clauses) if (!subsumes(c, d)) v.add(d);
    return v;
  }
}
