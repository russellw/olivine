import java.util.*;

public final class Clause {
  final Object[] literals;
  final int negativeSize;

  private Clause(Object[] literals, int negativeSize) {
    this.literals = literals;
    this.negativeSize = negativeSize;
  }

  static List<Clause> replace(Map<Object, Object> map, List<Clause> clauses) {
    var v = new ArrayList<Clause>(clauses.size());
    for (var c : clauses) {
      c = c.replace(map);
      if (!c.isTrue()) v.add(c);
    }
    return v;
  }

  Clause replace(Map<Object, Object> map) {
    var negative = new ArrayList<>(negativeSize);
    for (var i = 0; i < negativeSize; i++) negative.add(Term.replace(map, literals[i]));

    var positive = new ArrayList<>(positiveSize());
    for (var i = negativeSize; i < literals.length; i++)
      positive.add(Term.replace(map, literals[i]));

    return new Clause(negative, positive);
  }

  Clause renameVariables() {
    var map = new HashMap<Variable, Variable>();
    var v = new Object[literals.length];
    for (var i = 0; i < v.length; i++) {
      v[i] =
          Term.mapLeaves(
              a -> {
                if (a instanceof Variable a1) {
                  var b = map.get(a);
                  if (b == null) {
                    b = new Variable(a1.type);
                    map.put(a1, b);
                  }
                  return b;
                }
                return a;
              },
              literals[i]);
    }
    return new Clause(v, negativeSize);
  }

  public String toString() {
    return String.format("%s => %s", Arrays.toString(negative()), Arrays.toString(positive()));
  }

  Set<Variable> freeVariables() {
    var free = new LinkedHashSet<Variable>();
    for (var a : literals) Variable.freeVariables(a, Set.of(), free);
    return free;
  }

  static boolean propositional(List<Clause> clauses) {
    for (var c : clauses) for (var a : c.literals) if (!(a instanceof Fn)) return false;
    return true;
  }

  Clause(List<Object> negative, List<Object> positive) {
    // Simplify
    negative.replaceAll(Term::simplify);
    positive.replaceAll(Term::simplify);

    // Redundancy
    negative.removeIf(a -> a == Boolean.TRUE);
    positive.removeIf(a -> a == Boolean.FALSE);

    // Tautology?
    if (tautology(negative, positive)) {
      literals = new Object[] {Boolean.TRUE};
      negativeSize = 0;
      return;
    }

    // Literals
    negativeSize = negative.size();
    literals = new Object[negativeSize + positive.size()];
    for (var i = 0; i < negativeSize; i++) literals[i] = negative.get(i);
    for (var i = 0; i < positive.size(); i++) literals[negativeSize + i] = positive.get(i);
  }

  Object[] negative() {
    return Arrays.copyOf(literals, negativeSize);
  }

  Object[] positive() {
    return Arrays.copyOfRange(literals, negativeSize, literals.length);
  }

  int positiveSize() {
    return literals.length - negativeSize;
  }

  boolean isFalse() {
    return literals.length == 0;
  }

  boolean isTrue() {
    if (literals.length == 1 && literals[0] == Boolean.TRUE) {
      assert negativeSize == 0;
      return true;
    }
    return false;
  }

  private static boolean tautology(List<Object> negative, List<Object> positive) {
    if (negative.contains(Boolean.FALSE)) return true;
    if (positive.contains(Boolean.TRUE)) return true;
    for (var a : negative) if (positive.contains(a)) return true;
    return false;
  }
}
