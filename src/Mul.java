import java.math.BigInteger;

final class Mul extends Binary {
  Mul(Object arg0, Object arg1) {
    super(arg0, arg1);
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
