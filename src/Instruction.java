import java.util.AbstractCollection;
import java.util.Iterator;
import java.util.Map;
import java.util.function.Consumer;
import java.util.function.UnaryOperator;

abstract class Instruction extends AbstractCollection<Object> {
  // TODO would Term be a better name?
  static void walk(Consumer<Object> f, Object a0) {
    f.accept(a0);
    if (a0 instanceof Instruction a) for (var b : a) walk(f, b);
  }

  static long symbolCount(Object a0) {
    long n = 1;
    if (a0 instanceof Instruction a) for (var b : a) n += symbolCount(b);
    return n;
  }

  static Object replace(Map<?, Object> map, Object a) {
    return mapLeaves(
        b -> {
          var b1 = map.get(b);
          if (b1 != null) return replace(map, b1);
          return b;
        },
        a);
  }

  Object mapLeaves(UnaryOperator<Object> f) {
    throw new UnsupportedOperationException(toString());
  }

  Type type() {
    throw new UnsupportedOperationException(toString());
  }

  static boolean eq(Object a0, Object b0) {
    if (a0 instanceof Instruction a && b0 instanceof Instruction b) {
      if (a.getClass() != b.getClass()) return false;
      if (a instanceof Call a1 && a1.fn != ((Call) b).fn) return false;
      var n = a.size();
      if (n != b.size()) return false;
      for (var i = 0; i < n; i++) if (!eq(a.get(i), b.get(i))) return false;
      return true;
    }
    return a0.equals(b0);
  }

  static Object mapLeaves(UnaryOperator<Object> f, Object a0) {
    // TODO should this be just mapVars?
    if (a0 instanceof Instruction a) return a.mapLeaves(f);
    return f.apply(a0);
  }

  static Object simplify(Object a0) {
    // TODO
    return a0;
  }

  void set(int i, Object a) {
    throw new UnsupportedOperationException(toString());
  }

  Object eval(Map<Object, Object> map) {
    throw new UnsupportedOperationException(toString());
  }

  Object get(int i) {
    throw new UnsupportedOperationException(toString());
  }

  static Or implies(Object a, Object b) {
    return new Or(new Not(a), b);
  }

  public String toString() {
    var sb = new StringBuilder(getClass().getSimpleName());
    sb.append('(');
    for (var i = 0; i < size(); i++) {
      if (i > 0) sb.append(',');
      sb.append(get(i));
    }
    sb.append(')');
    return sb.toString();
  }

  public Iterator<Object> iterator() {
    return new Iterator<>() {
      public boolean hasNext() {
        return false;
      }

      public Object next() {
        throw new UnsupportedOperationException();
      }
    };
  }

  public int size() {
    return 0;
  }
}
