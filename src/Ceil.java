import java.math.BigInteger;

final class Ceil extends Unary {
  Ceil(Object arg) {
    super(arg);
  }

  Object apply(BigInteger a) {
    return a;
  }

  Object apply(BigRational a) {
    return a.ceil();
  }
}
