import java.util.HashMap;
import java.util.Map;

public final class KnuthBendixOrder {
  private final Map<Object, Integer> weights = new HashMap<>();

  private static Map<Variable, Integer> variables(Object a) {
    var map = new HashMap<Variable, Integer>();
    Term.walk(
        b -> {
          if (b instanceof Variable b1) map.put(b1, map.getOrDefault(b1, 0) + 1);
        },
        a);
    return map;
  }

  private int symbolWeight(Object a) {
    return switch (a) {
      case Boolean a1 -> {
        assert a1;
        yield 2;
      }
      case Variable ignored -> 1;
      default -> weights.computeIfAbsent(Term.symbol(a), key -> weights.size() + 3);
    };
  }

  private long totalWeight(Object a) {
    long n = symbolWeight(a);
    for (var b : Term.args(a)) n += totalWeight(b);
    return n;
  }

  // TODO: shortcut comparison of identical terms?
  // TODO: pacman lemma?
  PartialOrder compare(Object a, Object b) {
    // variables
    var avariables = variables(a);
    var bvariables = variables(b);
    var maybeLt = true;
    var maybeGt = true;
    for (var kv : avariables.entrySet())
      if (kv.getValue() > bvariables.getOrDefault(kv.getKey(), 0)) {
        maybeLt = false;
        break;
      }
    for (var kv : bvariables.entrySet())
      if (kv.getValue() > avariables.getOrDefault(kv.getKey(), 0)) {
        maybeGt = false;
        break;
      }
    if (!maybeLt && !maybeGt) return Term.eq(a, b) ? PartialOrder.EQ : PartialOrder.UNORDERED;

    // total weight
    var atotalWeight = totalWeight(a);
    var btotalWeight = totalWeight(b);
    if (atotalWeight < btotalWeight) return maybeLt ? PartialOrder.LT : PartialOrder.UNORDERED;
    if (atotalWeight > btotalWeight) return maybeGt ? PartialOrder.GT : PartialOrder.UNORDERED;

    // symbol weight
    var asymbolWeight = symbolWeight(a);
    var bsymbolWeight = symbolWeight(b);
    if (asymbolWeight < bsymbolWeight) return maybeLt ? PartialOrder.LT : PartialOrder.UNORDERED;
    if (asymbolWeight > bsymbolWeight) return maybeGt ? PartialOrder.GT : PartialOrder.UNORDERED;

    // recur
    var av = Term.args(a);
    var bv = Term.args(b);
    for (var i = 0; ; i++) {
      if (i == av.length || i == bv.length)
        return PartialOrder.of(Integer.compare(av.length, bv.length));
      if (!Term.eq(av[i], bv[i])) return compare(av[i], bv[i]);
    }
  }

  PartialOrder compare(boolean apol, Equation a, boolean bpol, Equation b) {
    if (apol == bpol) return EquationComparison.compare(this, a, b);
    return bpol
        ? EquationComparison.compareNP(this, a, b)
        : EquationComparison.compareNP(this, b, a).flip();
  }
}
