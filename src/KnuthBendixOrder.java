import java.math.BigInteger;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

final class KnuthBendixOrder {
  private final Map<Object, Integer> weights = new HashMap<>();

  KnuthBendixOrder(List<Clause> clauses) {
    // TODO remove the clauses parameter
    var symbols = new LinkedHashSet<>();
    for (var c : clauses)
      for (var a : c.literals)
        Term.walk(
            b0 -> {
              switch (b0) {
                case Call b -> symbols.add(b.fn);
                case Fn b -> symbols.add(b);
                default -> symbols.add(b0.getClass());
              }
            },
            a);
    var i = 2;
    for (var a : symbols) weights.put(a, i++);
  }

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
      default -> weights.computeIfAbsent(Term.symbol(a), k -> weights.size() + 2);
    };
  }

  private long totalWeight(Object a) {
    long n = symbolWeight(a);
    for (var b : Term.args(a)) n += totalWeight(b);
    return n;
  }

  // TODO: shortcut comparison of identical terms?
  // TODO: pacman lemma?
  PartialOrder compare(Object a0, Object b0) {
    // variables
    var avariables = variables(a0);
    var bvariables = variables(b0);
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
    if (!maybeLt && !maybeGt) return Term.eq(a0, b0) ? PartialOrder.EQ : PartialOrder.UNORDERED;

    // total weight
    var atotalWeight = totalWeight(a0);
    var btotalWeight = totalWeight(b0);
    if (atotalWeight < btotalWeight) return maybeLt ? PartialOrder.LT : PartialOrder.UNORDERED;
    if (atotalWeight > btotalWeight) return maybeGt ? PartialOrder.GT : PartialOrder.UNORDERED;

    // different tags or functions mean different symbols
    var asymbolWeight = symbolWeight(a0);
    var bsymbolWeight = symbolWeight(b0);
    if (asymbolWeight < bsymbolWeight) return maybeLt ? PartialOrder.LT : PartialOrder.UNORDERED;
    if (asymbolWeight > bsymbolWeight) return maybeGt ? PartialOrder.GT : PartialOrder.UNORDERED;
    // TODO why?
    assert asymbolWeight == 1 || a0.getClass() == b0.getClass();

    // in some cases, the same tags can still mean different symbols, e.g. constants
    // with different values, or casts to different types
    switch (a0) {
      case Cast a -> {
        // TODO It is possible to order casts by type
        // but are they frequent enough for it to matter?
        return PartialOrder.UNORDERED;
      }
      case BigInteger a -> {
        return PartialOrder.of(a.compareTo((BigInteger) b0));
      }
      case BigRational a -> {
        return PartialOrder.of(a.compareTo((BigRational) b0));
      }
      case Real a -> {
        return PartialOrder.of(a.val().compareTo(((Real) b0).val()));
      }
      case DistinctObject a -> {
        if (!(b0 instanceof DistinctObject b)) throw new IllegalStateException(b0.toString());

        // here, we rely on distinct objects being ordered by their names, in other words behaving
        // as though they had
        // value semantics. Strictly speaking, this is only guaranteed by the TPTP parser; it is not
        // guaranteed by the
        // DistinctObject class itself, which doesn't enforce unique names, and is happy to allow
        // distinct objects
        // to be compared by reference for efficiency in other contexts. so assert that
        // the precondition holds here, i.e. different objects have different names
        assert a == b || !(a.name.equals(b.name));
        return PartialOrder.of(a.name.compareTo(b.name));
      }
      default -> {}
    }

    // recur
    if (a0 instanceof Call a) {
      var b = (Call) b0;
      var n = a.size();
      var i = 0;
      while (i < a.size() && Term.eq(a.get(i), b.get(i))) i++;
      if (i == n) return PartialOrder.EQ;
      return compare(a.get(i), b.get(i));
    }
    if (a0 instanceof Term a) {
      var b = (Term) b0;

      var n = a.size();
      assert n == b.size();

      var i = 0;
      while (i < a.size() && Term.eq(a.get(i), b.get(i))) i++;

      if (i == n) return PartialOrder.EQ;
      return compare(a.get(i), b.get(i));
    }
    assert Term.eq(a0, b0);
    return PartialOrder.EQ;
  }

  PartialOrder compare(boolean apol, Equation a, boolean bpol, Equation b) {
    if (apol == bpol) return EquationComparison.compare(this, a, b);
    return bpol
        ? EquationComparison.compareNP(this, a, b)
        : EquationComparison.compareNP(this, b, a).flip();
  }
}
