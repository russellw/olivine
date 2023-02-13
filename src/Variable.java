import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Set;

@SuppressWarnings("ClassCanBeRecord")
final class Variable {
  final Type type;

  Variable(Type type) {
    this.type = type;
  }

  static Set<Variable> freeVariables(Object a) {
    var free = new LinkedHashSet<Variable>();
    freeVariables(a, Set.of(), free);
    return free;
  }

  static void freeVariables(Object a0, Set<Variable> bound, Set<Variable> free) {
    switch (a0) {
      case Variable a -> {
        if (!bound.contains(a)) free.add(a);
      }
      case Quantifier a -> {
        bound = new HashSet<>(bound);
        bound.addAll(Arrays.asList(a.variables));
        freeVariables(a.body, bound, free);
      }
      case Term a -> {
        for (var b : a) freeVariables(b, bound, free);
      }
      default -> {}
    }
  }

  public String toString() {
    return String.format("%s@%x", type, hashCode());
  }
}
