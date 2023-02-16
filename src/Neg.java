import java.math.BigInteger;

public final class Neg extends Term {
  Neg(Object a) {
    super(a);
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
