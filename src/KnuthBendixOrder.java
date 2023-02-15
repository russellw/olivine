import java.util.HashMap;
import java.util.Map;

final class KnuthBendixOrder {
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

  @SuppressWarnings("DuplicateBranchesInSwitch")
  private int symbolWeight(Object a) {
    return switch (a) {
      case Boolean ignored -> 1;
      case Variable ignored -> 1;
      default -> weights.computeIfAbsent(Term.symbol(a), key -> weights.size() + 2);
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

    // symbol weights are the same, so either the symbols are the same, or they
    // are different variables. The latter case would already have been caught by the variable check
    assert Term.symbol(a).equals(Term.symbol(b)) : String.format("%s != %s", a, b);

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
