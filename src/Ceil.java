import java.math.BigInteger;

final class Ceil extends Unary {
  Ceil(Object a) {
    super(a);
  }

  Object apply(BigInteger a) {
    return a;
  }

  Object apply(BigRational a) {
    return a.ceil();
  }
}
