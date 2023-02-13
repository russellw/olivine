import java.math.BigInteger;

final class DivTruncate extends Binary {
  DivTruncate(Object a, Object b) {
    super(a, b);
  }

  Object apply(int a, int b) {
    return a / b;
  }

  Object apply(BigInteger a, BigInteger b) {
    return a.divide(b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.divTruncate(b);
  }
}
