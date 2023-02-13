import java.math.BigInteger;

final class Truncate extends Unary {
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
