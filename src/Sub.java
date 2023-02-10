import java.math.BigInteger;

final class Sub extends Binary {
  Sub(Object arg0, Object arg1) {
    super(arg0, arg1);
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
