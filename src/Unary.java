import java.math.BigInteger;
import java.util.Map;

abstract class Unary extends Term {

  Unary(Object a) {
    super(a);
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
}
