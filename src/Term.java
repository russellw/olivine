import java.lang.reflect.InvocationTargetException;
import java.math.BigInteger;
import java.util.Arrays;
import java.util.Map;
import java.util.function.Consumer;
import java.util.function.UnaryOperator;

abstract class Term {
  final Object[] args;

  static void walk(Consumer<Object> f, Object a) {
    f.accept(a);
    for (var b : args(a)) walk(f, b);
  }

  static long treeSize(Object a) {
    long n = 1;
    for (var b : args(a)) n += treeSize(b);
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

  int apply(int a) {
    throw new UnsupportedOperationException(toString());
  }

  Object apply(BigInteger a) {
    throw new UnsupportedOperationException(toString());
  }

  Object apply(BigRational a) {
    throw new UnsupportedOperationException(toString());
  }

  Term remake(Object[] v) {
    var params = new Class[v.length];
    Arrays.fill(params, Object.class);
    try {
      var ctor = getClass().getDeclaredConstructor(params);
      return ctor.newInstance(v);
    } catch (IllegalAccessException
        | InstantiationException
        | InvocationTargetException
        | NoSuchMethodException e) {
      throw new RuntimeException(e);
    }
  }

  Type type() {
    return Type.of(args[0]);
  }

  Object apply(int a, int b) {
    throw new UnsupportedOperationException(toString());
  }

  Object apply(BigInteger a, BigInteger b) {
    throw new UnsupportedOperationException(toString());
  }

  Object apply(BigRational a, BigRational b) {
    throw new UnsupportedOperationException(toString());
  }

  static Object[] args(Object a0) {
    if (a0 instanceof Term a) return a.args;
    return new Object[0];
  }

  Object eval(Map<Object, Object> map) {
    var a0 = Etc.get(map, this.args[0]);
    switch (args.length) {
      case 1 -> {
        return switch (a0) {
          case Integer a -> apply(a);
          case BigInteger a -> apply(a);
          case BigRational a -> apply(a);
          case Real a -> {
            var r0 = apply(a.val());
            if (r0 instanceof BigRational r) yield new Real(r);
            yield r0;
          }
          default -> throw new IllegalArgumentException(toString());
        };
      }
      case 2 -> {
        var b = Etc.get(map, this.args[1]);
        return switch (a0) {
          case Integer a -> apply(a, (Integer) b);
          case BigInteger a -> apply(a, (BigInteger) b);
          case BigRational a -> apply(a, (BigRational) b);
          case Real a -> {
            var r0 = apply(a.val(), ((Real) b).val());
            if (r0 instanceof BigRational r) yield new Real(r);
            yield r0;
          }
          default -> throw new IllegalArgumentException(toString());
        };
      }
    }
    throw new UnsupportedOperationException(toString());
  }

  static boolean eq(Object a, Object b) {
    if (!(symbol(a).equals(symbol(b)))) return false;
    var av = args(a);
    var bv = args(b);
    if (av.length != bv.length) return false;
    for (var i = 0; i < av.length; i++) if (!eq(av[i], bv[i])) return false;
    return true;
  }

  static Object symbol(Object a0) {
    return switch (a0) {
      case Call a -> a.fn;
      case Cast a -> a.type();
      case Term a -> a.getClass();
      default -> a0;
    };
  }

  static Object mapLeaves(UnaryOperator<Object> f, Object a0) {
    if (a0 instanceof Term a) {
      var v = new Object[a.args.length];
      for (var i = 0; i < v.length; i++) v[i] = mapLeaves(f, a.args[i]);
      return a.remake(v);
    }
    return f.apply(a0);
  }

  static Object simplify(Object a0) {
    // TODO
    return a0;
  }

  Term(Object... args) {
    this.args = args;
  }

  static Or implies(Object a, Object b) {
    return new Or(new Not(a), b);
  }

  public String toString() {
    var sb = new StringBuilder(getClass().getSimpleName());
    sb.append('(');
    for (var i = 0; i < args.length; i++) {
      if (i > 0) sb.append(',');
      sb.append(args[i]);
    }
    sb.append(')');
    return sb.toString();
  }
}
