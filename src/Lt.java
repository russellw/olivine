import java.math.BigInteger;

final class Lt extends Binary {
  Lt(Object arg0, Object arg1) {
    super(arg0, arg1);
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
