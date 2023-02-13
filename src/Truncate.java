import java.math.BigInteger;

final class Truncate extends Term {
  Truncate(Object a) {
    super(a);
  }

  Object apply(BigInteger a) {
    return a;
  }

  Object apply(BigRational a) {
    return a.truncate();
  }
}
