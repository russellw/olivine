import java.math.BigInteger;

public final class Lt extends Term {
  Lt(Object a, Object b) {
    super(a, b);
  }

  Object apply(int a, int b) {
    return a < b;
  }

  Object apply(BigInteger a, BigInteger b) {
    return a.compareTo(b) < 0;
  }

  Type type() {
    return BooleanType.instance;
  }

  Object apply(BigRational a, BigRational b) {
    return a.compareTo(b) < 0;
  }
}
