import java.math.BigInteger;

public final class Mul extends Term {
  Mul(Object a, Object b) {
    super(a, b);
  }

  Object apply(int a, int b) {
    return a * b;
  }

  Object apply(BigInteger a, BigInteger b) {
    return a.multiply(b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.mul(b);
  }
}
