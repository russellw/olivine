import java.math.BigInteger;

public final class Sub extends Term {
  Sub(Object a, Object b) {
    super(a, b);
  }

  Object apply(int a, int b) {
    return a - b;
  }

  Object apply(BigInteger a, BigInteger b) {
    return a.subtract(b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.sub(b);
  }
}
