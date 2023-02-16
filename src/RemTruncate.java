import java.math.BigInteger;

public final class RemTruncate extends Term {
  RemTruncate(Object a, Object b) {
    super(a, b);
  }

  Object apply(int a, int b) {
    return a % b;
  }

  Object apply(BigInteger a, BigInteger b) {
    return a.remainder(b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.remTruncate(b);
  }
}
