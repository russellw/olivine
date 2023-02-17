import java.lang.reflect.InvocationTargetException;
import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;
import java.util.function.UnaryOperator;
import org.objectweb.asm.MethodVisitor;

public abstract class Term {
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

  static Object[] args(Object a) {
    if (a instanceof Term a1) return a1.args;
    return new Object[0];
  }

  void write(MethodVisitor methodVisitor) {
    throw new UnsupportedOperationException(toString());
  }

  Object eval(Map<Object, Object> map) {
    var a = Etc.get(map, this.args[0]);
    switch (args.length) {
      case 1 -> {
        return switch (a) {
          case Integer a1 -> apply(a1);
          case BigInteger a1 -> apply(a1);
          case BigRational a1 -> apply(a1);
          case Real a1 -> {
            var r0 = apply(a1.val());
            if (r0 instanceof BigRational r) yield new Real(r);
            yield r0;
          }
          default -> throw new IllegalArgumentException(toString());
        };
      }
      case 2 -> {
        var b = Etc.get(map, this.args[1]);
        return switch (a) {
          case Integer a1 -> apply(a1, (Integer) b);
          case BigInteger a1 -> apply(a1, (BigInteger) b);
          case BigRational a1 -> apply(a1, (BigRational) b);
          case Real a1 -> {
            var r = apply(a1.val(), ((Real) b).val());
            if (r instanceof BigRational r1) yield new Real(r1);
            yield r;
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

  static Object symbol(Object a) {
    return switch (a) {
      case Call a1 -> a1.fn;
      case Cast a1 -> a1.type();
      case Term a1 -> a1.getClass();
      default -> a;
    };
  }

  static Object mapLeaves(UnaryOperator<Object> f, Object a) {
    if (a instanceof Term a1) {
      var v = new Object[a1.args.length];
      for (var i = 0; i < v.length; i++) v[i] = mapLeaves(f, a1.args[i]);
      return a1.remake(v);
    }
    return f.apply(a);
  }

  Object simplify() {
    // recur
    var v = new Object[args.length];
    for (var i = 0; i < v.length; i++) v[i] = simplify(args[i]);
    var a = remake(v);

    // if arguments are constant, evaluate
    for (var b : v) if (!Etc.constant(b)) return a;
    return a.eval(null);
  }

  static Object simplify(Object a) {
    if (a instanceof Term a1) return a1.simplify();
    return a;
  }

  static Object splice(Object a, List<Integer> position, int i, Object b) {
    if (i == position.size()) return b;
    var a1 = (Term) a;
    var v = a1.args.clone();
    var j = position.get(i);
    v[j] = splice(v[j], position, i + 1, b);
    return a1.remake(v);
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
