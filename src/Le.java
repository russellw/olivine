import java.math.BigInteger;

final class Le extends Binary {
  Le(Object a, Object b) {
    super(a, b);
  }

  Object apply(int a, int b) {
    return a <= b;
  }

  Object apply(BigInteger a, BigInteger b) {
    return a.compareTo(b) <= 0;
  }

  Type type() {
    return BooleanType.instance;
  }

  Object apply(BigRational a, BigRational b) {
    return a.compareTo(b) <= 0;
  }
}
