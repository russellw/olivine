import java.math.BigInteger;
import java.util.Map;

abstract class Unary extends Term {

  Unary(Object arg) {
    super(arg);
  }

  Object eval(Map<Object, Object> map) {
    var a0 = Etc.get(map, args[0]);
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

  int apply(int a) {
    throw new UnsupportedOperationException(toString());
  }

  Object apply(BigInteger a) {
    throw new UnsupportedOperationException(toString());
  }

  Object apply(BigRational a) {
    throw new UnsupportedOperationException(toString());
  }
}
