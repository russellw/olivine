import java.lang.reflect.InvocationTargetException;
import java.math.BigInteger;
import java.util.Map;
import java.util.function.UnaryOperator;

abstract class Binary extends Term {

  Binary(Object a, Object b) {
    super(a, b);
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

  Object mapLeaves(UnaryOperator<Object> f) {
    try {
      var ctor = getClass().getDeclaredConstructor(Object.class, Object.class);
      return ctor.newInstance(mapLeaves(f, args[0]), mapLeaves(f, args[1]));
    } catch (IllegalAccessException
        | InstantiationException
        | InvocationTargetException
        | NoSuchMethodException e) {
      throw new RuntimeException(e);
    }
  }

  Object eval(Map<Object, Object> map) {
    var a0 = Etc.get(map, this.args[0]);
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
