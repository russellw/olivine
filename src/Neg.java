import java.math.BigInteger;

final class Neg extends Unary {
  Neg(Object arg) {
    super(arg);
  }

  int apply(int a) {
    return -a;
  }

  Object apply(BigInteger a) {
    return a.negate();
  }

  Object apply(BigRational a) {
    return a.neg();
  }
}
