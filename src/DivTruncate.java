import java.math.BigInteger;

public final class DivTruncate extends Term {
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
