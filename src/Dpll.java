import java.util.List;
import java.util.Map;

public final class Dpll {
  private long steps;
  private final boolean result;

  private static boolean isFalse(List<Clause> clauses) {
    for (var c : clauses) if (c.isFalse()) return true;
    return false;
  }

  private static boolean isTrue(List<Clause> clauses) {
    return clauses.isEmpty();
  }

  private boolean sat(List<Clause> clauses) {
    if (steps-- == 0) throw new Fail();
    if (isFalse(clauses)) return false;
    if (isTrue(clauses)) return true;

    // unit clause
    for (var c : clauses)
      if (c.literals.length == 1) {
        return sat(Clause.replace(Map.of(c.literals[0], c.negativeSize == 0), clauses));
      }

    // search
    var a = clauses.get(0).literals[0];
    return sat(Clause.replace(Map.of(a, false), clauses))
        || sat(Clause.replace(Map.of(a, true), clauses));
  }

  private Dpll(List<Clause> clauses, long steps) {
    this.steps = steps;
    result = sat(clauses);
  }

  static boolean sat(List<Clause> clauses, long steps) {
    assert Clause.propositional(clauses);
    for (var c : clauses) assert !c.isTrue();
    return new Dpll(clauses, steps).result;
  }
}
