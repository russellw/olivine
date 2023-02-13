import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Set;

@SuppressWarnings("ClassCanBeRecord")
final class Var {
  // TODO class name?
  final Type type;

  Var(Type type) {
    this.type = type;
  }

  static Set<Var> freeVars(Object a) {
    var free = new LinkedHashSet<Var>();
    freeVars(a, Set.of(), free);
    return free;
  }

  static void freeVars(Object a0, Set<Var> bound, Set<Var> free) {
    switch (a0) {
      case Var a -> {
        if (!bound.contains(a)) free.add(a);
      }
      case Quantifier a -> {
        bound = new HashSet<>(bound);
        bound.addAll(Arrays.asList(a.vars));
        freeVars(a.body, bound, free);
      }
      case Term a -> {
        for (var b : a) freeVars(b, bound, free);
      }
      default -> {}
    }
  }

  public String toString() {
    return String.format("%s@%x", type, hashCode());
  }
}
