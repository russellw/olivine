import java.math.BigInteger;

final class Truncate extends Unary {
  Truncate(Object arg) {
    super(arg);
  }

  Object apply(BigInteger a) {
    return a;
  }

  Object apply(BigRational a) {
    return a.truncate();
  }
}
