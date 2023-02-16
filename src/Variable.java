import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Set;

@SuppressWarnings("ClassCanBeRecord")
public final class Variable {
  final Type type;

  Variable(Type type) {
    this.type = type;
  }

  static Set<Variable> freeVariables(Object a) {
    var free = new LinkedHashSet<Variable>();
    freeVariables(a, Set.of(), free);
    return free;
  }

  static void freeVariables(Object a, Set<Variable> bound, Set<Variable> free) {
    switch (a) {
      case Variable a1 -> {
        if (!bound.contains(a)) free.add(a1);
      }
      case Quantifier a1 -> {
        bound = new HashSet<>(bound);
        bound.addAll(Arrays.asList(a1.variables));
        freeVariables(a1.body, bound, free);
      }
      case Term a1 -> {
        for (var b : a1.args) freeVariables(b, bound, free);
      }
      default -> {}
    }
  }

  public String toString() {
    return String.format("%s#%x", type, hashCode());
  }
}
